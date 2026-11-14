# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_admin"
require "recording_studio_publishable"
require "flat_pack"
require "recording_studio_sitemaps/version"
require "recording_studio_sitemaps/copy"
require "recording_studio_sitemaps/engine"
require "recording_studio_sitemaps/configuration"
require "recording_studio_sitemaps/absolute_url"
require "recording_studio_sitemaps/entry"
require "recording_studio_sitemaps/registry"
require "recording_studio_sitemaps/batch_sink"
require "recording_studio_sitemaps/source_failure"
require "recording_studio_sitemaps/log"
require "recording_studio_sitemaps/builtin_checks"
require "recording_studio_sitemaps/source_runner"
require "recording_studio_sitemaps/sources/publishable"
require "recording_studio_sitemaps/collection"
require "recording_studio_sitemaps/xml_builder"
require "recording_studio_sitemaps/exclusions"
require "recording_studio_sitemaps/coverage"
require "recording_studio_sitemaps/publish_hooks"
require "recording_studio_sitemaps/services/generate"
require "recording_studio_sitemaps/admin"
require "recording_studio_sitemaps/metrics"
require "recording_studio_sitemaps/api"

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

    def sources
      @sources ||= Registry.new
    end

    def filters
      @filters ||= Registry.new
    end

    def register_source(name, &)
      sources.register(name, &)
    end

    def unregister_source(name)
      sources.unregister(name)
    end

    def register_filter(name, &)
      filters.register(name, &)
    end

    def unregister_filter(name)
      filters.unregister(name)
    end

    def register_default_source!
      register_source(Sources::Publishable::NAME) do |batch|
        Sources::Publishable.new(batch).call
      end
    end
  end

  register_default_source!
end
