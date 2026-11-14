# frozen_string_literal: true

require "test_helper"

class RegistryTest < Minitest::Test
  def test_default_publishable_source_is_registered
    assert_equal [:publishable], RecordingStudioSitemaps.sources.names
    assert_empty RecordingStudioSitemaps.filters.names
  end

  def test_register_appends_and_reregister_keeps_place
    RecordingStudioSitemaps.register_source(:marketing) { |_batch| }
    RecordingStudioSitemaps.register_source(:publishable) { |_batch| }
    RecordingStudioSitemaps.register_filter(:second) { true }
    RecordingStudioSitemaps.register_filter(:first) { true }
    RecordingStudioSitemaps.register_filter(:second) { false }

    assert_equal %i[publishable marketing], RecordingStudioSitemaps.sources.names
    assert_equal %i[second first], RecordingStudioSitemaps.filters.names
  end

  def test_unregister_removes_a_source_or_filter
    RecordingStudioSitemaps.register_filter(:embargo) { true }

    RecordingStudioSitemaps.unregister_source(:publishable)
    RecordingStudioSitemaps.unregister_filter(:embargo)

    assert_empty RecordingStudioSitemaps.sources.names
    assert_empty RecordingStudioSitemaps.filters.names
  end

  def test_register_requires_a_name_and_a_block
    assert_raises(ArgumentError) { RecordingStudioSitemaps.register_source(nil) { nil } }
    assert_raises(ArgumentError) { RecordingStudioSitemaps.register_filter(:embargo) }
  end

  def test_builtin_checks_are_not_registry_filters
    refute_includes RecordingStudioSitemaps.filters.names, :absolute_url
    refute_includes RecordingStudioSitemaps.filters.names, :public_host
  end
end
