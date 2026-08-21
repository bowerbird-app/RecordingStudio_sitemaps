# Project Guidelines

## Architecture

- This repository is the Recording Studio Sitemaps Rails engine (`RecordingStudioSitemaps`).
- Preserve engine namespace isolation under `RecordingStudioSitemaps`.
- Treat `docs/gem_template/` as architectural reference material. The top-level README is the product; the dummy app is a host that proves the gem.
- Keep changes small and scoped. Do not add `/sitemap.xml`, Admin, generation logs, or Publishable wiring unless the request asks for that slice.

## UI Conventions

- FlatPack is the default UI system for this repo.
- The approved UI reference is the live FlatPack demo app at https://flatpack.bowerbird.io/ when you need to inspect current shared components and patterns.
- Start with the FlatPack demo app's table of components to quickly discover available UI building blocks before inventing custom markup.
- When editing ERB views, prefer `render FlatPack::...` components over custom HTML when an equivalent component exists.
- Prefer standardized and testable FlatPack ViewComponents over one-off ERB markup or custom JavaScript.
- Keep custom markup limited to semantic wrappers or content that FlatPack does not cover.

## Testing

- The standard root validation command is `bundle exec rake test` from the repository root.
- If a change affects dummy app boot, assets, or migrations, also validate the dummy app setup the same way CI does (`bundle exec rake test:all`).
- Add focused regression tests for engine hooks, generators, Recording Studio integration points, and host wiring.

## Repo Conventions

- Keep internal dependency assumptions intact unless the request explicitly asks to change private gem infrastructure.
- Update docs when product behavior or setup steps change.
- Prefer existing generator, service, and hook patterns over introducing a parallel abstraction.
