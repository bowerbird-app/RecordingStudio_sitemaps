# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_admin"
require "recording_studio_publishable"
require "flat_pack"
require "recording_studio_sitemaps/version"
require "recording_studio_sitemaps/engine"
require "recording_studio_sitemaps/configuration"
require "recording_studio_sitemaps/absolute_url"
require "recording_studio_sitemaps/xml_builder"
require "recording_studio_sitemaps/url_set"
require "recording_studio_sitemaps/exclusions"
require "recording_studio_sitemaps/publish_hooks"
require "recording_studio_sitemaps/services/generate"
require "recording_studio_sitemaps/admin"

module RecordingStudioSitemaps
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def rebuild!(source: :system)
      Services::Generate.call(source: source)
    end
  end
end
