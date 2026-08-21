# frozen_string_literal: true

module RecordingStudioSitemaps
  module Services
    class Generate
      def self.call(source: :system)
        new(source: source).call
      end

      def initialize(source:)
        @source = source.to_s
      end

      def call
        entries = UrlSet.entries
        xml = XmlBuilder.build(entries.map { |entry| { loc: entry.loc, lastmod: entry.lastmod } })
        write_log!(
          status: GenerationLog::SUCCESS,
          url_count: entries.size,
          xml: xml
        )
      rescue StandardError => e
        write_log!(
          status: GenerationLog::ERROR,
          url_count: 0,
          error_message: e.message
        )
      end

      private

      def write_log!(status:, url_count:, xml: nil, error_message: nil)
        GenerationLog.create!(
          built_at: Time.current,
          status: status,
          url_count: url_count,
          xml: xml,
          error_message: error_message,
          source: @source
        )
      end
    end
  end
end
