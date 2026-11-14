# frozen_string_literal: true

module RecordingStudioSitemaps
  module Sources
    # Default source. Hosts that only use Publishable keep the old sitemap
    # with no setup. A host or gem can unregister :publishable and replace it.
    #
    # This asks each recordable type for `.indexable` and walks it in batches.
    # Which rows that scope returns is Publishable's decision.
    class Publishable
      NAME = :publishable
      BATCH_SIZE = 500

      def initialize(batch)
        @batch = batch
      end

      def call
        indexable_types.each { |type| yield_type(type) }
        nil
      end

      private

      def yield_type(type)
        each_recordable_batch(type.indexable) do |recordables|
          entries = entries_for(type, recordables)
          @batch.yield(entries) if entries.any?
        end
      end

      def entries_for(type, recordables)
        recordings = recordings_for(type, recordables)
        recordables.filter_map { |recordable| entry_for(recordable, recordings[recordable.id]) }
      end

      def entry_for(recordable, recording)
        loc = AbsoluteUrl.call(recordable.try(:indexable_url))
        return if loc.blank?

        Entry.new(
          loc: loc,
          lastmod: lastmod_for(recordable),
          title: title_for(recordable),
          type: type_label(recordable),
          recording: recording
        )
      end

      def each_recordable_batch(relation)
        unless relation.respond_to?(:in_batches)
          yield array_of(relation)
          return
        end

        relation.in_batches(of: BATCH_SIZE) do |batch|
          rows = array_of(batch)
          yield rows if rows.any?
        end
      end

      def array_of(relation)
        relation.respond_to?(:to_a) ? relation.to_a : Array(relation)
      end

      def indexable_types
        return [] unless defined?(RecordingStudio)

        Array(RecordingStudio.configuration.recordable_types).filter_map do |type_name|
          type = type_name.to_s.safe_constantize
          type if type.respond_to?(:indexable)
        end
      end

      def recordings_for(type, recordables)
        model = recording_model
        return {} if model.nil? || type.name.blank? || recordables.empty?

        scope = model.where(recordable_type: type.name, recordable_id: recordables.map(&:id))
        scope = scope.where(trashed_at: nil) if trashed_column?(model)
        scope.order(:created_at, :id).each_with_object({}) do |recording, map|
          map[recording.recordable_id] = recording
        end
      end

      def recording_model
        return unless defined?(RecordingStudio::Recording)

        model = RecordingStudio::Recording
        model if model.respond_to?(:where)
      end

      def trashed_column?(model)
        model.respond_to?(:column_names) && model.column_names.include?("trashed_at")
      end

      def lastmod_for(recordable)
        recordable.try(:current_publishable_for_index).try(:publish_at)
      end

      def title_for(recordable)
        recordable.try(:title).presence ||
          recordable.try(:name).presence ||
          type_label(recordable)
      end

      def type_label(recordable)
        return unless defined?(RecordingStudio)
        return unless RecordingStudio.respond_to?(:recordable_type_label)

        RecordingStudio.recordable_type_label(recordable)
      end
    end
  end
end
