# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    module ChartOptions
      module_function

      def for_index_size(height:, xaxis: nil)
        {
          height: height,
          xaxis: xaxis.present? ? category_xaxis.merge(xaxis) : category_xaxis
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
    end

    class << self
      def index_size_chart_options(height:, xaxis: nil)
        ChartOptions.for_index_size(height: height, xaxis: xaxis)
      end
    end
  end
end
