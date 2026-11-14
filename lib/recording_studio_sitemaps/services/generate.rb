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
        count, xml = build_xml
        write_success_log!(count, xml)
      rescue StandardError => e
        write_error_log!(e)
      end

      private

      def build_xml
        count = 0
        xml = XmlBuilder.stream do |document|
          Collection.each_decision do |decision|
            next unless decision.accepted?

            document.add(decision.entry)
            count += 1
          end
        end
        [count, xml]
      end

      def write_success_log!(count, xml)
        write_log!(status: GenerationLog::SUCCESS, url_count: count, xml: xml)
      end

      def write_error_log!(error)
        Log.error(
          "[recording_studio_sitemaps] sitemap rebuild failed: #{error.class}: #{error.message}\n" \
          "#{Array(error.backtrace).first(20).join("\n")}"
        )
        write_log!(status: GenerationLog::ERROR, url_count: 0, error_message: "Failed")
      end

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
