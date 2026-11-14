# frozen_string_literal: true

module RecordingStudioSitemaps
  # Walks one source in batches. A raise inside the source becomes SourceFailure.
  # A raise in the caller (the rebuild writing XML) is left alone.
  class SourceRunner
    def initialize(registration)
      @registration = registration
      @from_source = true
      @yielded = false
    end

    def each_batch(&block)
      sink = BatchSink.new { |entries| forward_batch(entries, &block) }
      returned = @registration.block.call(sink)
      return if @yielded

      each_returned_batch(returned, &block)
    rescue StandardError => e
      raise e unless @from_source

      raise SourceFailure.new(@registration.name, e)
    end

    private

    def forward_batch(entries, &block)
      @yielded = true
      batch = normalize_batch(entries)
      return if batch.empty?

      hand_off { block.call(batch) }
    end

    def each_returned_batch(returned, &block)
      return if returned.nil?

      if returned.is_a?(Enumerator)
        returned.each { |item| hand_off_batch(item, &block) }
      else
        hand_off_batch(returned, &block)
      end
    end

    def hand_off_batch(entries, &block)
      batch = normalize_batch(entries)
      return if batch.empty?

      hand_off { block.call(batch) }
    end

    def hand_off
      @from_source = false
      yield
      @from_source = true
    end

    def normalize_batch(entries)
      rows = entries.is_a?(Array) ? entries.flatten(1) : [entries]
      rows.map { |entry| coerce_entry(entry) }
    end

    def coerce_entry(entry)
      return entry if entry.is_a?(Entry)
      return Entry.new(**entry.symbolize_keys) if entry.is_a?(Hash)

      raise ArgumentError, "Sitemap sources must yield entries"
    end
  end
end
