# Upgrading

## 0.3.0

Install Sitemaps `0.3.0`. No migration. English hosts need no locale change.

### Admin DSL readers return callables

These Admin DSL readers now return callables that Admin evaluates at render:

- `RecordingStudioSitemaps::Admin::Section.title`
- Section `link.text` (`open_sitemap`, `rebuild`, `build_history`)
- `RecordingStudioSitemaps::Admin::BuildHistory.title`
- Build history chart `title`
- Widget `title`, `info`, and `link_label` (Coverage, In the sitemap, Missing, Index size)

Hosts that read those values directly must evaluate them (call the callable, or use Admin `evaluate`) instead of treating them as Strings. Admin already evaluates them when rendering the section, screen, and widgets.

### Public helpers stay English

`Admin.last_build_line`, `coverage_info`, `findable_items`, `missing_items`, and `index_size_series` still return main's English literals. Exclusion reason strings stay English.

### Translating

Copy new `recording_studio.sitemaps.flashes.*` and `recording_studio.sitemaps.admin.*` keys into host locale files when translating. English ships only in the gem’s `config/locales/en.yml`; call sites do not pass English `default:`. A missing key behaves like a normal I18n miss. Hosts override by defining the same nested keys in their own `config/locales`. The engine does not add an explicit `i18n.load_path` initializer.
