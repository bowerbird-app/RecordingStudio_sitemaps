# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class SitemapsI18nRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "sitemaps-i18n-render@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    seed_admin_and_pages!
    sign_in @user
    switch_to_admin_root!(@admin_recording)
  end

  test "admin sitemaps section renders gem english from locale keys" do
    get "/admin/sections/sitemaps"

    assert_response :success
    assert_includes response.body, "Sitemaps"
    assert_includes response.body, "Open sitemap"
    assert_includes response.body, "Rebuild"
    assert_includes response.body, "Coverage"
    assert_includes response.body, "In the sitemap"
    assert_includes response.body, "Missing"
    assert_includes response.body, "Index size"
    assert_includes response.body, "Hidden from search"
    assert_includes response.body, RecordingStudioSitemaps::Admin.last_build_line
  end

  test "rebuild flash renders gem english notice" do
    get "/recording_studio_sitemaps/rebuild"
    follow_redirect! if response.redirect?

    assert_response :success
    assert_includes response.body, "Sitemap rebuilt."
  end

  test "admin copy helpers keep english under fr locale via default" do
    with_french_locale do
      assert_equal "No sitemap written yet",
                   RecordingStudioSitemaps::Copy.t(
                     "admin.last_build.none",
                     default: "No sitemap written yet"
                   )
      assert_equal "Nothing findable yet.",
                   RecordingStudioSitemaps::Copy.t(
                     "admin.findable.empty",
                     default: "Nothing findable yet."
                   )
      assert_equal "In the trash",
                   RecordingStudioSitemaps::Copy.t(
                     "admin.exclusions.in_the_trash",
                     default: "In the trash"
                   )
    end
  end

  test "exclusions public api stays english under fr locale" do
    relation_class = Class.new do
      def initialize(ids)
        @ids = ids
      end

      def where(*)
        self
      end

      def pluck(*)
        @ids
      end
    end
    publishable_class = Class.new do
      def initialize(noindex:)
        @noindex = noindex
      end

      def noindex?
        @noindex
      end
    end
    recordable_class = Class.new do
      attr_reader :id, :title, :name, :trashed_at, :indexable_url

      def initialize(id:, title:, publishable:, indexable_url:)
        @id = id
        @title = title
        @publishable = publishable
        @indexable_url = indexable_url
      end

      def current_publishable_for_index
        @publishable
      end
    end
    type_class = Class.new do
      def initialize(published_rows, indexable_ids, relation_class)
        @published_rows = published_rows
        @indexable_ids = indexable_ids
        @relation_class = relation_class
      end

      def published
        @published_rows
      end

      def indexable
        @relation_class.new(@indexable_ids)
      end
    end

    recordable = recordable_class.new(
      id: 99,
      title: "Hidden page",
      publishable: publishable_class.new(noindex: true),
      indexable_url: "/hidden"
    )
    type = type_class.new([recordable], [], relation_class)

    with_french_locale do
      stub_singleton_method(RecordingStudioSitemaps::UrlSet, :indexable_types, [type]) do
        reasons = RecordingStudioSitemaps::Exclusions.items

        assert_equal "Hidden from search", reasons.first.reason
      end
    end
  end

  private

  def with_french_locale
    previous = I18n.available_locales
    I18n.available_locales = previous | [:fr]
    I18n.with_locale(:fr) { yield }
  ensure
    I18n.available_locales = previous
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

  def seed_admin_and_pages!
    Current.actor = @user
    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    @admin_recording = RecordingStudio.root_recording_for(admin_root)
    grant_admin_access_for_test!(recording: @admin_recording, actor: @user)

    workspace = Workspace.create!(name: "I18n Sitemap Workspace #{SecureRandom.hex(4)}")
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
      attributes: { slug: "getting-started-i18n", status: "published", meta_robots: "index,follow" }
    )
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: excluded_recording,
      actor: @user,
      attributes: { slug: "staff-only-notes-i18n", status: "published", meta_robots: "noindex,follow" }
    )
    RecordingStudioSitemaps.rebuild!(source: :test)
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

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording
    ).recording
  end
end
