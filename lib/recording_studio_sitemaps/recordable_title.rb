# frozen_string_literal: true

module RecordingStudioSitemaps
  module RecordableTitle
    module_function

    def for(recordable, fallback:)
      recordable.try(:title).presence ||
        recordable.try(:name).presence ||
        fallback
    end
  end
end
