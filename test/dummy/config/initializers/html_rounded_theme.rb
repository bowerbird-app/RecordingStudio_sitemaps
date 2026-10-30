# frozen_string_literal: true

# Core 6 stamps data-theme="rounded" on the default layout <html>. Dummy also
# stamps it when a response skipped that layout, without vendoring the layout.
module DummyHtmlRoundedTheme
  extend ActiveSupport::Concern

  included do
    after_action :apply_dummy_html_rounded_theme
  end

  private

  def apply_dummy_html_rounded_theme
    return unless response.media_type&.include?("html")

    body = response.body.to_s
    return if body.blank?
    return if body.match?(/<html\b[^>]*\bdata-theme=/i)

    response.body = body.sub(/<html\b/i, '<html data-theme="rounded"')
  end
end

Rails.application.config.to_prepare do
  [
    ApplicationController,
    (RecordingStudio::ApplicationController if defined?(RecordingStudio::ApplicationController))
  ].compact.each do |controller|
    next if controller < DummyHtmlRoundedTheme

    controller.include(DummyHtmlRoundedTheme)
  end
end
