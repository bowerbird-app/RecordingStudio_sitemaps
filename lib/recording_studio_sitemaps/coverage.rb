# frozen_string_literal: true

module RecordingStudioSitemaps
  class Coverage
    TypeCount = Struct.new(:label, :included, :published, keyword_init: true)
    Snapshot = Struct.new(:included, :published, :types, keyword_init: true)

    def self.snapshot
      new.snapshot
    end

    def snapshot
      types = type_counts
      Snapshot.new(
        included: types.sum(&:included),
        published: types.sum(&:published),
        types: types
      )
    end

    private

    def type_counts
      included_by_type = UrlSet.entries.group_by { |entry| entry.recordable&.class }

      UrlSet.indexable_types.map do |type|
        TypeCount.new(
          label: label_for(type),
          included: included_by_type.fetch(type, []).size,
          published: published_count(type)
        )
      end
    end

    def published_count(type)
      return 0 unless type.respond_to?(:published)

      relation = type.published
      relation.respond_to?(:count) ? relation.count : Array(relation).size
    end

    def label_for(type)
      return RecordingStudio.recordable_type_label(type) if defined?(RecordingStudio)

      type.try(:model_name)&.human || type.name
    end
  end
end
