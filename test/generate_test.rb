# frozen_string_literal: true

require "test_helper"

class GenerateTest < Minitest::Test
  FakeLog = Struct.new(:status, :url_count, :xml, :error_message, :source, :built_at, keyword_init: true) do
    def success?
      status == "success"
    end
  end

  def setup
    super
    RecordingStudioSitemaps.unregister_source(:publishable)
  end

  def test_rebuild_writes_success_log_from_batches
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << RecordingStudioSitemaps::Entry.new(
        loc: "https://example.test/a",
        lastmod: Time.utc(2026, 8, 21),
        changefreq: "weekly",
        priority: 0.8
      )
    end
    created = nil

    RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://example.test") do
      RecordingStudioSitemaps::GenerationLog.stub(:create!, ->(**attrs) { created = FakeLog.new(**attrs) }) do
        created = RecordingStudioSitemaps.rebuild!(source: :admin)
      end
    end

    assert_equal "success", created.status
    assert_equal 1, created.url_count
    assert_includes created.xml, "https://example.test/a"
    assert_includes created.xml, "<changefreq>weekly</changefreq>"
    assert_includes created.xml, "<priority>0.8</priority>"
    assert_equal "admin", created.source
  end

  def test_source_failure_does_not_publish_a_partial_sitemap
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << RecordingStudioSitemaps::Entry.new(loc: "https://example.test/partial")
      raise "boom"
    end
    created = nil
    logs = []

    with_logger(logs) do
      RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://example.test") do
        RecordingStudioSitemaps::GenerationLog.stub(:create!, ->(**attrs) { created = FakeLog.new(**attrs) }) do
          created = RecordingStudioSitemaps.rebuild!(source: :publish)
        end
      end
    end

    assert_equal "error", created.status
    assert_equal 0, created.url_count
    assert_nil created.xml
    assert_equal "Failed", created.error_message
    refute_includes created.error_message.to_s, "boom"
    assert_equal "publish", created.source
    assert(logs.any? { |message| message.include?("boom") })
  end

  def test_a_filter_error_still_publishes_the_entries_that_passed
    RecordingStudioSitemaps.register_source(:pages) do |batch|
      batch << [
        RecordingStudioSitemaps::Entry.new(loc: "https://example.test/ok"),
        RecordingStudioSitemaps::Entry.new(loc: "https://example.test/bad")
      ]
    end
    RecordingStudioSitemaps.register_filter(:visibility) do |entry|
      raise "nope" if entry.loc.end_with?("/bad")

      true
    end
    created = nil

    with_logger([]) do
      RecordingStudioSitemaps.configuration.stub(:public_base_url, "https://example.test") do
        RecordingStudioSitemaps::GenerationLog.stub(:create!, ->(**attrs) { created = FakeLog.new(**attrs) }) do
          created = RecordingStudioSitemaps.rebuild!(source: :test)
        end
      end
    end

    assert_equal "success", created.status
    assert_equal 1, created.url_count
    assert_includes created.xml, "https://example.test/ok"
    refute_includes created.xml, "https://example.test/bad"
  end

  private

  def with_logger(logs, &)
    logger = Object.new
    logger.define_singleton_method(:error) { |message| logs << message }
    Rails.stub(:logger, logger, &)
  end
end
