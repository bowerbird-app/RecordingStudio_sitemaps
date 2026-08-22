# Update summary

0.2.1 ships the public sitemap, generation logs, and Admin Sitemaps section.

- `RecordingStudioSitemaps.rebuild!` is the one write path
- `/sitemap.xml` lists Publishable indexable URLs
- Admin shows Coverage, findable pages, Missing rows, and an Index size chart. The Index size card and last-build both open Build history
- Build history result is Ok / Failed (or the error). Chart x matches the When column; y is whole page counts
- Build history is a child Admin screen of generation logs
- Dummy default-layout head loads Flatpack CSS only
- Dummy pins Admin `2.0.1` and Publishable `v0.2.0`
