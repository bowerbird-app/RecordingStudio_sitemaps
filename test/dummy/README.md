# Dummy host

This Rails app exists to prove Recording Studio Sitemaps in a real host. It is not the product.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus seeded folder and page recordables
- Publishable on `Page` via `RecordingStudio::Capabilities::Publishable.to`
- One findable page and one published page hidden from search
- Public `/sitemap.xml` with no sign-in
- Admin Sitemaps section gated by Accessible on an admin root
- Recording Studio default layout (back/close chrome), Flatpack CSS/JS, Turbo, and Tailwind source scanning
- `html data-theme="rounded"` on both the login layout and the default layout
- Workspace switcher and Sign out in the default-layout chrome, not a host-only shell
- Signed-in `/` as a thin workspace slice (seeded workspace title, then folders and pages)

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Layouts and assets

Authenticated pages include `RecordingStudio::UsesDefaultLayout` and render `recording_studio/default_layout`. That layout owns the back/close chrome and Flatpack flash alerts. Dummy HTML sets Flatpack's `data-theme="rounded"`.

Devise sign-in keeps `layouts/application` so the login card can stay centered. That layout still loads:

- `flat_pack/variables`
- `flat_pack/application`
- `tailwind`
- Importmap JS, including `@hotwired/turbo-rails`

The host injects `flat_pack/application`, the workspace switcher, and Sign out through `app/views/recording_studio/_default_layout_head.html.erb`. Signed-in pages set `page_nav_back_url` and `page_nav_anchor_url` so default-layout PageNav actually gets back and close. Do not put the switcher or Sign out in the home view body.

Tailwind scans dummy views plus FlatPack/Recording Studio gem paths for `vendor/bundle`, `/usr/local/bundle` (CI), and mise installs. Rebuild with `bin/rails tailwindcss:build` if back/close icon buttons look like tiny dots.

## Useful Routes

- `/` - signed-in workspace slice
- `/sitemap.xml` - public sitemap, no sign-in
- `/admin/sections/sitemaps` - Admin Sitemaps section
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the sitemaps gem boots in a host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem likely needs adjustment before reuse.

Authenticated pages use Recording Studio's shared default layout. Devise sign-in keeps `layouts/application`.
