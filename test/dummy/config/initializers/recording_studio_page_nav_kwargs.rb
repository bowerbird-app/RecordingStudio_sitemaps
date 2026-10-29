# frozen_string_literal: true

# Recording Studio 4.2 default_layout only forwards page_nav_back_url /
# page_nav_anchor_url into FlatPack::PageNav as back_url / anchor_url.
# FlatPack 0.1.207 expects secondary_anchor_href / anchor_href. Map those
# core kwargs onto the same PageNav so Close and Back links appear.
# Do not replace PageNav with a host-only nav.
module RecordingStudioPageNavCoreKwargs
  def initialize(**system_arguments)
    anchor_url = system_arguments.delete(:anchor_url)
    back_url = system_arguments.delete(:back_url)
    if anchor_url.present? && system_arguments[:anchor_href].blank?
      system_arguments[:anchor_href] = anchor_url
    end
    if back_url.present? && system_arguments[:secondary_anchor_href].blank?
      system_arguments[:secondary_anchor_href] = back_url
    end
    super(**system_arguments)
  end
end

Rails.application.config.to_prepare do
  next if FlatPack::PageNav::Component.ancestors.include?(RecordingStudioPageNavCoreKwargs)

  FlatPack::PageNav::Component.prepend(RecordingStudioPageNavCoreKwargs)
end
