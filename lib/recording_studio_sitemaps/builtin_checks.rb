# frozen_string_literal: true

require "uri"

module RecordingStudioSitemaps
  # Generic loc checks the engine always applies, before registered filters.
  # These are not registry filters, so a host cannot unregister them.
  class BuiltinChecks
    ABSOLUTE_URL = :absolute_url
    PUBLIC_HOST = :public_host
    ABSOLUTE_URL_REASON = "Not an absolute URL"
    PUBLIC_HOST_REASON = "Off the public host"

    Result = Struct.new(:filter_name, :reason, keyword_init: true)

    def self.call(entry, public_base_url: RecordingStudioSitemaps.configuration.public_base_url)
      new(entry, public_base_url: public_base_url).call
    end

    def initialize(entry, public_base_url:)
      @entry = entry
      @public_base_url = public_base_url
    end

    def call
      return absolute_result unless absolute_http?(@entry.loc)
      return host_result if off_host?

      nil
    end

    private

    def absolute_result
      Result.new(filter_name: ABSOLUTE_URL, reason: ABSOLUTE_URL_REASON)
    end

    def host_result
      Result.new(filter_name: PUBLIC_HOST, reason: PUBLIC_HOST_REASON)
    end

    def off_host?
      expected = host_of(@public_base_url)
      return false if expected.blank?

      host_of(@entry.loc) != expected
    end

    def absolute_http?(value)
      uri = parse(value)
      return false unless uri

      %w[http https].include?(uri.scheme) && uri.host.present?
    end

    def host_of(value)
      parse(value)&.host&.downcase
    end

    def parse(value)
      URI.parse(value.to_s.strip)
    rescue URI::InvalidURIError
      nil
    end
  end
end
