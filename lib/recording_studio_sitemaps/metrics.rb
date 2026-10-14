# frozen_string_literal: true

require_relative "api/access"
require "recording_studio_metrics"

module RecordingStudioSitemaps
  # Site-wide metrics about the most recent sitemap build (GenerationLog.latest).
  module Metrics
    RESOURCE = :sitemaps
    API = :operations
    EXPOSE = { api: [API] }.freeze
    AUTHORIZE = ->(context) { RecordingStudioSitemaps::Api::Access.can_view?(context) }

    LATEST = lambda do |relation|
      relation.order(built_at: :desc, created_at: :desc, id: :desc).first
    end
    LAST_BUILD_STATUS = lambda do |relation, _context|
      log = LATEST.call(relation)
      log ? [{ key: log.status, value: 1 }] : []
    end
    LAST_BUILD_AGE = lambda do |relation, _context|
      log = LATEST.call(relation)
      log && (Time.current - log.built_at).to_i
    end
    LAST_BUILD_URL_COUNT = lambda do |relation, _context|
      LATEST.call(relation)&.url_count
    end

    STATUS_DESCRIPTION = "Result of the most recent sitemap build: one row keyed success or error. " \
                         "Empty before the first build."
    AGE_DESCRIPTION = "Seconds since the most recent sitemap build (any result). Empty before the first build."
    URL_COUNT_DESCRIPTION = "Pages listed by the most recent sitemap build (0 when it failed). " \
                            "Empty before the first build."

    module_function

    def register!
      return if RecordingStudioMetrics.for_resource(RESOURCE).any?

      RecordingStudioMetrics.register(
        RESOURCE,
        model: RecordingStudioSitemaps::GenerationLog,
        blast_radius: :site,
        api_authorize: AUTHORIZE
      ) { RecordingStudioSitemaps::Metrics.define(self) }
    end

    def define(dsl)
      dsl.custom :last_build_status, title: "Last sitemap build result", description: STATUS_DESCRIPTION,
                                     result_type: :breakdown, expose: EXPOSE, cacheable: false, &LAST_BUILD_STATUS
      dsl.custom :last_build_age, title: "Last sitemap build age", description: AGE_DESCRIPTION,
                                  result_type: :scalar, unit: "seconds", expose: EXPOSE, cacheable: false,
                 &LAST_BUILD_AGE
      dsl.custom :last_build_url_count, title: "Pages in last sitemap build", description: URL_COUNT_DESCRIPTION,
                                        result_type: :scalar, unit: "count", expose: EXPOSE, cacheable: false,
                 &LAST_BUILD_URL_COUNT
    end
  end
end
