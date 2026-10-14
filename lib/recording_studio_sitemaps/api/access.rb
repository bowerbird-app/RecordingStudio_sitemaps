# frozen_string_literal: true

module RecordingStudioSitemaps
  module Api
    # Same check as the Build history admin screen: AdminRoot :view. Fails closed.
    module Access
      module_function

      ResolverContext = Struct.new(:controller)

      def admin_root_recording
        return unless defined?(RecordingStudioAdmin)

        config = RecordingStudioAdmin.configuration
        resolver = config.site_admin_recording_resolver || config.access_recording_resolver
        return unless resolver

        begin
          resolver.call(ResolverContext.new(nil))
        rescue StandardError
          nil
        end
      end

      def can_view?(context)
        actor = context&.access_grant&.actor
        recording = admin_root_recording
        return false if actor.blank? || recording.blank?
        return false unless defined?(RecordingStudioAccessible)

        RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)
      end
    end
  end
end
