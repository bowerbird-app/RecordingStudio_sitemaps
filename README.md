# Recording Studio Sitemaps

A public `/sitemap.xml` of the pages people can find. Built from Publishable URLs that are indexable. Generation logs remember when the list was written. Admin lists what is in the sitemap and why a live page was left out.

This gem owns the XML list, the build log, and the Admin view of that list. Publishable still owns per-page search tags (`indexable?`, robots, canonical). Do not treat this as a second SEO gem.

## What is included

A page appears when Publishable says it is indexable: currently published, not marked noindex, with a usable canonical or public URL, and not in the trash.

- `loc` is the canonical override when set, otherwise the public URL
- `lastmod` is the publish time
- No `changefreq` or `priority`

There is one sitemap for the public host, not one per workspace. `/sitemap.xml` is logged-out and has no actor. If the findable URL count heads toward 50,000, Admin warns. This slice does not split into a sitemap index.

Sitemap rows are not recordings. They are derived and can be rebuilt. Each rebuild writes a **log** (when, count, errors). Admin reads those logs.

## Domain action

`RecordingStudioSitemaps.rebuild!(source:)` is the only write path. Publish/unpublish hooks and the Admin Rebuild button both call it.

```ruby
RecordingStudioSitemaps.rebuild!(source: :admin)
```

## Install

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.6.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.18.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.3.0"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.3.1"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.8.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.10.0", require: false
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.207"
gem "recording_studio_sitemaps", github: "bowerbird-app/RecordingStudio_sitemaps"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.13"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_metrics", "~> 0.3"
gem "recording_studio_publishable", "~> 0.6"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_sitemaps:install
bin/rails generate recording_studio_sitemaps:migrations
bin/rails db:migrate
```

The install generator mounts `/sitemap.xml` and the engine rebuild path. Set the public host:

```ruby
RecordingStudioSitemaps.configure do |config|
  config.public_base_url = "https://www.example.com"
end
```

Enable Publishable on the types that should appear:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: %w[Workspace Folder]

  include RecordingStudio::Capabilities::Publishable.to(
    public_controller: "pages",
    public_action: :show
  )
end
```

Enable the Admin section on the admin root and grant Accessible access. Do not use `user.admin?`.

```ruby
class AdminRoot < ApplicationRecord
  include RecordingStudio::Recordable
  include RecordingStudioAdmin::AllowsAdminSections

  recording_studio_recordable label: "Admin", root: true, shared: false
  RecordingStudio.enable_capability(:accessible, on: self)

  recording_studio_admin_sections do
    section :sitemaps
  end
end
```

## Admin

The Sitemaps section is four equal cards in one row, then Open sitemap / Rebuild. The subtitle is the last rebuild (`Last built 22 Aug 2026, 02:19` — same date language as the history table).

- **Index size** — how many pages made the sitemap each rebuild, from the last 30 days of generation logs. The card is a link to **Build history** (`context.admin_screen_path("build_history")`)
- **Coverage** — findable pages over published Publishable pages, as a progress bar
- **In the sitemap** — each findable page, with its type
- **Missing** — each published page that missed the list and why, plus any Publishable type with none in the sitemap

Do not mark any of those widgets `view_variant: :compact`. Compact cards render on their own Admin row and shrink the others.

**Build history** is a child Admin screen: the same log as a line/area chart plus a table of when / pages / result. It uses Admin’s standard `filter :date_range, field: :built_at, default: :last_30_days`. The DateRangeInput trigger shows that preset name (`Last 30 days`), not a raw from–to string. Chart and table follow that window. Result is `Ok` on a good write, or `Failed` / the real error when it did not. Chart dates use the same language as the When column; the page-count axis stays on whole numbers. Flatpack's ApexCharts pin still paints `0.0` when `decimalsInFloat` is `0`, so the dummy host wraps that pin to label ticks `0`, `1`, `2`. Coverage extra-info breaks the count down by type and warns when the list heads toward 50,000 URLs. Empty space is fine. There is no vanity “total URLs ever” card.

Admin chrome puts Accessible avatars in the PageNav right slot (`recording_studio_accessible_avatars` on the admin root). Configure `avatar_resolver` so people resolve to a Flatpack avatar group; the helper falls back to + Access only when nobody resolves. Do not put Sign out or Root Switchable in that slot.

## Operations metrics

Sitemaps registers site-wide metrics about the most recent build. The host exposes them once:

```ruby
RecordingStudioMetrics::Api.register!(api: :operations)
```

Staff with AdminRoot `:view` (the Build history check, `RecordingStudioSitemaps::Api::Access.can_view?`) can read:

| Path | Type / unit | Value |
| --- | --- | --- |
| `GET /recording_studio_api/apis/operations/v1/metrics/sitemaps/last_build_status` | breakdown | One row keyed `success` or `error` |
| `GET /recording_studio_api/apis/operations/v1/metrics/sitemaps/last_build_age` | scalar / `seconds` | Seconds since the newest `built_at` |
| `GET /recording_studio_api/apis/operations/v1/metrics/sitemaps/last_build_url_count` | scalar / `count` | `url_count` of that build (0 when it failed) |

All three read the newest `GenerationLog` (any result) and are empty before the first build. They are point-in-time values, so they take no `from` / `to` / `interval`, no `group_by`, and no filters, and they skip the Metrics cache.

## Dummy host

`test/dummy/` is a host that proves the gem. It is not the product.

Dummy credentials (`test/dummy/config/credentials.yml.enc`) are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or put that key in `test/dummy/config/master.key` (gitignored). Keep the encrypted file; do not generate a per-repo dummy key.

Authenticated dummy pages use Recording Studio's shared default layout (`UsesDefaultLayout` / `recording_studio/default_layout`) so back/close chrome and Flatpack alerts come from core. Dummy HTML uses Flatpack's `data-theme="rounded"`. The host default-layout head loads Flatpack CSS only — Sign out and Root Switchable stay off the PageNav right slot. Dummy sets `avatar_resolver` and overrides Admin’s section grid to Flatpack `cols: 4` so the four Sitemaps cards share one equal-width row.

Dummy kit pins:

| Gem | Pin |
|-----|-----|
| Recording Studio | `v4.6.0` |
| Accessible | `v0.18.0` |
| Admin | `v2.3.0` |
| Publishable | `v0.8.0` |
| Root Switchable | `v0.9.0` |
| Metrics | `v0.3.1` |
| Trashable | `v0.10.0` |
| Cache | `v0.5.0` |
| FlatPack | `v0.1.207` |

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seed creates one findable page and one published page hidden from search. During seed it rebuilds after the first page, again after a second findable page, then after that page is hidden — so Index size has a short honest history. Coverage still ends at 1/2. Sign-in details live in the dummy README. After sign-in, switch the current root to Admin before opening `/admin/sections/sitemaps` or `/admin/screens/build_history`.

## Cloud Agent boot

Cloud Agent Builds run `.cursor/install.sh`, then `.cursor/fetch-skills.sh`.
The install hook provisions a cold image. On a warm snapshot it skips apt,
ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are
already usable. If `RAILS_MASTER_KEY` is set, install writes gitignored
`test/dummy/config/master.key` so dummy credentials decrypt. Fetch-skills
always runs last. `.cursor/start.sh` starts PostgreSQL on each boot. Rebuild
with Draft off to load a new pack. See
[Cursor skills in Cloud Agents](docs/cursor-skills.md).

## Internationalization

Rebuild flashes use Rails I18n under `recording_studio.sitemaps.flashes.*`. English ships only in `config/locales/en.yml` — call sites do not pass English `default:`. Rails engines load `config/locales` automatically (no extra `i18n.load_path` initializer). Hosts override by adding the same keys under `recording_studio.sitemaps` in their own `config/locales`; a host’s translations take precedence over the engine’s. This gem does not depend on `recording_studio_internationalization`, and it never shipped a top-level `recording_studio_sitemaps.*` locale namespace.

Admin DSL values (titles, link text, chart titles, column titles, subtitles, widget title/info/link_label) stay main’s English string literals. Public Admin helpers (`last_build_line`, `coverage_info`, `findable_items`, `missing_items`, `index_size_series`), `Exclusions` reason strings, Admin table cell values (`Ok` / `Failed`), and persisted generation-log errors stay English literals. Generator CLI text and developer-facing messages stay English. See `UPGRADING.md`.

## Out of scope

Image, news, and video sitemaps, search-engine ping, robots.txt, user-facing sitemap UI, JSON API, Embeddable, and Support or Press kit special cases.

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
