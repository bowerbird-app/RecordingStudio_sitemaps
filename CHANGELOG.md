# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.4] - 2026-10-28

### Changed
- Dummy default layout uses FlatPack PageNav's native API (`with_back`, `with_close`, `with_item`). The dummy kwargs shim (`recording_studio_page_nav_kwargs.rb`) is gone.
- Dummy and root (dev) Gemfile FlatPack pin is GitHub tag `v0.1.329` (was `v0.1.207`) so Bundler resolves `view_component >= 4.14` (GHSA-8qw7-6phv-7q6p). No separate `view_component` pin. Gemspec stays `flat_pack ~> 0.1.129`; this gem ships no PageNav views.
- Dummy Admin pin is GitHub tag `v2.4.0` (was `v2.3.0`) so Admin cards render on FlatPack `v0.1.329`. Dummy widget override uses Card `border: :strong` instead of `style: :outlined`.
- Dummy Root Switchable pin is GitHub tag `v0.10.0` (was `v0.9.0`; needs Recording Studio `~> 4.1` and FlatPack `>= 0.1.304`). Recording Studio stays `v4.7.0`. Accessible stays `v0.18.0`. Metrics, Cache, Trashable, and Publishable stay main's pins.
- Lockfile-only: `crass` `1.0.8` and dummy `net-ssh` `7.3.8` (advisory-patched). No Gemfile or gemspec change.
- SimpleCov HTML/JSON under `coverage/` and `test/dummy/coverage/` is no longer tracked.
- Docs: README Metrics constraint matches gemspec `< 1.0`. UPGRADING covers `0.5.4`. Dummy pin text in UPDATE_SUMMARY and MIGRATION_NOTES matches the dummy Gemfile.

### Upgrade notes
- Bump to `0.5.4`. No migration. No gemspec change. Dummy and the root Gemfile pin FlatPack at `v0.1.329`. Dummy tests this kit: Recording Studio `v4.7.0`, Accessible `v0.18.0`, Admin `v2.4.0`, Root Switchable `v0.10.0`. Hosts that copy the dummy kit should move those tags. Hosts already on `flat_pack ~> 0.1.129` need nothing unless they still call the old PageNav keywords (`anchor_url` / `back_url` / `anchor_href` / `secondary_anchor_href`) or Card `style: :outlined`.

## [0.5.2] - 2026-10-22

### Changed
- Runtime dependency `recording_studio_metrics` ceiling lifted to `< 1.0` (was `< 0.6`). (CI tested with Metrics 0.5.0). No code change.
- Pin Ruby at `3.3.12` (was `3.3.6`) so GitHub runners can install the patch.

### Upgrade notes
- Bump to `0.5.2`. No migration. No code change. Hosts on Metrics `0.3.x` through `0.5.x` stay valid.

## [0.5.1] - 2026-10-20

### Changed
- Runtime dependency `recording_studio_metrics` is `>= 0.3, < 0.6` (was `~> 0.3`). Dummy kit pin is GitHub tag `v0.5.0`.

### Upgrade notes
- Bump to `0.5.1`. No migration. Hosts on Metrics `0.3.x` stay valid. Hosts moving to Metrics `0.5.x` can use tag `v0.5.0`. Metrics `0.5` `chart_series` points are `{ x:, y: }` hashes; this gem already emits that shape for Index size.

## [0.5.0] - 2026-10-19

### Added
- Admin Sitemaps section widget `widgets.sitemaps.last_build` shows how long ago the newest sitemap write was (`3 hours ago`). The value comes from `RecordingStudioMetrics` `sitemaps.last_build_age`, which is seconds since `GenerationLog.built_at`. The card links to Build history. Empty before the first build.

### Upgrade notes
- Bump to `0.5.0`. No migration. No new gem. Hosts that already expose `sitemaps.*` operations metrics get the widget on the Sitemaps section.

## [0.4.0] - 2026-10-14

### Added
- Operations metrics for the most recent sitemap build (`GenerationLog`, newest `built_at`):
  - `sitemaps.last_build_status` (breakdown): one row keyed `success` or `error`.
  - `sitemaps.last_build_age` (scalar, unit `seconds`): seconds since that build.
  - `sitemaps.last_build_url_count` (scalar, unit `count`): pages in that build (0 when it failed).
  - Each is empty before the first build. Site-wide, exposed to `:operations`, and gated by AdminRoot `:view` (`RecordingStudioSitemaps::Api::Access.can_view?`), the same as the Build history screen. Not cached, so age is current.
  - Point-in-time values: no `from` / `to` / `interval`, no `group_by` (one build), and no filters (Build history only filters by date).

### Changed
- New runtime dependency `recording_studio_metrics` `~> 0.3` (GitHub tag `v0.3.1`); the dev Gemfile no longer loads it with `require: false`.

### Upgrade notes
- Bump to `0.4.0`. No migration. Pin `recording_studio_metrics` to tag `v0.3.1` and call `RecordingStudioMetrics::Api.register!(api: :operations)` once in the host.

## [0.3.0] - 2026-10-13

i18n WAVE 2: translate non-view rebuild flashes through Rails I18n. Translation-only — English output stays byte-identical to main when hosts leave defaults alone. Admin DSL values (titles, link text, chart titles, column titles, subtitles, widget title/info/link_label) stay main's English string literals. Public Admin helpers (`last_build_line`, `coverage_info`, `findable_items`, `missing_items`, `index_size_series`), `Exclusions` reason strings, Admin table cell values (`Ok` / `Failed`), and persisted generation-log error messages stay main's English literals.

### Added
- English Rails I18n keys under `recording_studio.sitemaps.flashes` for rebuild success and failure alerts.
- `Copy.t` helper that looks up `recording_studio.sitemaps.*` keys. English comes only from `config/locales/en.yml` (no English `default:` on call sites).
- Host English override coverage: test-only fixture `test/dummy/test/locales/sitemaps_host_override.en.yml` plus a real-page assert on the rebuild success flash.
- Always-loaded boot-order guard `test/dummy/config/locales/recording_studio_sitemaps_boot_override.en.yml` for the rarely shown `flashes.rebuild_failed` key, with a real failed-rebuild flash assert (file present, `I18n.t` returns HOST, `I18n.load_path` untouched, main English absent).
- Locale regression: every translated flash call site must use `Copy.t` (not an English notice/alert literal); every `lib/**/*.rb` file must not mention `i18n.load_path` / `I18n.load_path`; gem `lib/` / `app/` call sites must not pass English `default:` to `Copy.t` / `t(`; gem `config/locales/*.yml` ships only real product keys (no HOST / probe / test-only keys — those stay under `test/dummy`).

### Changed
- Dummy and root GitHub pin for Recording Studio is `v4.2.2`
- Gemspec `recording_studio_accessible` constraint is `~> 0.11` (GitHub tag `v0.11.1`)
- Gemspec `recording_studio_publishable` constraint is `~> 0.4` (GitHub tag `v0.4.2`)
- Dummy Admin GitHub tag is `v2.0.4`; dummy Root Switchable is `v0.5.3`
- Dummy Accessible schema uses string roles, `depends_on_recording_id`, and the access invitations table. Grants go through `bootstrap_owner_access!` / `grant_access`
- Rebuild controller flashes resolve through `Copy.t` (keys in `en.yml`).

### Upgrade notes
- Accessible requirement is `~> 0.11`. Example GitHub tag is `v0.11.1`. Hosts on Accessible `0.9.x` or older need Accessible's 0.8–0.11 migrations (depends-on recording, invitations, role integer → string) and must grant via Accessible services, not by writing `RecordingStudio::Access` rows.
- Publishable requirement is `~> 0.4`. Example GitHub tag is `v0.4.2`.
- Admin example GitHub tag is `v2.0.4` (`~> 2.0` is unchanged). Dummy Root Switchable example tag is `v0.5.3`.
- Install Sitemaps `0.3.0`. No migration.
- English hosts need no change. Copy new `recording_studio.sitemaps.flashes.*` keys into host locale files when translating. English is only in `config/locales/en.yml`; call sites do not pass English `default:`.
- Hosts override by defining the same nested keys in their own `config/locales`. The engine does not add an explicit `i18n.load_path` initializer.
- Admin DSL values stay main's English literals (not callables, no admin locale keys).
- Public helpers `Admin.last_build_line`, `coverage_info`, `findable_items`, `missing_items`, and `index_size_series` still return main's English literals. Exclusion reason strings stay English.

## [0.2.3] - 2026-09-16

Dependency pins for Accessible and Publishable.

### Changed
- Gemspec `recording_studio_accessible` constraint is `~> 0.9`
- Gemspec `recording_studio_publishable` constraint is `~> 0.2.0`
- Root and dummy GitHub tags are Accessible `v0.9.1` and Publishable `v0.2.1`
- Dummy `recording_studio_accesses` includes `depends_on_recording_id`

### Upgrade notes
- Accessible requirement is `~> 0.9`. Example GitHub tag is `v0.9.1`.
- Publishable requirement is `~> 0.2.0`. Example GitHub tag is `v0.2.1`. The hard pin `= 0.2.0` is gone.
- Hosts on Accessible `0.7.x` or older need the Accessible `depends_on_recording_id` migration. Sitemaps adds no new engine migration.

## [0.2.2] - 2026-09-03

Cloud Agent Builds fetch Cursor skills at install. Product is unchanged.

### Added
- `.cursor/environment.json`, `.cursor/install.sh`, `.cursor/fetch-skills.sh`, and `.cursor/start.sh` so Cloud Agent Builds provision a cold image, skip warm provision, and always fetch the skill pack last
- Gitignore for `.cursor/skills/` and `.cursor/rules/` so the fetched pack is not vendored

### Upgrade notes
- No host or schema changes. Rebuild the Cloud Agent environment with Draft off so Build loads the pack.

## [0.2.1] - 2026-08-21

Public `/sitemap.xml`, generation logs, and the Admin Sitemaps section.

### Added
- `RecordingStudioSitemaps.rebuild!` as the one domain action for publish/unpublish hooks and Admin Rebuild
- Public `/sitemap.xml` of Publishable indexable URLs (`loc` + `lastmod` only)
- Generation logs for when a sitemap was written, how many URLs it held, and any error
- Admin Sitemaps section: four equal cards (Index size, Coverage, In the sitemap, Missing), last rebuild as the section subtitle, Open sitemap, Rebuild
- Build history Admin screen (`build_history`) from generation logs: Admin `date_range` on `built_at` defaulting to last 30 days, pages-over-time chart, and when / pages / result table. Result is `Ok` or `Failed` (or the real error). Chart x uses the same date language as the table; y stays on whole page counts. Dummy pins ApexCharts through `recording_studio_sitemaps/apexcharts.js` so ticks read `0`, `1`, `2` instead of `0.0`. The DateRangeInput trigger shows Admin’s `Last 30 days` preset label.
- Warning when the findable URL count heads toward 50,000
- Install generator mounts `/sitemap.xml` and asks the host for `public_base_url`
- Dummy seed with one findable page, one published page left out of the sitemap, and a short rebuild history so Index size is not a single point

### Changed
- Gemspec now depends on Admin `~> 2.0`, Publishable `= 0.2.0`, and FlatPack `~> 0.1.129`
- Dummy GitHub tags: Admin `2.0.1` and Publishable `v0.2.0`
- Dummy Page enables Publishable with `RecordingStudio::Capabilities::Publishable.to`
- Configuration is `public_base_url` and `url_count_warning_threshold` (template `api_key` / `enable_feature_x` / `timeout` are gone)
- Dummy default-layout head loads Flatpack CSS only. Sign out and Root Switchable stay out of the PageNav right slot
- Dummy Admin section uses Accessible avatars (`recording_studio_accessible_avatars`, `button_style: :primary`) and a Flatpack four-column widget row
- Dummy Accessible config sets `avatar_resolver` so staff on the admin root resolve to a Flatpack avatar group

### Removed
- Engine sample `recording_studio_sitemaps_pages` table. Sitemap rows are derived; only generation logs are stored.

### Upgrade notes
- Add Admin `2.0.1` and Publishable `v0.2.0` next to Recording Studio `v4.2.0`
- Set `config.public_base_url` to the public host search engines should see
- Run `bin/rails generate recording_studio_sitemaps:install` and `bin/rails generate recording_studio_sitemaps:migrations`
- Enable Publishable on types that should appear
- Enable `section :sitemaps` on the admin root and grant Accessible access. Do not use `user.admin?`
- If a host copied Sign out or a root switcher into `_default_layout_head.html.erb`, remove them. That partial should load Flatpack CSS only
- Set Accessible `avatar_resolver` if staff have names or photos. Admin already renders `recording_studio_accessible_avatars` in the section slot
- Admin’s default section grid is three columns. Four equal Sitemaps cards share one row when the host uses Flatpack Grid `cols: 4` (the dummy host does this)
- Pin `apexcharts` to `recording_studio_sitemaps/apexcharts.js` if Build history y labels still show `0.0`
- Drop any `recording_studio_sitemaps_pages` table if a host copied the old engine migration

## [0.1.0] - 2026-08-21

First product release of Recording Studio Sitemaps. A public `/sitemap.xml` of Publishable indexable URLs, with generation logs and Admin last-build / excluded URL views, is the product direction. This slice ships the gem identity and Recording Studio 4.2 host pins only. It does not emit XML, logs, Admin, a generator, or Publishable wiring.

### Added
- Gemspec dependencies `recording_studio`, `~> 4.2` and `recording_studio_accessible`, `~> 0.6`

### Changed
- Renamed the engine from the addon template to `recording_studio_sitemaps`
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.1`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated pages use Recording Studio's default layout chrome and load Flatpack CSS/JS (including `flat_pack/application` and Turbo). Devise sign-in keeps its own layout and still loads those assets. Root Switchable sits in the default-layout chrome.

### Removed
- Leftover template identity in the public README and gemspec
- Dummy starter docs pages
- Template example capability mixin
- Engine sample home controller

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v4.2.0` and Accessible `v0.6.1`
- Declare `spec.add_dependency "recording_studio", "~> 4.2"` and `spec.add_dependency "recording_studio_accessible", "~> 0.6"`
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Do not expect `/sitemap.xml`, Admin, generation logs, or Publishable wiring from this version

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.5.4...HEAD
[0.5.4]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.2.3...v0.3.0
[0.2.3]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.2.3
[0.2.2]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.2.2
[0.2.1]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.2.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.1.0
