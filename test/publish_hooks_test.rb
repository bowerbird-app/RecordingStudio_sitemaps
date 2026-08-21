# frozen_string_literal: true

require "test_helper"

class PublishHooksTest < Minitest::Test
  Event = Struct.new(:recordable_type)

  def test_publishable_event_matches_publishable_child_type
    assert RecordingStudioSitemaps::PublishHooks.publishable_event?(
      Event.new("RecordingStudioPublishable::Publishable")
    )
    refute RecordingStudioSitemaps::PublishHooks.publishable_event?(Event.new("Page"))
    refute RecordingStudioSitemaps::PublishHooks.publishable_event?(Object.new)
  end

  def test_handle_rebuilds_only_for_publishable_events
    called = []
    RecordingStudioSitemaps.stub(:rebuild!, ->(source:) { called << source }) do
      RecordingStudioSitemaps::PublishHooks.handle(Event.new("Page"))
      RecordingStudioSitemaps::PublishHooks.handle(Event.new("RecordingStudioPublishable::Publishable"))
    end

    assert_equal [:publish], called
  end

  def test_install_registers_the_after_record_hook_once
    RecordingStudioSitemaps::PublishHooks.instance_variable_set(:@installed, false)
    calls = []
    hooks = RecordingStudio.configuration.hooks

    hooks.stub(:after_record, ->(&block) { calls << block }) do
      RecordingStudioSitemaps::PublishHooks.install!
      RecordingStudioSitemaps::PublishHooks.install!
    end

    assert_equal 1, calls.size
    assert RecordingStudioSitemaps::PublishHooks.instance_variable_get(:@installed)
  ensure
    RecordingStudioSitemaps::PublishHooks.instance_variable_set(:@installed, true)
  end
end

