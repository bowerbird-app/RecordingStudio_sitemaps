# frozen_string_literal: true

module RecordingStudioSitemaps
  module AdminRebuildHelper
    def recording_studio_admin_register_page_actions(actions, overflow_after: 3)
      Array(actions).each_with_index do |action, index|
        kwargs = {
          role: recording_studio_admin_page_nav_role(action.style),
          overflow: index >= overflow_after
        }
        kwargs[:data] = { turbo_method: :post } if sitemaps_rebuild_action?(action)
        register_page_nav(action.text, preserve_anchor_url(action.url), **kwargs)
      end
      nil
    end

    def sitemaps_rebuild_action?(action)
      return true if action.try(:name).to_s == "rebuild"

      action.try(:url).to_s.include?("/recording_studio_sitemaps/rebuild")
    end
  end
end
