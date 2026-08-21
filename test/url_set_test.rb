# frozen_string_literal: true

require "test_helper"

class UrlSetTest < Minitest::Test
  def test_indexable_types_skips_types_without_indexable
    RecordingStudio.configuration.stub(:recordable_types, %w[String Object MissingType]) do
      types = RecordingStudioSitemaps::UrlSet.indexable_types

      refute_includes types, String
      refute_includes types, Object
    end
  end

  def test_absolute_url_helper_is_used_for_paths
    url = RecordingStudioSitemaps::AbsoluteUrl.call(
      "/published/abc/slug",
      public_base_url: "https://site.test"
    )

    assert_equal "https://site.test/published/abc/slug", url
  end
end
