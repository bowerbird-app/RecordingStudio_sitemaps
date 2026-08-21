# frozen_string_literal: true

require "test_helper"

class GenerateTest < Minitest::Test
  FakeEntry = Struct.new(:loc, :lastmod, keyword_init: true)
  FakeLog = Struct.new(:status, :url_count, :xml, :error_message, :source, :built_at, keyword_init: true) do
    def success?
      status == "success"
    end
  end

  def test_rebuild_writes_success_log
    entries = [FakeEntry.new(loc: "https://example.test/a", lastmod: Time.utc(2026, 8, 21))]
    created = nil

    RecordingStudioSitemaps::UrlSet.stub(:entries, entries) do
      RecordingStudioSitemaps::GenerationLog.stub(:create!, ->(**attrs) { FakeLog.new(**attrs) }) do
        created = RecordingStudioSitemaps.rebuild!(source: :admin)
      end
    end

    assert_equal "success", created.status
    assert_equal 1, created.url_count
    assert_includes created.xml, "https://example.test/a"
    assert_equal "admin", created.source
  end

  def test_rebuild_writes_error_log_when_url_set_raises
    created = nil

    RecordingStudioSitemaps::UrlSet.stub(:entries, -> { raise "boom" }) do
      RecordingStudioSitemaps::GenerationLog.stub(:create!, ->(**attrs) { FakeLog.new(**attrs) }) do
        created = RecordingStudioSitemaps.rebuild!(source: :publish)
      end
    end

    assert_equal "error", created.status
    assert_equal 0, created.url_count
    assert_equal "boom", created.error_message
    assert_equal "publish", created.source
  end
end
