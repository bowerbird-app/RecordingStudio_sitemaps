# frozen_string_literal: true

require "test_helper"

class RecordableTitleTest < Minitest::Test
  FakeRecordable = Struct.new(:title, :name, keyword_init: true)

  def test_prefers_title_then_name_then_fallback
    titled = FakeRecordable.new(title: "Getting started", name: "ignored")
    named = FakeRecordable.new(title: nil, name: "Draft URL")
    blank = FakeRecordable.new(title: "  ", name: nil)

    assert_equal "Getting started", RecordingStudioSitemaps::RecordableTitle.for(titled, fallback: "Page")
    assert_equal "Draft URL", RecordingStudioSitemaps::RecordableTitle.for(named, fallback: "Page")
    assert_equal "Page", RecordingStudioSitemaps::RecordableTitle.for(blank, fallback: "Page")
  end
end
