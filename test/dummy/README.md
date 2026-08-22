# Dummy host

This Rails app exists to prove Recording Studio Sitemaps in a real host. It is not the product.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus seeded folder and page recordables
- Publishable on `Page` via `RecordingStudio::Capabilities::Publishable.to`
- One findable page and one published page hidden from search, with a short rebuild history for Index size
- Public `/sitemap.xml` with no sign-in
- Admin Sitemaps section and Build history screen gated by Accessible on an admin root (switch the current root to Admin first)
- Recording Studio default layout (back/close chrome), Flatpack CSS/JS, Turbo, and Tailwind source scanning
- `html data-theme="rounded"` on both the login layout and the default layout
- Signed-in `/` as a thin workspace slice (seeded workspace title, then folders and pages)
- Root Switchable stays on its own page. The Admin PageNav slot is Accessible avatars (`avatar_resolver` plus `recording_studio_accessible_avatars`). Sign out and the workspace switcher are not stuffed into that slot
- Admin Sitemaps uses a Flatpack four-column widget row so Index size, Coverage, In the sitemap, and Missing stay equal

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

The dummy home stays on a workspace. Admin lives on the Admin root. Switch to **Admin** in the root switcher, then open `/admin/sections/sitemaps`. `/sitemap.xml` is public and does not need a sign-in.

## Layouts and assets

Authenticated pages include `RecordingStudio::UsesDefaultLayout` and render `recording_studio/default_layout`. That layout owns the back/close chrome and Flatpack flash alerts. Dummy HTML sets Flatpack's `data-theme="rounded"`.

Devise sign-in keeps `layouts/application` so the login card can stay centered. That layout still loads:

- `flat_pack/variables`
- `flat_pack/application`
- `tailwind`
- Importmap JS, including `@hotwired/turbo-rails`

The host injects `flat_pack/application` through `app/views/recording_studio/_default_layout_head.html.erb`. That partial loads Flatpack CSS only. Core owns back/close. Admin’s section view uses Accessible avatars in the PageNav right slot and Flatpack Grid `cols: 4` for the Sitemaps cards. Do not put Sign out, a login link, or the workspace switcher in that slot. Signed-in pages set `page_nav_back_url` and `page_nav_anchor_url` so default-layout PageNav actually gets back and close.

Tailwind scans dummy views plus FlatPack/Recording Studio gem paths for `vendor/bundle`, `/usr/local/bundle` (CI), and mise installs. Rebuild with `bin/rails tailwindcss:build` if back/close icon buttons look like tiny dots.

## Useful Routes

- `/` - signed-in workspace slice
- `/sitemap.xml` - public sitemap, no sign-in
- `/admin/sections/sitemaps` - Admin Sitemaps section (switch to the Admin root first)
- `/admin/screens/build_history` - Admin build history chart and table
- `/recording_studio_root_switchable/v1/root_switch` - workspace / Admin root switcher page
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the sitemaps gem boots in a host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem likely needs adjustment before reuse.

Authenticated pages use Recording Studio's shared default layout. Devise sign-in keeps `layouts/application`.
