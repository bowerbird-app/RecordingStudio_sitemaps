# frozen_string_literal: true

RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "AdminRoot",
    "RecordingStudioPublishable::Publishable"
  ]

  config.require_recordable_declarations = true

  # Recording Studio 6.5 denies writes unless authorize_write is set.
  # The dummy keeps the previous open writes used by the test host.
  config.allow_unauthorized_writes = true

  config.app_name = "Dummy host" if config.respond_to?(:app_name=)

  config.actor = -> { Current.actor }

  config.event_notifications_enabled = true

  config.idempotency_mode = :return_existing

  config.recordable_dup_strategy = :dup
end
