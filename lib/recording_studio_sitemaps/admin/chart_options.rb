# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    module ChartOptions
      module_function

      def for_index_size(height:, max_pages:)
        {
          height: height,
          xaxis: category_xaxis,
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
      def index_size_chart_options(height:)
        max_pages = [index_size_points.map { |point| point[:y] }.max || 0, 1].max
        ChartOptions.for_index_size(height: height, max_pages: max_pages)
      end
    end
  end
end
