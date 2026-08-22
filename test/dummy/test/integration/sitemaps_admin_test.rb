# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class SitemapsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "sitemaps-admin@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    seed_admin_and_pages!
    sign_in @user
    switch_to_admin_root!(@admin_recording)
  end

  test "admin sitemaps section lists coverage, findable pages, and missing pages" do
    coverage = RecordingStudioSitemaps::Coverage.snapshot

    get "/admin/sections/sitemaps"

    assert_response :success
    assert_select "html[data-theme=rounded]", count: 1
    assert_select "body[data-recording-studio-default-layout=true]", count: 1
    assert_includes response.body, "flat_pack/application"
    assert_includes response.body, "Last built"
    assert_includes response.body, "Coverage"
    assert_includes response.body, "#{coverage.included} / #{coverage.published}"
    assert_operator coverage.included, :>, 0
    assert_operator coverage.published, :>, coverage.included
    assert_includes response.body, "In the sitemap"
    assert_includes response.body, "Getting Started"
    assert_includes response.body, "Page"
    assert_includes response.body, "Missing"
    assert_includes response.body, "Staff-only notes"
    assert_includes response.body, "Hidden from search"
    assert_includes response.body, "Open sitemap"
    assert_includes response.body, "Rebuild"
    assert_includes response.body, "Index size"
    assert_includes response.body, "Build history"
    refute_includes response.body, "Sign out"
    refute_includes response.body, 'href="/users/sign_out"'
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
    refute_includes response.body, "Findable pages"
    refute_includes response.body, "Live but left out"
    refute_includes response.body, "total URLs ever"
    refute_includes response.body, "recordable"
    refute_includes response.body, "indexable?"
    refute_includes response.body, "Sign in"
  end

  test "rebuild action writes a log and returns to the sitemaps section" do
    assert_difference -> { RecordingStudioSitemaps::GenerationLog.count }, +1 do
      get "/recording_studio_sitemaps/rebuild"
    end

    follow_redirect! if response.redirect?

    assert_response :success
    assert_includes response.body, "Sitemap rebuilt."
    assert_predicate RecordingStudioSitemaps::GenerationLog.latest, :success?
  end

  test "build history screen shows the index chart and rebuild table" do
    write_history_logs!

    get "/admin/screens/build_history"

    assert_response :success
    assert_select "html[data-theme=rounded]", count: 1
    assert_select "body[data-recording-studio-default-layout=true]", count: 1
    assert_includes response.body, "Build history"
    assert_includes response.body, "Every rebuild, and whether the list grew or shrank."
    assert_includes response.body, "/admin/screens/build_history/chart"
    assert_includes response.body, "/admin/screens/build_history/table"
    refute_includes response.body, "Sign out"
    refute_includes response.body, 'href="/users/sign_out"'
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
    refute_includes response.body, "recordable"

    get "/admin/screens/build_history/chart"
    assert_response :success
    assert_includes response.body, "Pages in the sitemap"

    get "/admin/screens/build_history/table"
    assert_response :success
    assert_includes response.body, "Each rebuild"
    assert_includes response.body, "When"
    assert_includes response.body, "Pages"
    assert_includes response.body, "Worked"
  end

  test "rebuild is forbidden without admin root access" do
    stranger = User.find_or_create_by!(email: "sitemaps-stranger@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    sign_in stranger

    get "/recording_studio_sitemaps/rebuild"

    assert_response :forbidden
  end

  private

  def seed_admin_and_pages!
    Current.actor = @user
    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    @admin_recording = RecordingStudio.root_recording_for(admin_root)
    grant_admin_access_for_test!(recording: @admin_recording, actor: @user)

    workspace = Workspace.create!(name: "Admin Sitemap Workspace #{SecureRandom.hex(4)}")
    folder = Folder.create!(name: "Docs")
    indexable_page = Page.create!(title: "Getting Started")
    excluded_page = Page.create!(title: "Staff-only notes")
    root = RecordingStudio.root_recording_for(workspace)
    folder_recording = record_child(folder, root, root)
    indexable_recording = record_child(indexable_page, root, folder_recording)
    excluded_recording = record_child(excluded_page, root, folder_recording)

    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: indexable_recording,
      actor: @user,
      attributes: { slug: "getting-started", status: "published", meta_robots: "index,follow" }
    )
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: excluded_recording,
      actor: @user,
      attributes: { slug: "staff-only-notes", status: "published", meta_robots: "noindex,follow" }
    )
    RecordingStudioSitemaps.rebuild!(source: :test)
  ensure
    Current.actor = nil
  end

  def write_history_logs!
    RecordingStudioSitemaps::GenerationLog.delete_all
    RecordingStudioSitemaps::GenerationLog.create!(
      built_at: 2.days.ago,
      status: RecordingStudioSitemaps::GenerationLog::SUCCESS,
      url_count: 1,
      source: "test"
    )
    RecordingStudioSitemaps::GenerationLog.create!(
      built_at: 1.day.ago,
      status: RecordingStudioSitemaps::GenerationLog::SUCCESS,
      url_count: 2,
      source: "test"
    )
    RecordingStudioSitemaps.rebuild!(source: :test)
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

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording
    ).recording
  end
end
