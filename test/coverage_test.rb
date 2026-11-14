# frozen_string_literal: true

require "test_helper"

class CoverageTest < Minitest::Test
  def test_counts_included_and_offered_by_type
    page = RecordingStudioSitemaps::Entry.new(loc: "https://site.test/a", type: "Page")
    support = RecordingStudioSitemaps::Entry.new(loc: "https://site.test/b", type: "Support page")
    decisions = [
      RecordingStudioSitemaps::Collection::Decision.new(entry: page),
      RecordingStudioSitemaps::Collection::Decision.new(entry: page),
      RecordingStudioSitemaps::Collection::Decision.new(
        entry: support,
        filter_name: :embargo,
        reason: "Embargo"
      )
    ]

    RecordingStudioSitemaps::Collection.stub(:decisions, decisions) do
      snapshot = RecordingStudioSitemaps::Coverage.snapshot

      assert_equal 2, snapshot.included
      assert_equal 3, snapshot.offered
      assert_equal ["Page", "Support page"], snapshot.types.map(&:label)
      assert_equal [2, 0], snapshot.types.map(&:included)
      assert_equal [2, 1], snapshot.types.map(&:offered)
    end
  end
end
