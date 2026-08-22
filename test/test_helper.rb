# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_sitemaps"

unless RecordingStudioSitemaps.const_defined?(:GenerationLog, false)
  generation_log = Class.new do
    def self.latest
      nil
    end

    def self.latest_successful
      nil
    end

    def self.create!(**)
      nil
    end

    def self.order(*)
      []
    end
  end
  generation_log.const_set(:SUCCESS, "success")
  generation_log.const_set(:ERROR, "error")
  RecordingStudioSitemaps.const_set(:GenerationLog, generation_log)
end
