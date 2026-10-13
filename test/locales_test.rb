# frozen_string_literal: true

require "test_helper"
require "yaml"

class LocalesTest < Minitest::Test
  EXPECTED = {
    "flashes.rebuilt" => "Sitemap rebuilt.",
    "flashes.rebuild_failed" => "Sitemap rebuild hit a snag. Check the last build.",
    "admin.section.title" => "Sitemaps",
    "admin.section.open_sitemap" => "Open sitemap",
    "admin.section.rebuild" => "Rebuild",
    "admin.section.build_history" => "Build history",
    "admin.screen.title" => "Build history",
    "admin.screen.chart_title" => "Pages in the sitemap",
    "admin.widgets.coverage.title" => "Coverage",
    "admin.widgets.findable.title" => "In the sitemap",
    "admin.widgets.findable.info" => "Pages search engines can pick up from this sitemap.",
    "admin.widgets.missing.title" => "Missing",
    "admin.widgets.missing.info" => "Published pages that did not make the sitemap, and why.",
    "admin.widgets.index_size.title" => "Index size",
    "admin.widgets.index_size.info" => "How many pages made the sitemap each rebuild.",
    "admin.widgets.index_size.link_label" => "Build history",
    "admin.chart.pages_series" => "Pages"
  }.freeze

  def test_en_yml_ships_expected_english_under_recording_studio_sitemaps
    path = File.expand_path("../config/locales/en.yml", __dir__)
    tree = YAML.safe_load_file(path, aliases: true)
    root = tree.fetch("en").fetch("recording_studio").fetch("sitemaps")

    EXPECTED.each do |key, english|
      assert_equal english, dig(root, key.split(".")), "expected #{key.inspect} => #{english.inspect}"
    end
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
        next unless source.include?("Copy.t") || source.match?(/\bt\(/)

        source.scan(/Copy\.t\([^)]*\)/m).each do |call|
          refute_match(/\bdefault\s*:/, call, "#{path} passes default: to Copy.t: #{call}")
        end
      end
    end
  end

  private

  def dig(hash, parts)
    parts.reduce(hash) { |node, part| node.fetch(part) }
  end
end
