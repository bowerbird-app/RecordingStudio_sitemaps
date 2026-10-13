# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class BuildHistory < RecordingStudioAdmin::Screen
      key SCREEN_BUILD_HISTORY
      title ->(_context) { Copy.t("admin.screen.title", default: "Build history") }
      # Plain string: Admin indexes screen.subtitle without evaluate in
      # available_admin_items_resolver#link_item_search_text (needs Marco to fix).
      subtitle "Every rebuild, and whether the list grew or shrank."
      icon :clock
      blast_radius :site

      query { |_context| GenerationLog.order(:built_at) }
      filter :date_range, field: :built_at, default: :last_30_days

      summary do
        hide_metric
        hide_change
        hide_period
      end

      chart do
        title ->(_context) { Copy.t("admin.screen.chart_title", default: "Pages in the sitemap") }
        type :area
        options do |context|
          RecordingStudioSitemaps::Admin.index_size_chart_options(
            height: 320,
            logs: context.query_result.relation
          )
        end
        series do |context|
          RecordingStudioSitemaps::Admin.index_size_series_for_render(
            logs: context.query_result.relation
          )
        end
      end

      table do
        # Table title is read raw (no evaluate) by Admin's screen resolver.
        title "Each rebuild"
        hide_columns_button
        # Column headers stay English (Marco accepted).
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
