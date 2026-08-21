# frozen_string_literal: true

require "test_helper"

class UrlSetTest < Minitest::Test
  IndexableType = Struct.new(:recordable) do
    def indexable
      [recordable]
    end
  end

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

  def test_entries_use_public_url_and_publish_time
    published_at = Time.utc(2026, 8, 21, 9, 0, 0)
    publishable = Struct.new(:publish_at).new(published_at)
    recordable = Struct.new(:indexable_url, :current_publishable_for_index).new(
      "/published/abc/getting-started",
      publishable
    )
    instance = RecordingStudioSitemaps::UrlSet.new

    instance.stub(:indexable_types, [IndexableType.new(recordable)]) do
      RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://site.test") do
        entries = instance.entries

        assert_equal 1, entries.size
        assert_equal "https://site.test/published/abc/getting-started", entries.first.loc
        assert_equal published_at, entries.first.lastmod
        assert_equal recordable, entries.first.recordable
      end
    end
  end

  def test_entries_omit_recordables_without_a_usable_url
    recordable = Struct.new(:indexable_url, :current_publishable_for_index).new(nil, nil)
    instance = RecordingStudioSitemaps::UrlSet.new

    instance.stub(:indexable_types, [IndexableType.new(recordable)]) do
      assert_empty instance.entries
    end
  end
end
