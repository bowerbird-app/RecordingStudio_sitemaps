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
        return unless available?
        return if already_registered?
        return unless operations_api_present?

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

      def available?
        defined?(RecordingStudioApi) &&
          RecordingStudioApi.respond_to?(:register_endpoint) &&
          RecordingStudioApi.respond_to?(:registered_endpoint)
      end

      def already_registered?
        return false unless available?
        return false unless operations_api_present?

        RecordingStudioApi.registered_endpoint(NAME, api: API)
      end

      def operations_api_present?
        configuration = RecordingStudioApi.configuration if RecordingStudioApi.respond_to?(:configuration)
        return true unless configuration.respond_to?(:api_names)

        Array(configuration.api_names).include?("operations")
      end
    end
  end
end
