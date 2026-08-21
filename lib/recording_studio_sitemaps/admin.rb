# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WIDGET_COVERAGE = "widgets.sitemaps.coverage"
    WIDGET_FINDABLE = "widgets.sitemaps.findable"
    WIDGET_MISSING = "widgets.sitemaps.missing"

    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_section(Section)
        RecordingStudioAdmin.register_widget(coverage_widget)
        RecordingStudioAdmin.register_widget(findable_widget)
        RecordingStudioAdmin.register_widget(missing_widget)
      end

      def coverage_widget
        @coverage_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_COVERAGE) do
          type :progress
          title "Coverage"
          info { |_| RecordingStudioSitemaps::Admin.coverage_info }
          hide_change
          hide_period
          metadata { |_| RecordingStudioSitemaps::Admin.coverage_metadata }
        end
      end

      def findable_widget
        @findable_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_FINDABLE) do
          type :list
          title "In the sitemap"
          info "Pages search engines can pick up from this sitemap."
          list_options({ divider: true })
          items { |_| RecordingStudioSitemaps::Admin.findable_items }
        end
      end

      def missing_widget
        @missing_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_MISSING) do
          type :list
          title "Missing"
          info "Published pages that did not make the sitemap, and why."
          list_options({ divider: true })
          items { |_| RecordingStudioSitemaps::Admin.missing_items }
        end
      end

      def last_build_line
        log = GenerationLog.latest
        return "No sitemap written yet." if log.blank?

        stamp = log.built_at.strftime("%d %b %Y, %H:%M")
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

    class Section < RecordingStudioAdmin::Section
      key "sitemaps"
      title "Sitemaps"
      subtitle "The public list of pages search engines may find."
      icon :map
      blast_radius :site

      link :open_sitemap,
           text: "Open sitemap",
           url: ->(_context) { "/sitemap.xml" },
           style: :secondary

      link :rebuild,
           text: "Rebuild",
           url: ->(_context) { "/recording_studio_sitemaps/rebuild" },
           style: :primary

      link :last_build,
           text: ->(_context) { RecordingStudioSitemaps::Admin.last_build_line },
           url: ->(_context) { "#" },
           style: :ghost

      widget WIDGET_COVERAGE
      widget WIDGET_FINDABLE
      widget WIDGET_MISSING
    end
  end
end
