# frozen_string_literal: true

require "test_helper"

class ExclusionsTest < Minitest::Test
  def test_accepted_entries_are_not_listed
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << RecordingStudioSitemaps::Entry.new(
        loc: "https://www.example.com/findable",
        title: "Findable",
        type: "Page"
      )
    end

    with_base do
      assert_empty RecordingStudioSitemaps::Exclusions.items
    end
  end

  def test_withheld_entries_keep_english_filter_reasons
    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << [
        RecordingStudioSitemaps::Entry.new(loc: "/hidden", title: "Hidden page", type: "Page"),
        RecordingStudioSitemaps::Entry.new(
          loc: "https://other.test/old",
          title: "Old page",
          type: "Page"
        )
      ]
    end

    with_base do
      reasons = RecordingStudioSitemaps::Exclusions.items

      assert_equal "Not an absolute URL", reasons.find { |row| row.title == "Hidden page" }.reason
      assert_equal :absolute_url, reasons.find { |row| row.title == "Hidden page" }.filter_name
      assert_equal "Off the public host", reasons.find { |row| row.title == "Old page" }.reason
    end
  end

  private

  def with_base(&)
    RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://www.example.com", &)
  end
end
