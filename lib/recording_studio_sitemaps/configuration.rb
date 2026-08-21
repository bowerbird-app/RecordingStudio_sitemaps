# frozen_string_literal: true

module RecordingStudioSitemaps
  class Configuration
    URL_COUNT_WARNING_THRESHOLD = 45_000
    SITEMAP_URL_LIMIT = 50_000

    attr_accessor :public_base_url, :url_count_warning_threshold
    attr_reader :hooks

    def initialize
      @public_base_url = nil
      @url_count_warning_threshold = URL_COUNT_WARNING_THRESHOLD
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        public_base_url: public_base_url,
        url_count_warning_threshold: url_count_warning_threshold,
        hooks_registered: hooks.registered_counts
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end

    def approaching_url_limit?(count)
      count.to_i >= url_count_warning_threshold.to_i
    end
  end
end
