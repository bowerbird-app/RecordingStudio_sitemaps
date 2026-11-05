# frozen_string_literal: true

require "test_helper"
require File.expand_path("../app/helpers/recording_studio_sitemaps/admin_rebuild_helper", __dir__)

class AdminRebuildHelperTest < Minitest::Test
  class View
    include RecordingStudioSitemaps::AdminRebuildHelper

    attr_reader :registered

    def initialize
      @registered = []
    end

    def recording_studio_admin_page_nav_role(style)
      style.to_s == "primary" ? :primary : :secondary
    end

    def preserve_anchor_url(url)
      url
    end

    def register_page_nav(text, url, role:, overflow:, data: nil)
      @registered << { text: text, url: url, role: role, overflow: overflow, data: data }
    end
  end

  FakeAction = Struct.new(:name, :text, :url, :style, keyword_init: true)

  def test_rebuild_action_registers_as_post
    view = View.new
    actions = [
      FakeAction.new(name: :open_sitemap, text: "Open sitemap", url: "/sitemap.xml", style: :secondary),
      FakeAction.new(name: :rebuild, text: "Rebuild", url: "/recording_studio_sitemaps/rebuild", style: :primary)
    ]

    view.recording_studio_admin_register_page_actions(actions)

    open_sitemap, rebuild = view.registered
    assert_nil open_sitemap[:data]
    assert_equal({ turbo_method: :post }, rebuild[:data])
    assert_equal :primary, rebuild[:role]
  end

  def test_rebuild_detected_from_url_when_name_missing
    view = View.new
    action = FakeAction.new(name: nil, text: "Rebuild", url: "/recording_studio_sitemaps/rebuild", style: :primary)

    assert view.sitemaps_rebuild_action?(action)
  end
end
