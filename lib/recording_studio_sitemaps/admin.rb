# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WIDGET_COVERAGE = "widgets.sitemaps.coverage"
    WIDGET_FINDABLE = "widgets.sitemaps.findable"
    WIDGET_MISSING = "widgets.sitemaps.missing"
    WIDGET_INDEX_SIZE = "widgets.sitemaps.index_size"
    SCREEN_BUILD_HISTORY = "build_history"

    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_section(Section)
        RecordingStudioAdmin.register_screen(BuildHistory)
        RecordingStudioAdmin.register_widget(coverage_widget)
        RecordingStudioAdmin.register_widget(findable_widget)
        RecordingStudioAdmin.register_widget(missing_widget)
        RecordingStudioAdmin.register_widget(index_size_widget)
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

      def index_size_widget
        @index_size_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_INDEX_SIZE, blast_radius: :site) do
          type :chart
          title "Index size"
          info "How many pages made the sitemap each rebuild."
          hide_metric
          hide_change
          hide_period
          chart_type :area
          chart_options { { height: 180 } }
          series { |_| RecordingStudioSitemaps::Admin.index_size_series }
          link_to { |context| context.admin_screen_path(SCREEN_BUILD_HISTORY) }
        end
      end

      def index_size_series
        [
          {
            name: "Pages",
            data: GenerationLog.order(:built_at).map { |log| { x: log.built_at, y: log.url_count } }
          }
        ]
      end

      def build_when(log)
        log.built_at.strftime("%d %b %Y, %H:%M")
      end

      def build_result(log)
        log.success? ? "Worked" : "Failed"
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

      link :build_history,
           text: "Build history",
           url: ->(context) { context.admin_screen_path(SCREEN_BUILD_HISTORY) },
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
      widget WIDGET_INDEX_SIZE, view_variant: :compact
    end

    class BuildHistory < RecordingStudioAdmin::Screen
      key SCREEN_BUILD_HISTORY
      title "Build history"
      subtitle "Every rebuild, and whether the list grew or shrank."
      icon :clock
      blast_radius :site

      query { |_context| GenerationLog.order(:built_at) }

      summary do
        hide_metric
        hide_change
        hide_period
      end

      chart do
        title "Pages in the sitemap"
        type :area
        options { { height: 320 } }
        series { |_context| RecordingStudioSitemaps::Admin.index_size_series }
      end

      table do
        title "Each rebuild"
        hide_columns_button
        column :built_at,
               title: "When",
               value: ->(row, _context) { RecordingStudioSitemaps::Admin.build_when(row) }
        column :url_count, title: "Pages"
        column :status,
               title: "Result",
               tooltip: ->(row, _context) { row.error_message },
               value: ->(row, _context) { RecordingStudioSitemaps::Admin.build_result(row) }
        default_sort :built_at, direction: :desc
        paginate per_page: 25, mode: :infinite
      end
    end
  end
end
