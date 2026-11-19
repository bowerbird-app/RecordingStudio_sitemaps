# Upgrading

## 0.13.0

Install Sitemaps `0.13.0`. No Sitemaps migration. Gemspec runtime floors are unchanged. Development and dummy Gemfiles pin Recording Studio `~> 7.8` (`v7.8.0`), Flatpack `~> 0.2` (`v0.2.0`), Accessible `~> 0.58` (`v0.58.0`), Admin `~> 2.20` (`v2.20.0`), API `~> 1.21` (`v1.21.2`), Icons `~> 0.5` (`v0.5.0`), Logs `~> 0.9` (`v0.9.0`), Metrics `~> 0.10` (`v0.10.0`), Moveable `~> 6.1` (`v6.1.0`), Publishable `~> 1.5` (`v1.5.0`), and Trashable `~> 1.3` (`v1.3.0`). The dummy also pins Cache `~> 0.8` (`v0.8.0`) and Root Switchable `~> 0.17` (`v0.17.0`).

Hosts MUST run the Recording Studio 7.4, 7.5 and 7.7 migrations if they have not.

flat_pack 0.2.0 is supported; hosts moving to 0.2 must remove the manual `flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller registration.

Hosts that load Recording Studio API 1.12 or newer need `config/recording_studio_api.yml`. A missing file raises during boot. Copy API migration `20261117000024_add_owner_to_recording_studio_api_api_clients` before provisioning clients that store an owner.

## 0.12.0

Install Sitemaps `0.12.0`. No Sitemaps migration. Recording Studio stays `7.0` or newer and below `8`. Accessible stays `0.44.0` or newer and is now below `2.0`. Admin stays `2.16.0` or newer and is now below `3.0`. Metrics stays `0.9.0` or newer and is now below `2.0`. Publishable stays `0.18.1` or newer and is now below `2.0`. Rails and Flatpack constraints are unchanged. Dummy kit pins are unchanged.

## 0.11.1

Install Sitemaps `0.11.1`. No Sitemaps migration. Publishable must be `0.18.1` or newer and below `1.0`. Publishable `0.18.1` requires Recording Studio API `0.24.0` or newer and below `1`, and Flatpack `0.1.341` or newer. API `0.24` also requires Moveable `5.0` or newer and below `6`.

Drop a host copy of `RecordingStudio::Recording.recording_studio_trashable_kept_sql` if it only existed to satisfy API `0.23`. API `0.24` and Admin `2.16` do not call it. Trashable `0.17` already routes kept rows through `RecordingStudio.kept_sql`.

Dummy kit pins: Publishable `v0.18.1`, API `v0.24.0`, Moveable `v5.0.0`. Recording Studio stays `v7.0.0`. Accessible stays `v0.44.0`. Admin stays `v2.16.0`. Trashable stays `v0.17.0`. Root Switchable stays `v0.16.0`. Metrics stays `v0.9.0`. Logs stays `v0.8.0`. Cache stays `v0.6.3`. Icons stay `v0.2.1`. Flatpack stays `v0.1.357` because that tag is already at or above Publishable's `>= 0.1.341` floor.

## 0.11.0

Install Sitemaps `0.11.0`. No Sitemaps migration. Recording Studio must be `7.0` or newer and below `8`. Accessible must be `0.44.0` or newer and below `1.0`. Admin must be `2.16.0` or newer. Metrics must be `0.9.0` or newer and below `1.0`. Publishable must be `0.18.0` or newer and below `1.0`. Earlier Publishable releases still require core 6.

`root_recording_for` only finds a root. Seeds and other setup that used to create one by looking it up now call `RecordingStudio.create_root_recording!(recordable, actor:)`. A second call returns the existing root.

Core 7 refuses a write until `config.authorize_write` returns true. Remove `config.allow_unauthorized_writes`. The callback still needs an actor on the write. `config.actor` supplies one when the call does not.

Admin `2.16` dropped `site_admin_recording_resolver`. Site-wide screens (`blast_radius :site`) need `RecordingStudioAccessible` `config.admin_root_resolver`, and the admin mount's `access_recording_resolver` should return `RecordingStudioAccessible.admin_root(context:)`. The operations rebuild check reads `access_recording_resolver` only.

API `0.23` still calls `RecordingStudio::Recording.recording_studio_trashable_kept_sql`. Trashable `0.17` removed that method. The dummy defines it as `RecordingStudio.kept_sql` until API moves.

Copy core's `add_root_recording_id_to_recording_studio_events` migration if events do not already store `root_recording_id`. Publishable `0.18.0` drops `index_rs_publishable_child_per_parent`. Then run `bin/rails generate recording_studio:single_child_index` and migrate. The generated index counts trashed rows.

Dummy kit pins: Recording Studio `v7.0.0`, Accessible `v0.44.0`, Admin `v2.16.0`, Publishable `v0.18.0`, Trashable `v0.17.0`, Root Switchable `v0.16.0`, Metrics `v0.9.0`, Logs `v0.8.0`. Moveable stays `v4.1.1`. Publishable `0.18` requires API `~> 0.23`, and API `0.23` requires Moveable `~> 4.0`, so Moveable `v5.0.0` does not resolve beside this kit. Cache stays `v0.6.3`. API stays `v0.23.0`. FlatPack stays `v0.1.357`.

## 0.10.0

Install Sitemaps `0.10.0`. No Sitemaps migration. Hosts that only publish indexable pages keep the same `/sitemap.xml` with no setup. The Publishable walk is the default source `:publishable`. Remove it with `RecordingStudioSitemaps.unregister_source(:publishable)` if a host wants to replace it.

Other gems register their own rules. A visibility filter (embargo, access restrictions) returns `false` or a reason String. A source (press kits, marketing pages) yields entries in batches. Register from a host initializer or that gem's engine initializer. Built-in checks drop a blank or non-absolute loc, and a loc off `public_base_url`'s host. They are not registry filters.

A filter that raises drops that one entry and logs the exception. A source that raises fails the rebuild and does not replace the last good sitemap. `changefreq` and `priority` are written when an entry sets them.

`UrlSet` is gone. `Coverage::Snapshot#published` is now `#offered`. `Exclusions` lists withheld entries with `filter_name` and `reason`. It no longer reports noindex, trash, or a missing URL from the Publishable split. Admin Missing shows the filter and the reason.

## 0.9.0

Install Sitemaps `0.9.0`. No Sitemaps migration. Optional operations rebuild: `POST /recording_studio_api/apis/operations/v1/sitemaps/rebuild`. This gem does not gemspec-depend on Recording Studio API. If that constant is missing, Sitemaps boots with no JSON rebuild route. Last-build metrics are unchanged. Dummy kit pins Recording Studio API `v0.21.3` (plus Moveable `v4.1.1` and Icons `v0.2.1` with `require: false`). Other dummy pins stay as 0.8.0. Gemspec floors are unchanged.

## 0.8.0

Install Sitemaps `0.8.0`. No Sitemaps migration. Rebuild is POST-only with CSRF. `/sitemap.xml` serves the last successful log, or empty XML with `Cache-Control` when there is none — it does not rebuild on miss. Failed builds show `Failed` in Admin; exceptions stay in the server log. Dummy kit pins FlatPack `v0.1.341`, Accessible `v0.24.1`, Metrics `v0.7.2`, Logs `v0.7.3`, Trashable `v0.12.2`, Cache `v0.6.2`, Root Switchable `v0.11.5`. Admin stays `v2.8.0`. Rails lockfiles are `8.1.4.1`. Gemspec floors are unchanged.

## 0.6.1

Install Sitemaps `0.6.1`. No Sitemaps migration. Drop any host `apexcharts` pin to `recording_studio_sitemaps/apexcharts.js`. Admin 2.8 / FlatPack `integer_ticks` own whole-number page-count ticks. The wrapper file is still shipped and deprecated. Do not copy Admin’s `_widget.html.erb`. Reload host JavaScript. Do not rebuild Tailwind.

## 0.6.0

Install Sitemaps `0.6.0`. No Sitemaps migration. Pin Recording Studio at GitHub tag `v6.3.0` (`>= 6.3.0`), Admin `v2.8.0` (`>= 2.8.0`), and FlatPack `v0.1.331` (`>= 0.1.331`). Pin Accessible `v0.23.1`, Metrics `v0.7.0`, Trashable `v0.12.0`, Logs `v0.7.1`, and Publishable `v0.13.0`. Build history uses Admin’s hash date-range preset (`days: 31`). The DateRangeInput prepend module is gone (`install_date_range_last_30_days!`, its require, and `admin/date_range_last_30_days.rb`). Reload host JavaScript so the date picker has `last_30_days`. Do not rebuild Tailwind. Hosts still on core 4.x cannot install this version.

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
