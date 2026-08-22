# frozen_string_literal: true

module RecordingStudioSitemaps
  class GenerationLog < ApplicationRecord
    self.table_name = "recording_studio_sitemaps_generation_logs"

    SUCCESS = "success"
    ERROR = "error"

    scope :newest_first, -> { order(built_at: :desc, created_at: :desc, id: :desc) }
    scope :successful, -> { where(status: SUCCESS) }

    def self.latest
      newest_first.first
    end

    def self.latest_successful
      successful.newest_first.first
    end

    def success?
      status == SUCCESS
    end
  end
end
