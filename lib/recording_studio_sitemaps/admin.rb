# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    WIDGET_COVERAGE = "widgets.sitemaps.coverage"
    WIDGET_FINDABLE = "widgets.sitemaps.findable"
    WIDGET_MISSING = "widgets.sitemaps.missing"
    WIDGET_INDEX_SIZE = "widgets.sitemaps.index_size"
    WIDGET_LAST_BUILD = "widgets.sitemaps.last_build"
    SCREEN_BUILD_HISTORY = "build_history"

    def self.date_range_presets
      [:last_30_days, *FlatPack::DateRangeInput::Component::DEFAULT_PRESET_KEYS]
    end

    def self.date_range_input_values(filter)
      value = filter.value
      if value&.preset_key.to_s == "last_30_days"
        today = Date.current
        return [today - 29, today]
      end

      [value&.start_date, value&.end_date]
    end
  end
end

require_relative "admin/queries"
require_relative "admin/last_build"
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
        RecordingStudioAdmin.register_widget(last_build_widget)
      end
    end
  end
end
