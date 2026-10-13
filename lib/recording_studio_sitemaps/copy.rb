# frozen_string_literal: true

require "i18n"

module RecordingStudioSitemaps
  # Rails I18n lookups for Sitemaps user-facing copy. English ships only in
  # `config/locales/en.yml` under `recording_studio.sitemaps.*`. Call sites do
  # not pass English `default:` — a missing key behaves like a normal I18n
  # miss (translation missing / raise-on-missing), same as main for unknown keys.
  #
  # Public Admin helpers (`last_build_line`, `coverage_info`, `findable_items`,
  # `missing_items`, `index_size_series`) and Exclusions reasons stay main's
  # English literals. Controllers and Admin DSL call sites call `Copy.t`.
  module Copy
    PREFIX = "recording_studio.sitemaps"

    module_function

    def t(key, **)
      I18n.t("#{PREFIX}.#{key}", **)
    end
  end
end
