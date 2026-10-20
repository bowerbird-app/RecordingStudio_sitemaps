# Upgrading

## 0.4.1

Install Sitemaps `0.4.1`. No migration. `recording_studio_metrics` is `>= 0.3, < 0.6`. Hosts can stay on Metrics `0.3.x` or move to `0.5.0` (GitHub tag `v0.5.0`) without taking newer Sitemaps. Metrics `0.5.0` `chart_series` points are `{ x:, y: }` hashes.

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

`Admin.last_build_line`, `coverage_info`, `findable_items`, `missing_items`,
and `index_size_series` still return main’s English literals. Exclusion reason
strings stay English.

### Translating

Copy new `recording_studio.sitemaps.flashes.*` keys into host locale files when
translating. Hosts override by defining the same nested keys in their own
`config/locales`. The engine does not add an explicit `i18n.load_path`
initializer.
