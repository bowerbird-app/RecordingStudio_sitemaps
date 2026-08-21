# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Dummy signed-in home is a workspace page slice inside Recording Studio default-layout chrome (back/close, workspace switcher, and Sign out). Dummy Tailwind also scans mise gem paths so PageNav icon buttons keep their size. Dummy-only; no version bump.

## [0.1.0] - 2026-08-21

First product release of Recording Studio Sitemaps. A public `/sitemap.xml` of Publishable indexable URLs, with generation logs and Admin last-build / excluded URL views, is the product direction. This slice ships the gem identity and Recording Studio 4.2 host pins only. It does not emit XML, logs, Admin, a generator, or Publishable wiring.

### Added
- Gemspec dependencies `recording_studio`, `~> 4.2` and `recording_studio_accessible`, `~> 0.6`

### Changed
- Renamed the engine from the addon template to `recording_studio_sitemaps`
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.1`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated pages use Recording Studio's default layout chrome and load Flatpack CSS/JS (including `flat_pack/application` and Turbo). Devise sign-in keeps its own layout and still loads those assets. Root Switchable sits in the default-layout chrome.

### Removed
- Leftover template identity in the public README and gemspec
- Dummy starter docs pages
- Template example capability mixin
- Engine sample home controller

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v4.2.0` and Accessible `v0.6.1`
- Declare `spec.add_dependency "recording_studio", "~> 4.2"` and `spec.add_dependency "recording_studio_accessible", "~> 0.6"`
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Do not expect `/sitemap.xml`, Admin, generation logs, or Publishable wiring from this version

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_sitemaps/releases/tag/v0.1.0
