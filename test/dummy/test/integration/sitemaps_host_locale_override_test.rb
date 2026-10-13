# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class SitemapsHostLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_REBUILT = "HOST rebuild succeeded."
  HOST_REBUILD_FAILED = "HOST rebuild failed — check the last build."
  REBUILT_KEY = "recording_studio.sitemaps.flashes.rebuilt"
  REBUILD_FAILED_KEY = "recording_studio.sitemaps.flashes.rebuild_failed"
  BOOT_HOST_LOCALE = Rails.root.join("config/locales/recording_studio_sitemaps_host.en.yml")
  FRESH_HOST_LOCALE = Rails.root.join("test/locales/sitemaps_host_override.en.yml")

  setup do
    @load_path_before = I18n.load_path.dup
    @backend_before = I18n.backend
    @user = User.find_or_create_by!(email: "sitemaps-host-override@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    seed_admin!
    sign_in @user
    switch_to_admin_root!(@admin_recording)
  end

  teardown do
    I18n.backend = @backend_before if @backend_before
    assert_equal @load_path_before, I18n.load_path,
                 "test must not leave I18n.load_path modified"
  end

  # Real-boot-order guard: host file under config/locales must win without any
  # test-time load_path mutation. Render assertion uses the failed-rebuild flash.
  test "host locale override for recording_studio.sitemaps wins on boot order" do
    assert File.exist?(BOOT_HOST_LOCALE)
    assert_includes File.read(BOOT_HOST_LOCALE), HOST_REBUILD_FAILED
    assert_equal HOST_REBUILD_FAILED, I18n.t(REBUILD_FAILED_KEY)
    assert_equal @load_path_before, I18n.load_path,
                 "boot-order test must not mutate I18n.load_path"

    failed = RecordingStudioSitemaps::GenerationLog.new(
      status: RecordingStudioSitemaps::GenerationLog::ERROR,
      built_at: Time.current,
      url_count: 0,
      source: "test"
    )

    stub_singleton_method(RecordingStudioSitemaps, :rebuild!, ->(*) { failed }) do
      get "/recording_studio_sitemaps/rebuild"
    end

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_includes response.body, HOST_REBUILD_FAILED
    refute_includes response.body, "Sitemap rebuild hit a snag. Check the last build."
  end

  # Test-only fixture: swap to a fresh Simple backend loaded from the current
  # load_path, then layer the fixture via load_translations. Restore by putting
  # the previous backend object back — never write @translations / @initialized.
  test "host locale file overrides gem rebuild flash on the real admin section" do
    assert File.exist?(FRESH_HOST_LOCALE), "expected test-only host override fixture at #{FRESH_HOST_LOCALE}"
    assert_includes File.read(FRESH_HOST_LOCALE), HOST_REBUILT

    previous_backend = I18n.backend
    I18n.backend = I18n::Backend::Simple.new
    I18n.reload!
    I18n.t(REBUILT_KEY)
    I18n.backend.load_translations(FRESH_HOST_LOCALE.to_s)

    assert_equal @load_path_before, I18n.load_path
    assert_equal HOST_REBUILT, I18n.t(REBUILT_KEY)
    assert_equal HOST_REBUILD_FAILED, I18n.t(REBUILD_FAILED_KEY)

    get "/recording_studio_sitemaps/rebuild"

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_includes response.body, HOST_REBUILT
    refute_includes response.body, "Sitemap rebuilt."
  ensure
    I18n.backend = previous_backend if previous_backend
  end

  test "default english rebuild flash is unchanged outside the host override" do
    get "/recording_studio_sitemaps/rebuild"

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Sitemap rebuilt."
    refute_includes response.body, HOST_REBUILT
  end

  private

  def seed_admin!
    Current.actor = @user
    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    @admin_recording = RecordingStudio.root_recording_for(admin_root)
    grant_admin_access_for_test!(recording: @admin_recording, actor: @user)
  ensure
    Current.actor = nil
  end

  def switch_to_admin_root!(admin_recording)
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: admin_recording.id,
        return_to: "/"
      }
    }
  end

  def stub_singleton_method(target, method_name, replacement)
    singleton = target.singleton_class
    original = target.method(method_name)
    singleton.define_method(method_name) do |*args, **kwargs, &block|
      if replacement.respond_to?(:call)
        replacement.call(*args, **kwargs, &block)
      else
        replacement
      end
    end
    yield
  ensure
    singleton.define_method(method_name, original)
  end
end
