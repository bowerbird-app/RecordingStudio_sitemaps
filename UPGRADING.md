# Upgrading

## 0.6.0

Install Sitemaps `0.6.0`. No migration. Pin FlatPack at GitHub tag `v0.1.331` (`>= 0.1.331`). Build history passes FlatPack DateRangeInput `presets:` (`:last_30_days` first, then the default names). The old DateRangeInput prepend is gone. Reload host JavaScript so the date picker has `last_30_days`. Do not rebuild Tailwind.

## 0.5.3

Install Sitemaps `0.5.3`. No migration. Dummy default layout uses native FlatPack PageNav (`with_back`, `with_close`, `with_item`). Dummy and the root Gemfile pin FlatPack at GitHub tag `v0.1.329`. Dummy kit also pins Admin `v2.4.0` and Root Switchable `v0.10.0`. Lockfile-only: `crass` `1.0.8` and dummy `net-ssh` `7.3.8`. SimpleCov output under `coverage/` and `test/dummy/coverage/` is untracked. Gemspec is unchanged. Hosts already on `flat_pack ~> 0.1.129` need nothing unless they still call the old PageNav keywords or Card `style: :outlined`.

## 0.5.2

Install Sitemaps `0.5.2`. No migration. `recording_studio_metrics` is `>= 0.3, < 1.0`. Hosts on Metrics `0.3.x` through `0.5.x` stay valid.

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
