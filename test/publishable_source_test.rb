# frozen_string_literal: true

require "test_helper"

class PublishableSourceTest < Minitest::Test
  Recordable = Struct.new(:id, :indexable_url, :title, :publish_at, keyword_init: true) do
    def current_publishable_for_index
      Struct.new(:publish_at).new(publish_at)
    end
  end

  class BatchingRelation
    def initialize(rows)
      @rows = rows
    end

    def in_batches(of:)
      @rows.each_slice(of) { |slice| yield Batch.new(slice) }
    end

    def to_a
      raise "loaded every row"
    end

    class Batch
      def initialize(rows)
        @rows = rows
      end

      def to_a
        @rows
      end
    end
  end

  class BareList
    def initialize(rows)
      @rows = rows
    end

    def to_ary
      @rows
    end
  end

  class RecordingScope
    def initialize(rows)
      @rows = rows
    end

    def where(*)
      self
    end

    def order(*)
      self
    end

    def each_with_object(memo)
      @rows.each { |row| yield row, memo }
      memo
    end
  end

  def test_indexable_types_skip_types_without_indexable
    entries = []
    source = source_for(entries)

    RecordingStudio.configuration.stub(:recordable_types, %w[String Object MissingType]) do
      source.call
    end

    assert_empty entries
  end

  def test_entries_use_public_url_publish_time_title_and_recording
    published_at = Time.utc(2026, 8, 21, 9, 0, 0)
    recordable = Recordable.new(
      id: 7,
      indexable_url: "/published/abc/getting-started",
      title: "Getting Started",
      publish_at: published_at
    )
    recording = Object.new
    entries = collect(recordable, recording)

    assert_equal 1, entries.size
    assert_equal "https://site.test/published/abc/getting-started", entries.first.loc
    assert_equal published_at, entries.first.lastmod
    assert_equal "Getting Started", entries.first.title
    assert_equal "Page", entries.first.type
    assert_equal recording, entries.first.recording
  end

  def test_entries_without_in_batches_still_load_and_attach_recordings
    recordable = Recordable.new(id: 7, indexable_url: "/one", title: "One", publish_at: nil)
    recording = Struct.new(:recordable_id).new(7)
    scope = RecordingScope.new([recording])
    entries = []
    source = source_for(entries)
    type = fake_type(BareList.new([recordable]))

    model = Class.new do
      class << self
        attr_accessor :scope

        def where(**)
          scope
        end

        def column_names
          %w[id trashed_at]
        end
      end
    end
    model.scope = scope
    RecordingStudio.const_set(:Recording, model)

    RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://site.test") do
      source.stub(:indexable_types, [type]) do
        RecordingStudio.stub(:recordable_type_label, "Page") { source.call }
      end
    end
  ensure
    RecordingStudio.send(:remove_const, :Recording) if RecordingStudio.const_defined?(:Recording, false)

    assert_equal recording, entries.first.recording
  end

  def test_entries_walk_in_batches_and_skip_a_blank_url
    first = Recordable.new(id: 1, indexable_url: "/one", title: "One", publish_at: nil)
    blank = Recordable.new(id: 2, indexable_url: nil, title: "Blank", publish_at: nil)
    entries = []
    source = source_for(entries)
    relation = BatchingRelation.new([first, blank])
    type = fake_type(relation)

    RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://site.test") do
      source.stub(:indexable_types, [type]) do
        source.stub(:recordings_for, {}) do
          RecordingStudio.stub(:recordable_type_label, "Page") do
            source.call
          end
        end
      end
    end

    assert_equal ["One"], entries.map(&:title)
  end

  private

  def collect(recordable, recording)
    entries = []
    source = source_for(entries)
    type = fake_type(BatchingRelation.new([recordable]))

    RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://site.test") do
      source.stub(:indexable_types, [type]) do
        source.stub(:recordings_for, { recordable.id => recording }) do
          RecordingStudio.stub(:recordable_type_label, "Page") { source.call }
        end
      end
    end
    entries
  end

  def source_for(entries)
    sink = RecordingStudioSitemaps::BatchSink.new { |batch| entries.concat(batch) }
    RecordingStudioSitemaps::Sources::Publishable.new(sink)
  end

  def fake_type(relation)
    type = Class.new
    type.define_singleton_method(:name) { "Page" }
    type.define_singleton_method(:indexable) { relation }
    type
  end
end
