# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    # Admin's date_range default is :last_30_days. Flatpack DateRangeInput only
    # paints a preset name when the selected dates match one of its quick
    # presets, so last_30_days otherwise renders as a raw from–to string.
    module DateRangeLast30Days
      PRESET_KEY = "last_30_days"

      private

      def quick_range_presets
        [{ key: PRESET_KEY, label: last_30_days_label }] + super
      end

      def preset_range_for(key)
        return last_30_days_range if key.to_s == PRESET_KEY

        super
      end

      def last_30_days_label
        last_30_days_period.label
      end

      def last_30_days_range
        period = last_30_days_period
        { start: period.start_date.iso8601, end: period.end_date.iso8601 }
      end

      def last_30_days_period
        RecordingStudioAdmin::Period.from_preset_key(:last_30_days)
      end
    end
  end
end
