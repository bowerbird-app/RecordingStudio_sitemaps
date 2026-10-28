# frozen_string_literal: true

require "test_helper"

class RecordableTitleTest < Minitest::Test
  FakeRecordable = Struct.new(:title, :name, keyword_init: true)

  def test_prefers_title_then_name_then_fallback
    titled = FakeRecordable.new(title: "Getting started", name: "ignored")
    named = FakeRecordable.new(title: nil, name: "Draft URL")
    blank = FakeRecordable.new(title: "  ", name: nil)

    assert_equal "Getting started", RecordingStudioSitemaps::RecordableTitle.for(titled) { "Page" }
    assert_equal "Draft URL", RecordingStudioSitemaps::RecordableTitle.for(named) { "Page" }
    assert_equal "Page", RecordingStudioSitemaps::RecordableTitle.for(blank) { "Page" }
  end

  def test_does_not_evaluate_fallback_when_title_is_present
    evaluated = false
    titled = FakeRecordable.new(title: "Getting started")

    result = RecordingStudioSitemaps::RecordableTitle.for(titled) do
      evaluated = true
      "Page"
    end

    assert_equal "Getting started", result
    refute evaluated
  end
end
