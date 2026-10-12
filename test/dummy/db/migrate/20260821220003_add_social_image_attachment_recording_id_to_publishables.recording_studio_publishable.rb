# frozen_string_literal: true

class AddSocialImageAttachmentRecordingIdToPublishables < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:recording_studio_publishable_publishables)
    return if column_exists?(:recording_studio_publishable_publishables, :social_image_attachment_recording_id)

    add_column :recording_studio_publishable_publishables, :social_image_attachment_recording_id, :uuid
    add_index :recording_studio_publishable_publishables,
              :social_image_attachment_recording_id,
              name: "index_rs_publishables_on_social_image_attachment_recording_id"
    add_foreign_key :recording_studio_publishable_publishables,
                    :recording_studio_recordings,
                    column: :social_image_attachment_recording_id,
                    name: "fk_rs_publishables_social_image_attachment_recording"
  end

  def down
    return unless table_exists?(:recording_studio_publishable_publishables)
    return unless column_exists?(:recording_studio_publishable_publishables, :social_image_attachment_recording_id)

    if foreign_key_exists?(:recording_studio_publishable_publishables, name: "fk_rs_publishables_social_image_attachment_recording")
      remove_foreign_key :recording_studio_publishable_publishables,
                         name: "fk_rs_publishables_social_image_attachment_recording"
    end
    if index_exists?(:recording_studio_publishable_publishables, :social_image_attachment_recording_id,
                     name: "index_rs_publishables_on_social_image_attachment_recording_id")
      remove_index :recording_studio_publishable_publishables,
                   name: "index_rs_publishables_on_social_image_attachment_recording_id"
    end
    remove_column :recording_studio_publishable_publishables, :social_image_attachment_recording_id
  end
end
