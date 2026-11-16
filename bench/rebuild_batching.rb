# frozen_string_literal: true

require "etc"
require "fileutils"
require "json"
require "logger"

# Reproducible seed and rebuild benchmark for sitemap URL batching.
#
# From test/dummy:
#   DB_NAME=sitemap_bench SEED=1 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench MEASURE=1 MODE=stock RUNS=5 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench MEASURE=1 MODE=preload RUNS=5 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench MEASURE=1 MODE=join RUNS=5 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench CHECK=1 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench EXPOSURE=1 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench PROFILE=wall bundle exec rails runner /workspace/bench/rebuild_batching.rb
#   DB_NAME=sitemap_bench MEMORY=1 bundle exec rails runner /workspace/bench/rebuild_batching.rb
#
# MODE=gem measures the code on disk. MODE=stock forces the per-row lookup.
# MODE=preload and MODE=join patch the running process only.
#
# Claim, written before the timed runs: removing the per-row indexable_url and
# current_publishable_for_index lookups cuts rebuild wall time by more than the
# run-to-run spread. If the after median does not fall below the before
# minimum, do not ship.

CLAIM = "Removing per-row indexable_url and current_publishable_for_index lookups cuts rebuild wall time by more than the run-to-run spread. If the after median does not fall below the before minimum, do not ship."

ROOTS = Integer(ENV.fetch("ROOTS", "850"))
INDEXABLE_COUNT = Integer(ENV.fetch("INDEXABLE", "3700"))
EXCLUDED_EACH = Integer(ENV.fetch("EXCLUDED_EACH", "120"))
BATCH_SIZE = 500
ABSOLUTE_CANONICAL = 1..200
RELATIVE_CANONICAL = 201..220
OFFHOST_CANONICAL = 221..230
PUBLIC_BASE_URL = ENV.fetch("SITEMAP_PUBLIC_BASE_URL", "http://localhost:3000")
ARTIFACTS = ENV.fetch("BENCH_ARTIFACTS", "/opt/cursor/artifacts/bench")

module BenchUrlBatch
  UrlContext = Struct.new(:url, :publish_at, keyword_init: true)
  ChildRef = Struct.new(:id, keyword_init: true)

  module_function

  def contexts_for(recordables, parents_by_recordable_id)
    parents = recordables.filter_map { |recordable| parents_by_recordable_id[recordable.id] }
    children = children_by_parent_id(parents)
    publishables = publishables_by_id(children.values)
    recordables.each_with_object({}) do |recordable, map|
      parent = parents_by_recordable_id[recordable.id]
      child = parent && children[parent.id]
      publishable = child && publishables[child.recordable_id]
      map[recordable.id] = context_for(recordable, child, publishable)
    end
  end

  def contexts_from_joined_rows(rows)
    rows.each_with_object({}) do |row, map|
      map[row.id] = joined_context(row)
    end
  end

  def joined_select(type)
    table = type.table_name
    [
      "#{table}.*",
      "publishable_recordings.id AS sitemap_child_id",
      "recording_studio_publishable_publishables.slug AS sitemap_slug",
      "recording_studio_publishable_publishables.canonical_url AS sitemap_canonical_url",
      "recording_studio_publishable_publishables.publish_at AS sitemap_publish_at",
      "recording_studio_publishable_publishables.unpublish_at AS sitemap_unpublish_at",
      "recording_studio_publishable_publishables.status AS sitemap_status",
      "recording_studio_publishable_publishables.meta_robots AS sitemap_meta_robots"
    ].join(", ")
  end

  def active_recordings
    model = RecordingStudio::Recording
    return model.kept if model.respond_to?(:kept)

    model.where(trashed_at: nil)
  end

  def children_by_parent_id(parents)
    return {} if parents.empty?

    scope = active_recordings.where(parent_recording_id: parents.map(&:id))
    scope = scope.of_type(RecordingStudioPublishable::Publishable)
    scope.order(:id).each_with_object({}) do |child, map|
      map[child.parent_recording_id] ||= child
    end
  end

  def publishables_by_id(children)
    ids = children.map(&:recordable_id)
    return {} if ids.empty?

    RecordingStudioPublishable::Publishable.where(id: ids).index_by(&:id)
  end

  def context_for(recordable, child, publishable)
    return UrlContext.new if publishable.blank? || publishable.noindex?

    url = resolved_url(recordable, child, publishable)
    url = nil unless recordable.class.indexable_url?(url)
    UrlContext.new(url: url, publish_at: publishable.publish_at)
  end

  def resolved_url(recordable, child, publishable)
    canonical = publishable.canonical_url.presence
    return canonical if canonical
    return if child.blank? || !publishable.currently_published?

    RecordingStudioPublishable::Routing.url_for(
      publishable_recording: child,
      publishable: publishable,
      parent_recordable_type: recordable.class.name
    )
  end

  def joined_context(row)
    publishable = instantiate_publishable(row)
    return UrlContext.new if publishable.blank? || publishable.noindex?

    child_id = row.read_attribute("sitemap_child_id")
    child = ChildRef.new(id: child_id) if child_id.present?
    url = resolved_url(row, child, publishable)
    url = nil unless row.class.indexable_url?(url)
    UrlContext.new(url: url, publish_at: publishable.publish_at)
  end

  def instantiate_publishable(row)
    attributes = {
      "slug" => row.read_attribute("sitemap_slug"),
      "canonical_url" => row.read_attribute("sitemap_canonical_url"),
      "publish_at" => row.read_attribute("sitemap_publish_at"),
      "unpublish_at" => row.read_attribute("sitemap_unpublish_at"),
      "status" => row.read_attribute("sitemap_status"),
      "meta_robots" => row.read_attribute("sitemap_meta_robots")
    }
    return if attributes["slug"].blank? && attributes["status"].blank?

    RecordingStudioPublishable::Publishable.instantiate(attributes)
  end

  def loc_for(url)
    RecordingStudioSitemaps::AbsoluteUrl.call(url)
  end
end

module BenchHarness
  module_function

  def prepare!
    STDOUT.sync = true
    pin_public_base_url!
    silence_logs! unless ENV["NOISY"] == "1"
    memoize_trashed_at_column!
    capture_originals!
  end

  # Trashable asks the connection if trashed_at exists on every kept scope.
  # That bypasses the schema cache, so a seed pays a full column lookup per call.
  # The column does not change during a run.
  # Each publishable write runs the sitemap publish hook, which rebuilds the
  # whole url set. Leaving that on makes the seed quadratic. Measurement
  # restores the real rebuild!.
  def silence_publish_rebuilds!
    singleton = class << RecordingStudioSitemaps; self; end
    unless singleton.method_defined?(:bench_original_rebuild!)
      singleton.alias_method :bench_original_rebuild!, :rebuild!
    end
    singleton.define_method(:rebuild!) { |source: :system| nil }
  end

  def restore_publish_rebuilds!
    singleton = class << RecordingStudioSitemaps; self; end
    return unless singleton.method_defined?(:bench_original_rebuild!)

    singleton.alias_method :rebuild!, :bench_original_rebuild!
  end

  def memoize_trashed_at_column!
    return unless defined?(RecordingStudioTrashable::RecordingFilter)
    return unless RecordingStudioTrashable::RecordingFilter.respond_to?(:trashed_at_column?)

    filter = RecordingStudioTrashable::RecordingFilter.singleton_class
    return if filter.method_defined?(:bench_original_trashed_at_column?)

    filter.alias_method :bench_original_trashed_at_column?, :trashed_at_column?
    filter.define_method(:trashed_at_column?) do
      return @bench_trashed_at_column if defined?(@bench_trashed_at_column)

      @bench_trashed_at_column = bench_original_trashed_at_column?
    end
  end

  def pin_public_base_url!
    RecordingStudioSitemaps.configuration.public_base_url = PUBLIC_BASE_URL
  end

  def silence_logs!
    null_logger = Logger.new(nil)
    null_logger.level = Logger::ERROR
    Rails.logger = null_logger if defined?(Rails)
    ActiveRecord::Base.logger = null_logger
    ActiveRecord.verbose_query_logs = false if ActiveRecord.respond_to?(:verbose_query_logs=)
    ActiveRecord.query_log_tags_enabled = false if ActiveRecord.respond_to?(:query_log_tags_enabled=)
  end

  def api
    if defined?(RecordingStudioSitemaps::Sources::Publishable)
      :main
    elsif defined?(RecordingStudioSitemaps::UrlSet)
      :v090
    else
      raise "This app has neither Sources::Publishable nor UrlSet"
    end
  end

  def version
    RecordingStudioSitemaps::VERSION
  end

  def capture_originals!
    return if @captured

    case api
    when :main
      klass = RecordingStudioSitemaps::Sources::Publishable
      klass.alias_method :bench_original_entries_for, :entries_for
      klass.alias_method :bench_original_entry_for, :entry_for
      klass.alias_method :bench_original_yield_type, :yield_type
    when :v090
      klass = RecordingStudioSitemaps::UrlSet
      klass.alias_method :bench_original_entries, :entries
      klass.alias_method :bench_original_entries_for, :entries_for
      klass.alias_method :bench_original_entry_for, :entry_for
    end
    @captured = true
  end

  def install!(mode)
    capture_originals!
    case mode.to_s
    when "gem", ""
      restore_booted_methods!
    when "stock"
      api == :main ? install_main_stock! : restore_booted_methods!
    when "preload"
      api == :main ? install_main_preload! : install_v090_preload!
    when "join"
      api == :main ? install_main_join! : install_v090_join!
    else
      raise "Unknown MODE=#{mode}"
    end
  end

  def restore_booted_methods!
    case api
    when :main
      klass = RecordingStudioSitemaps::Sources::Publishable
      klass.alias_method :entries_for, :bench_original_entries_for
      klass.alias_method :entry_for, :bench_original_entry_for
      klass.alias_method :yield_type, :bench_original_yield_type
    when :v090
      klass = RecordingStudioSitemaps::UrlSet
      klass.alias_method :entries, :bench_original_entries
      klass.alias_method :entries_for, :bench_original_entries_for
      klass.alias_method :entry_for, :bench_original_entry_for
    end
  end

  def install_main_stock!
    RecordingStudioSitemaps::Sources::Publishable.class_eval do
      def yield_type(type)
        each_recordable_batch(type.indexable) do |recordables|
          entries = entries_for(type, recordables)
          @batch.yield(entries) if entries.any?
        end
      end

      def entries_for(type, recordables)
        recordings = recordings_for(type, recordables)
        recordables.filter_map { |recordable| entry_for(recordable, recordings[recordable.id]) }
      end

      def entry_for(recordable, recording)
        loc = RecordingStudioSitemaps::AbsoluteUrl.call(recordable.try(:indexable_url))
        return if loc.blank?

        RecordingStudioSitemaps::Entry.new(
          loc: loc,
          lastmod: lastmod_for(recordable),
          title: title_for(recordable),
          type: type_label(recordable),
          recording: recording
        )
      end
    end
  end

  def install_main_preload!
    RecordingStudioSitemaps::Sources::Publishable.class_eval do
      def entries_for(type, recordables)
        recordings = recordings_for(type, recordables)
        contexts = BenchUrlBatch.contexts_for(recordables, recordings)
        recordables.filter_map do |recordable|
          entry_from_context(recordable, recordings[recordable.id], contexts[recordable.id])
        end
      end

      def entry_from_context(recordable, recording, context)
        loc = BenchUrlBatch.loc_for(context&.url)
        return if loc.blank?

        RecordingStudioSitemaps::Entry.new(
          loc: loc,
          lastmod: context.publish_at,
          title: title_for(recordable),
          type: type_label(recordable),
          recording: recording
        )
      end
    end
  end

  def install_main_join!
    RecordingStudioSitemaps::Sources::Publishable.class_eval do
      def yield_type(type)
        relation = type.indexable.select(BenchUrlBatch.joined_select(type))
        each_recordable_batch(relation) do |recordables|
          recordings = recordings_for(type, recordables)
          contexts = BenchUrlBatch.contexts_from_joined_rows(recordables)
          entries = recordables.filter_map do |recordable|
            entry_from_context(recordable, recordings[recordable.id], contexts[recordable.id])
          end
          @batch.yield(entries) if entries.any?
        end
      end

      def entry_from_context(recordable, recording, context)
        loc = BenchUrlBatch.loc_for(context&.url)
        return if loc.blank?

        RecordingStudioSitemaps::Entry.new(
          loc: loc,
          lastmod: context.publish_at,
          title: title_for(recordable),
          type: type_label(recordable),
          recording: recording
        )
      end
    end
  end

  def install_v090_preload!
    RecordingStudioSitemaps::UrlSet.class_eval do
      def entries_for(type)
        relation = type.indexable
        return entries_from_rows(relation.to_a) unless relation.respond_to?(:in_batches)

        collected = []
        relation.in_batches(of: BenchHarness::BATCH_SIZE) do |batch|
          rows = batch.to_a
          collected.concat(entries_from_rows(rows)) if rows.any?
        end
        collected
      end

      def entries_from_rows(rows)
        parents = bench_parents(rows)
        contexts = BenchUrlBatch.contexts_for(rows, parents)
        rows.filter_map { |row| entry_from_context(row, contexts[row.id]) }
      end

      def entry_from_context(recordable, context)
        loc = BenchUrlBatch.loc_for(context&.url)
        return if loc.blank?

        RecordingStudioSitemaps::UrlSet::Entry.new(
          loc: loc,
          lastmod: context.publish_at,
          recordable: recordable
        )
      end

      def bench_parents(rows)
        return {} if rows.empty?

        type_name = rows.first.class.name
        scope = BenchUrlBatch.active_recordings.where(recordable_type: type_name, recordable_id: rows.map(&:id))
        scope.order(:created_at, :id).each_with_object({}) do |recording, map|
          map[recording.recordable_id] = recording
        end
      end
    end
  end

  def install_v090_join!
    RecordingStudioSitemaps::UrlSet.class_eval do
      def entries_for(type)
        relation = type.indexable.select(BenchUrlBatch.joined_select(type))
        return entries_from_joined(relation.to_a) unless relation.respond_to?(:in_batches)

        collected = []
        relation.in_batches(of: BenchHarness::BATCH_SIZE) do |batch|
          rows = batch.to_a
          collected.concat(entries_from_joined(rows)) if rows.any?
        end
        collected
      end

      def entries_from_joined(rows)
        contexts = BenchUrlBatch.contexts_from_joined_rows(rows)
        rows.filter_map { |row| entry_from_context(row, contexts[row.id]) }
      end

      def entry_from_context(recordable, context)
        loc = BenchUrlBatch.loc_for(context&.url)
        return if loc.blank?

        RecordingStudioSitemaps::UrlSet::Entry.new(
          loc: loc,
          lastmod: context.publish_at,
          recordable: recordable
        )
      end
    end
  end

  BATCH_SIZE = ::BATCH_SIZE
end

module BenchSeed
  module_function

  def call
    BenchHarness.silence_publish_rebuilds!
    puts "seed start #{Time.now.utc.iso8601} roots=#{ROOTS} indexable=#{INDEXABLE_COUNT} excluded_each=#{EXCLUDED_EACH}"
    user = ensure_user!
    Current.actor = user if defined?(Current)
    roots = ensure_roots!(user)
    puts "seed roots ready #{roots.length}"
    slugs = RecordingStudioPublishable::Publishable.pluck(:slug).to_set
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    seed_indexable!(user, roots, slugs, started)
    seed_excluded!(user, roots, slugs, started)
    print_counts!
  end

  def ensure_user!
    email = "bench@example.com"
    user = User.find_by(email: email)
    return user if user

    User.create!(email: email, password: "Password123!", password_confirmation: "Password123!")
  end

  def ensure_roots!(user)
    existing = Workspace.where("name LIKE ?", "Bench root %").index_by(&:name)
    Array.new(ROOTS) do |index|
      name = format("Bench root %04d", index + 1)
      workspace = existing[name] || Workspace.create!(name: name)
      root = root_for(workspace) || create_root!(workspace, user)
      folder = folder_for(root) || create_folder!(root, user, index)
      { workspace: workspace, root: root, folder: folder }
    end
  end

  def root_for(workspace)
    RecordingStudio::Recording.where(recordable: workspace, parent_recording_id: nil).order(:created_at, :id).last
  end

  def folder_for(root)
    BenchUrlBatch.active_recordings.where(parent_recording: root, recordable_type: "Folder").order(:created_at, :id).first
  end

  def create_root!(recordable, actor)
    if RecordingStudio.respond_to?(:create_root_recording!)
      RecordingStudio.create_root_recording!(recordable, actor: actor)
    else
      RecordingStudio.root_recording_for(recordable)
    end
  end

  def create_folder!(root, user, index)
    folder = Folder.create!(name: format("Bench folder %04d", index + 1))
    record_child!(folder, root, user)
    folder
  end

  def seed_indexable!(user, roots, slugs, started)
    cursor = 0
    roots.each_with_index do |entry, root_index|
      count = pages_for_root(root_index)
      count.times do
        cursor += 1
        slug = format("bench-kit-%04d", cursor)
        next if slugs.include?(slug)

        publish!(
          title: "Bench kit #{cursor}",
          slug: slug,
          root: entry.fetch(:root),
          user: user,
          attributes: indexable_attributes(cursor, slug)
        )
        slugs << slug
        report_progress!("indexable", cursor, started)
      end
    end
    raise "indexable cursor #{cursor} != #{INDEXABLE_COUNT}" unless cursor == INDEXABLE_COUNT
  end

  def pages_for_root(root_index)
    base, extra = INDEXABLE_COUNT.divmod(ROOTS)
    base + (root_index < extra ? 1 : 0)
  end

  def indexable_attributes(cursor, slug)
    attributes = { status: "published", meta_robots: "index,follow", time_zone: "UTC" }
    if ABSOLUTE_CANONICAL.cover?(cursor)
      attributes[:canonical_url] = "#{PUBLIC_BASE_URL}/featured/#{slug}"
    elsif RELATIVE_CANONICAL.cover?(cursor)
      attributes[:canonical_url] = "/featured/#{slug}"
    elsif OFFHOST_CANONICAL.cover?(cursor)
      attributes[:canonical_url] = "https://press.example/#{slug}"
    end
    attributes
  end

  def seed_excluded!(user, roots, slugs, started)
    excluded_specs.each do |spec|
      EXCLUDED_EACH.times do |index|
        slug = format("bench-%<kind>s-%<index>04d", kind: spec.fetch(:kind), index: index + 1)
        next if slugs.include?(slug)

        page, recording = publish!(
          title: "Bench #{spec.fetch(:kind)} #{index + 1}",
          slug: slug,
          root: roots[index % roots.length].fetch(:root),
          user: user,
          attributes: spec.fetch(:attributes)
        )
        spec[:after]&.call(page, recording, user)
        slugs << slug
        report_progress!(spec.fetch(:kind), index + 1, started)
      end
    end
  end

  def excluded_specs
    [
      { kind: "draft", attributes: { status: "draft", meta_robots: "index,follow" } },
      {
        kind: "scheduled",
        attributes: {
          status: "published",
          publish_at: 3.days.from_now.iso8601,
          time_zone: "UTC",
          meta_robots: "index,follow"
        }
      },
      {
        kind: "expired",
        attributes: {
          status: "published",
          publish_at: 3.days.ago.iso8601,
          unpublish_at: 1.day.ago.iso8601,
          time_zone: "UTC",
          meta_robots: "index,follow"
        }
      },
      { kind: "noindex", attributes: { status: "published", meta_robots: "noindex,follow" } },
      {
        kind: "trashed",
        attributes: { status: "published", meta_robots: "index,follow" },
        after: lambda { |_page, recording, _user|
          RecordingStudioTrashable.void_recording!(recording)
        }
      },
      { kind: "private", attributes: { status: "published", meta_robots: "index,follow" } }
    ]
  end

  def publish!(title:, slug:, root:, user:, attributes:)
    page = Page.create!(title: title)
    recording = record_child!(page, root, user)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: recording,
      actor: user,
      attributes: { slug: slug }.merge(attributes)
    )
    raise "Update failed for #{slug}: #{result.error.inspect}" if result.respond_to?(:failure?) && result.failure?

    [page, recording]
  end

  def record_child!(recordable, root, user)
    result = RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root,
      parent_recording: root
    )
    result.respond_to?(:recording) ? result.recording : result
  end

  def report_progress!(kind, count, started)
    return unless (count % 100).zero?

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    puts format("seed %-10s %4d  elapsed %.0fs", kind, count, elapsed)
  end

  def print_counts!
    puts "seed roots=#{Workspace.where('name LIKE ?', 'Bench root %').count}"
    puts "seed pages=#{Page.where('title LIKE ?', 'Bench %').count}"
    puts "seed recordings=#{RecordingStudio::Recording.count}"
    puts "seed indexable=#{Page.indexable.where('pages.title LIKE ?', 'Bench %').count}"
    puts "seed draft=#{Page.draft.where('pages.title LIKE ?', 'Bench draft %').count}"
    puts "seed scheduled=#{Page.scheduled.where('pages.title LIKE ?', 'Bench scheduled %').count}"
    puts "seed published_noindex=#{Page.published.where(id: noindex_ids).count}"
    puts "seed private_indexable=#{Page.indexable.where(id: private_ids).count}"
    puts "seed expired_indexable=#{Page.indexable.where(id: expired_ids).count}"
  end

  def noindex_ids
    publishable_page_ids("bench-noindex-%")
  end

  def private_ids
    publishable_page_ids("bench-private-%")
  end

  def expired_ids
    publishable_page_ids("bench-expired-%")
  end

  def publishable_page_ids(slug_pattern)
    child_ids = RecordingStudioPublishable::Publishable.where("slug LIKE ?", slug_pattern).select(:id)
    parent_ids = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPublishable::Publishable",
      recordable_id: child_ids
    ).select(:parent_recording_id)
    RecordingStudio::Recording.where(id: parent_ids, recordable_type: "Page").select(:recordable_id)
  end
end

module BenchMeasure
  module_function

  def call(mode)
    BenchHarness.restore_publish_rebuilds!
    BenchHarness.install!(mode)
    FileUtils.mkdir_p(ARTIFACTS)
    warmup
    runs = Integer(ENV.fetch("RUNS", "5")).times.map { |index| one_run(index + 1) }
    summary = summarize(mode, runs)
    path = File.join(ARTIFACTS, "#{label}-#{mode}.json")
    File.write(path, JSON.pretty_generate(summary))
    puts JSON.pretty_generate(summary)
    summary
  end

  def profile(mode)
    kind = ENV.fetch("PROFILE")
    require "stackprof"
    BenchHarness.restore_publish_rebuilds!
    BenchHarness.install!(mode)
    FileUtils.mkdir_p(ARTIFACTS)
    path = File.join(ARTIFACTS, "#{label}-#{mode}-stackprof-#{kind}.dump")
    StackProf.run(mode: kind.to_sym, raw: true, out: path) do
      with_cache { RecordingStudioSitemaps.rebuild!(source: :bench) }
    end
    puts "stackprof #{kind} #{path}"
  end

  def memory(mode)
    require "memory_profiler"
    BenchHarness.restore_publish_rebuilds!
    BenchHarness.install!(mode)
    FileUtils.mkdir_p(ARTIFACTS)
    path = File.join(ARTIFACTS, "#{label}-#{mode}-memory.txt")
    report = MemoryProfiler.report do
      with_cache { RecordingStudioSitemaps.rebuild!(source: :bench) }
    end
    report.pretty_print(to_file: path, scale_bytes: true)
    puts "memory_profiler #{path} allocated=#{report.total_allocated_memsize} objects=#{report.total_allocated}"
  end

  def warmup
    with_cache { RecordingStudioSitemaps.rebuild!(source: :bench_warmup) }
    puts "warmup done version=#{BenchHarness.version} api=#{BenchHarness.api} cache=#{cache_enabled?}"
  end

  def with_cache
    if cache_enabled?
      ActiveRecord::Base.cache { yield }
    else
      ActiveRecord::Base.uncached { yield }
    end
  end

  def cache_enabled?
    ENV["CACHE"] != "0"
  end

  def one_run(index)
    GC.start
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      name = event.payload[:name].to_s
      next if name == "SCHEMA" || name == "TRANSACTION"

      queries << { cached: event.payload[:cached] == true, ms: event.duration, name: name, sql: event.payload[:sql].to_s }
    end
    peak = rss_kb
    stop = false
    sampler = Thread.new do
      until stop
        peak = [peak, rss_kb].max
        sleep 0.05
      end
    end
    allocated_before = GC.stat[:total_allocated_objects]
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    log = with_cache { RecordingStudioSitemaps.rebuild!(source: :bench) }
    wall_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
    stop = true
    sampler.join
    allocated = GC.stat[:total_allocated_objects] - allocated_before
    uncached = queries.reject { |query| query[:cached] }
    xml = log.respond_to?(:xml) ? log.xml.to_s : ""
    result = {
      index: index,
      wall_ms: wall_ms.round(1),
      queries_uncached: uncached.size,
      queries_cached: queries.size - uncached.size,
      sql_ms: uncached.sum { |query| query[:ms] }.round(1),
      allocations: allocated,
      rss_kb: rss_kb,
      peak_rss_kb: peak,
      url_count: log.respond_to?(:url_count) ? log.url_count : nil,
      xml_bytes: xml.bytesize,
      success: log.respond_to?(:success?) ? log.success? : false,
      error: log.respond_to?(:error_message) ? log.error_message : nil
    }
    File.write(File.join(ARTIFACTS, "#{label}-#{ENV.fetch('MODE', 'gem')}.xml"), xml) if xml.present?
    puts format(
      "run %d wall=%.1fms uncached=%d cached=%d sql=%.1fms alloc=%d peak=%.1fMB urls=%s bytes=%d",
      index, result[:wall_ms], result[:queries_uncached], result[:queries_cached], result[:sql_ms],
      result[:allocations], result[:peak_rss_kb] / 1024.0, result[:url_count], result[:xml_bytes]
    )
    result
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def summarize(mode, runs)
    walls = runs.map { |run| run[:wall_ms] }
    {
      claim: CLAIM,
      version: BenchHarness.version,
      api: BenchHarness.api,
      mode: mode,
      noisy_logger: ENV["NOISY"] == "1",
      query_cache: cache_enabled?,
      public_base_url: RecordingStudioSitemaps.configuration.public_base_url,
      runs: runs,
      median_wall_ms: median(walls),
      min_wall_ms: walls.min,
      max_wall_ms: walls.max,
      queries_uncached: runs.map { |run| run[:queries_uncached] }.uniq,
      sql_ms: median(runs.map { |run| run[:sql_ms] }),
      allocations: median(runs.map { |run| run[:allocations] }),
      peak_rss_mb: (runs.map { |run| run[:peak_rss_kb] }.max / 1024.0).round(1),
      url_count: runs.map { |run| run[:url_count] }.uniq,
      xml_bytes: runs.map { |run| run[:xml_bytes] }.uniq,
      errors: runs.count { |run| !run[:success] },
      loadavg: File.read("/proc/loadavg").split.first(3),
      nproc: Etc.nprocessors
    }
  end

  def median(values)
    sorted = values.map(&:to_f).sort
    mid = sorted.length / 2
    return sorted[mid] if sorted.length.odd?

    ((sorted[mid - 1] + sorted[mid]) / 2.0).round(1)
  end

  def rss_kb
    File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i
  end

  def label
    "v#{BenchHarness.version}"
  end
end

module BenchCheck
  module_function

  def call
    pages = Page.indexable.order(:id).limit(Integer(ENV.fetch("CHECK_LIMIT", "30"))).to_a
    stock = stock_locs(pages)
    comparisons = %w[preload join].to_h do |mode|
      [mode, patched_locs(pages, mode)]
    end
    BenchHarness.install!("stock")
    comparisons.each do |mode, locs|
      mismatches = pages.filter_map do |page|
        next if stock[page.id] == locs[page.id]

        { id: page.id, stock: stock[page.id], other: locs[page.id] }
      end
      puts "#{mode} compared=#{pages.size} mismatches=#{mismatches.size}"
      mismatches.first(5).each { |row| puts row.inspect }
    end
  end

  def stock_locs(pages)
    pages.to_h do |page|
      [page.id, [BenchUrlBatch.loc_for(page.indexable_url), page.current_publishable_for_index&.publish_at&.xmlschema]]
    end
  end

  def patched_locs(pages, mode)
    parents = BenchUrlBatch.active_recordings.where(recordable_type: "Page", recordable_id: pages.map(&:id))
    parents = parents.order(:created_at, :id).each_with_object({}) { |recording, map| map[recording.recordable_id] = recording }
    contexts = if mode == "join"
      rows = Page.indexable.where(id: pages.map(&:id)).select(BenchUrlBatch.joined_select(Page)).to_a
      BenchUrlBatch.contexts_from_joined_rows(rows)
    else
      BenchUrlBatch.contexts_for(pages, parents)
    end
    pages.to_h do |page|
      context = contexts[page.id]
      [page.id, [BenchUrlBatch.loc_for(context&.url), context&.publish_at&.xmlschema]]
    end
  end
end

module BenchExposure
  module_function

  def call
    log = RecordingStudioSitemaps::GenerationLog.latest_successful
    raise "no successful sitemap" if log.nil? || log.xml.blank?

    xml = log.xml
    report = {
      url_count: log.url_count,
      xml_bytes: xml.bytesize,
      indexable: Page.indexable.where("pages.title LIKE ?", "Bench %").count,
      draft_in_xml: count_slugs(xml, "bench-draft-"),
      scheduled_in_xml: count_slugs(xml, "bench-scheduled-"),
      expired_in_xml: count_slugs(xml, "bench-expired-"),
      noindex_in_xml: count_slugs(xml, "bench-noindex-"),
      trashed_in_xml: count_slugs(xml, "bench-trashed-"),
      private_in_xml: count_slugs(xml, "bench-private-"),
      offhost_in_xml: (OFFHOST_CANONICAL).count { |index| xml.include?(format("bench-kit-%04d", index)) },
      draft_scope: Page.draft.where("pages.title LIKE ?", "Bench draft %").count,
      scheduled_scope: Page.scheduled.where("pages.title LIKE ?", "Bench scheduled %").count,
      unpublished_scope: Page.unpublished.where("pages.title LIKE ?", "Bench %").count,
      private_indexable_scope: Page.indexable.where(id: BenchSeed.private_ids).count,
      expired_indexable_scope: Page.indexable.where(id: BenchSeed.expired_ids).count
    }
    puts JSON.pretty_generate(report)
    File.write(File.join(ARTIFACTS, "#{BenchMeasure.label}-exposure.json"), JSON.pretty_generate(report))
    report
  end

  def count_slugs(xml, prefix)
    xml.scan(%r{/#{Regexp.escape(prefix)}[0-9]+}).uniq.size
  end
end

BenchHarness.prepare!

if ENV["SEED"] == "1"
  BenchSeed.call
end

if ENV["CHECK"] == "1"
  BenchCheck.call
end

if ENV["MEASURE"] == "1"
  BenchMeasure.call(ENV.fetch("MODE", "gem"))
end

if ENV["PROFILE"].present?
  BenchMeasure.profile(ENV.fetch("MODE", "gem"))
end

if ENV["MEMORY"] == "1"
  BenchMeasure.memory(ENV.fetch("MODE", "gem"))
end

if ENV["EXPOSURE"] == "1"
  BenchExposure.call
end
