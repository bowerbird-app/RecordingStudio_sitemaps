# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WHEN_FORMAT = "%d %b %Y, %H:%M"

    class << self
      def index_size_points(format_x: true, logs: nil, range: nil)
        generation_logs(logs: logs, range: range).map.with_index do |log, index|
          { x: format_x ? format_when(log) : index, y: log.url_count.to_i }
        end
      end

      def index_size_series(format_x: true, logs: nil, range: nil)
        [{ name: "Pages", data: index_size_points(format_x: format_x, logs: logs, range: range) }]
      end

      def format_when(value)
        time = value.respond_to?(:built_at) ? value.built_at : value
        time.strftime(WHEN_FORMAT)
      end

      def build_when(log)
        format_when(log)
      end

      def build_result(log)
        return "Ok" if log.success?

        "Failed"
      end

      def last_build_value(context = nil)
        LastBuild.value(context)
      end

      def last_build_line
        log = GenerationLog.latest
        return "No sitemap written yet" if log.blank?

        stamp = build_when(log)
        return "Last built #{stamp}" if log.success?

        "Last build failed #{stamp}"
      end

      def build_history_screen?(context)
        params = context.respond_to?(:params) ? context.params.to_h : {}
        params.stringify_keys["key"].to_s == SCREEN_BUILD_HISTORY
      end

      def coverage_metadata
        snapshot = Coverage.snapshot
        included = snapshot.included
        offered = snapshot.offered
        max = [offered, 1].max
        value = [included, max].min

        {
          progress_value: value,
          progress_max: max,
          progress_label: "#{included} / #{offered}"
        }
      end

      def coverage_info
        snapshot = Coverage.snapshot
        breakdown = snapshot.types.map { |type| "#{type.label} #{type.included}/#{type.offered}" }
        parts = [breakdown.join("; ").presence || "No pages offered yet."]
        if RecordingStudioSitemaps.configuration.approaching_url_limit?(snapshot.included)
          parts << "This list is getting close to the 50,000 URL cap. A split is not available yet."
        end
        parts.join(" ")
      end

      def findable_items
        entries = Collection.accepted
        return [list_item("Nothing findable yet.")] if entries.empty?

        entries.map { |entry| findable_item_for(entry) }
      end

      def missing_items
        rows = exclusion_rows + empty_type_rows
        return [list_item("Nothing missing. Nice.")] if rows.empty?

        rows
      end

      private

      def generation_logs(logs: nil, range: nil)
        relation = logs || GenerationLog.order(:built_at)
        return relation if range.blank?

        if relation.respond_to?(:where)
          relation.where(built_at: range)
        else
          Array(relation).select { |log| range.cover?(log.built_at) }
        end
      end

      def exclusion_rows
        Exclusions.items.map { |row| list_item(row.title, trailing: row.detail) }
      end

      def empty_type_rows
        Coverage.snapshot.types.filter_map do |type|
          next unless type.included.zero? && type.offered.positive?

          list_item(type.label, trailing: "None in the sitemap")
        end
      end

      def findable_item_for(entry)
        list_item(entry.title.presence || entry.loc, trailing: entry.type)
      end

      def list_item(text, trailing: nil)
        item = { text: text }
        item[:trailing] = trailing if trailing.present?
        item
      end
    end
  end
end
