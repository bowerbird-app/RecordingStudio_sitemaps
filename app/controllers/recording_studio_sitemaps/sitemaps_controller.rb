# frozen_string_literal: true

module RecordingStudioSitemaps
  class SitemapsController < ActionController::Base
    skip_forgery_protection

    def show
      xml = latest_xml || rebuild_xml
      render xml: xml, content_type: "application/xml"
    end

    private

    def latest_xml
      GenerationLog.latest_successful&.xml.presence
    end

    def rebuild_xml
      log = RecordingStudioSitemaps.rebuild!(source: :request)
      log&.xml.presence || XmlBuilder.build([])
    end
  end
end
