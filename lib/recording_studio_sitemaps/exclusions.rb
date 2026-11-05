# frozen_string_literal: true

module RecordingStudioSitemaps
  class Exclusions
    Reason = Struct.new(:title, :reason, keyword_init: true)

    def self.items
      new.items
    end

    def items
      UrlSet.indexable_types.flat_map { |type| items_for(type) }
    end

    private

    def items_for(type)
      published = type.respond_to?(:published) ? type.published.to_a : []
      indexable_ids = type.indexable.where(id: published.map(&:id)).pluck(:id)

      published.filter_map do |recordable|
        next if indexable_ids.include?(recordable.id)

        reason = reason_for(recordable)
        next if reason.blank?

        Reason.new(title: title_for(recordable), reason: reason)
      end
    end

    def title_for(recordable)
      recordable.try(:title).presence ||
        recordable.try(:name).presence ||
        recordable.class.model_name.human
    end

    def reason_for(recordable)
      return "In the trash" if trashed?(recordable)

      publishable = recordable.try(:current_publishable_for_index)
      return "Hidden from search" if publishable&.try(:noindex?)
      return "No public URL" if recordable.try(:indexable_url).blank?

      "Left out of the sitemap"
    end

    def trashed?(recordable)
      return true if recordable.try(:trashed_at).present?

      recording = RecordingStudio::Recording.find_by(
        recordable_type: recordable.class.name,
        recordable_id: recordable.id
      )
      recording&.trashed_at.present?
    rescue StandardError
      false
    end
  end
end
