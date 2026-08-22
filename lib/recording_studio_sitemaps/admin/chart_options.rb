# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    module ChartOptions
      module_function

      def for_index_size(height:, max_pages:, xaxis: nil)
        {
          height: height,
          xaxis: xaxis.present? ? category_xaxis.merge(xaxis) : category_xaxis,
          yaxis: integer_page_yaxis(max_pages)
        }
      end

      def category_xaxis
        {
          type: "category",
          labels: {
            rotate: -45,
            hideOverlappingLabels: true,
            trim: false
          }
        }
      end

      def integer_page_yaxis(max_pages)
        {
          decimalsInFloat: 0,
          min: 0,
          max: max_pages,
          tickAmount: max_pages,
          stepSize: 1,
          forceNiceScale: false
        }
      end
    end

    class << self
      def index_size_chart_options(height:, logs: nil, range: nil, xaxis: nil)
        max_pages = [index_size_points(logs: logs, range: range).map { |point| point[:y] }.max || 0, 1].max
        ChartOptions.for_index_size(height: height, max_pages: max_pages, xaxis: xaxis)
      end
    end
  end
end
