# frozen_string_literal: true

# Publishable v0.2.0 includes Attachable on its child recordable for social images.
# Sitemaps does not depend on Attachable. This dummy-only stub lets Publishable boot.
unless defined?(RecordingStudio::Capabilities::Attachable)
  module RecordingStudio
    module Capabilities
      module Attachable
        def self.to(**)
          Module.new
        end
      end
    end
  end
end
