# frozen_string_literal: true

require_relative "lib/recording_studio_sitemaps/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_sitemaps"
  spec.version     = RecordingStudioSitemaps::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_sitemaps"
  spec.summary     = "Public sitemap.xml for Recording Studio hosts"
  spec.description = "A public /sitemap.xml of Publishable indexable URLs, with generation " \
                     "logs and Admin last-build / excluded URL views. This slice ships the " \
                     "engine identity and host pins, not XML yet."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
  spec.add_dependency "recording_studio_accessible", "~> 0.6"
end
