# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class HomePageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "signed in home is a workspace slice inside default layout chrome" do
    user = User.find_or_create_by!(email: "home-slice@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    workspace = Workspace.create!(name: "Slice Workspace")
    root_recording = RecordingStudio.root_recording_for(workspace)

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: "/"
      }
    }
    follow_redirect!

    assert_response :success
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    assert_select "nav.flat-pack-page-nav", count: 1
    assert_select "[aria-label='Go back']", count: 1
    assert_select "a[aria-label='Close'][href='/']", count: 1
    refute_includes response.body, "Sign out"
    refute_includes response.body, 'href="/users/sign_out"'
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
    assert_select "h1", text: workspace.name
    refute_select "h1", text: "Dummy host"
    refute_includes response.body, "proves the"
    refute_includes response.body, "admin@admin.com"
    refute_includes response.body, "Sitemap XML"
    refute_includes response.body, "dummy_page_nav"
  end
end
