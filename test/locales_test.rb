# frozen_string_literal: true

require "test_helper"
require "yaml"

class LocalesTest < Minitest::Test
  # rubocop:disable Style/FormatStringToken -- I18n tokens use %{stamp}.
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
    "admin.last_build.none" => "No sitemap written yet",
    "admin.last_build.success" => "Last built %{stamp}",
    "admin.last_build.failed" => "Last build failed %{stamp}",
    "admin.coverage.no_published_pages" => "No published pages yet.",
    "admin.coverage.url_cap_warning" =>
      "This list is getting close to the 50,000 URL cap. A split is not available yet.",
    "admin.findable.empty" => "Nothing findable yet.",
    "admin.missing.empty" => "Nothing missing. Nice.",
    "admin.missing.none_in_sitemap" => "None in the sitemap",
    "admin.exclusions.in_the_trash" => "In the trash",
    "admin.exclusions.hidden_from_search" => "Hidden from search",
    "admin.exclusions.no_public_url" => "No public URL",
    "admin.exclusions.left_out" => "Left out of the sitemap",
    "admin.chart.pages_series" => "Pages"
  }.freeze
  # rubocop:enable Style/FormatStringToken

  def test_en_yml_ships_expected_english_under_recording_studio_sitemaps
    path = File.expand_path("../config/locales/en.yml", __dir__)
    tree = YAML.safe_load_file(path, aliases: true)
    root = tree.fetch("en").fetch("recording_studio").fetch("sitemaps")

    EXPECTED.each do |key, english|
      assert_equal english, dig(root, key.split(".")), "expected #{key.inspect} => #{english.inspect}"
    end
  end

  def test_copy_t_resolves_english_without_default
    path = File.expand_path("../config/locales/en.yml", __dir__)
    backend_before = I18n.backend
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.load_translations(path)

    EXPECTED.each do |key, english|
      next if english.include?("%{")

      assert_equal english, RecordingStudioSitemaps::Copy.t(key)
    end

    assert_equal "Last built 01 Jan 2026, 12:00",
                 RecordingStudioSitemaps::Copy.t(
                   "admin.last_build.success",
                   stamp: "01 Jan 2026, 12:00"
                 )
  ensure
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

  private

  def dig(hash, parts)
    parts.reduce(hash) { |node, part| node.fetch(part) }
  end
end
