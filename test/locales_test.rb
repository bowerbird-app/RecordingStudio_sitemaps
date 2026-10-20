# frozen_string_literal: true

require "test_helper"
require "yaml"

class LocalesTest < Minitest::Test
  EXPECTED = {
    "flashes.rebuilt" => "Sitemap rebuilt.",
    "flashes.rebuild_failed" => "Sitemap rebuild hit a snag. Check the last build."
  }.freeze

  def test_en_yml_ships_expected_english_under_recording_studio_sitemaps
    path = File.expand_path("../config/locales/en.yml", __dir__)
    tree = YAML.safe_load_file(path, aliases: true)
    root = tree.fetch("en").fetch("recording_studio").fetch("sitemaps")

    EXPECTED.each do |key, english|
      assert_equal english, dig(root, key.split(".")), "expected #{key.inspect} => #{english.inspect}"
    end
    refute root.key?("admin"), "Admin DSL copy must not ship locale keys"
  end

  # Wave-wide: probe / test-only keys must not ship in the gem package.
  # Host-override probes live under test/dummy (boot override or test/locales).
  def test_gem_packaged_locales_have_no_probe_or_test_only_keys
    locales_dir = File.expand_path("../config/locales", __dir__)
    Dir.glob(File.join(locales_dir, "*.yml")).each do |path|
      source = File.read(path)
      refute_match(/\bHOST\b/, source, "#{path} must not ship HOST / probe copy")
      refute_match(/\bprobe\b/i, source, "#{path} must not ship probe keys")
      refute_match(/\btest[_-]only\b/i, source, "#{path} must not ship test-only keys")

      tree = YAML.safe_load_file(path, aliases: true)
      root = tree.fetch("en").fetch("recording_studio").fetch("sitemaps")
      leaf_keys = flatten_leaf_keys(root)
      assert_equal EXPECTED.keys.sort, leaf_keys.sort,
                   "#{path} must ship only real product keys (#{EXPECTED.keys.inspect})"
    end

    gemspec = File.read(File.expand_path("../recording_studio_sitemaps.gemspec", __dir__))
    refute_includes gemspec, "test/dummy",
                    "gemspec must not package dummy host-override / probe locale files"
  end

  def test_copy_t_resolves_english_from_en_yml
    path = File.expand_path("../config/locales/en.yml", __dir__)
    backend_before = I18n.backend
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.load_translations(path)

    EXPECTED.each do |key, english|
      assert_equal english, RecordingStudioSitemaps::Copy.t(key)
    end
  ensure
    I18n.backend = backend_before
  end

  def test_missing_copy_key_behaves_like_plain_i18n_miss
    path = File.expand_path("../config/locales/en.yml", __dir__)
    backend_before = I18n.backend
    exception_before = I18n.exception_handler
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.load_translations(path)
    I18n.exception_handler = I18n::ExceptionHandler.new

    missing_key = "flashes.does_not_exist_#{SecureRandom.hex(4)}"
    direct = I18n.t("recording_studio.sitemaps.#{missing_key}")
    via_copy = RecordingStudioSitemaps::Copy.t(missing_key)

    assert_equal direct, via_copy
    assert_match(/translation missing/i, via_copy)
  ensure
    I18n.exception_handler = exception_before if exception_before
    I18n.backend = backend_before
  end

  def test_lib_files_do_not_set_i18n_load_path
    lib_root = File.expand_path("../lib", __dir__)
    Dir.glob(File.join(lib_root, "**", "*.rb")).each do |path|
      source = File.read(path)

      refute_includes source, "i18n.load_path", path
      refute_includes source, "I18n.load_path", path
    end
  end

  def test_gem_call_sites_do_not_pass_english_default_to_copy_t
    roots = [
      File.expand_path("../lib", __dir__),
      File.expand_path("../app", __dir__)
    ]
    roots.each do |root|
      Dir.glob(File.join(root, "**", "*.rb")).each do |path|
        source = File.read(path)
        next unless source.include?("Copy.t")

        source.scan(/Copy\.t\([^)]*\)/m).each do |call|
          refute_match(/\bdefault\s*:/, call, "#{path} passes default: to Copy.t: #{call}")
        end
      end
    end
  end

  def test_admin_dsl_titles_and_link_text_stay_literal_strings
    section = RecordingStudioSitemaps::Admin::Section
    screen = RecordingStudioSitemaps::Admin::BuildHistory

    assert_instance_of String, section.title
    assert_equal "Sitemaps", section.title
    section.links.each do |link|
      assert_instance_of String, link.text, link.name
    end
    assert_instance_of String, screen.title
    assert_equal "Build history", screen.title
    assert_instance_of String, screen.subtitle
    assert_instance_of String, screen.chart_value.title
    assert_instance_of String, screen.table_value.title
    screen.table_value.columns.each do |column|
      assert_instance_of String, column.title, column.key
    end

    widget = RecordingStudioSitemaps::Admin.index_size_widget
    assert_instance_of String, widget.title
    assert_instance_of String, widget.info
    assert_instance_of String, widget.link_label

    last_build = RecordingStudioSitemaps::Admin.last_build_widget
    assert_instance_of String, last_build.title
    assert_instance_of String, last_build.info
    assert_instance_of String, last_build.link_label
  end

  # Reverting any translated flash to a string literal must fail this test.
  def test_each_translated_flash_call_site_uses_copy_t_not_english_literals
    path = File.expand_path("../app/controllers/recording_studio_sitemaps/rebuilds_controller.rb", __dir__)
    source = File.read(path)

    EXPECTED.each do |key, english|
      assert_includes source, %(Copy.t("#{key}")),
                      "expected Copy.t(#{key.inspect}); reverting #{key} to a literal would drop host overrides"
      refute_match(
        /(?:notice|alert):\s*"#{Regexp.escape(english)}"/,
        source,
        "controller must not embed #{english.inspect} as a notice/alert literal"
      )
    end
  end

  private

  def dig(hash, parts)
    parts.reduce(hash) { |node, part| node.fetch(part) }
  end

  def flatten_leaf_keys(node, prefix = nil)
    case node
    when Hash
      node.flat_map { |key, value| flatten_leaf_keys(value, [prefix, key].compact.join(".")) }
    else
      [prefix]
    end
  end
end
