# frozen_string_literal: true

require "test_helper"

class SitemapXmlTest < ActionDispatch::IntegrationTest
  setup do
    seed_sitemap_pages!
  end

  test "public sitemap includes indexable loc and omits excluded pages" do
    get "/sitemap.xml"

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<loc>"
    assert_includes response.body, "getting-started"
    refute_includes response.body, "staff-only-notes"
    refute_includes response.body, "changefreq"
    refute_includes response.body, "priority"
  end

  test "public sitemap does not require a signed-in actor" do
    get "/sitemap.xml"

    assert_response :success
    refute_includes response.body, "users/sign_in"
  end

  test "rebuild writes a generation log the public sitemap can serve" do
    log = RecordingStudioSitemaps.rebuild!(source: :test)

    assert_predicate log, :success?
    assert_operator log.url_count, :>=, 1
    assert_includes log.xml, "getting-started"

    get "/sitemap.xml"

    assert_response :success
    assert_includes response.body, log.xml[/<loc>.*<\/loc>/]
  end

  test "public sitemap rebuilds when no successful log exists" do
    RecordingStudioSitemaps::GenerationLog.delete_all

    get "/sitemap.xml"

    assert_response :success
    assert_includes response.body, "getting-started"
    assert_predicate RecordingStudioSitemaps::GenerationLog.latest, :success?
  end

  private

  def seed_sitemap_pages!
    user = User.find_or_create_by!(email: "sitemap-xml@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    workspace = Workspace.create!(name: "Sitemap Workspace #{SecureRandom.hex(4)}")
    folder = Folder.create!(name: "Docs")
    indexable_page = Page.create!(title: "Getting Started")
    excluded_page = Page.create!(title: "Staff-only notes")

    Current.actor = user
    root = RecordingStudio.root_recording_for(workspace)
    folder_recording = record_child(folder, root, root)
    indexable_recording = record_child(indexable_page, root, folder_recording)
    excluded_recording = record_child(excluded_page, root, folder_recording)

    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: indexable_recording,
      actor: user,
      attributes: { slug: "getting-started", status: "published", meta_robots: "index,follow" }
    )
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: excluded_recording,
      actor: user,
      attributes: { slug: "staff-only-notes", status: "published", meta_robots: "noindex,follow" }
    )
  ensure
    Current.actor = nil
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
