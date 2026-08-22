# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
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
        options { RecordingStudioSitemaps::Admin.index_size_chart_options(height: 320) }
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
