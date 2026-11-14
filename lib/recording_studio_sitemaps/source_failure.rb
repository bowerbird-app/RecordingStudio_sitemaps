# frozen_string_literal: true

module RecordingStudioSitemaps
  # A source raised. The rebuild must not publish a partial urlset.
  class SourceFailure < StandardError
    attr_reader :source_name

    def initialize(source_name, error)
      @source_name = source_name
      super("Sitemap source #{source_name} failed: #{error.class}: #{error.message}")
      set_backtrace(error.backtrace) if error.backtrace
    end
  end
end
