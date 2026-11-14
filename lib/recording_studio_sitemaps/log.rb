# frozen_string_literal: true

module RecordingStudioSitemaps
  module Log
    module_function

    def error(message)
      return unless defined?(Rails)
      return unless Rails.respond_to?(:logger) && Rails.logger

      Rails.logger.error(message)
    end
  end
end
