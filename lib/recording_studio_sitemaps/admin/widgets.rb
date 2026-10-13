# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class << self
      def coverage_widget
        @coverage_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_COVERAGE) do
          type :progress
          title ->(_context) { Copy.t("admin.widgets.coverage.title") }
          # coverage_info is a public helper and stays English.
          info { |_| RecordingStudioSitemaps::Admin.coverage_info }
          hide_change
          hide_period
          metadata { |_| RecordingStudioSitemaps::Admin.coverage_metadata }
        end
      end

      def findable_widget
        @findable_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_FINDABLE) do
          type :list
          title ->(_context) { Copy.t("admin.widgets.findable.title") }
          info ->(_context) { RecordingStudioSitemaps::Admin.findable_widget_info }
          list_options({ divider: true })
          items { |_| RecordingStudioSitemaps::Admin.findable_items }
        end
      end

      def missing_widget
        @missing_widget ||= RecordingStudioAdmin::Widget.new(WIDGET_MISSING) do
          type :list
          title ->(_context) { Copy.t("admin.widgets.missing.title") }
          info ->(_context) { RecordingStudioSitemaps::Admin.missing_widget_info }
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

      # Widget call-site copy (not public data helpers).
      def findable_widget_info
        Copy.t("admin.widgets.findable.info")
      end

      def missing_widget_info
        Copy.t("admin.widgets.missing.info")
      end

      def index_size_widget_info
        Copy.t("admin.widgets.index_size.info")
      end

      def index_size_link_label
        Copy.t("admin.widgets.index_size.link_label")
      end

      def index_size_series_for_render(**)
        index_size_series(**).map do |entry|
          entry.merge(name: Copy.t("admin.chart.pages_series"))
        end
      end
    end

    INDEX_SIZE_WIDGET = proc do
      type :chart
      title ->(_context) { Copy.t("admin.widgets.index_size.title") }
      info { |_| RecordingStudioSitemaps::Admin.index_size_widget_info }
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
        RecordingStudioSitemaps::Admin.index_size_series_for_render(format_x: false, range: range)
      end
      link_label { |_| RecordingStudioSitemaps::Admin.index_size_link_label }
      link_to { |context| context.admin_screen_path("build_history") }
    end
  end
end
