# frozen_string_literal: true

module RecordingStudioSitemaps
  class SitemapsController < ActionController::Base
    skip_forgery_protection

    def show
      expires_in 5.minutes, public: true
      render xml: latest_xml || XmlBuilder.build([]), content_type: "application/xml"
    end

    private

    def latest_xml
      GenerationLog.latest_successful&.xml.presence
    end
  end
end
