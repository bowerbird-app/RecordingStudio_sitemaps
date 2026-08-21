# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WIDGET_LAST_BUILD = "widgets.sitemaps.last_build"
    WIDGET_INDEXABLE_COUNT = "widgets.sitemaps.indexable_count"
    WIDGET_EXCLUDED = "widgets.sitemaps.excluded"

    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_section(Section)
        RecordingStudioAdmin.register_widget(last_build_widget)
        RecordingStudioAdmin.register_widget(indexable_count_widget)
        RecordingStudioAdmin.register_widget(excluded_widget)
      end

      def last_build_widget
        @last_build_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_LAST_BUILD) do
          type :number
          title "Last build"
          info "When this sitemap was last written, and whether that write stuck."
          hide_change
          hide_period
          value { |_| RecordingStudioSitemaps::Admin.last_build_value }
          subtitle { |_| RecordingStudioSitemaps::Admin.last_build_status }
        end
      end

      def indexable_count_widget
        @indexable_count_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_INDEXABLE_COUNT) do
          type :number
          title "Findable pages"
          info { |_| RecordingStudioSitemaps::Admin.indexable_count_info }
          hide_change
          hide_period
          value { |_| RecordingStudioSitemaps::UrlSet.entries.size }
        end
      end

      def excluded_widget
        @excluded_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_EXCLUDED) do
          type :list
          title "Live but left out"
          info "Published pages that did not make the sitemap, and why."
          items { |_| RecordingStudioSitemaps::Admin.excluded_items }
        end
      end

      def last_build_value
        log = GenerationLog.latest
        return "Not yet" if log.blank?

        log.built_at.strftime("%d %b %Y, %H:%M")
      end

      def last_build_status
        log = GenerationLog.latest
        return "No sitemap written yet." if log.blank?
        return "Built" if log.success?

        "Failed"
      end

      def indexable_count_info
        count = UrlSet.entries.size
        if RecordingStudioSitemaps.configuration.approaching_url_limit?(count)
          "This list is getting close to the 50,000 URL cap. A split is not available yet."
        else
          "Published pages that can show up in search."
        end
      end

      def excluded_items
        rows = Exclusions.items
        return [{ text: "Nothing left out. Nice." }] if rows.empty?

        rows.map { |row| { text: row.title, trailing: row.reason } }
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

      widget WIDGET_LAST_BUILD
      widget WIDGET_INDEXABLE_COUNT
      widget WIDGET_EXCLUDED
    end
  end
end
