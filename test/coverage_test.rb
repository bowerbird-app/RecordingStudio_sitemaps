# frozen_string_literal: true

require "test_helper"

class CoverageTest < Minitest::Test
  FakeEntry = Struct.new(:recordable)

  def test_counts_included_and_published_by_type
    page_type = Class.new
    support_type = Class.new
    page_type.define_singleton_method(:published) { %i[one two] }
    support_type.define_singleton_method(:published) { %i[kit] }

    entries = [FakeEntry.new(page_type.new)]
    labels = { page_type => "Page", support_type => "Support page" }

    RecordingStudioSitemaps::UrlSet.stub(:indexable_types, [page_type, support_type]) do
      RecordingStudioSitemaps::UrlSet.stub(:entries, entries) do
        RecordingStudio.stub(:recordable_type_label, ->(type) { labels.fetch(type) }) do
          snapshot = RecordingStudioSitemaps::Coverage.snapshot

          assert_equal 1, snapshot.included
          assert_equal 3, snapshot.published
          assert_equal ["Page", "Support page"], snapshot.types.map(&:label)
          assert_equal [1, 0], snapshot.types.map(&:included)
          assert_equal [2, 1], snapshot.types.map(&:published)
        end
      end
    end
  end
end
