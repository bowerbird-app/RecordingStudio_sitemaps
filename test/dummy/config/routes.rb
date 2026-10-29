Rails.application.routes.draw do
  devise_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioPublishable::Engine, at: "/"
  mount RecordingStudioAccessible::Engine, at: "/admin/access"
  recording_studio_admin_for :admin, at: "/admin", root_section: :sitemaps

  get "sitemap.xml", to: RecordingStudioSitemaps::SitemapsController.action(:show), as: :sitemap
  mount RecordingStudioSitemaps::Engine, at: "/recording_studio_sitemaps"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
