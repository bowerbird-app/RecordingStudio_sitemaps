# frozen_string_literal: true

module AdminAccessHelpers
  def grant_admin_access_for_test!(recording:, actor:, role: :admin)
    result = RecordingStudioAccessible.bootstrap_owner_access!(
      recording:,
      actor:,
      idempotency_key: "dummy-bootstrap-#{actor.model_name.singular}-#{actor.id}-#{recording.id}"
    )
    return recording if result.success?

    previous_authorizer = RecordingStudioAccessible.configuration.access_management_authorizer
    RecordingStudioAccessible.configuration.access_management_authorizer = ->(*) { true }
    begin
      RecordingStudioAccessible.grant_access(
        recording:,
        actor:,
        role:,
        manager_actor: actor,
        idempotency_key: "dummy-grant-#{actor.model_name.singular}-#{actor.id}-#{recording.id}-#{role}"
      )
    ensure
      RecordingStudioAccessible.configuration.access_management_authorizer = previous_authorizer
    end

    recording
  end
end
