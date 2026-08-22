# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class Section < RecordingStudioAdmin::Section
      key "sitemaps"
      title "Sitemaps"
      subtitle { |_context| RecordingStudioSitemaps::Admin.last_build_line }
      icon :map
      blast_radius :site

      link :open_sitemap,
           text: "Open sitemap",
           url: ->(_context) { "/sitemap.xml" },
           style: :secondary

      link :rebuild,
           text: "Rebuild",
           url: ->(_context) { "/recording_studio_sitemaps/rebuild" },
           style: :primary

      # Admin only enables screens that a section link resolves to. Keep this
      # path for Build history, but hide it on the section so last-built stays
      # in the subtitle and Index size remains the open control.
      link :build_history,
           text: "Build history",
           url: ->(context) { context.admin_screen_path(SCREEN_BUILD_HISTORY) },
           style: :ghost,
           visible_if: ->(context) { RecordingStudioSitemaps::Admin.build_history_screen?(context) }

      widget WIDGET_INDEX_SIZE
      widget WIDGET_COVERAGE
      widget WIDGET_FINDABLE
      widget WIDGET_MISSING
    end
  end
end
