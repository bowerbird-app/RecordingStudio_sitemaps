# Update summary

Unreleased pins Accessible `~> 0.13` (tag `v0.13.0`) and Publishable `~> 0.6` (tag `v0.6.0`).

- `RecordingStudioSitemaps.rebuild!` is the one write path
- `/sitemap.xml` lists Publishable indexable URLs
- Admin shows four equal cards: Index size, Coverage, findable pages, and Missing. The subtitle is the last rebuild. Index size opens Build history
- Build history uses Admin’s last-30-days date range. The filter control shows `Last 30 days`. Result is Ok / Failed (or the error). Chart x matches the When column; y is whole page counts
- Dummy PageNav slot is Accessible avatars, not Sign out or a root switcher
- Build history is a child Admin screen of generation logs
- Dummy default-layout head loads Flatpack CSS only
- Dummy pins Accessible `v0.13.0`, Admin `v2.1.0`, Publishable `v0.6.0`, and Root Switchable `v0.6.0`
