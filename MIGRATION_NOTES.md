# Upgrade notes

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
8. Index size and Build history read generation logs. Build history uses Admin `filter :date_range, field: :built_at, default: :last_30_days`. Result is Ok / Failed (or the error). Chart dates match the When column; page-count ticks stay whole numbers. Do not mark Sitemaps widgets `view_variant: :compact`.
9. Pin `apexcharts` to `recording_studio_sitemaps/apexcharts.js` if Build history y-axis labels still show `0.0`. Flatpack Chart cannot pass a JS formatter through JSON; ApexCharts 3.45 still paints `.0` when `decimalsInFloat` is `0`.
10. Admin’s section grid is three columns. The dummy host overrides that view to Flatpack `cols: 4` so Index size, Coverage, In the sitemap, and Missing share one equal-width row.

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
