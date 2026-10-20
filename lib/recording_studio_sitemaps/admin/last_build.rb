# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    module LastBuild
      AGE = "sitemaps.last_build_age"
      EMPTY = "No sitemap written yet"

      module_function

      def value(context = nil)
        seconds = metric(context)&.value
        return EMPTY if seconds.nil?

        "#{ActiveSupport::Duration.build(seconds.to_i).inspect} ago"
      end

      def metric(context)
        RecordingStudioMetrics::Admin.execute(
          AGE,
          admin_context: context || system_context,
          scope: :site,
          site_authorized: true,
          cache: false
        )
      end

      def system_context
        RecordingStudioMetrics::Context.new(scope: :site, system: true, site_authorized: true, timezone: "UTC")
      end
    end
  end
end
