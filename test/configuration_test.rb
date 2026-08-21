# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioSitemaps::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(public_base_url: "https://example.test", url_count_warning_threshold: 40_000)

    assert_equal "https://example.test", @configuration.public_base_url
    assert_equal 40_000, @configuration.url_count_warning_threshold
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", public_base_url: "https://kept.test")

    refute_respond_to @configuration, :unknown_key
    assert_equal "https://kept.test", @configuration.public_base_url
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_nil original[:public_base_url]
    assert_nil @configuration.public_base_url
    assert_equal original[:url_count_warning_threshold], @configuration.url_count_warning_threshold
  end

  def test_initialize_uses_defaults
    configuration = RecordingStudioSitemaps::Configuration.new

    assert_nil configuration.public_base_url
    assert_equal RecordingStudioSitemaps::Configuration::URL_COUNT_WARNING_THRESHOLD,
                 configuration.url_count_warning_threshold
    assert_instance_of RecordingStudio::Hooks, configuration.hooks
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("public_base_url" => "https://string.test", "url_count_warning_threshold" => 12)

    assert_equal "https://string.test", @configuration.public_base_url
    assert_equal 12, @configuration.url_count_warning_threshold
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioSitemaps.configure

    assert_kind_of RecordingStudioSitemaps::Configuration, RecordingStudioSitemaps.configuration
  end

  def test_approaching_url_limit_uses_threshold
    @configuration.url_count_warning_threshold = 45_000

    refute @configuration.approaching_url_limit?(44_999)
    assert @configuration.approaching_url_limit?(45_000)
    assert @configuration.approaching_url_limit?(50_000)
  end
end
