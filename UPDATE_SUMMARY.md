# Update summary

0.6.0 pins Recording Studio `v6.3.0` (`>= 6.3.0`), Accessible `v0.23.1` (`>= 0.23.1`), Admin `v2.8.0` (`>= 2.8.0`), Publishable `v0.13.0` (`>= 0.13.0`), Metrics `v0.7.0` (`>= 0.7.0, < 1.0`), Trashable `v0.12.0`, Logs `v0.7.1`, and FlatPack `v0.1.331`.

- `RecordingStudioSitemaps.rebuild!` is the one write path
- `/sitemap.xml` lists Publishable indexable URLs
- Admin shows Last build, Index size, Coverage, findable pages, and Missing. The subtitle is the last rebuild. Last build and Index size open Build history
- Build history uses Admin’s last-30-days date range. Admin’s hash preset (`days: 31`) makes the filter control show `Last 30 days`. Result is Ok / Failed (or the error). Chart x matches the When column; y is whole page counts
- Dummy PageNav slot is Accessible avatars, not Sign out or a root switcher
- Build history is a child Admin screen of generation logs
- Dummy default-layout head loads Flatpack CSS only
- Dummy pins Recording Studio `v6.3.0`, Accessible `v0.23.1`, Admin `v2.8.0`, Publishable `v0.13.0`, Root Switchable `v0.11.0`, Metrics `v0.7.0`, Trashable `v0.12.0`, Logs `v0.7.1`, Cache `v0.6.0`, and FlatPack `v0.1.331`
