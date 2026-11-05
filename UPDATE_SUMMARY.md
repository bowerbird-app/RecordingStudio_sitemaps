# Update summary

0.8.1 keeps the 0.8.0 POST Rebuild and empty sitemap-on-miss behavior. Failed writes still show `Failed` in Admin and no longer store a message on the generation log.

0.8.0 keeps the 0.7.0 core floor (`recording_studio >= 6.3.0`, Admin `v2.8.0`) and makes Rebuild POST-only. Public `/sitemap.xml` serves the last successful log or empty XML. Failed writes show `Failed` in Admin.

- `RecordingStudioSitemaps.rebuild!` is the one write path
- `/sitemap.xml` lists Publishable indexable URLs from the last successful log
- Admin shows Last build, Index size, Coverage, findable pages, and Missing. The subtitle is the last rebuild. Last build and Index size open Build history. Rebuild is a POST
- Build history uses Admin’s last-30-days date range. Result is Ok / Failed. Chart x matches the When column; y is whole page counts via Admin `integer_ticks`
- Dummy PageNav slot is Accessible avatars, not Sign out or a root switcher
- Dummy default-layout head loads Flatpack CSS only
- Dummy pins Recording Studio `v6.3.0`, Accessible `v0.24.1`, Admin `v2.8.0`, Publishable `v0.13.0`, Root Switchable `v0.11.5`, Metrics `v0.7.2`, Trashable `v0.12.2`, Logs `v0.7.3`, Cache `v0.6.2`, and FlatPack `v0.1.341`
