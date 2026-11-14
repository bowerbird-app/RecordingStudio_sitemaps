# frozen_string_literal: true

require "cgi"

module RecordingStudioSitemaps
  class XmlBuilder
    NAMESPACE = "http://www.sitemaps.org/schemas/sitemap/0.9"

    def self.build(entries)
      stream do |document|
        Array(entries).each { |entry| document.add(entry) }
      end
    end

    def self.stream
      document = new
      yield document
      document.finish
    end

    def initialize
      @chunks = []
    end

    def add(entry)
      xml = url_xml(attributes_for(entry))
      @chunks << xml if xml
    end

    def finish
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="#{NAMESPACE}">
        #{@chunks.join}</urlset>
      XML
    end

    private

    def attributes_for(entry)
      return entry unless entry.respond_to?(:loc)

      {
        loc: entry.loc,
        lastmod: entry.lastmod,
        changefreq: entry.changefreq,
        priority: entry.priority
      }
    end

    def url_xml(entry)
      loc = xml_escape(entry[:loc].to_s)
      return if loc.blank?

      lines = ["  <url>", "    <loc>#{loc}</loc>"]
      append_optional(lines, "lastmod", format_lastmod(entry[:lastmod]))
      append_optional(lines, "changefreq", entry[:changefreq])
      append_optional(lines, "priority", entry[:priority])
      lines << "  </url>\n"
      "#{lines.join("\n")}\n"
    end

    def append_optional(lines, tag, value)
      return if value.blank?

      lines << "    <#{tag}>#{xml_escape(value)}</#{tag}>"
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
