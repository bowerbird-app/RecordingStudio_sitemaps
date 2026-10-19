# frozen_string_literal: true

require "i18n"

module RecordingStudioSitemaps
  # Rails I18n lookups for Sitemaps user-facing copy. English ships only in
  # `config/locales/en.yml` under `recording_studio.sitemaps.*`. Call sites do
  # not pass English `default:` — a missing key behaves like a normal I18n
  # miss (translation missing / raise-on-missing).
  #
  # Admin DSL values (titles, link text, column titles, subtitles, widget
  # title/info/link_label) stay main's English string literals. Public Admin
  # helpers (`last_build_line`, `last_build_value`, and the rest) and Exclusions
  # reasons stay main's English literals. Controllers
  # call `Copy.t` for flashes.
  module Copy
    PREFIX = "recording_studio.sitemaps"

    module_function

    def t(key, **)
      I18n.t("#{PREFIX}.#{key}", **)
    end
  end
end
