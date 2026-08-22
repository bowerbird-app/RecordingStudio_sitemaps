# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WHEN_FORMAT = "%d %b %Y, %H:%M"

    class << self
      def index_size_points(format_x: true)
        GenerationLog.order(:built_at).map.with_index do |log, index|
          { x: format_x ? format_when(log) : index, y: log.url_count.to_i }
        end
      end

      def index_size_series(format_x: true)
        [{ name: "Pages", data: index_size_points(format_x: format_x) }]
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

        log.try(:error_message).presence || "Failed"
      end

      def last_build_line
        log = GenerationLog.latest
        return "No sitemap written yet." if log.blank?

        stamp = build_when(log)
        return "Last built #{stamp}." if log.success?

        "Last build failed #{stamp}."
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

      def coverage_info
        snapshot = Coverage.snapshot
        breakdown = snapshot.types.map { |type| "#{type.label} #{type.included}/#{type.published}" }
        parts = [breakdown.join("; ").presence || "No published pages yet."]
        if RecordingStudioSitemaps.configuration.approaching_url_limit?(snapshot.included)
          parts << "This list is getting close to the 50,000 URL cap. A split is not available yet."
        end
        parts.join(" ")
      end

      def findable_items
        entries = UrlSet.entries
        return [list_item("Nothing findable yet.")] if entries.empty?

        entries.map { |entry| findable_item_for(entry.recordable) }
      end

      def missing_items
        rows = Exclusions.items.map { |row| list_item(row.title, trailing: row.reason) }
        Coverage.snapshot.types.each do |type|
          next unless type.included.zero?

          rows << list_item(type.label, trailing: "None in the sitemap")
        end
        return [list_item("Nothing missing. Nice.")] if rows.empty?

        rows
      end

      private

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
  end
end
