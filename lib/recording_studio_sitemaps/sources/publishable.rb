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
      UrlContext = Struct.new(:url, :publish_at, :resolved, keyword_init: true)

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
        contexts = url_contexts_for(recordables, recordings)
        recordables.filter_map do |recordable|
          entry_for(recordable, recordings[recordable.id], contexts[recordable.id])
        end
      end

      def entry_for(recordable, recording, context = nil)
        if context&.resolved
          loc = AbsoluteUrl.call(context.url)
          lastmod = context.publish_at
        else
          loc = AbsoluteUrl.call(recordable.try(:indexable_url))
          lastmod = lastmod_for(recordable)
        end
        return if loc.blank?

        Entry.new(
          loc: loc,
          lastmod: lastmod,
          title: title_for(recordable),
          type: type_label(recordable),
          recording: recording
        )
      end

      # indexable_url and current_publishable_for_index each reload the parent
      # recording, its publishable child, and the publishable row. The parent
      # for this batch is already in `recordings`. Load the children and the
      # publishable rows once, then build the URL with Routing.
      def url_contexts_for(recordables, recordings)
        return {} unless defined?(RecordingStudioPublishable::Routing)

        children = children_by_parent_id(recordings.values)
        publishables = publishables_by_id(children.values)
        recordables.each_with_object({}) do |recordable, map|
          parent = recordings[recordable.id]
          child = parent.respond_to?(:id) ? children[parent.id] : nil
          publishable = child.respond_to?(:recordable_id) ? publishables[child.recordable_id] : nil
          map[recordable.id] = url_context_for(recordable, child, publishable)
        end
      end

      def children_by_parent_id(parents)
        model = recording_model
        return {} if model.nil? || parents.empty?
        return {} unless defined?(RecordingStudioPublishable::Publishable)
        return {} unless parents.all? { |parent| parent.respond_to?(:id) }

        scope = if model.respond_to?(:kept)
          model.kept
        elsif model.respond_to?(:all)
          model.all
        else
          return {}
        end
        scope = scope.where(parent_recording_id: parents.map(&:id))
        scope = scope.of_type(RecordingStudioPublishable::Publishable) if scope.respond_to?(:of_type)
        scope.order(:id).each_with_object({}) do |child, map|
          map[child.parent_recording_id] ||= child
        end
      end

      def publishables_by_id(children)
        ids = children.map(&:recordable_id)
        return {} if ids.empty?

        RecordingStudioPublishable::Publishable.where(id: ids).index_by(&:id)
      end

      def url_context_for(recordable, child, publishable)
        return UrlContext.new(resolved: false) if publishable.blank?
        return UrlContext.new(resolved: true) if publishable.noindex?

        url = publishable.canonical_url.presence
        if url.blank? && child.present? && publishable.currently_published?
          url = RecordingStudioPublishable::Routing.url_for(
            publishable_recording: child,
            publishable: publishable,
            parent_recordable_type: recordable.class.name
          )
        end
        url = nil unless recordable.class.respond_to?(:indexable_url?) && recordable.class.indexable_url?(url)
        UrlContext.new(url: url, publish_at: publishable.publish_at, resolved: true)
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
