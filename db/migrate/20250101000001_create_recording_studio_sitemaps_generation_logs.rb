# frozen_string_literal: true

class CreateRecordingStudioSitemapsGenerationLogs < ActiveRecord::Migration[8.1]
  def change
    create_generation_logs
    index_generation_logs
  end

  private

  def create_generation_logs
    create_table :recording_studio_sitemaps_generation_logs, id: :uuid do |t|
      t.datetime :built_at, null: false
      t.string :status, null: false
      t.integer :url_count, null: false, default: 0
      t.text :error_message
      t.text :xml
      t.string :source, null: false

      t.timestamps
    end
  end

  def index_generation_logs
    add_index :recording_studio_sitemaps_generation_logs, %i[built_at created_at],
              name: "index_rs_sitemaps_generation_logs_on_built_at"
    add_index :recording_studio_sitemaps_generation_logs, :status
  end
end
