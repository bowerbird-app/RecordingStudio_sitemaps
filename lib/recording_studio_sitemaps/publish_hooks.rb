# frozen_string_literal: true

module RecordingStudioSitemaps
  class PublishHooks
    PUBLISHABLE_TYPE = "RecordingStudioPublishable::Publishable"

    class << self
      def install!
        return if @installed
        return unless defined?(RecordingStudio)

        RecordingStudio.configuration.hooks.after_record do |event|
          handle(event)
        end
        @installed = true
      end

      def handle(event)
        return unless publishable_event?(event)

        RecordingStudioSitemaps.rebuild!(source: :publish)
      end

      def publishable_event?(event)
        event.respond_to?(:recordable_type) && event.recordable_type == PUBLISHABLE_TYPE
      end
    end
  end
end
