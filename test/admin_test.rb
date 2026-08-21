# frozen_string_literal: true

require "test_helper"

class AdminTest < Minitest::Test
  FakeLog = Struct.new(:built_at, :status, keyword_init: true) do
    def success?
      status == "success"
    end
  end

  def test_last_build_value_without_log
    RecordingStudioSitemaps::GenerationLog.stub(:latest, nil) do
      assert_equal "Not yet", RecordingStudioSitemaps::Admin.last_build_value
      assert_equal "No sitemap written yet.", RecordingStudioSitemaps::Admin.last_build_status
    end
  end

  def test_last_build_value_with_success_and_failure
    built_at = Time.utc(2026, 8, 21, 15, 30, 0)

    RecordingStudioSitemaps::GenerationLog.stub(:latest, FakeLog.new(built_at: built_at, status: "success")) do
      assert_equal "21 Aug 2026, 15:30", RecordingStudioSitemaps::Admin.last_build_value
      assert_equal "Built", RecordingStudioSitemaps::Admin.last_build_status
    end

    RecordingStudioSitemaps::GenerationLog.stub(:latest, FakeLog.new(built_at: built_at, status: "error")) do
      assert_equal "Failed", RecordingStudioSitemaps::Admin.last_build_status
    end
  end

  def test_indexable_count_info_warns_near_limit
    RecordingStudioSitemaps::UrlSet.stub(:entries, Array.new(45_000)) do
      assert_includes RecordingStudioSitemaps::Admin.indexable_count_info, "50,000"
    end

    RecordingStudioSitemaps::UrlSet.stub(:entries, Array.new(2)) do
      assert_includes RecordingStudioSitemaps::Admin.indexable_count_info, "search"
    end
  end

  def test_excluded_items_use_human_reasons
    RecordingStudioSitemaps::Exclusions.stub(:items, []) do
      assert_equal [{ text: "Nothing left out. Nice." }], RecordingStudioSitemaps::Admin.excluded_items
    end

    row = RecordingStudioSitemaps::Exclusions::Reason.new(title: "Staff-only notes", reason: "Hidden from search")
    RecordingStudioSitemaps::Exclusions.stub(:items, [row]) do
      assert_equal(
        [{ text: "Staff-only notes", trailing: "Hidden from search" }],
        RecordingStudioSitemaps::Admin.excluded_items
      )
    end
  end

  def test_register_is_safe_when_admin_is_defined
    RecordingStudioSitemaps::Admin.instance_variable_set(:@last_build_widget, nil)
    RecordingStudioSitemaps::Admin.instance_variable_set(:@indexable_count_widget, nil)
    RecordingStudioSitemaps::Admin.instance_variable_set(:@excluded_widget, nil)

    RecordingStudioSitemaps::Admin.register!

    assert RecordingStudioAdmin.section_for("sitemaps")
    assert RecordingStudioAdmin.widget_for(RecordingStudioSitemaps::Admin::WIDGET_LAST_BUILD)
  end
end
