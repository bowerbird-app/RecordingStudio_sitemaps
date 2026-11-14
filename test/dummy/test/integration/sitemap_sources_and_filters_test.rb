# frozen_string_literal: true

require "test_helper"

class SitemapSourcesAndFiltersTest < ActionDispatch::IntegrationTest
  PARTIAL_LOC = "http://www.example.com/partial-from-a-failed-source"

  setup do
    @user = User.create!(
      email: "sitemap-contract-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    Current.actor = @user
    @workspace = Workspace.create!(name: "Contract Workspace #{SecureRandom.hex(4)}")
    @root = RecordingStudio.root_recording_for(@workspace)
  end

  teardown do
    Current.actor = nil
  end

  test "served sitemap keeps public entries and drops everything the contract rejects" do
    publish_page!("Public guide", slug: "public-guide", status: "published", meta_robots: "index,follow")
    publish_page!("Draft notes", slug: "draft-notes", status: "draft", meta_robots: "index,follow")
    publish_page!("Hidden notes", slug: "hidden-notes", status: "published", meta_robots: "noindex,follow")
    trashed = publish_page!("Trashed notes", slug: "trashed-notes", status: "published", meta_robots: "index,follow")
    trash_recording!(trashed)

    register_contract_source!
    register_contract_filters!

    log = RecordingStudioSitemaps.rebuild!(source: :test)

    assert_predicate log, :success?
    get "/sitemap.xml"

    assert_response :success
    assert_includes response.body, "public-guide"
    assert_includes response.body, "marketing-page"
    refute_includes response.body, "draft-notes"
    refute_includes response.body, "hidden-notes"
    refute_includes response.body, "trashed-notes"
    refute_includes response.body, "vetoed-page"
    refute_includes response.body, "relative-page"
    refute_includes response.body, "off-host-page"
    refute_includes response.body, "raises-page"

    withheld = RecordingStudioSitemaps::Exclusions.items
    assert_equal :veto, withheld.find { |row| row.loc.include?("vetoed-page") }.filter_name
    assert_equal "Held back by veto", withheld.find { |row| row.loc.include?("vetoed-page") }.reason
    assert_equal :absolute_url, withheld.find { |row| row.title == "Relative page" }.filter_name
    assert_equal :public_host, withheld.find { |row| row.title == "Off host page" }.filter_name
    assert_equal "Filter failed", withheld.find { |row| row.title == "Raises page" }.reason

    public_entry = RecordingStudioSitemaps::Collection.accepted.find { |entry| entry.loc.include?("public-guide") }
    assert_equal "Public guide", public_entry.title
    assert_equal "Page", public_entry.type
    assert_equal "Page", public_entry.recording.recordable_type

    good_xml = response.body
    RecordingStudioSitemaps.register_source(:broken) do |batch|
      batch << RecordingStudioSitemaps::Entry.new(loc: PARTIAL_LOC, title: "Partial")
      raise "source blew up"
    end

    failed = RecordingStudioSitemaps.rebuild!(source: :test)

    assert_equal RecordingStudioSitemaps::GenerationLog::ERROR, failed.status
    refute_includes failed.xml.to_s, PARTIAL_LOC
    get "/sitemap.xml"
    assert_equal good_xml, response.body
    refute_includes response.body, "partial-from-a-failed-source"
  end

  private

  def register_contract_source!
    base = RecordingStudioSitemaps.configuration.public_base_url
    RecordingStudioSitemaps.register_source(:contract_probe) do |batch|
      batch << [
        RecordingStudioSitemaps::Entry.new(loc: "#{base}/vetoed-page", title: "Vetoed page", type: "Page"),
        RecordingStudioSitemaps::Entry.new(loc: "/relative-page", title: "Relative page", type: "Page"),
        RecordingStudioSitemaps::Entry.new(
          loc: "https://other.test/off-host-page",
          title: "Off host page",
          type: "Page"
        ),
        RecordingStudioSitemaps::Entry.new(loc: "#{base}/raises-page", title: "Raises page", type: "Page"),
        RecordingStudioSitemaps::Entry.new(
          loc: "#{base}/marketing-page",
          title: "Marketing",
          type: "Page",
          changefreq: "monthly",
          priority: 0.3
        )
      ]
    end
  end

  def register_contract_filters!
    RecordingStudioSitemaps.register_filter(:veto) do |entry|
      entry.loc.to_s.include?("vetoed-page") ? "Held back by veto" : true
    end
    RecordingStudioSitemaps.register_filter(:raises) do |entry|
      raise "filter blew up" if entry.loc.to_s.include?("raises-page")

      true
    end
  end

  def publish_page!(title, slug:, status:, meta_robots:)
    page = Page.create!(title: title)
    page_recording = RecordingStudio.record!(
      action: "created",
      recordable: page,
      root_recording: @root,
      parent_recording: @root
    ).recording
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: page_recording,
      actor: @user,
      attributes: { slug: slug, status: status, meta_robots: meta_robots }
    )
    page_recording
  end

  def trash_recording!(recording)
    if recording.respond_to?(:recording_studio_trashable_trash!)
      recording.recording_studio_trashable_trash!(actor: @user)
    else
      recording.log_event!(action: "trashed", actor: @user)
      recording.update!(trashed_at: Time.current)
    end
  end
end
