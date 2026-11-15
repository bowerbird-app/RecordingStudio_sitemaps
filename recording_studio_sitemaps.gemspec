# frozen_string_literal: true

require_relative "lib/recording_studio_sitemaps/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_sitemaps"
  spec.version     = RecordingStudioSitemaps::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_sitemaps"
  spec.summary     = "Public sitemap.xml for Recording Studio hosts"
  spec.description = "A public /sitemap.xml built from registered sources and filters, " \
                     "with generation logs and Admin views of what was left out."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "flat_pack", ">= 0.1.331"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", ">= 7.0", "< 8.0"
  spec.add_dependency "recording_studio_accessible", ">= 0.44.0", "< 1.0"
  spec.add_dependency "recording_studio_admin", ">= 2.16.0"
  spec.add_dependency "recording_studio_metrics", ">= 0.9.0", "< 1.0"
  spec.add_dependency "recording_studio_publishable", ">= 0.18.1", "< 1.0"
end
