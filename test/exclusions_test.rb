# frozen_string_literal: true

require "test_helper"

class ExclusionsTest < Minitest::Test
  FakeRelation = Struct.new(:ids) do
    def where(*)
      self
    end

    def pluck(*)
      ids
    end
  end

  FakePublishable = Struct.new(:noindex, :canonical, keyword_init: true) do
    def noindex?
      noindex
    end
  end

  FakeRecordable = Struct.new(:id, :title, :name, :trashed_at, :indexable_url, :publishable, keyword_init: true) do
    def current_publishable_for_index
      publishable
    end
  end

  FakeType = Struct.new(:published_rows, :indexable_ids) do
    def published
      published_rows
    end

    def indexable
      FakeRelation.new(indexable_ids)
    end
  end

  def test_skips_indexable_rows
    recordable = FakeRecordable.new(id: 1, title: "Findable", publishable: FakePublishable.new(noindex: false))

    RecordingStudioSitemaps::UrlSet.stub(:indexable_types, [FakeType.new([recordable], [1])]) do
      assert_empty RecordingStudioSitemaps::Exclusions.items
    end
  end

  def test_reasons_for_noindex_missing_url_and_trash
    noindex = FakeRecordable.new(
      id: 2,
      title: "Staff-only notes",
      publishable: FakePublishable.new(noindex: true),
      indexable_url: "/hidden"
    )
    no_url = FakeRecordable.new(
      id: 3,
      name: "Draft URL",
      publishable: FakePublishable.new(noindex: false),
      indexable_url: nil
    )
    trashed = FakeRecordable.new(
      id: 4,
      title: "Old page",
      trashed_at: Time.utc(2026, 8, 1),
      publishable: FakePublishable.new(noindex: false),
      indexable_url: "/old"
    )
    type = FakeType.new([noindex, no_url, trashed], [])

    RecordingStudioSitemaps::UrlSet.stub(:indexable_types, [type]) do
      reasons = RecordingStudioSitemaps::Exclusions.items

      assert_equal "Hidden from search", reasons.find { |row| row.title == "Staff-only notes" }.reason
      assert_equal "No public URL", reasons.find { |row| row.title == "Draft URL" }.reason
      assert_equal "In the trash", reasons.find { |row| row.title == "Old page" }.reason
    end
  end
end
