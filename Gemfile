# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_sitemaps.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", ">= 0.1.331", github: "bowerbird-app/flatpack", tag: "v0.1.377"
gem "recording_studio", ">= 7.0", "< 8.0", github: "bowerbird-app/RecordingStudio", tag: "v7.3.0"
gem "recording_studio_accessible", ">= 0.44.0", "< 1.0",
    github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.45.1"
gem "recording_studio_admin", ">= 2.16.0", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.18.0"
gem "recording_studio_logs", github: "bowerbird-app/RecordingStudio_logs", tag: "v0.8.0"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.9.0"
gem "recording_studio_publishable", ">= 0.18.1", "< 2.0",
    github: "bowerbird-app/RecordingStudio_publishable", tag: "v1.1.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v1.0.1", require: false
# Publishable 1.1.0 gemspec requires API >= 1.1, < 2.0. These are GitHub-only.
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "v1.2.1", require: false
gem "recording_studio_icons", github: "bowerbird-app/RecordingStudio_icons", tag: "v0.4.0", require: false
gem "recording_studio_moveable", github: "bowerbird-app/RecordingStudio_moveable", tag: "v6.0.0", require: false

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
