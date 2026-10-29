# frozen_string_literal: true

# Recording Studio 4.7 and Admin 2.3 still pass PageNav kwargs removed in
# FlatPack 0.1.274 (right_slot, back_label, anchor_href, secondary_anchor_href).
# Map those onto with_back / with_close / with_item so Close and Back still
# appear. Do not replace PageNav with a host-only nav.
module RecordingStudioPageNavCoreKwargs
  REMOVED_PAGE_NAV_KEYWORDS = %i[
    show_back
    back_href
    back_icon
    back_tooltip
    back_label
    back_style
    back_size
    anchor_href
    anchor_icon
    anchor_tooltip
    anchor_label
    anchor_style
    anchor_size
    secondary_anchor_href
    back_url
    anchor_url
  ].freeze

  def initialize(**system_arguments)
    @rs_page_nav_legacy = REMOVED_PAGE_NAV_KEYWORDS.each_with_object({}) do |key, collected|
      next unless system_arguments.key?(key)

      collected[key] = system_arguments.delete(key)
    end
    super(**system_arguments)
  end

  def before_render
    apply_legacy_page_nav_slots
    super if defined?(super)
  end

  def right_slot(&block)
    with_item(&block)
  end

  private

  def apply_legacy_page_nav_slots
    return if @rs_page_nav_legacy.blank?

    back_href = @rs_page_nav_legacy[:back_url].presence ||
      @rs_page_nav_legacy[:secondary_anchor_href].presence ||
      @rs_page_nav_legacy[:back_href].presence
    close_href = @rs_page_nav_legacy[:anchor_url].presence ||
      @rs_page_nav_legacy[:anchor_href].presence

    with_back(
      href: back_href,
      icon: @rs_page_nav_legacy[:back_icon],
      tooltip: @rs_page_nav_legacy[:back_label].presence || @rs_page_nav_legacy[:back_tooltip],
      style: @rs_page_nav_legacy[:back_style],
      size: @rs_page_nav_legacy[:back_size]
    )
    return if close_href.blank?

    with_close(
      href: close_href,
      icon: @rs_page_nav_legacy[:anchor_icon],
      tooltip: @rs_page_nav_legacy[:anchor_label].presence || @rs_page_nav_legacy[:anchor_tooltip]
    )
  end
end

Rails.application.config.to_prepare do
  next if FlatPack::PageNav::Component.ancestors.include?(RecordingStudioPageNavCoreKwargs)

  FlatPack::PageNav::Component.prepend(RecordingStudioPageNavCoreKwargs)
end
