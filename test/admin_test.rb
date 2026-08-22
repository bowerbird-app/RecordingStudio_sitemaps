# frozen_string_literal: true

require "test_helper"

class AdminTest < Minitest::Test
  FakeLog = Struct.new(:built_at, :status, :url_count, :error_message, keyword_init: true) do
    def success?
      status == "success"
    end
  end

  FakeContext = Struct.new(:path, :params, keyword_init: true) do
    def admin_screen_path(key)
      "/admin/screens/#{key}"
    end

    def widget_time_range(default_preset_key: nil, **)
      return unless default_preset_key

      period = RecordingStudioAdmin::Period.from_preset_key(default_preset_key)
      period.start_date.beginning_of_day..period.end_date.end_of_day
    end
  end

  FakePage = Struct.new(:title, :name, keyword_init: true)

  class DateRangeInputStandIn
    prepend RecordingStudioSitemaps::Admin::DateRangeLast30Days

    def presets
      quick_range_presets
    end

    def range_for(key)
      preset_range_for(key)
    end

    private

    def quick_range_presets
      [{ key: "this_week", label: "This week" }]
    end

    def preset_range_for(_key)
      { start: nil, end: nil }
    end
  end

  def page_snapshot(included: 1, published: 2)
    RecordingStudioSitemaps::Coverage::Snapshot.new(
      included: included,
      published: published,
      types: [
        RecordingStudioSitemaps::Coverage::TypeCount.new(
          label: "Page",
          included: included,
          published: published
        )
      ]
    )
  end

  def test_last_build_line_without_log
    RecordingStudioSitemaps::GenerationLog.stub(:latest, nil) do
      assert_equal "No sitemap written yet", RecordingStudioSitemaps::Admin.last_build_line
    end
  end

  def test_last_build_line_with_success_and_failure
    built_at = Time.utc(2026, 8, 21, 15, 30, 0)

    RecordingStudioSitemaps::GenerationLog.stub(:latest, FakeLog.new(built_at: built_at, status: "success")) do
      assert_equal "Last built 21 Aug 2026, 15:30", RecordingStudioSitemaps::Admin.last_build_line
    end

    RecordingStudioSitemaps::GenerationLog.stub(:latest, FakeLog.new(built_at: built_at, status: "error")) do
      assert_equal "Last build failed 21 Aug 2026, 15:30", RecordingStudioSitemaps::Admin.last_build_line
    end
  end

  def test_coverage_metadata_uses_progress_keys
    RecordingStudioSitemaps::Coverage.stub(:snapshot, page_snapshot) do
      metadata = RecordingStudioSitemaps::Admin.coverage_metadata

      assert_equal 1, metadata[:progress_value]
      assert_equal 2, metadata[:progress_max]
      assert_equal "1 / 2", metadata[:progress_label]
    end
  end

  def test_coverage_info_lists_types_and_warns_near_limit
    RecordingStudioSitemaps::Coverage.stub(:snapshot, page_snapshot) do
      assert_equal "Page 1/2", RecordingStudioSitemaps::Admin.coverage_info
    end

    RecordingStudioSitemaps::Coverage.stub(:snapshot, page_snapshot(included: 45_000, published: 45_000)) do
      info = RecordingStudioSitemaps::Admin.coverage_info

      assert_includes info, "Page 45000/45000"
      assert_includes info, "50,000"
    end
  end

  def test_findable_items_use_title_and_type
    RecordingStudioSitemaps::UrlSet.stub(:entries, []) do
      assert_equal [{ text: "Nothing findable yet." }], RecordingStudioSitemaps::Admin.findable_items
    end

    page = FakePage.new(title: "Getting Started")
    entry = RecordingStudioSitemaps::UrlSet::Entry.new(loc: "https://site.test/a", lastmod: nil, recordable: page)

    RecordingStudioSitemaps::UrlSet.stub(:entries, [entry]) do
      RecordingStudio.stub(:recordable_type_label, "Page") do
        assert_equal(
          [{ text: "Getting Started", trailing: "Page" }],
          RecordingStudioSitemaps::Admin.findable_items
        )
      end
    end
  end

  def test_missing_items_use_page_title_and_reason
    RecordingStudioSitemaps::Coverage.stub(:snapshot, page_snapshot) do
      RecordingStudioSitemaps::Exclusions.stub(:items, []) do
        assert_equal [{ text: "Nothing missing. Nice." }], RecordingStudioSitemaps::Admin.missing_items
      end

      row = RecordingStudioSitemaps::Exclusions::Reason.new(title: "Staff-only notes", reason: "Hidden from search")
      RecordingStudioSitemaps::Exclusions.stub(:items, [row]) do
        assert_equal(
          [{ text: "Staff-only notes", trailing: "Hidden from search" }],
          RecordingStudioSitemaps::Admin.missing_items
        )
      end
    end
  end

  def test_missing_items_include_types_with_zero_in_the_sitemap
    snapshot = RecordingStudioSitemaps::Coverage::Snapshot.new(
      included: 0,
      published: 1,
      types: [
        RecordingStudioSitemaps::Coverage::TypeCount.new(label: "Support page", included: 0, published: 1)
      ]
    )

    RecordingStudioSitemaps::Coverage.stub(:snapshot, snapshot) do
      RecordingStudioSitemaps::Exclusions.stub(:items, []) do
        assert_equal(
          [{ text: "Support page", trailing: "None in the sitemap" }],
          RecordingStudioSitemaps::Admin.missing_items
        )
      end
    end
  end

  def test_index_size_series_uses_generation_log_counts
    logs = [
      FakeLog.new(built_at: Time.utc(2026, 8, 1, 12), url_count: 1, status: "success"),
      FakeLog.new(built_at: Time.utc(2026, 8, 2, 12), url_count: 2, status: "success"),
      FakeLog.new(built_at: Time.utc(2026, 8, 3, 12), url_count: 1, status: "success")
    ]

    RecordingStudioSitemaps::GenerationLog.stub(:order, logs) do
      series = RecordingStudioSitemaps::Admin.index_size_series
      options = RecordingStudioSitemaps::Admin.index_size_chart_options(height: 320)

      assert_equal "Pages", series.first[:name]
      assert_equal(
        [
          { x: "01 Aug 2026, 12:00", y: 1 },
          { x: "02 Aug 2026, 12:00", y: 2 },
          { x: "03 Aug 2026, 12:00", y: 1 }
        ],
        series.first[:data]
      )
      refute(series.first[:data].any? { |point| point[:x].to_s.include?("T") })
      assert_equal 0, options.dig(:yaxis, :decimalsInFloat)
      assert_equal 0, options.dig(:yaxis, :min)
      assert_equal 2, options.dig(:yaxis, :max)
      assert_equal 2, options.dig(:yaxis, :tickAmount)
      assert_equal 1, options.dig(:yaxis, :stepSize)
      assert_equal false, options.dig(:yaxis, :forceNiceScale)
      assert_equal "category", options.dig(:xaxis, :type)
    end
  end

  def test_index_size_series_honors_time_range
    logs = [
      FakeLog.new(built_at: Time.utc(2026, 6, 1, 12), url_count: 9, status: "success"),
      FakeLog.new(built_at: Time.utc(2026, 8, 20, 12), url_count: 2, status: "success")
    ]
    range = Time.utc(2026, 8, 1)..Time.utc(2026, 8, 31)

    RecordingStudioSitemaps::GenerationLog.stub(:order, logs) do
      series = RecordingStudioSitemaps::Admin.index_size_series(range: range)

      assert_equal [{ x: "20 Aug 2026, 12:00", y: 2 }], series.first[:data]
    end
  end

  def test_index_size_widget_is_a_chart_linked_to_history
    logs = [FakeLog.new(built_at: Time.utc(2026, 8, 1, 12), url_count: 1, status: "success")]
    widget = nil

    RecordingStudioSitemaps::GenerationLog.stub(:order, logs) do
      widget = RecordingStudioSitemaps::Admin.index_size_widget.resolve(FakeContext.new)
    end

    assert_equal :chart, widget.type
    assert_equal :area, widget.chart_type
    assert_equal "Index size", widget.title
    assert_equal RecordingStudioSitemaps::Admin::WIDGET_INDEX_SIZE, widget.key
    assert_equal "Build history", widget.link_label
    assert_equal "/admin/screens/build_history", widget.link_to
    assert_equal 0, widget.chart_options.dig(:yaxis, :decimalsInFloat)
    assert_equal 1, widget.chart_options.dig(:yaxis, :stepSize)
    assert_equal false, widget.chart_options.dig(:xaxis, :labels, :show)
    assert_equal "Pages", widget.series.first[:name]
    assert_equal [{ x: 0, y: 1 }], widget.series.first[:data]
    refute widget.show_change
    refute widget.show_period
    refute widget.show_metric
  end

  def test_build_history_screen_reads_logs
    screen = RecordingStudioSitemaps::Admin::BuildHistory

    assert_equal "build_history", screen.key
    assert_equal :site, screen.blast_radius
    assert_equal "Build history", screen.title
    assert_equal "Every rebuild, and whether the list grew or shrank.", screen.subtitle
    date_range = screen.filters.find { |filter| filter.type == :date_range }
    assert date_range
    assert_equal :built_at, date_range.options[:field]
    assert_equal :last_30_days, date_range.options[:default]
    period = RecordingStudioAdmin::Period.from_preset_key(:last_30_days)
    assert_equal "Last 30 days", period.label
    refute_equal "#{period.start_date.iso8601} to #{period.end_date.iso8601}", period.label
    picker = DateRangeInputStandIn.new
    assert_equal "last_30_days", picker.presets.first[:key]
    assert_equal "Last 30 days", picker.presets.first[:label]
    assert_equal period.start_date.iso8601, picker.range_for("last_30_days")[:start]
    assert_equal period.end_date.iso8601, picker.range_for("last_30_days")[:end]
    assert_equal :area, screen.chart_value.type
    assert_equal "Pages in the sitemap", screen.chart_value.title
    assert_equal %i[built_at url_count status], screen.table_value.columns.map(&:key)
    assert_equal "Ok", RecordingStudioSitemaps::Admin.build_result(FakeLog.new(status: "success"))
    assert_equal "Failed", RecordingStudioSitemaps::Admin.build_result(FakeLog.new(status: "error"))
    assert_equal "Disk was full",
                 RecordingStudioSitemaps::Admin.build_result(
                   FakeLog.new(status: "error", error_message: "Disk was full")
                 )
    refute_equal "Worked", RecordingStudioSitemaps::Admin.build_result(FakeLog.new(status: "success"))
    refute_equal "Worker", RecordingStudioSitemaps::Admin.build_result(FakeLog.new(status: "success"))
    refute_equal "success", RecordingStudioSitemaps::Admin.build_result(FakeLog.new(status: "success"))
  end

  def test_section_widgets_are_equal_and_not_compact
    usages = RecordingStudioSitemaps::Admin::Section.widget_usages

    assert_equal(
      [
        RecordingStudioSitemaps::Admin::WIDGET_INDEX_SIZE,
        RecordingStudioSitemaps::Admin::WIDGET_COVERAGE,
        RecordingStudioSitemaps::Admin::WIDGET_FINDABLE,
        RecordingStudioSitemaps::Admin::WIDGET_MISSING
      ],
      usages.map(&:key)
    )
    assert(usages.all? { |usage| usage.view_variant.nil? })
    refute(usages.any? { |usage| usage.view_variant == :compact })
  end

  def test_section_subtitle_is_last_built_and_rebuild_has_no_last_built_button
    names = RecordingStudioSitemaps::Admin::Section.links.map(&:name)

    assert_equal %i[open_sitemap rebuild build_history], names
    refute_includes names, :last_build

    section_context = FakeContext.new(params: { key: "sitemaps" })
    visible = RecordingStudioSitemaps::Admin::Section.links.filter_map do |link|
      link.resolve(section_context)&.name
    end
    assert_equal %i[open_sitemap rebuild], visible

    screen_context = FakeContext.new(params: { key: "build_history" })
    history = RecordingStudioSitemaps::Admin::Section.links.find { |link| link.name == :build_history }
    assert_equal "/admin/screens/build_history", history.resolve(screen_context).url

    built_at = Time.utc(2026, 8, 21, 15, 30, 0)
    RecordingStudioSitemaps::GenerationLog.stub(:latest, FakeLog.new(built_at: built_at, status: "success")) do
      subtitle = RecordingStudioSitemaps::Admin::Section.evaluate(
        RecordingStudioSitemaps::Admin::Section.subtitle,
        FakeContext.new
      )

      assert_equal "Last built 21 Aug 2026, 15:30", subtitle
      assert_equal "Last built 21 Aug 2026, 15:30", RecordingStudioSitemaps::Admin.last_build_line
    end
  end

  def test_register_is_safe_when_admin_is_defined
    RecordingStudioSitemaps::Admin.instance_variable_set(:@coverage_widget, nil)
    RecordingStudioSitemaps::Admin.instance_variable_set(:@findable_widget, nil)
    RecordingStudioSitemaps::Admin.instance_variable_set(:@missing_widget, nil)
    RecordingStudioSitemaps::Admin.instance_variable_set(:@index_size_widget, nil)

    RecordingStudioSitemaps::Admin.register!

    assert RecordingStudioAdmin.section_for("sitemaps")
    assert RecordingStudioAdmin.screen_for("build_history")
    assert RecordingStudioAdmin.widget_for(RecordingStudioSitemaps::Admin::WIDGET_COVERAGE)
    assert RecordingStudioAdmin.widget_for(RecordingStudioSitemaps::Admin::WIDGET_FINDABLE)
    assert RecordingStudioAdmin.widget_for(RecordingStudioSitemaps::Admin::WIDGET_MISSING)
    assert RecordingStudioAdmin.widget_for(RecordingStudioSitemaps::Admin::WIDGET_INDEX_SIZE)
    refute RecordingStudioAdmin.widget_for("widgets.sitemaps.last_build")
    refute RecordingStudioAdmin.widget_for("widgets.sitemaps.indexable_count")
    refute RecordingStudioAdmin.widget_for("widgets.sitemaps.excluded")
  end
end
