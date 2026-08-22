# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-08-21

Public `/sitemap.xml`, generation logs, and the Admin Sitemaps section.

### Added
- `RecordingStudioSitemaps.rebuild!` as the one domain action for publish/unpublish hooks and Admin Rebuild
- Public `/sitemap.xml` of Publishable indexable URLs (`loc` + `lastmod` only)
- Generation logs for when a sitemap was written, how many URLs it held, and any error
- Admin Sitemaps section: four equal cards (Index size, Coverage, In the sitemap, Missing), last rebuild as the section subtitle, Open sitemap, Rebuild
- Build history Admin screen (`build_history`) from generation logs: Admin `date_range` on `built_at` defaulting to last 30 days, pages-over-time chart, and when / pages / result table. Result is `Ok` or `Failed` (or the real error). Chart x uses the same date language as the table; y stays on whole page counts. Dummy pins ApexCharts through `recording_studio_sitemaps/apexcharts.js` so ticks read `0`, `1`, `2` instead of `0.0`. The DateRangeInput trigger shows Admin’s `Last 30 days` preset label; dummy pins the date picker so that preset still applies.
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
- Pin the Flatpack date picker through `recording_studio_sitemaps/flatpack_date_picker_controller.js` if the Build history filter shows a raw from–to string instead of `Last 30 days`
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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.2.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.1.0
