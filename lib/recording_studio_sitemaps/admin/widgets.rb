# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class << self
      def coverage_widget
        @coverage_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_COVERAGE) do
          type :progress
          title ->(_context) { Copy.t("admin.widgets.coverage.title", default: "Coverage") }
          info { |_| RecordingStudioSitemaps::Admin.coverage_info }
          hide_change
          hide_period
          metadata { |_| RecordingStudioSitemaps::Admin.coverage_metadata }
        end
      end

      def findable_widget
        @findable_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_FINDABLE) do
          type :list
          title ->(_context) { Copy.t("admin.widgets.findable.title", default: "In the sitemap") }
          info ->(_context) { RecordingStudioSitemaps::Admin.findable_info }
          list_options({ divider: true })
          items { |_| RecordingStudioSitemaps::Admin.findable_items }
        end
      end

      def missing_widget
        @missing_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_MISSING) do
          type :list
          title ->(_context) { Copy.t("admin.widgets.missing.title", default: "Missing") }
          info ->(_context) { RecordingStudioSitemaps::Admin.missing_info }
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

      def findable_info
        Copy.t(
          "admin.widgets.findable.info",
          default: "Pages search engines can pick up from this sitemap."
        )
      end

      def missing_info
        Copy.t(
          "admin.widgets.missing.info",
          default: "Published pages that did not make the sitemap, and why."
        )
      end

      def index_size_info
        Copy.t(
          "admin.widgets.index_size.info",
          default: "How many pages made the sitemap each rebuild."
        )
      end

      def index_size_link_label
        Copy.t("admin.widgets.index_size.link_label", default: "Build history")
      end
    end

    INDEX_SIZE_WIDGET = proc do
      type :chart
      title ->(_context) { Copy.t("admin.widgets.index_size.title", default: "Index size") }
      info { |_| RecordingStudioSitemaps::Admin.index_size_info }
      hide_metric
      hide_change
      hide_period
      chart_type :area
      chart_options do |context|
        range = context.widget_time_range(default_preset_key: :last_30_days)
        RecordingStudioSitemaps::Admin.index_size_chart_options(
          height: 160,
          range: range,
          xaxis: { labels: { show: false } }
        )
      end
      series do |context|
        range = context.widget_time_range(default_preset_key: :last_30_days)
        RecordingStudioSitemaps::Admin.index_size_series(format_x: false, range: range)
      end
      link_label { |_| RecordingStudioSitemaps::Admin.index_size_link_label }
      link_to { |context| context.admin_screen_path("build_history") }
    end
  end
end
