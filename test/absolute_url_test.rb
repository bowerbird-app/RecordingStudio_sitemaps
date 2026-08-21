# frozen_string_literal: true

require "test_helper"

class AbsoluteUrlTest < Minitest::Test
  def test_keeps_absolute_http_urls
    assert_equal(
      "https://canonical.test/page",
      RecordingStudioSitemaps::AbsoluteUrl.call(
        "https://canonical.test/page",
        public_base_url: "http://www.example.com"
      )
    )
  end

  def test_prefixes_paths_with_public_base_url
    assert_equal(
      "http://www.example.com/published/abc/slug",
      RecordingStudioSitemaps::AbsoluteUrl.call(
        "/published/abc/slug",
        public_base_url: "http://www.example.com/"
      )
    )
  end

  def test_returns_nil_for_blank_or_unusable_values
    assert_nil RecordingStudioSitemaps::AbsoluteUrl.call(nil, public_base_url: "http://www.example.com")
    assert_nil RecordingStudioSitemaps::AbsoluteUrl.call("not a url", public_base_url: "http://www.example.com")
    assert_nil RecordingStudioSitemaps::AbsoluteUrl.call("/published/abc", public_base_url: nil)
  end
end
