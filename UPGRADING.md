# Upgrading

## 0.5.3

Install Sitemaps `0.5.3`. No migration. Coverage reports stay untracked. Template rename leftovers (`docs/gem_template/`, `bin/rename_gem`) are gone. The engine no longer applies template model/controller extension hooks or swallows YAML/`config.x` load errors. Hosts with `config/recording_studio_sitemaps.yml` still load it through `config_for` when the file exists. Dummy kit hosts that boot Publishable should pin Attachable `v0.10.0` (newer tags need FlatPack or Recording Studio bumps this wave does not make) and list `RecordingStudioAttachable::Attachment`.

## 0.5.2

Install Sitemaps `0.5.2`. No migration. `recording_studio_metrics` is `>= 0.3, < 1.0`. Dummy and the example Gemfile pin Metrics at tag `v0.5.0`. Hosts on Metrics `0.3.x` through `0.5.x` stay valid.

## 0.5.1

Install Sitemaps `0.5.1`. No migration. `recording_studio_metrics` is `>= 0.3, < 0.6`. Dummy and the example Gemfile pin Metrics at tag `v0.5.0`. Hosts on Metrics `0.3.x` do not need to move.

## 0.5.0

Install Sitemaps `0.5.0`. No migration. No new gem. The Sitemaps Admin section adds a Last build number widget that reads `sitemaps.last_build_age` through `RecordingStudioMetrics` and shows time ago in words. The card links to Build history. Public helper `Admin.last_build_value` returns English literals.

## 0.4.0

Install Sitemaps `0.4.0`. No migration. Add `recording_studio_metrics` at tag `v0.3.1` (`~> 0.3`) and call `RecordingStudioMetrics::Api.register!(api: :operations)` once to expose the `sitemaps.*` build metrics.

## 0.3.0

Install Sitemaps `0.3.0`. No migration. English hosts need no locale change.

### Flashes

Rebuild controller flashes resolve through `Copy.t` with keys under
`recording_studio.sitemaps.flashes.*`. English ships only in the gem’s
`config/locales/en.yml`; call sites do not pass English `default:`. A missing
key behaves like a normal I18n miss.

### Admin DSL stays English

Admin DSL values (section/screen/widget titles, link text, chart titles,
column titles, subtitles, widget info/link_label) stay main’s literal Strings.
They are not callables and have no locale keys.

### Public helpers stay English

`Admin.last_build_line`, `Admin.last_build_value`, `coverage_info`, `findable_items`,
`missing_items`, and `index_size_series` still return main’s English literals.
Exclusion reason strings stay English.

### Translating

Copy new `recording_studio.sitemaps.flashes.*` keys into host locale files when
translating. Hosts override by defining the same nested keys in their own
`config/locales`. The engine does not add an explicit `i18n.load_path`
initializer.
