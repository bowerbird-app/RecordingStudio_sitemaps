# Recording Studio Sitemaps

A public `/sitemap.xml` of the pages people can find. Sources say what to offer. Filters say what to leave out. Generation logs remember when the list was written. Admin lists what is in the sitemap and which filter held a URL back.

This gem owns the XML list, the build log, and the Admin view of that list. It does not know about embargoes, press kits, press centers, access rules, or trash. Those gems register a source or a filter from their own code. Publishable still owns per-page search tags. Do not treat this as a second SEO gem.

## What is included

The engine registers one source, `:publishable`. It asks each recordable type that responds to `.indexable` for rows, in batches, and turns each row into an entry. Hosts that only use Publishable keep the same sitemap with no setup. A host or gem can unregister `:publishable` and replace it.

- `loc` is the canonical override when set, otherwise the public URL, joined onto `public_base_url` when it is only a path
- `lastmod` is the publish time
- `changefreq` and `priority` are written only when a source sets them. The Publishable source does not.

## Sources and filters

A source offers entries. A filter sees every entry from every source and can veto it. Built-in checks run first, then registered filters, in registration order. The first veto wins. Later filters are not called for that entry.

An entry has `loc` and `lastmod`. `changefreq` and `priority` are optional. Admin also reads `title`, `type`, and `recording` when the source has them.

Register from a host initializer, or from a gem engine initializer, after this gem has loaded. Re-registering a name replaces that block and keeps its place. `unregister_source` and `unregister_filter` remove one.

```ruby
# config/initializers/recording_studio_sitemaps.rb
# or an engine initializer in the gem that owns the rule

RecordingStudioSitemaps.register_filter(:embargo) do |entry|
  next true if entry.recording.blank?

  Embargo.blocks_public?(entry.recording) ? "Under embargo" : true
end

RecordingStudioSitemaps.register_source(:marketing_pages) do |batch|
  batch << RecordingStudioSitemaps::Entry.new(
    loc: "https://www.example.com/pricing",
    lastmod: Date.new(2026, 1, 1),
    changefreq: "monthly",
    priority: 0.4,
    title: "Pricing",
    type: "Page"
  )
end
```

Returning an array or an Enumerator from the block works too, if the block never calls the batch sink. Prefer the sink, and yield batches, so a later sitemap index can split at 50,000 URLs without loading every row.

A filter returns `true` to keep the entry. `false` and `nil` withhold it, and Admin shows the filter's name. A String withholds it, and Admin shows that reason. Any other return value keeps the entry.

Built-in checks are not in the filter registry, so they cannot be removed:

- `:absolute_url` drops a blank loc or a loc that is not an absolute http(s) URL. Reason: "Not an absolute URL".
- `:public_host` drops a loc whose host is not `public_base_url`'s host, ignoring scheme and letter case. Reason: "Off the public host". When `public_base_url` has no host, this check does not run.

### Fail closed

A filter that raises drops that entry, logs the exception, and the rebuild continues. The entry is never written. Admin shows "Filter failed" for that filter. The exception text stays in the server log.

A source that raises aborts the rebuild. Entries already streamed from that source, or from earlier sources, are thrown away. The generation log is `Failed`. `/sitemap.xml` keeps serving the last successful log. A partial list must not silently replace a good sitemap.

### What other gems register

Register from the gem that owns the rule. This gem will not call into those gems.

- A visibility filter, for embargo or for access restrictions, that returns `false` or a reason when the public should not see `entry.recording`
- A source for URLs this gem does not know about, such as press kits or a static marketing page

There is one sitemap for the public host, not one per workspace. `/sitemap.xml` is logged-out and has no actor. It serves the last successful generation log. When there is no successful log, it returns an empty urlset and does not rebuild. If the findable URL count heads toward 50,000, Admin warns. This slice does not split into a sitemap index.

Sitemap rows are not recordings. They are derived and can be rebuilt. Each rebuild writes a **log** (when, count, errors). Admin reads those logs.

## Domain action

`RecordingStudioSitemaps.rebuild!(source:)` is the only write path. Publish/unpublish hooks, the Admin Rebuild POST, and the operations API rebuild all call it. Admin Rebuild is POST-only with CSRF.

```ruby
RecordingStudioSitemaps.rebuild!(source: :admin)
```

## Install

```ruby
# Gemfile
gem "recording_studio", "~> 7.8", github: "bowerbird-app/RecordingStudio", tag: "v7.8.0"
gem "recording_studio_accessible", "~> 0.58", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.58.0"
gem "recording_studio_admin", "~> 2.20", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.20.0"
gem "recording_studio_logs", "~> 0.9", github: "bowerbird-app/RecordingStudio_logs", tag: "v0.9.0"
gem "recording_studio_metrics", "~> 0.10", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.10.0"
gem "recording_studio_publishable", "~> 1.5", github: "bowerbird-app/RecordingStudio_publishable", tag: "v1.5.0"
gem "recording_studio_trashable", "~> 1.3", github: "bowerbird-app/RecordingStudio_trashable", tag: "v1.3.0", require: false
gem "recording_studio_api", "~> 1.21", github: "bowerbird-app/RecordingStudio_api", tag: "v1.21.2", require: false
gem "recording_studio_icons", "~> 0.5", github: "bowerbird-app/RecordingStudio_icons", tag: "v0.5.0", require: false
gem "recording_studio_moveable", "~> 6.1", github: "bowerbird-app/RecordingStudio_moveable", tag: "v6.1.0", require: false
gem "flat_pack", "~> 0.2", github: "bowerbird-app/flatpack", tag: "v0.2.0"
gem "recording_studio_sitemaps", github: "bowerbird-app/RecordingStudio_sitemaps"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", ">= 7.0", "< 8.0"
gem "recording_studio_accessible", ">= 0.44.0", "< 2.0"
gem "recording_studio_admin", ">= 2.16.0", "< 3.0"
gem "recording_studio_metrics", ">= 0.9.0", "< 2.0"
gem "recording_studio_publishable", ">= 0.18.1", "< 2.0"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_sitemaps:install
bin/rails generate recording_studio_sitemaps:migrations
bin/rails db:migrate
```

Hosts MUST run the Recording Studio 7.4, 7.5 and 7.7 migrations if they have not. flat_pack 0.2.0 is supported; hosts moving to 0.2 must remove the manual `flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller registration.

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

The Sitemaps section is five cards in a four-column row (the fifth wraps), then Open sitemap / Rebuild. Rebuild is a POST. The subtitle is the last rebuild (`Last built 22 Aug 2026, 02:19` — same date language as the history table).

- **Last build** — how long ago the newest write was, from `RecordingStudioMetrics` `sitemaps.last_build_age` (seconds since `GenerationLog.built_at`, shown as time ago in words). The card is a link to **Build history**
- **Index size** — how many pages made the sitemap each rebuild, from the last 30 days of generation logs. The card is a link to **Build history** (`context.admin_screen_path("build_history")`)
- **Coverage** — entries that passed filters, over entries sources offered, as a progress bar
- **In the sitemap** — each accepted entry, with its title and type
- **Missing** — each entry a filter or built-in check held back, with the filter and the reason, plus any type with none in the sitemap

Do not mark any of those widgets `view_variant: :compact`. Compact cards render on their own Admin row and shrink the others.

**Build history** is a child Admin screen: the same log as a line/area chart plus a table of when / pages / result. It uses Admin’s standard `filter :date_range, field: :built_at, default: :last_30_days`. Admin’s DateRangeInput hash preset (`days: 31`) makes the trigger show `Last 30 days`, not a raw from–to string. Chart and table follow that window. Result is `Ok` on a good write, or `Failed` when it did not. Exception text stays in the server log, not the Admin table. Chart dates use the same language as the When column; the page-count axis stays on whole numbers through Admin / FlatPack `integer_ticks`. Do not pin `apexcharts` to `recording_studio_sitemaps/apexcharts.js` — that wrapper is deprecated. Coverage extra-info breaks the count down by type and warns when the list heads toward 50,000 URLs. Empty space is fine. There is no vanity “total URLs ever” card.

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

## Operations rebuild

When Recording Studio API is loaded and the host has an `:operations` API, Sitemaps registers one POST. It does not gemspec-depend on `recording_studio_api`.

| Path | Action |
| --- | --- |
| `POST /recording_studio_api/apis/operations/v1/sitemaps/rebuild` | `RecordingStudioSitemaps.rebuild!(source: :api)` |

Staff with AdminRoot `:view` (`RecordingStudioSitemaps::Api::Access.can_view?`) can call it. That is the same Accessible check as Admin Rebuild HTML. A token whose root is not Admin gets `404`. Last-build metrics stay read-only and are unchanged.

## Dummy host

`test/dummy/` is a host that proves the gem. It is not the product.

Dummy credentials (`test/dummy/config/credentials.yml.enc`) are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or put that key in `test/dummy/config/master.key` (gitignored). Keep the encrypted file; do not generate a per-repo dummy key.

Authenticated dummy pages call `recording_studio_layout` and use Recording Studio's shared default layout so back/close chrome and Flatpack alerts come from core. Dummy HTML uses Flatpack's `data-theme="rounded"`. The host default-layout head loads Flatpack CSS only — Sign out and Root Switchable stay off the PageNav right slot. Dummy sets `avatar_resolver` and overrides Admin’s section grid to Flatpack `cols: 4` so the four Sitemaps cards share one equal-width row.

Dummy kit pins:

| Gem | Pin |
|-----|-----|
| Recording Studio | `~> 7.8` (`v7.8.0`) |
| Accessible | `~> 0.58` (`v0.58.0`) |
| Admin | `~> 2.20` (`v2.20.0`) |
| Publishable | `~> 1.5` (`v1.5.0`) |
| Root Switchable | `~> 0.17` (`v0.17.0`) |
| Metrics | `~> 0.10` (`v0.10.0`) |
| Trashable | `~> 1.3` (`v1.3.0`) |
| Logs | `~> 0.9` (`v0.9.0`) |
| Moveable | `~> 6.1` (`v6.1.0`) |
| Cache | `~> 0.8` (`v0.8.0`) |
| API | `~> 1.21` (`v1.21.2`; Publishable requires it; dummy mounts it) |
| Icons | `~> 0.5` (`v0.5.0`) |
| FlatPack | `~> 0.2` (`v0.2.0`) |

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seed creates one findable page and one published page hidden from search. During seed it rebuilds after the first page, again after a second findable page, then after that page is hidden — so Index size has a short honest history. The hidden page is not offered by the Publishable source, so Coverage ends at 1/1 unless a filter holds an offered URL back. Sign-in details live in the dummy README. After sign-in, switch the current root to Admin before opening `/admin/sections/sitemaps` or `/admin/screens/build_history`.

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

Admin DSL values (titles, link text, chart titles, column titles, subtitles, widget title/info/link_label) stay main’s English string literals. Public Admin helpers (`last_build_line`, `last_build_value`, `coverage_info`, `findable_items`, `missing_items`, `index_size_series`), `Exclusions` reason strings, and Admin table cell values (`Ok` / `Failed`) stay English literals. Failed writes store `Failed` and log the exception server-side. Generator CLI text and developer-facing messages stay English. See `UPGRADING.md`.

## Out of scope

Image, news, and video sitemaps, search-engine ping, a sitemap index split, robots.txt, and user-facing sitemap UI. Press kits and other products register their own source. This gem does not special-case them.

This README is the product. The dummy app is a host that proves the gem.
