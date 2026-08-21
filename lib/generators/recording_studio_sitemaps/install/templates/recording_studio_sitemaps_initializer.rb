# frozen_string_literal: true

RecordingStudioSitemaps.configure do |config|
  # Public host used when an indexable page only has a path, not a full URL.
  config.public_base_url = ENV.fetch("SITEMAP_PUBLIC_BASE_URL", "http://localhost:3000")

  # Warn in Admin when the findable URL count heads toward the 50,000 URL cap.
  # config.url_count_warning_threshold = 45_000
end
