# frozen_string_literal: true

module RecordingStudioSitemaps
  module Admin
    class Section < RecordingStudioAdmin::Section
      key "sitemaps"
      title ->(_context) { Copy.t("admin.section.title", default: "Sitemaps") }
      subtitle { |_context| RecordingStudioSitemaps::Admin.last_build_line }
      icon :map
      blast_radius :site

      link :open_sitemap,
           text: ->(_context) { Copy.t("admin.section.open_sitemap", default: "Open sitemap") },
           url: ->(_context) { "/sitemap.xml" },
           style: :secondary

      link :rebuild,
           text: ->(_context) { Copy.t("admin.section.rebuild", default: "Rebuild") },
           url: ->(_context) { "/recording_studio_sitemaps/rebuild" },
           style: :primary

      # Admin only enables screens that a section link resolves to. Keep this
      # path for Build history, but hide it on the section so last-built stays
      # in the subtitle and Index size remains the open control.
      link :build_history,
           text: ->(_context) { Copy.t("admin.section.build_history", default: "Build history") },
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
