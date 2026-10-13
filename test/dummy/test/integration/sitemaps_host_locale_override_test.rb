# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class SitemapsHostLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_SECTION_TITLE = "HOST Sitemaps"
  HOST_REBUILD_FAILED = "HOST rebuild failed — check the last build."
  SECTION_TITLE_KEY = "recording_studio.sitemaps.admin.section.title"
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

    follow_redirect! if response.redirect?

    assert_response :success
    assert_includes response.body, HOST_REBUILD_FAILED
    refute_includes response.body, "Sitemap rebuild hit a snag. Check the last build."
  end

  # Test-only fixture applied via backend.load_translations(file) on top of the
  # already-initialized backend — never mutates I18n.load_path (Marshal).
  test "host locale file overrides gem sitemaps section title on the real admin section" do
    assert File.exist?(FRESH_HOST_LOCALE), "expected test-only host override fixture at #{FRESH_HOST_LOCALE}"
    assert_includes File.read(FRESH_HOST_LOCALE), HOST_SECTION_TITLE

    snapshot = i18n_backend_translations_snapshot
    I18n.t(SECTION_TITLE_KEY)
    I18n.backend.load_translations(FRESH_HOST_LOCALE.to_s)

    assert_equal @load_path_before, I18n.load_path
    assert_equal HOST_SECTION_TITLE, I18n.t(SECTION_TITLE_KEY)
    assert_equal HOST_REBUILD_FAILED, I18n.t(REBUILD_FAILED_KEY)

    get "/admin/sections/sitemaps"

    assert_response :success
    assert_includes response.body, HOST_SECTION_TITLE
  ensure
    restore_i18n_backend_translations(snapshot) if snapshot
  end

  test "default english section title is unchanged outside the host override" do
    get "/admin/sections/sitemaps"

    assert_response :success
    assert_includes response.body, "Sitemaps"
    refute_includes response.body, HOST_SECTION_TITLE
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

  def i18n_backend_translations_snapshot
    backend = I18n.backend
    backend.send(:init_translations) unless backend.initialized?
    translations =
      if backend.respond_to?(:translations)
        backend.translations
      else
        backend.instance_variable_get(:@translations)
      end
    return unless translations

    deep_plain_copy(translations)
  end

  def restore_i18n_backend_translations(snapshot)
    backend = I18n.backend
    backend.instance_variable_set(:@translations, snapshot)
    backend.instance_variable_set(:@initialized, true) if backend.instance_variable_defined?(:@initialized)
  end

  def deep_plain_copy(value)
    case value
    when Hash
      value.each_with_object({}) { |(key, child), copy| copy[key] = deep_plain_copy(child) }
    when Array
      value.map { |child| deep_plain_copy(child) }
    else
      value
    end
  end
end
