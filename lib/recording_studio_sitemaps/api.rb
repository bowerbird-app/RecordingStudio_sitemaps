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

        operations = false
        RecordingStudioApi.configuration.each_api do |api|
          operations = true if api.name.to_s == API.to_s
        end
        return unless operations
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
        RecordingStudioApi.registered_endpoint(NAME, api: API)
      end
    end
  end
end
