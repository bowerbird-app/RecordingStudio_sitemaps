# frozen_string_literal: true

require "test_helper"

# Pages that Publishable itself says are not indexable must stay out of the
# sitemap. "Private" is not a Publishable state: a published index,follow page
# is indexable, and the default source includes it.
class SitemapStateExclusionsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "sitemap-states-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = @user
    @workspace = Workspace.create!(name: "State Workspace #{SecureRandom.hex(4)}")
    @root = RecordingStudio.create_root_recording!(@workspace, actor: @user)
  end

  teardown do
    Current.actor = nil
  end

  test "draft scheduled expired trashed and noindex pages stay out of the sitemap" do
    draft = publish!("Draft notes", slug: "state-draft", status: "draft", meta_robots: "index,follow")
    scheduled = publish!(
      "Scheduled notes",
      slug: "state-scheduled",
      status: "published",
      publish_at: 3.days.from_now.iso8601,
      time_zone: "UTC",
      meta_robots: "index,follow"
    )
    expired = publish!(
      "Expired notes",
      slug: "state-expired",
      status: "published",
      publish_at: 3.days.ago.iso8601,
      unpublish_at: 1.day.ago.iso8601,
      time_zone: "UTC",
      meta_robots: "index,follow"
    )
    noindex = publish!("Noindex notes", slug: "state-noindex", status: "published", meta_robots: "noindex,follow")
    trashed = publish!("Trashed notes", slug: "state-trashed", status: "published", meta_robots: "index,follow")
    visible = publish!("Visible notes", slug: "state-visible", status: "published", meta_robots: "index,follow")

    RecordingStudioTrashable.void_recording!(trashed.fetch(:recording))

    assert_includes Page.draft, draft.fetch(:page)
    assert_includes Page.scheduled, scheduled.fetch(:page)
    assert_includes Page.published, noindex.fetch(:page)
    assert_includes Page.indexable, visible.fetch(:page)
    refute_includes Page.indexable, draft.fetch(:page)
    refute_includes Page.indexable, scheduled.fetch(:page)
    refute_includes Page.indexable, expired.fetch(:page)
    refute_includes Page.indexable, noindex.fetch(:page)
    refute_includes Page.indexable, trashed.fetch(:page)
    assert_predicate expired_publishable(expired), :previously_published?
    refute_predicate expired_publishable(expired), :currently_published?

    log = RecordingStudioSitemaps.rebuild!(source: :test)

    assert_predicate log, :success?
    assert_includes log.xml, "state-visible"
    %w[state-draft state-scheduled state-expired state-noindex state-trashed].each do |slug|
      refute_includes log.xml, slug
    end
  end

  test "a published indexable page is not excluded for a private slug" do
    published = publish!("Private notes", slug: "state-private", status: "published", meta_robots: "index,follow")

    assert_includes Page.indexable, published.fetch(:page)

    log = RecordingStudioSitemaps.rebuild!(source: :test)

    assert_predicate log, :success?
    assert_includes log.xml, "state-private"
  end

  private

  def publish!(title, **attributes)
    page = Page.create!(title: title)
    recording = RecordingStudio.record!(
      action: "created",
      recordable: page,
      root_recording: @root,
      parent_recording: @root
    ).recording
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: recording,
      actor: @user,
      attributes: attributes
    )
    raise result.error if result.failure?

    { page: page, recording: recording }
  end

  def expired_publishable(record)
    record.fetch(:recording).reload.current_publishable
  end
end
