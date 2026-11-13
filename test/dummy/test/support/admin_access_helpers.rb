# frozen_string_literal: true

module AdminAccessHelpers
  ROLE_RANK = {
    "view" => 1,
    "edit" => 2,
    "admin" => 3
  }.freeze

  def grant_admin_access_for_test!(recording:, actor:, role: "admin")
    current_role = RecordingStudioAccessible.role_for(actor: actor, recording: recording)
    return recording if role_covers?(current_role, role)

    if role.to_s == "admin"
      bootstrap_result = RecordingStudioAccessible.bootstrap_owner_access!(
        recording: recording,
        actor: actor
      )
      return recording if bootstrap_result.success?
    end

    manager = existing_test_access_manager(recording, role)
    manager = bootstrap_test_access_manager!(recording) if manager.nil? && role.to_s != "admin"
    raise "Failed to grant access in test: no manager holds #{role}" if manager.nil?

    previous_authorizer = RecordingStudioAccessible.configuration.access_management_authorizer
    begin
      RecordingStudioAccessible.configuration.access_management_authorizer = ->(recording:, **) { recording.present? }

      result = RecordingStudioAccessible.grant_access(
        recording: recording,
        actor: actor,
        role: role,
        manager_actor: manager
      )

      raise "Failed to grant access in test: #{result.error}" if result.failure?
    ensure
      RecordingStudioAccessible.configuration.access_management_authorizer = previous_authorizer
    end

    recording
  end

  # Root Switchable 0.12+ requires Accessible :view on the current root before
  # the mounted switch page. Grant it on every switchable root the dummy lists.
  def grant_view_for_root_switch!(actor)
    Workspace.find_each do |workspace|
      recording = RecordingStudio.root_recording_for(workspace)
      next unless recording

      grant_admin_access_for_test!(recording: recording, actor: actor, role: "view")
    end

    AdminRoot.find_each do |admin_root|
      recording = RecordingStudio.root_recording_for(admin_root)
      next unless recording

      grant_admin_access_for_test!(recording: recording, actor: actor, role: "view")
    end
  end

  private

  def existing_test_access_manager(recording, role)
    RecordingStudioAccessible.access_recordings_for(recording).each do |access_recording|
      access = access_recording.recordable
      next unless access.respond_to?(:actor) && access.actor
      next unless role_covers?(access.role, role)

      held = RecordingStudioAccessible.role_for(actor: access.actor, recording: recording)
      return access.actor if role_covers?(held, role)
    end

    nil
  end

  def bootstrap_test_access_manager!(recording)
    manager = User.find_or_create_by!(email: "recording-studio-sitemaps-grant-manager@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    bootstrap = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: manager)
    raise "Failed to bootstrap test access manager: #{bootstrap.error}" if bootstrap.failure?

    manager
  end

  def role_covers?(current_role, required_role)
    return false if current_role.nil?

    (ROLE_RANK[current_role.to_s] || 0) >= (ROLE_RANK[required_role.to_s] || 0)
  end
end
