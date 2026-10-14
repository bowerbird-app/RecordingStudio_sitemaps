# frozen_string_literal: true

require "test_helper"

class SitemapMetricsTest < ActiveSupport::TestCase
  include AdminAccessHelpers

  GrantContext = Struct.new(:access_grant)
  Grant = Struct.new(:actor)

  setup do
    RecordingStudioSitemaps::GenerationLog.delete_all
    @staff = user!("sitemap-metrics-staff")
    @outsider = user!("sitemap-metrics-outsider")
    Current.actor = @staff
    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    grant_admin_access_for_test!(recording: RecordingStudio.root_recording_for(admin_root), actor: @staff)
    Current.actor = nil
  end

  test "last build metrics are empty before the first build" do
    assert_equal [], execute("sitemaps.last_build_status").data
    assert_nil execute("sitemaps.last_build_age").value
    assert_nil execute("sitemaps.last_build_url_count").value
  end

  test "last build metrics read the newest generation log" do
    now = Time.utc(2026, 10, 14, 12)
    log!(built_at: now - 2.hours, status: "success", url_count: 40)
    log!(built_at: now - 30.minutes, status: "error", url_count: 0)

    travel_to now do
      assert_equal [{ key: "error", value: 1 }], execute("sitemaps.last_build_status").data
      assert_equal 30.minutes.to_i, execute("sitemaps.last_build_age").value
      assert_equal 0, execute("sitemaps.last_build_url_count").value
    end

    log!(built_at: now - 1.minute, status: "success", url_count: 42)
    travel_to now do
      assert_equal [{ key: "success", value: 1 }], execute("sitemaps.last_build_status").data
      assert_equal 60, execute("sitemaps.last_build_age").value
      assert_equal 42, execute("sitemaps.last_build_url_count").value
    end
  end

  test "catalog fields, no group_by, no date range, and operations exposure" do
    catalog = RecordingStudioMetrics.definitions.index_by(&:identifier)
    status = catalog.fetch("sitemaps.last_build_status")
    age = catalog.fetch("sitemaps.last_build_age")
    count = catalog.fetch("sitemaps.last_build_url_count")

    assert_equal "seconds", age.unit
    assert_equal "count", count.unit
    [status, age, count].each do |definition|
      assert definition.title.present?
      assert definition.description.present?
      assert_equal [], definition.group_by
      assert_equal :site, definition.blast_radius
      assert_equal [:operations], definition.exposed_apis
      refute definition.cacheable
    end
  end

  test "api_authorize allows AdminRoot staff and denies everyone else" do
    authorize = RecordingStudioMetrics.registry.api_authorize_for(:sitemaps)
    assert_equal RecordingStudioSitemaps::Metrics::AUTHORIZE, authorize
    assert authorize.call(GrantContext.new(Grant.new(@staff)))
    refute authorize.call(GrantContext.new(Grant.new(@outsider)))
    refute authorize.call(GrantContext.new(Grant.new(nil)))
    refute authorize.call(nil)
  end

  private

  def execute(identifier)
    RecordingStudioMetrics.execute(
      identifier,
      context: RecordingStudioMetrics::Context.new(scope: :site, actor: @staff, site_authorized: true, timezone: "UTC"),
      cache: false
    )
  end

  def log!(built_at:, status:, url_count:)
    RecordingStudioSitemaps::GenerationLog.create!(built_at: built_at, status: status, url_count: url_count,
                                                   source: "test")
  end

  def user!(prefix)
    User.create!(email: "#{prefix}-#{SecureRandom.hex(4)}@example.com", password: "Password123!",
                 password_confirmation: "Password123!")
  end
end
