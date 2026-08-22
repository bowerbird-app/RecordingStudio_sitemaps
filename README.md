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
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.1"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.2.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.133"
gem "recording_studio_sitemaps", github: "bowerbird-app/RecordingStudio_sitemaps"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.6"
gem "recording_studio_admin", "~> 2.0"
gem "recording_studio_publishable", "= 0.2.0"
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

The Sitemaps section is Coverage plus two lists, an Index size chart, then Open sitemap / Rebuild:

- **Coverage** — findable pages over published Publishable pages, as a progress bar
- **In the sitemap** — each findable page, with its type
- **Missing** — each published page that missed the list and why, plus any Publishable type with none in the sitemap
- **Index size** — how many pages made the sitemap each rebuild, from generation logs. Opens **Build history**

**Build history** is a child Admin screen: the same log as a line/area chart plus a table of when / pages / result. Result is `Ok` on a good write, or `Failed` / the real error when it did not. Chart dates use the same language as the When column; the page-count axis stays on whole numbers. Last build time and status sit as a quiet line next to Rebuild and open that screen. Coverage extra-info breaks the count down by type and warns when the list heads toward 50,000 URLs. Empty space is fine. There is no vanity “total URLs ever” card.

## Dummy host

`test/dummy/` is a host that proves the gem. It is not the product.

Authenticated dummy pages use Recording Studio's shared default layout (`UsesDefaultLayout` / `recording_studio/default_layout`) so back/close chrome and Flatpack alerts come from core. Dummy HTML uses Flatpack's `data-theme="rounded"`. The host default-layout head loads Flatpack CSS only — Sign out and Root Switchable stay off the PageNav right slot.

Dummy kit pins:

| Gem | Pin |
|-----|-----|
| Recording Studio | `v4.2.0` |
| Accessible | `v0.6.1` |
| Admin | `2.0.1` |
| Publishable | `v0.2.0` |
| Root Switchable | `v0.5.0` |
| FlatPack | `v0.1.133` |

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Seed creates one findable page and one published page hidden from search. During seed it rebuilds after the first page, again after a second findable page, then after that page is hidden — so Index size has a short honest history. Coverage still ends at 1/2. Sign-in details live in the dummy README. After sign-in, switch the current root to Admin before opening `/admin/sections/sitemaps` or `/admin/screens/build_history`.

## Out of scope

Image, news, and video sitemaps, search-engine ping, robots.txt, user-facing sitemap UI, JSON API, Embeddable, and Support or Press kit special cases.

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
