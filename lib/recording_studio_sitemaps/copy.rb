# frozen_string_literal: true

require "i18n"

module RecordingStudioSitemaps
  # Rails I18n lookups for Sitemaps user-facing copy. Every call passes
  # `default:` English so a host locale without a fallback never shows
  # "translation missing". Keys live under `recording_studio.sitemaps.*`.
  #
  # Public lib return values (Exclusions reasons, persisted error messages)
  # stay main's English literals. Controllers and Admin render helpers call
  # `Copy.t` at display time.
  module Copy
    PREFIX = "recording_studio.sitemaps"

    module_function

    def t(key, **)
      I18n.t("#{PREFIX}.#{key}", **)
    end
  end
end
