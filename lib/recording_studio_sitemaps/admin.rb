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

module RecordingStudioSitemaps
  module Admin
    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_section(Section)
        RecordingStudioAdmin.register_screen(BuildHistory)
        RecordingStudioAdmin.register_widget(coverage_widget)
        RecordingStudioAdmin.register_widget(findable_widget)
        RecordingStudioAdmin.register_widget(missing_widget)
        RecordingStudioAdmin.register_widget(index_size_widget)
      end
    end
  end
end
