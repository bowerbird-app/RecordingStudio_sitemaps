# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_sitemaps.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", ">= 0.1.331", github: "bowerbird-app/flatpack", tag: "v0.1.331"
gem "recording_studio", "~> 4.2", github: "bowerbird-app/RecordingStudio", tag: "v4.7.0"
gem "recording_studio_accessible", "~> 0.13", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.18.0"
gem "recording_studio_admin", "~> 2.0", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.3.0"
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.5.0"
gem "recording_studio_publishable", "~> 0.6", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.8.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.11.0", require: false

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
