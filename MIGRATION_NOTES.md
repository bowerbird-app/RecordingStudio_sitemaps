# Upgrade notes

## Unreleased

Raise Recording Studio to GitHub tag `v6.3.0` (`>= 6.3.0`). Raise Admin to `v2.8.0` (`>= 2.8.0`). Raise Accessible to `v0.23.1` (`>= 0.23.1`). Raise Metrics to `v0.7.0` (`>= 0.7.0, < 1.0`). Raise Trashable to `v0.12.0`. Pin Logs `v0.7.1` (Admin 2.8 runtime). Raise Publishable to `v0.13.0` (`>= 0.13.0`). Raise dummy Root Switchable to `v0.11.0`. Dummy and root FlatPack stay `v0.1.331`.

- Recording Studio `>= 6.3.0` (GitHub tag `v6.3.0`) — core 6 layout (`recording_studio_layout`, `flat_pack_page_nav`); Admin 2.8.0 requires this floor
- Accessible `>= 0.23.1` (GitHub tag `v0.23.1`) — Admin 2.8.0 development kit pin; no Sitemaps-owned Accessible migration
- Publishable `>= 0.13.0` (GitHub tag `v0.13.0`) — 0.8.0 still requires core `~> 4.2`, so Bundler cannot keep that tag beside core 6.3.0
- Trashable GitHub tag `v0.12.0` — Admin 2.8.0 kit pin; query-only in this host (`require: false`)
- Admin `>= 2.8.0` (GitHub tag `v2.8.0`) — DateRangeInput hash preset `{ key: :last_30_days, label: "Last 30 days", days: 31 }`; also pin Logs `v0.7.1`, Metrics `v0.7.0`, and Trashable `v0.12.0`
- Dummy Root Switchable tag `v0.11.0` — 0.10.0 still requires core `~> 4.1`
- Dummy and root FlatPack GitHub tag `v0.1.331` (`>= 0.1.331`)

### Host app

1. Pin Recording Studio at GitHub tag `v6.3.0` (`>= 6.3.0`). Follow core’s 6.x upgrade notes for layout (`recording_studio_layout`, `content_for :title`, `flat_pack_page_nav`). English hosts need no locale change.
2. Pin Accessible at GitHub tag `v0.23.1` (`>= 0.23.1`). From `0.13.x`, run `bin/rails generate recording_studio_accessible:migrations` and `bin/rails db:migrate` so `0.14.0` action-audience tables land (`recording_studio_access_constraints`, `recording_studio_access_rules`). Also pin Metrics `v0.7.0` and Trashable `v0.12.0` with `require: false` so Bundler can resolve Accessible’s query-only Trashable dependency. English hosts need no locale change.
3. Pin Publishable at GitHub tag `v0.13.0` (`>= 0.13.0`). English hosts need no locale change. Optional: subscribe to `RecordingStudioPublishable.subscribe` for published/unpublished/revised notifications added in `0.7.0`. Hosts missing `social_image_attachment_recording_id` on `recording_studio_publishable_publishables` should run `bin/rails generate recording_studio_publishable:migrations` then `bin/rails db:migrate` (revising a publishable requires that column).
4. Pin Admin at GitHub tag `v2.8.0` and FlatPack at `v0.1.331` (`recording_studio_admin >= 2.8.0`, `flat_pack >= 0.1.331`). Also pin Logs `v0.7.1`, Metrics `v0.7.0`, and Trashable `v0.12.0` with `require: false` next to Admin. Build history uses Admin’s hash date-range preset. Do not copy `_filter_fields` or prepend DateRangeInput. English hosts need no locale change. Dummy default layout comes from core 6. Dummy Admin cards use `border: :strong` instead of `style: :outlined`.
5. If the host uses Root Switchable, pin it at GitHub tag `v0.11.0` (dummy-tested) and Metrics at `v0.7.0`. Root Switchable `0.10.0` cannot install beside core 6.3.0. English hosts that leave `page_copy` unset or use plain Strings need no locale change. Do not set required `page_copy` keys to `nil`.
6. Run `bin/rails generate recording_studio_accessible:migrations` and `bin/rails db:migrate` if you are on Accessible `0.9.x` or older. That adds `depends_on_recording_id`, the access invitations table, and string roles on `recording_studio_accesses`.
7. Grant access through Accessible services (`bootstrap_owner_access!`, `grant_access`). `RecordingStudio::Access` is readonly. Roles are strings (`view`, `edit`, `admin`).
8. To translate Accessible UI/mail, copy `recording_studio.accessible.*` into host locale files. English hosts need no locale change.
9. Sitemaps adds no new engine migration.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.5.1

Install Sitemaps `0.5.1`. No migration. `recording_studio_metrics` is `>= 0.3, < 0.6`. Example GitHub tag is `v0.5.0`. Hosts on Metrics `0.3.x` stay valid.

## 0.5.0

Install Sitemaps `0.5.0`. No migration. The Sitemaps Admin section shows Last build as time ago from `sitemaps.last_build_age`. No new gem.

## 0.4.0

Install Sitemaps `0.4.0`. No migration. Add `recording_studio_metrics` at tag `v0.3.1` (`~> 0.3`) and call `RecordingStudioMetrics::Api.register!(api: :operations)` once to expose the `sitemaps.*` build metrics.

## 0.3.0

Install Sitemaps `0.3.0`. No migration. English hosts need no locale change.

Rebuild flashes use `recording_studio.sitemaps.flashes.*`. Admin DSL values stay main’s English literals (not callables). Public helpers `Admin.last_build_line`, `coverage_info`, `findable_items`, `missing_items`, and `index_size_series` still return main's English literals. Exclusion reasons stay English. See `UPGRADING.md`.

Copy new `recording_studio.sitemaps.flashes.*` keys into host locale files when translating.

## 0.2.3

Raise Accessible to `~> 0.9` and relax Publishable to `~> 0.2.0`.

- Accessible `~> 0.9` (dummy GitHub tag `v0.9.1`)
- Publishable `~> 0.2.0` (dummy GitHub tag `v0.2.1`)

### Host app

1. Pin Accessible at `~> 0.9` and resolve it from GitHub tag `v0.9.1`.
2. Pin Publishable at `~> 0.2.0` and resolve it from GitHub tag `v0.2.1`. Remove any `= 0.2.0` pin.
3. If you are on Accessible `0.7.x` or older, run `bin/rails generate recording_studio_accessible:migrations`. Then run `bin/rails db:migrate`. That adds `depends_on_recording_id` on `recording_studio_accesses`. Sitemaps adds no new engine migration.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.2.1

This slice ships the public sitemap, generation logs, and Admin.

- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.1`)
- Publishable `= 0.2.0` (dummy GitHub tag `v0.2.0`)
- FlatPack dummy tag `v0.1.133`

### Host app

1. Add Admin and Publishable next to this gem. Publishable must not depend on Sitemaps.
2. Run `bin/rails generate recording_studio_sitemaps:install` and `bin/rails generate recording_studio_sitemaps:migrations`.
3. Set `RecordingStudioSitemaps.configuration.public_base_url` to the public host.
4. Enable Publishable with `include RecordingStudio::Capabilities::Publishable.to(...)` on types that should appear.
5. Enable `section :sitemaps` on the admin root and grant Accessible access to that root. Admin requires the current root to be that admin root.
6. Drop `recording_studio_sitemaps_pages` if a host copied the old engine migration. Sitemap URLs are derived; only generation logs are stored.
7. Do not put Sign out or a root switcher in `_default_layout_head.html.erb`. That partial loads Flatpack CSS. Core owns back/close. Set Accessible `avatar_resolver` so the Admin slot can show who has access.
8. Last build reads `RecordingStudioMetrics` `sitemaps.last_build_age` (seconds since stored `GenerationLog.built_at`) and shows time ago in words. Index size and Build history read generation logs. Build history uses Admin `filter :date_range, field: :built_at, default: :last_30_days`. Admin’s DateRangeInput hash preset (`days: 31`) makes the trigger show `Last 30 days`. Result is Ok / Failed (or the error). Chart dates match the When column; page-count ticks stay whole numbers. Do not mark Sitemaps widgets `view_variant: :compact`.
9. Pin `apexcharts` to `recording_studio_sitemaps/apexcharts.js` if Build history y labels still show `0.0`. Flatpack Chart cannot pass a JS formatter through JSON; ApexCharts 3.45 still paints `.0` when `decimalsInFloat` is `0`.
10. Admin’s section grid is three columns. The dummy host overrides that view to Flatpack `cols: 4`. Last build, Index size, Coverage, In the sitemap, and Missing share that row. The fifth card wraps.

`RecordingStudioSitemaps.rebuild!` is the one write path. Publish/unpublish and Admin Rebuild both call it.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

## 0.1.0

This repo is now Recording Studio Sitemaps, not the addon starting point.

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `~> 4.2` (dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.6.1`)
- Root Switchable dummy tag `v0.5.0` when the dummy host uses it
- FlatPack dummy tag `v0.1.133`

### Host app

1. Change the gem name from the old addon starting point to `recording_studio_sitemaps`.
2. Add `recording_studio`, `~> 4.2` and `recording_studio_accessible`, `~> 0.6`.
3. Run `bin/rails generate recording_studio_sitemaps:install` and `bin/rails generate recording_studio_sitemaps:migrations`.
4. Include `RecordingStudio::UsesDefaultLayout` on authenticated host screens.

This version does not emit `/sitemap.xml`, write generation logs, mount an Admin section, or wire Publishable.

### Verify

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```
