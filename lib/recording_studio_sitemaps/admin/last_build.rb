# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    module LastBuild
      STATUS = "sitemaps.last_build_status"
      AGE = "sitemaps.last_build_age"
      URL_COUNT = "sitemaps.last_build_url_count"

      module_function

      def items(context = nil)
        snapshot = snapshot(context)
        return [row("No sitemap written yet.")] if empty?(snapshot)

        [
          row("Result", trailing: status_label(snapshot[:status])),
          row("Age", trailing: format_age(snapshot[:age])),
          row("Pages", trailing: snapshot[:url_count].to_i.to_s)
        ]
      end

      def snapshot(context)
        {
          status: status_key(metric(STATUS, context)),
          age: metric(AGE, context)&.value,
          url_count: metric(URL_COUNT, context)&.value
        }
      end

      def empty?(snapshot)
        snapshot[:status].blank? && snapshot[:age].nil? && snapshot[:url_count].nil?
      end

      def metric(identifier, context)
        RecordingStudioMetrics::Admin.execute(
          identifier,
          admin_context: context || system_context,
          scope: :site,
          site_authorized: true,
          cache: false
        )
      end

      def system_context
        RecordingStudioMetrics::Context.new(scope: :site, system: true, site_authorized: true, timezone: "UTC")
      end

      def status_key(result)
        row = Array(result&.data).first
        return unless row

        (row[:key] || row["key"]).presence
      end

      def status_label(status)
        return "Ok" if status.to_s == "success"
        return "Failed" if status.to_s == "error"

        status.to_s.presence || "Failed"
      end

      def format_age(seconds)
        return "—" if seconds.nil?

        ActiveSupport::Duration.build(seconds.to_i).inspect
      end

      def row(text, trailing: nil)
        item = { text: text }
        item[:trailing] = trailing if trailing.present?
        item
      end
    end
  end
end
