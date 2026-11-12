# frozen_string_literal: true

require "test_helper"

class SitemapRebuildApiTest < ActionDispatch::IntegrationTest
  OPERATIONS_ROOT = "/recording_studio_api/apis/operations/v1"

  setup do
    @staff = User.find_or_create_by!(email: "sitemap-rebuild-api-staff@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    Current.actor = @staff
    @admin_root_recordable = AdminRoot.find_or_create_by!(name: "Admin")
    @admin_root = RecordingStudio.root_recording_for(@admin_root_recordable)
    grant_admin_access_for_test!(recording: @admin_root, actor: @staff)
    @workspace = Workspace.find_or_create_by!(name: "Sitemap rebuild API workspace")
    @workspace_root = RecordingStudio.root_recording_for(@workspace)
    unless RecordingStudioAccessible.authorized?(actor: @staff, recording: @workspace_root, role: :view)
      grant_admin_access_for_test!(recording: @workspace_root, actor: @staff, role: "admin")
    end
  end

  teardown do
    Current.actor = nil
  end

  test "rebuild writes a generation log through RecordingStudioSitemaps.rebuild!" do
    issued = issue_token(access_point: @admin_root, actor: @staff, role: :view, api: :operations)
    grant_admin_access_for_test!(
      recording: @admin_root,
      actor: issued.fetch(:api_client),
      role: "view"
    )

    log = nil
    assert_difference -> { RecordingStudioSitemaps::GenerationLog.count }, 1 do
      post "#{OPERATIONS_ROOT}/sitemaps/rebuild", headers: bearer_headers(issued.fetch(:token)), as: :json
      assert_response :success, response.body
      log = RecordingStudioSitemaps::GenerationLog.order(:created_at).last
    end

    body = response.parsed_body
    assert_equal log.id, body.fetch("id")
    assert_equal RecordingStudioSitemaps::GenerationLog::SUCCESS, body.fetch("status")
    assert_equal "api", body.fetch("source")
    assert_equal "api", log.source
    assert_equal log.url_count, body.fetch("url_count")
  end

  test "rebuild returns 401 without a token" do
    assert_no_difference -> { RecordingStudioSitemaps::GenerationLog.count } do
      post "#{OPERATIONS_ROOT}/sitemaps/rebuild", as: :json
    end

    assert_response :unauthorized
  end

  test "rebuild returns 403 when the actor cannot view Admin" do
    issued = issue_token(access_point: @admin_root, actor: @staff, role: :view, api: :operations)
    RecordingStudio::Access.where(id: issued.fetch(:access_recording).recordable_id).update_all(role: "")
    refute RecordingStudioAccessible.authorized?(
      actor: issued.fetch(:access_recording).recordable.reload.actor,
      recording: @admin_root,
      role: :view
    )

    assert_no_difference -> { RecordingStudioSitemaps::GenerationLog.count } do
      post "#{OPERATIONS_ROOT}/sitemaps/rebuild", headers: bearer_headers(issued.fetch(:token)), as: :json
    end

    assert_response :forbidden
  end

  test "register! raises when sitemaps.rebuild already has a foreign handler" do
    existing = RecordingStudioApi.registered_endpoint(
      RecordingStudioSitemaps::Api::NAME,
      api: RecordingStudioSitemaps::Api::API
    )
    original_handler = existing.handler
    existing.instance_variable_set(:@handler, Object)

    error = assert_raises(RecordingStudioApi::ConfigurationError) do
      RecordingStudioSitemaps::Api.register!
    end

    assert_equal "API endpoint sitemaps.rebuild is already registered", error.message
  ensure
    existing&.instance_variable_set(:@handler, original_handler) if original_handler
  end

  test "rebuild returns 404 for a foreign root" do
    issued = issue_token(access_point: @workspace_root, actor: @staff, role: :view, api: :operations)

    assert_no_difference -> { RecordingStudioSitemaps::GenerationLog.count } do
      post "#{OPERATIONS_ROOT}/sitemaps/rebuild", headers: bearer_headers(issued.fetch(:token)), as: :json
    end

    assert_response :not_found
  end

  private

  def bearer_headers(token)
    { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
  end

  def issue_token(access_point:, actor:, role:, api:)
    original = RecordingStudioAccessible.configuration.access_management_authorizer
    RecordingStudioAccessible.configuration.access_management_authorizer = ->(**) { true }
    provision = RecordingStudioApi::Services::ProvisionApiClient.call(
      access_point_recording: access_point,
      manager_actor: actor,
      role: role,
      name: "Sitemap rebuild #{api} #{SecureRandom.hex(4)}",
      api: api
    )
    raise provision.error unless provision.success?

    token_result = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      grant_type: "client_credentials",
      client_id: provision.value.fetch(:credential).oauth_client_id,
      client_secret: provision.value.fetch(:token),
      api: api
    )
    raise token_result.error unless token_result.success?

    {
      token: token_result.value.fetch(:access_token),
      access_recording: provision.value.fetch(:access_recording),
      api_client: provision.value.fetch(:api_client)
    }
  ensure
    RecordingStudioAccessible.configuration.access_management_authorizer = original
  end
end
