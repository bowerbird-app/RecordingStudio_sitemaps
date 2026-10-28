class HomeController < ApplicationController
  def index
    @workspace = current_root_recordable
    @workspace_items = workspace_items
  end

  private

  def workspace_items
    root = current_root_recording
    return [] if @workspace.blank? || root.blank?

    root.child_recordings.includes(:recordable).filter_map { |recording| workspace_item_for(recording) }
  end

  def workspace_item_for(recording)
    return if recording.trashed_at.present?

    recordable = recording.recordable
    return if recordable.blank?

    name = recordable.try(:name).presence || recordable.try(:title).presence
    return if name.blank?

    { name: name, kind: recordable.class.model_name.human }
  end
end
