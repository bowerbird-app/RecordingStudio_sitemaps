# frozen_string_literal: true

module RecordingStudioSitemaps
  # Entries a built-in check or a registered filter withheld.
  # The reason stays an English literal. The filter name says which check said no.
  class Exclusions
    Item = Struct.new(:title, :reason, :filter_name, :loc, keyword_init: true) do
      def detail
        label = filter_name.to_s.tr("_", " ").capitalize
        return label if reason.blank? || reason == label

        "#{label} — #{reason}"
      end
    end

    def self.items
      new.items
    end

    def items
      Collection.withheld.map { |decision| item_for(decision) }
    end

    private

    def item_for(decision)
      entry = decision.entry
      Item.new(
        title: entry.title.presence || entry.loc,
        reason: decision.reason,
        filter_name: decision.filter_name,
        loc: entry.loc
      )
    end
  end
end
