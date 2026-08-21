# frozen_string_literal: true

require "uri"

module RecordingStudioSitemaps
  class AbsoluteUrl
    def self.call(url, public_base_url: RecordingStudioSitemaps.configuration.public_base_url)
      new(url, public_base_url: public_base_url).call
    end

    def initialize(url, public_base_url:)
      @url = url.to_s.strip
      @public_base_url = public_base_url.to_s.strip.chomp("/")
    end

    def call
      return if @url.blank?
      return @url if absolute?(@url)
      return unless @url.start_with?("/")
      return if @public_base_url.blank?

      "#{@public_base_url}#{@url}"
    end

    private

    def absolute?(value)
      uri = URI.parse(value)
      %w[http https].include?(uri.scheme) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
end
