# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WHEN_FORMAT = "%d %b %Y, %H:%M"

    EXCLUSION_REASON_KEYS = {
      "In the trash" => "admin.exclusions.in_the_trash",
      "Hidden from search" => "admin.exclusions.hidden_from_search",
      "No public URL" => "admin.exclusions.no_public_url",
      "Left out of the sitemap" => "admin.exclusions.left_out"
    }.freeze

    # rubocop:disable Metrics/ClassLength -- Admin render helpers share this singleton.
    class << self
      def index_size_points(format_x: true, logs: nil, range: nil)
        generation_logs(logs: logs, range: range).map.with_index do |log, index|
          { x: format_x ? format_when(log) : index, y: log.url_count.to_i }
        end
      end

      def index_size_series(format_x: true, logs: nil, range: nil)
        [{
          name: Copy.t("admin.chart.pages_series", default: "Pages"),
          data: index_size_points(format_x: format_x, logs: logs, range: range)
        }]
      end

      def format_when(value)
        time = value.respond_to?(:built_at) ? value.built_at : value
        time.strftime(WHEN_FORMAT)
      end

      def build_when(log)
        format_when(log)
      end

      # Admin cell values stay English like column headers (Marco accepted).
      def build_result(log)
        return "Ok" if log.success?

        log.try(:error_message).presence || "Failed"
      end

      # rubocop:disable Style/FormatStringToken -- I18n tokens use %{stamp}.
      def last_build_line
        log = GenerationLog.latest
        return Copy.t("admin.last_build.none", default: "No sitemap written yet") if log.blank?

        stamp = build_when(log)
        return Copy.t("admin.last_build.success", stamp: stamp, default: "Last built %{stamp}") if log.success?

        Copy.t("admin.last_build.failed", stamp: stamp, default: "Last build failed %{stamp}")
      end
      # rubocop:enable Style/FormatStringToken

      def build_history_screen?(context)
        params = context.respond_to?(:params) ? context.params.to_h : {}
        params.stringify_keys["key"].to_s == SCREEN_BUILD_HISTORY
      end

      def coverage_metadata
        snapshot = Coverage.snapshot
        included = snapshot.included
        published = snapshot.published
        max = [published, 1].max
        value = [included, max].min

        {
          progress_value: value,
          progress_max: max,
          progress_label: "#{included} / #{published}"
        }
      end

      # rubocop:disable Metrics/MethodLength -- coverage breakdown plus optional URL-cap warning.
      def coverage_info
        snapshot = Coverage.snapshot
        breakdown = snapshot.types.map { |type| "#{type.label} #{type.included}/#{type.published}" }
        parts = [
          breakdown.join("; ").presence ||
            Copy.t("admin.coverage.no_published_pages", default: "No published pages yet.")
        ]
        if RecordingStudioSitemaps.configuration.approaching_url_limit?(snapshot.included)
          parts << Copy.t(
            "admin.coverage.url_cap_warning",
            default: "This list is getting close to the 50,000 URL cap. A split is not available yet."
          )
        end
        parts.join(" ")
      end
      # rubocop:enable Metrics/MethodLength

      def findable_items
        entries = UrlSet.entries
        return [list_item(Copy.t("admin.findable.empty", default: "Nothing findable yet."))] if entries.empty?

        entries.map { |entry| findable_item_for(entry.recordable) }
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength -- exclusion rows plus empty/zero-type states.
      def missing_items
        rows = Exclusions.items.map do |row|
          list_item(row.title, trailing: translate_exclusion_reason(row.reason))
        end
        Coverage.snapshot.types.each do |type|
          next unless type.included.zero?

          rows << list_item(
            type.label,
            trailing: Copy.t("admin.missing.none_in_sitemap", default: "None in the sitemap")
          )
        end
        return [list_item(Copy.t("admin.missing.empty", default: "Nothing missing. Nice."))] if rows.empty?

        rows
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      def translate_exclusion_reason(reason)
        key = EXCLUSION_REASON_KEYS[reason]
        return reason unless key

        Copy.t(key, default: reason)
      end

      def generation_logs(logs: nil, range: nil)
        relation = logs || GenerationLog.order(:built_at)
        return relation if range.blank?

        if relation.respond_to?(:where)
          relation.where(built_at: range)
        else
          Array(relation).select { |log| range.cover?(log.built_at) }
        end
      end

      def findable_item_for(recordable)
        list_item(title_for(recordable), trailing: type_for(recordable))
      end

      def list_item(text, trailing: nil)
        item = { text: text }
        item[:trailing] = trailing if trailing.present?
        item
      end

      def title_for(recordable)
        recordable.try(:title).presence ||
          recordable.try(:name).presence ||
          type_for(recordable)
      end

      def type_for(recordable)
        return RecordingStudio.recordable_type_label(recordable) if defined?(RecordingStudio) && recordable

        recordable.class.model_name.human
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
