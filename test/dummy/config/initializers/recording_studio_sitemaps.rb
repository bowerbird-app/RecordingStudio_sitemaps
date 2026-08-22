# frozen_string_literal: true

RecordingStudioSitemaps.configure do |config|
  config.public_base_url = ENV.fetch("SITEMAP_PUBLIC_BASE_URL") do
    Rails.env.development? ? "http://localhost:3000" : "http://www.example.com"
  end
end
