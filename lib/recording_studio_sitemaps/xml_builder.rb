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
      urls = @entries.filter_map { |entry| url_xml(entry) }.join
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="#{NAMESPACE}">
        #{urls}</urlset>
      XML
    end

    private

    def url_xml(entry)
      loc = xml_escape(entry[:loc].to_s)
      return if loc.blank?

      lastmod = format_lastmod(entry[:lastmod])
      lastmod_line = lastmod.present? ? "    <lastmod>#{xml_escape(lastmod)}</lastmod>\n" : ""
      "  <url>\n    <loc>#{loc}</loc>\n#{lastmod_line}  </url>\n"
    end

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
