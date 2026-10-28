# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioSitemaps.instance_variable_get(:@configuration)
    RecordingStudioSitemaps.instance_variable_set(:@configuration, RecordingStudioSitemaps::Configuration.new)
  end

  def teardown
    RecordingStudioSitemaps.configuration.hooks.clear!
    RecordingStudioSitemaps.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioSitemaps.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioSitemaps.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_sitemaps.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_sitemaps.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioSitemaps.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_sitemaps).new({ url_count_warning_threshold: 40_000 })
    app_config = Struct.new(:x).new(xcfg)

    with_host_yaml("public_base_url: https://from-yaml.test\n") do |root|
      app = yaml_app(root, app_config, { public_base_url: "https://from-yaml.test" })

      find_initializer("recording_studio_sitemaps.load_config").block.call(app)
    end

    assert hook_called
    assert_equal RecordingStudioSitemaps.configuration, hook_payload
    assert_equal "https://from-yaml.test", RecordingStudioSitemaps.configuration.public_base_url
    assert_equal 40_000, RecordingStudioSitemaps.configuration.url_count_warning_threshold
  end

  def test_load_config_skips_missing_yaml_and_config_without_to_h
    pair_config = Class.new do
      def each_pair
        yield(:url_count_warning_threshold, 15)
      end
    end.new

    xcfg = Struct.new(:recording_studio_sitemaps).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config, :root).new(app_config, "/tmp/missing-sitemaps-host")

    find_initializer("recording_studio_sitemaps.load_config").block.call(app)

    assert_equal RecordingStudioSitemaps::Configuration::URL_COUNT_WARNING_THRESHOLD,
                 RecordingStudioSitemaps.configuration.url_count_warning_threshold
  end

  def test_load_config_merges_x_config_when_to_h_is_present
    xcfg = Struct.new(:recording_studio_sitemaps).new({ url_count_warning_threshold: 22 })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config).new(app_config)

    find_initializer("recording_studio_sitemaps.load_config").block.call(app)

    assert_equal 22, RecordingStudioSitemaps.configuration.url_count_warning_threshold
  end

  def test_load_config_is_noop_without_config_sources
    app = Struct.new(:config).new(Object.new)

    find_initializer("recording_studio_sitemaps.load_config").block.call(app)

    assert_nil RecordingStudioSitemaps.configuration.public_base_url
    assert_equal RecordingStudioSitemaps::Configuration::URL_COUNT_WARNING_THRESHOLD,
                 RecordingStudioSitemaps.configuration.url_count_warning_threshold
  end

  def test_does_not_register_template_extension_initializers
    assert_nil find_initializer("recording_studio_sitemaps.apply_model_extensions")
    assert_nil find_initializer("recording_studio_sitemaps.apply_controller_extensions")
    refute RecordingStudioSitemaps::Engine.respond_to?(:apply_model_extensions)
    refute RecordingStudioSitemaps::Engine.respond_to?(:apply_controller_extensions)
  end

  def test_apply_model_extensions_is_not_defined
    refute RecordingStudioSitemaps::Engine.respond_to?(:apply_model_extensions)
  end

  def test_apply_controller_extensions_is_not_defined
    refute RecordingStudioSitemaps::Engine.respond_to?(:apply_controller_extensions)
  end

  private

  def yaml_app(root, app_config, yaml)
    app = Struct.new(:config, :root) do
      attr_accessor :yaml

      def config_for(_name)
        @yaml
      end
    end.new(app_config, root)
    app.yaml = yaml
    app
  end

  def with_host_yaml(contents)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config", "recording_studio_sitemaps.yml"), contents)
      yield dir
    end
  end

  def find_initializer(name)
    RecordingStudioSitemaps::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
