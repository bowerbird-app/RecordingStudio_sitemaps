# frozen_string_literal: true

module RecordingStudioSitemaps
  # Receives one batch of entries from a source.
  # A batch is an entry, a hash, or an array of those.
  class BatchSink
    def initialize(&on_batch)
      @on_batch = on_batch
    end

    def yield(entries)
      @on_batch.call(entries)
    end
    alias << yield
  end
end
