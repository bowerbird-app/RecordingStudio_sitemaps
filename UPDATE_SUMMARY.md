# Update summary

0.8.0 keeps the 0.7.0 Admin / FlatPack `integer_ticks` charts and tightens Rebuild plus failed-build handling.

- `RecordingStudioSitemaps.rebuild!` is the one write path
- Admin Rebuild is POST `/recording_studio_sitemaps/rebuild` with CSRF
- `/sitemap.xml` lists Publishable indexable URLs
- Admin shows Last build, Index size, Coverage, findable pages, and Missing. The subtitle is the last rebuild. Last build and Index size open Build history
- Build history Result is Ok / Failed. Exception text is logged, not stored or shown
- Dummy PageNav slot is Accessible avatars, not Sign out or a root switcher
- Dummy default-layout head loads Flatpack CSS only
- Dummy pins Recording Studio `v6.3.0`, Accessible `v0.24.1`, Admin `v2.8.0`, Publishable `v0.13.0`, Root Switchable `v0.11.4`, Metrics `v0.7.2`, Trashable `v0.12.2`, Logs `v0.7.3`, Cache `v0.6.2`, and FlatPack `v0.1.341`
