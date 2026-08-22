# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WIDGET_COVERAGE = "widgets.sitemaps.coverage"
    WIDGET_FINDABLE = "widgets.sitemaps.findable"
    WIDGET_MISSING = "widgets.sitemaps.missing"
    WIDGET_INDEX_SIZE = "widgets.sitemaps.index_size"
    SCREEN_BUILD_HISTORY = "build_history"
  end
end

require_relative "admin/queries"
require_relative "admin/chart_options"
require_relative "admin/widgets"
require_relative "admin/section"
require_relative "admin/build_history"
require_relative "admin/date_range_last_30_days"

module RecordingStudioSitemaps
  module Admin
    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        install_date_range_last_30_days!
        RecordingStudioAdmin.register_section(Section)
        RecordingStudioAdmin.register_screen(BuildHistory)
        RecordingStudioAdmin.register_widget(coverage_widget)
        RecordingStudioAdmin.register_widget(findable_widget)
        RecordingStudioAdmin.register_widget(missing_widget)
        RecordingStudioAdmin.register_widget(index_size_widget)
      end

      def install_date_range_last_30_days!
        component = date_range_input_component
        return unless component
        return if component.ancestors.include?(DateRangeLast30Days)

        component.prepend(DateRangeLast30Days)
      end

      def date_range_input_component
        FlatPack::DateRangeInput::Component
      rescue NameError
        nil
      end
    end
  end
end
