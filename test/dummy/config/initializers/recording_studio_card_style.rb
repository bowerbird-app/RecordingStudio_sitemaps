# frozen_string_literal: true

# Admin 2.3 and Root Switchable 0.9 still pass Card `style:` (including
# :outlined), which FlatPack 0.1.329 rejects. Drop those kwargs in the dummy
# host so engine screens boot. Do not ship this shim from the gem.
module RecordingStudioCardLegacyStyle
  def initialize(**system_arguments)
    system_arguments.delete(:style)
    system_arguments.delete(:theme)
    system_arguments.delete(:tone)
    super(**system_arguments)
  end
end

Rails.application.config.to_prepare do
  next if FlatPack::Card::Component.ancestors.include?(RecordingStudioCardLegacyStyle)

  FlatPack::Card::Component.prepend(RecordingStudioCardLegacyStyle)
end
