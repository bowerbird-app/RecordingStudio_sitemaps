# frozen_string_literal: true

module RecordingStudioSitemaps
  # Included entries over entries sources offered, grouped by the entry's type.
  class Coverage
    TypeCount = Struct.new(:label, :included, :offered, keyword_init: true)
    Snapshot = Struct.new(:included, :offered, :types, keyword_init: true)

    def self.snapshot
      new.snapshot
    end

    def snapshot
      types = type_counts
      Snapshot.new(
        included: types.sum(&:included),
        offered: types.sum(&:offered),
        types: types
      )
    end

    private

    def type_counts
      grouped = Collection.decisions.group_by { |decision| label_for(decision.entry) }
      grouped.map do |label, decisions|
        TypeCount.new(
          label: label,
          included: decisions.count(&:accepted?),
          offered: decisions.size
        )
      end
    end

    def label_for(entry)
      entry.type.presence || "Page"
    end
  end
end
