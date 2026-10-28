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

    required_role = role.to_s
    if required_role == "admin"
      bootstrap_result = RecordingStudioAccessible.bootstrap_owner_access!(
        recording: recording,
        actor: actor
      )
      return recording if bootstrap_result.success?
    end

    grantor = grantor_who_holds_role(recording: recording, role: required_role)
    raise "Failed to grant access in test: no grantor holds #{required_role}" if grantor.blank?

    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: actor,
      role: required_role,
      manager_actor: grantor
    )

    raise "Failed to grant access in test: #{result.error}" if result.failure?

    recording
  end

  private

  def grantor_who_holds_role(recording:, role:)
    RecordingStudioAccessible.access_recordings_for(recording).filter_map do |access_recording|
      access = access_recording.recordable
      next unless access.respond_to?(:role) && access.respond_to?(:actor)
      next unless role_covers?(access.role, role)

      access.actor
    end.first
  end

  def role_covers?(current_role, required_role)
    return false if current_role.nil?

    (ROLE_RANK[current_role.to_s] || 0) >= (ROLE_RANK[required_role.to_s] || 0)
  end
end
