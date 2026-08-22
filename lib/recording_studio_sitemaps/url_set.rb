# frozen_string_literal: true

module RecordingStudioSitemaps
  class UrlSet
    Entry = Struct.new(:loc, :lastmod, :recordable, keyword_init: true)

    def self.entries
      new.entries
    end

    def self.indexable_types
      new.indexable_types
    end

    def entries
      indexable_types.flat_map { |type| entries_for(type) }.compact
    end

    def indexable_types
      configured_types.filter_map do |type_name|
        type = type_name.safe_constantize
        next unless type.respond_to?(:indexable)

        type
      end
    end

    private

    def configured_types
      return [] unless defined?(RecordingStudio)

      Array(RecordingStudio.configuration.recordable_types)
    end

    def entries_for(type)
      type.indexable.filter_map { |recordable| entry_for(recordable) }
    end

    def entry_for(recordable)
      loc = AbsoluteUrl.call(recordable.try(:indexable_url))
      return if loc.blank?

      Entry.new(loc: loc, lastmod: lastmod_for(recordable), recordable: recordable)
    end

    def lastmod_for(recordable)
      publishable = recordable.try(:current_publishable_for_index)
      publishable.try(:publish_at)
    end
  end
end
