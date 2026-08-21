# frozen_string_literal: true

# Recording Studio 4.2 default_layout only forwards page_nav_back_url /
# page_nav_anchor_url into FlatPack::PageNav as back_url / anchor_url.
# FlatPack 0.1.133 Close renders only when anchor_href is set; Back is always
# history.back. Map those core kwargs onto the same PageNav so Close appears.
# Do not replace PageNav with a host-only nav.
module RecordingStudioPageNavCoreKwargs
  def initialize(**system_arguments)
    anchor_url = system_arguments.delete(:anchor_url)
    system_arguments.delete(:back_url)
    if anchor_url.present? && system_arguments[:anchor_href].blank?
      system_arguments[:anchor_href] = anchor_url
    end
    super(**system_arguments)
  end
end

FlatPack::PageNav::Component.prepend(RecordingStudioPageNavCoreKwargs)
