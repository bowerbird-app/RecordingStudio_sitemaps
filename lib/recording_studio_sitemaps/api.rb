# frozen_string_literal: true

require_relative "api/access"
require_relative "api/rebuild"

module RecordingStudioSitemaps
  # Registers one operations POST when Recording Studio API is loaded.
  # MCP advertises registered endpoints automatically. This gem adds no MCP tools.
  module Api
    NAME = "sitemaps.rebuild"
    PATH = "sitemaps/rebuild"
    API = :operations

    OPENAPI = {
      title: "Sitemap - Rebuild",
      summary: "Rebuild the public sitemap",
      description: "Writes a new sitemap generation log. Same action as Admin Rebuild. " \
                   "Needs view on Admin.",
      tags: ["Sitemaps"]
    }.freeze

    class << self
      def register!
        return unless defined?(::RecordingStudioApi)
        return unless RecordingStudioApi.configuration.api_names.include?(API.to_s)
        return if already_registered?

        register_rebuild_endpoint!
        true
      end

      def register_rebuild_endpoint!
        RecordingStudioApi.register_endpoint(
          NAME,
          api: API,
          http_verb: :post,
          path: PATH,
          handler: Rebuild,
          openapi: OPENAPI
        )
      end

      def already_registered?
        existing = RecordingStudioApi.registered_endpoint(NAME, api: API)
        return false unless existing
        return true if existing.handler == Rebuild

        raise RecordingStudioApi::ConfigurationError, "API endpoint #{NAME} is already registered"
      end
    end
  end
end
