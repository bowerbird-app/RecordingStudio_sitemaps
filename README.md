# Recording Studio Sitemaps

A public `/sitemap.xml` of the pages people can find. Built from Publishable URLs that are indexable. Generation logs and Admin will show the last build and what was left out.

This gem does not ship `/sitemap.xml`, generation logs, Admin, a generator, or Publishable wiring yet. Hosts install it next to Recording Studio 4.2.

## Install

Add the gem next to Recording Studio 4.2 and Accessible. GitHub hosting is not a reason to skip the gemspec pins.

```ruby
# Gemfile
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"
gem "recording_studio_sitemaps", github: "bowerbird-app/RecordingStudio_sitemaps"
```

```ruby
# gemspec / host Gemfile constraints
gem "recording_studio", "~> 4.2"
gem "recording_studio_accessible", "~> 0.6"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_sitemaps:install
bin/rails generate recording_studio_sitemaps:migrations
bin/rails db:migrate
```

Do not add Publishable, Admin, Support, Press kits, Attachable, API, Webhooks, Users, Billing, or Notifications for this slice.

## Dummy host

`test/dummy/` is a host that proves the gem. It is not the product.

Authenticated dummy pages use Recording Studio's shared default layout (`UsesDefaultLayout` / `recording_studio/default_layout`) so back/close chrome and Flatpack alerts come from core. Root Switchable sits in that chrome. Devise sign-in keeps `layouts/application` and still loads Flatpack CSS/JS plus Turbo.

Dummy kit pins:

| Gem | Pin |
|-----|-----|
| Recording Studio | `v4.2.0` |
| Accessible | `v0.6.1` |
| Root Switchable | `v0.5.0` |
| FlatPack | `v0.1.133` |

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

## Engine internals

`docs/gem_template/` stays as engine-internal reference from the original addon template. This README is the product.
