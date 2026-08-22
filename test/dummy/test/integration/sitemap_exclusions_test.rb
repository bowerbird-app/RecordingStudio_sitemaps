# frozen_string_literal: true

require "test_helper"

class SitemapExclusionsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "sitemap-exclusions-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = @user
  end

  teardown do
    Current.actor = nil
  end

  test "published noindex pages are excluded with a human reason" do
    page = publish_page!("Hidden notes", slug: "hidden-notes", meta_robots: "noindex,follow")

    reasons = RecordingStudioSitemaps::Exclusions.items
    match = reasons.find { |row| row.title == page.title }

    assert match
    assert_equal "Hidden from search", match.reason
    refute_includes RecordingStudioSitemaps::UrlSet.entries.map(&:loc), /hidden-notes/
  end

  test "rebuild logs success count and xml" do
    publish_page!("Visible page", slug: "visible-page", meta_robots: "index,follow")

    log = RecordingStudioSitemaps.rebuild!(source: :test)

    assert_predicate log, :success?
    assert_operator log.url_count, :>=, 1
    assert_includes log.xml, "visible-page"
    assert_equal "test", log.source
    assert_equal log, RecordingStudioSitemaps::GenerationLog.latest
  end

  private

  def publish_page!(title, slug:, meta_robots:)
    workspace = Workspace.create!(name: "Exclusion Workspace #{SecureRandom.hex(4)}")
    page = Page.create!(title: title)
    root = RecordingStudio.root_recording_for(workspace)
    page_recording = RecordingStudio.record!(
      action: "created",
      recordable: page,
      root_recording: root,
      parent_recording: root
    ).recording

    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: page_recording,
      actor: @user,
      attributes: { slug: slug, status: "published", meta_robots: meta_robots }
    )
    page
  end
end
