# frozen_string_literal: true

require "test_helper"

class PageNavHelperTest < ActionView::TestCase
  include PageNavHelper

  test "recording_studio_page_nav writes title and slot content" do
    recording_studio_page_nav(
      title: "Build history",
      page_nav_anchor_url: "/admin",
      page_nav_back_url: "/",
      page_nav_back_icon: nil
    )

    assert_equal "Build history", content_for(:title)
    assert_equal "/admin", content_for(:page_nav_anchor_url)
    assert_equal "/", content_for(:page_nav_back_url)
    refute content_for?(:page_nav_back_icon)
  end
end
