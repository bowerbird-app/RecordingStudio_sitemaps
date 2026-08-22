# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class Section < RecordingStudioAdmin::Section
      key "sitemaps"
      title "Sitemaps"
      subtitle "The public list of pages search engines may find."
      icon :map
      blast_radius :site

      link :open_sitemap,
           text: "Open sitemap",
           url: ->(_context) { "/sitemap.xml" },
           style: :secondary

      link :build_history,
           text: "Build history",
           url: ->(context) { context.admin_screen_path(SCREEN_BUILD_HISTORY) },
           style: :secondary

      link :rebuild,
           text: "Rebuild",
           url: ->(_context) { "/recording_studio_sitemaps/rebuild" },
           style: :primary

      link :last_build,
           text: ->(_context) { RecordingStudioSitemaps::Admin.last_build_line },
           url: ->(_context) { "#" },
           style: :ghost

      widget WIDGET_COVERAGE
      widget WIDGET_FINDABLE
      widget WIDGET_MISSING
      widget WIDGET_INDEX_SIZE, view_variant: :compact
    end
  end
end
