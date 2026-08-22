# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Flatpack Chart loads ApexCharts by the "apexcharts" pin. decimalsInFloat: 0 still
# paints 0.0 / 1.0, so wrap the CDN build and format those ticks as 0 / 1 / 2.
if defined?(RecordingStudioSitemaps::Engine)
  pin "apexcharts", to: "recording_studio_sitemaps/apexcharts.js"
end

# Pin FlatPack controllers
if defined?(FlatPack::Engine)
  pin_all_from FlatPack::Engine.root.join("app/javascript/flat_pack/controllers"), under: "controllers/flat_pack", to: "flat_pack/controllers", preload: false
  pin "flat_pack/heroicons", to: "flat_pack/heroicons.js", preload: false
  pin "recording_studio_sitemaps/flatpack_date_picker_original",
      to: "flat_pack/controllers/flatpack_date_picker_controller.js",
      preload: false
  pin "controllers/flat_pack/flatpack_date_picker_controller",
      to: "recording_studio_sitemaps/flatpack_date_picker_controller.js",
      preload: false
end
