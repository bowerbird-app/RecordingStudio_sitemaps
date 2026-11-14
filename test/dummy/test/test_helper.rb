# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require_relative "support/admin_access_helpers"

class ActionDispatch::IntegrationTest
  include AdminAccessHelpers
end

module SitemapRegistryIsolation
  def before_setup
    @_sitemap_sources = RecordingStudioSitemaps.sources.snapshot
    @_sitemap_filters = RecordingStudioSitemaps.filters.snapshot
    super
  end

  def after_teardown
    super
    RecordingStudioSitemaps.sources.restore(@_sitemap_sources) if @_sitemap_sources
    RecordingStudioSitemaps.filters.restore(@_sitemap_filters) if @_sitemap_filters
  end
end

ActiveSupport::TestCase.prepend(SitemapRegistryIsolation)
