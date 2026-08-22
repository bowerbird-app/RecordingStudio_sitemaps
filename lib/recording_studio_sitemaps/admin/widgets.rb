# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class << self
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
        @index_size_widget ||= RecordingStudioAdmin::Widget.new(
          WIDGET_INDEX_SIZE,
          blast_radius: :site,
          &INDEX_SIZE_WIDGET
        )
      end
    end

    INDEX_SIZE_WIDGET = proc do
      type :chart
      title "Index size"
      info "How many pages made the sitemap each rebuild."
      hide_metric
      hide_change
      hide_period
      chart_type :area
      chart_options { RecordingStudioSitemaps::Admin.index_size_chart_options(height: 180) }
      series { |_| RecordingStudioSitemaps::Admin.index_size_series }
      link_label "Build history"
      link_to { |context| context.admin_screen_path("build_history") }
    end
  end
end
