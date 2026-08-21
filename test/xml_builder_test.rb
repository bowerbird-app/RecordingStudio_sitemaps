# frozen_string_literal: true

require "test_helper"

class XmlBuilderTest < Minitest::Test
  def test_builds_urlset_with_loc_and_lastmod
    published_at = Time.utc(2026, 8, 21, 10, 0, 0)
    xml = RecordingStudioSitemaps::XmlBuilder.build(
      [
        { loc: "https://example.test/published/abc/getting-started", lastmod: published_at }
      ]
    )

    assert_includes xml, '<?xml version="1.0" encoding="UTF-8"?>'
    assert_includes xml, '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    assert_includes xml, "<loc>https://example.test/published/abc/getting-started</loc>"
    assert_includes xml, "<lastmod>2026-08-21T10:00:00Z</lastmod>"
    refute_includes xml, "changefreq"
    refute_includes xml, "priority"
  end

  def test_skips_blank_locs_and_escapes_markup
    xml = RecordingStudioSitemaps::XmlBuilder.build(
      [
        { loc: "" },
        { loc: "https://example.test/a&b", lastmod: nil }
      ]
    )

    refute_includes xml, "<loc></loc>"
    assert_includes xml, "<loc>https://example.test/a&amp;b</loc>"
  end

  def test_empty_entries_still_emit_urlset
    xml = RecordingStudioSitemaps::XmlBuilder.build([])

    assert_includes xml, "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
    refute_includes xml, "<url>"
  end
end
