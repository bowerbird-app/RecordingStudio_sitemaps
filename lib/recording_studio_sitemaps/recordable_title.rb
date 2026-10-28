# frozen_string_literal: true

module RecordingStudioSitemaps
  module RecordableTitle
    module_function

    def for(recordable)
      recordable.try(:title).presence ||
        recordable.try(:name).presence ||
        yield
    end
  end
end
