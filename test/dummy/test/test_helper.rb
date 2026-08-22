# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require_relative "support/admin_access_helpers"

class ActionDispatch::IntegrationTest
  include AdminAccessHelpers
end
