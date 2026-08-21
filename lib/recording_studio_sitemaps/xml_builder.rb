# frozen_string_literal: true

require "cgi"

module RecordingStudioSitemaps
  class XmlBuilder
    NAMESPACE = "http://www.sitemaps.org/schemas/sitemap/0.9"

    def self.build(entries)
      new(entries).build
    end

    def initialize(entries)
      @entries = Array(entries)
    end

    def build
      lines = +%(<urlset xmlns="#{NAMESPACE}">\n)
      @entries.each do |entry|
        loc = xml_escape(entry[:loc].to_s)
        next if loc.blank?

        lines << "  <url>\n"
        lines << "    <loc>#{loc}</loc>\n"
        lastmod = format_lastmod(entry[:lastmod])
        lines << "    <lastmod>#{xml_escape(lastmod)}</lastmod>\n" if lastmod.present?
        lines << "  </url>\n"
      end
      lines << "</urlset>\n"
      %(<?xml version="1.0" encoding="UTF-8"?>\n#{lines})
    end

    private

    def format_lastmod(value)
      return if value.blank?
      return value.xmlschema if value.respond_to?(:xmlschema)

      value.to_s
    end

    def xml_escape(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end
