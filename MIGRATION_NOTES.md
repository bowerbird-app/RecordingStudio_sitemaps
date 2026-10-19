# Upgrade notes

## Unreleased

Raise Accessible to GitHub tag `v0.18.0` (`~> 0.13` still matches). Raise Publishable to `~> 0.6`. Admin stays `~> 2.0`. Raise Recording Studio to `v4.7.0`. Raise Trashable to `v0.11.0`. Raise dummy Root Switchable to `v0.8.0`.

- Recording Studio `~> 4.2` (GitHub tag `v4.7.0`) — addon engines can register shipped English; English output unchanged; no host migration
- Accessible `~> 0.13` (GitHub tag `v0.18.0`) — adds optional `ControllerAuth` for sibling engines; Trashable query helpers `~> 0.10` still match `0.11.0`; pin Metrics `v0.2.0` and Trashable `v0.11.0` with `require: false` when resolving from git; no Accessible migration for `0.18.0`
- Publishable `~> 0.6` (GitHub tag `v0.8.0`) — i18n wave 2 for non-view copy plus `0.7` visibility notifications; English output unchanged; no host migration
- Trashable GitHub tag `v0.11.0` (`~> 0.10` still matches) — shipped English fallback through `RecordingStudio.t`; requires Recording Studio `~> 4.7`; no migration
- Admin dummy GitHub tag `v2.3.0` (Trashable query helpers `~> 0.10` still match `0.11.0`; pin Metrics `v0.2.0` and Trashable `v0.11.0` with `require: false` next to Admin; `~> 2.0` still matches; no host migration)
- Dummy Root Switchable tag `v0.8.0` (translatable `page_copy`; English output unchanged; requires Accessible `~> 0.13` and Metrics `~> 0.2`; no new host migration)

### Host app

1. Pin Recording Studio at GitHub tag `v4.7.0` (`~> 4.2` still matches). No core migration between `4.6.x` and `4.7.0`. English hosts need no locale change. Prefer `Labels.empty_label` over identity checks against `Labels::EMPTY_LABEL` when the locale may not be English.
2. Pin Accessible at GitHub tag `v0.18.0` (`~> 0.13` still matches). From `0.13.x`, run `bin/rails generate recording_studio_accessible:migrations` and `bin/rails db:migrate` so `0.14.0` action-audience tables land (`recording_studio_access_constraints`, `recording_studio_access_rules`). `0.18.0` itself needs no migration; also pin Metrics `v0.2.0` and Trashable `v0.11.0` with `require: false` so Bundler can resolve Accessible’s query-only Trashable dependency. Trashable `0.11.0` requires Recording Studio `~> 4.7`. English hosts need no locale change.
3. Pin Publishable at GitHub tag `v0.8.0` (`~> 0.6` still matches). English hosts need no locale change. Optional: subscribe to `RecordingStudioPublishable.subscribe` for published/unpublished/revised notifications added in `0.7.0`. Hosts missing `social_image_attachment_recording_id` on `recording_studio_publishable_publishables` should run `bin/rails generate recording_studio_publishable:migrations` then `bin/rails db:migrate` (revising a publishable requires that column).
4. Pin Admin at GitHub tag `v2.3.0` and FlatPack at `v0.1.207` if you use Admin (`~> 2.0` still matches). Also pin Metrics `v0.2.0` and Trashable `v0.11.0` with `require: false` next to Admin (Bundler needs Metrics for Trashable’s gemspec, and Trashable `0.11.0` needs Recording Studio `~> 4.7`). English hosts need no locale change.
5. If the host uses Root Switchable, pin it at GitHub tag `v0.8.0` and Metrics at `v0.2.0` (Root Switchable `0.7+` depends on Metrics `~> 0.2`, which is not on RubyGems). No Root Switchable migration between `0.6.x` and `0.8.0`. English hosts that leave `page_copy` unset or use plain Strings need no locale change. Do not set required `page_copy` keys to `nil`.
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

## 0.5.0

Install Sitemaps `0.5.0`. No migration. The Sitemaps Admin section shows Last build from the existing `sitemaps.last_build_*` metrics. No new gem.

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
8. Last build reads `RecordingStudioMetrics` (`sitemaps.last_build_status`, `sitemaps.last_build_age`, `sitemaps.last_build_url_count`). Index size and Build history read generation logs. Build history uses Admin `filter :date_range, field: :built_at, default: :last_30_days`. The DateRangeInput trigger shows `Last 30 days`. Result is Ok / Failed (or the error). Chart dates match the When column; page-count ticks stay whole numbers. Do not mark Sitemaps widgets `view_variant: :compact`.
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
