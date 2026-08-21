# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_sitemaps/version"
require "recording_studio_sitemaps/engine"
require "recording_studio_sitemaps/configuration"

module RecordingStudioSitemaps
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
