# frozen_string_literal: true

module RecordingStudioSitemaps
  module Api
    class Rebuild
      def self.call(context)
        new(context).call
      end

      def initialize(context)
        @context = context
      end

      def call
        deny_foreign_root!
        deny_without_view!

        log = RecordingStudioSitemaps.rebuild!(source: :api)
        {
          id: log.id,
          status: log.status,
          url_count: log.url_count,
          built_at: log.built_at,
          source: log.source
        }
      end

      private

      attr_reader :context

      def deny_foreign_root!
        admin_root = Access.admin_root_recording
        root = context.root_recording
        return if admin_root.present? && root.present? && admin_root.id == root.id

        raise RecordingStudioApi::NotFoundError, "Root was not found"
      end

      def deny_without_view!
        return if Access.can_view?(context)

        raise RecordingStudioApi::AuthorizationError,
              "API access grant is not authorized for this capability"
      end
    end
  end
end
