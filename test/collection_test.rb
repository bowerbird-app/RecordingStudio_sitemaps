# frozen_string_literal: true

require "test_helper"

class CollectionTest < Minitest::Test
  def setup
    super
    @base = "https://www.example.com"
  end

  def test_sources_run_in_registration_order_and_return_values_count
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:first) do |batch|
      batch << entry("one")
    end
    RecordingStudioSitemaps.register_source(:second) do
      [entry("two")]
    end
    RecordingStudioSitemaps.register_source(:third) do
      Enumerator.new { |yielder| yielder << [entry("three")] }
    end

    with_base do
      assert_equal %w[one two three], RecordingStudioSitemaps::Collection.accepted.map(&:title)
    end
  end

  def test_hash_entries_and_optional_sitemap_fields_pass_through
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:marketing) do |batch|
      batch << {
        loc: "#{@base}/pricing",
        lastmod: Date.new(2026, 1, 1),
        changefreq: "monthly",
        priority: 0.4,
        title: "Pricing",
        type: "Page"
      }
    end

    with_base do
      accepted = RecordingStudioSitemaps::Collection.accepted

      assert_equal "monthly", accepted.first.changefreq
      assert_equal 0.4, accepted.first.priority
      assert_equal "Pricing", accepted.first.title
    end
  end

  def test_filters_run_on_every_source_and_the_first_rejection_wins
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) { |batch| batch << [entry("kept"), entry("vetoed")] }
    seen_by_second = []
    RecordingStudioSitemaps.register_filter(:embargo) do |candidate|
      candidate.title == "vetoed" ? "Under embargo" : true
    end
    RecordingStudioSitemaps.register_filter(:later) do |candidate|
      seen_by_second << candidate.title
      true
    end

    with_base do
      decisions = RecordingStudioSitemaps::Collection.decisions
      withheld = decisions.reject(&:accepted?)

      assert_equal(["kept"], decisions.select(&:accepted?).map { |decision| decision.entry.title })
      assert_equal [:embargo], withheld.map(&:filter_name)
      assert_equal "Under embargo", withheld.first.reason
      assert_equal ["kept"], seen_by_second
      item = RecordingStudioSitemaps::Exclusions::Item.new(
        title: withheld.first.entry.title,
        reason: withheld.first.reason,
        filter_name: withheld.first.filter_name
      )
      assert_equal "Embargo — Under embargo", item.detail
    end
  end

  def test_false_and_nil_drop_with_the_filter_name
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) { |batch| batch << [entry("nope"), entry("also")] }
    RecordingStudioSitemaps.register_filter(:embargo) { |candidate| candidate.title == "nope" ? false : nil }

    with_base do
      reasons = RecordingStudioSitemaps::Exclusions.items

      assert_empty RecordingStudioSitemaps::Collection.accepted
      assert_equal %w[Embargo Embargo], reasons.map(&:detail)
    end
  end

  def test_a_filter_that_raises_drops_that_entry_and_keeps_the_rest
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) { |batch| batch << [entry("kept"), entry("boom")] }
    RecordingStudioSitemaps.register_filter(:visibility) do |candidate|
      raise "nope" if candidate.title == "boom"

      true
    end
    logs = []

    with_logger(logs) do
      with_base do
        withheld = RecordingStudioSitemaps::Exclusions.items

        assert_equal ["kept"], RecordingStudioSitemaps::Collection.accepted.map(&:title)
        assert_equal :visibility, withheld.first.filter_name
        assert_equal "Filter failed", withheld.first.reason
        assert(logs.any? { |message| message.include?("nope") && message.include?("visibility") })
      end
    end
  end

  def test_builtin_checks_drop_blank_relative_and_off_host_locs
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:messy) do |batch|
      batch << [
        entry("in", loc: "#{@base}/in"),
        entry("relative", loc: "/relative"),
        entry("away", loc: "https://other.test/away"),
        entry("blank", loc: "  ")
      ]
    end
    called = false
    RecordingStudioSitemaps.register_filter(:later) do
      called = true
      true
    end

    with_base do
      withheld = RecordingStudioSitemaps::Exclusions.items

      assert_equal ["in"], RecordingStudioSitemaps::Collection.accepted.map(&:title)
      assert_equal %i[absolute_url public_host absolute_url], withheld.map(&:filter_name)
      assert_equal "Not an absolute URL", withheld.first.reason
      assert_equal "Off the public host", withheld[1].reason
      assert called
    end
  end

  def test_builtin_checks_run_before_filters_so_a_bad_loc_never_reaches_them
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:messy) { |batch| batch << entry("relative", loc: "/relative") }
    RecordingStudioSitemaps.register_filter(:visibility) { raise "should not run" }

    with_base do
      assert_equal [:absolute_url], RecordingStudioSitemaps::Exclusions.items.map(&:filter_name)
    end
  end

  def test_host_check_waits_until_a_public_host_is_configured
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) { |batch| batch << entry("away", loc: "https://other.test/away") }

    with_base(nil) do
      assert_equal ["away"], RecordingStudioSitemaps::Collection.accepted.map(&:title)
    end
  end

  def test_host_match_ignores_scheme_and_letter_case
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << entry("same", loc: "https://WWW.Example.COM/pricing")
    end

    with_base("http://www.example.com") do
      assert_equal ["same"], RecordingStudioSitemaps::Collection.accepted.map(&:title)
    end
  end

  def test_a_source_that_yields_something_other_than_an_entry_fails_closed
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:bad) { |batch| batch << :nope }

    error = assert_raises(RecordingStudioSitemaps::SourceFailure) do
      RecordingStudioSitemaps::Collection.accepted
    end

    assert_includes error.message, "Sitemap sources must yield entries"
  end

  def test_an_invalid_uri_is_not_an_absolute_url
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:bad) { |batch| batch << entry("bad", loc: "http://[") }

    with_base do
      assert_equal [:absolute_url], RecordingStudioSitemaps::Collection.withheld.map(&:filter_name)
    end
  end

  def test_the_default_source_walks_publishable_types
    RecordingStudio.configuration.stub(:recordable_types, []) do
      assert_empty RecordingStudioSitemaps::Collection.accepted
    end
  end

  def test_a_source_that_raises_does_not_return_a_partial_list
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << entry("partial")
      raise "source blew up"
    end

    error = assert_raises(RecordingStudioSitemaps::SourceFailure) do
      RecordingStudioSitemaps::Collection.accepted
    end

    assert_equal :pages, error.source_name
    assert_includes error.message, "source blew up"
  end

  def test_a_source_can_replace_the_default
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:publishable) { |batch| batch << entry("replacement") }

    with_base do
      assert_equal ["replacement"], RecordingStudioSitemaps::Collection.accepted.map(&:title)
      assert_equal [:publishable], RecordingStudioSitemaps.sources.names
    end
  end

  def test_collection_code_does_not_name_other_domain_gems
    root = File.expand_path("../lib/recording_studio_sitemaps", __dir__)
    files = %w[
      collection.rb exclusions.rb coverage.rb builtin_checks.rb
      source_runner.rb registry.rb sources/publishable.rb
    ]
    forbidden = %w[Embargo PressKit PressCenter Accessible Trashable noindex]

    files.each do |name|
      source = File.read(File.join(root, name))
      forbidden.each do |word|
        refute_includes source, word, "#{name} mentions #{word}"
      end
    end
  end

  private

  def entry(title, loc: nil)
    RecordingStudioSitemaps::Entry.new(
      loc: loc || "#{@base}/#{title}",
      title: title,
      type: "Page"
    )
  end

  def with_base(base = @base, &)
    RecordingStudioSitemaps.configuration.stub(:public_base_url, base, &)
  end

  def with_logger(logs, &)
    logger = Object.new
    logger.define_singleton_method(:error) { |message| logs << message }
    Rails.stub(:logger, logger, &)
  end
end
