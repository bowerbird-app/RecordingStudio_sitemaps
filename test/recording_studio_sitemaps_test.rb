# frozen_string_literal: true

require "test_helper"

class RecordingStudioSitemapsTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.1.0", ::RecordingStudioSitemaps::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioSitemaps::Engine
  end

  def test_gemspec_pins_recording_studio_and_accessible
    gemspec = File.read(File.expand_path("../recording_studio_sitemaps.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.6"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.1"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_publishable"'
    refute_includes gemspec, 'spec.add_dependency "recording_studio_admin"'
    refute_includes gemspec, "internal template"
    assert_includes gemspec, "https://github.com/bowerbird-app/RecordingStudio_sitemaps"
    refute_includes gemspec, "https://github.com/bowerbird-app/recording_studio_sitemaps"
    refute_includes gemspec, "RecordingStudio_gem_template"
  end

  def test_dummy_gemfile_pins_verified_4x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.133"'
    refute_includes gemfile, "recording_studio/v3.0.0"
    refute_includes gemfile, 'tag: "v0.6.0"'
    refute_includes gemfile, 'tag: "v0.1.134"'
    refute_includes gemfile, 'tag: "0.3.1"'
  end

  def test_does_not_ship_copied_core_hooks_or_template_leftovers
    refute File.exist?(File.expand_path("../lib/recording_studio_sitemaps/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_sitemaps/services/base_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_sitemaps/services/example_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_sitemaps/capabilities/example.rb", __dir__))
    refute File.exist?(File.expand_path("../app/controllers/recording_studio_sitemaps/home_controller.rb", __dir__))
  end

  def test_dummy_app_uses_recording_studio_default_layout
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)

    assert_includes controller_source, "include RecordingStudio::UsesDefaultLayout"
    assert_includes controller_source, '"recording_studio/default_layout"'
    assert_includes controller_source, "return \"application\" if devise_controller?"
    refute_includes controller_source, "flat_pack_sidebar"
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, '<html data-theme="rounded">'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "FlatPack::Alert::Component"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"
  end

  def test_dummy_pins_turbo_and_loads_flatpack_js
    application_js = File.read(File.expand_path("dummy/app/javascript/application.js", __dir__))
    importmap = File.read(File.expand_path("dummy/config/importmap.rb", __dir__))

    assert_includes application_js, 'import "@hotwired/turbo-rails"'
    refute_includes application_js, 'import { application } from "controllers/application"'
    assert_includes importmap, 'pin "@hotwired/turbo-rails", to: "turbo.min.js"'
  end

  def test_dummy_default_layout_head_loads_flatpack_and_root_switch_chrome
    default_layout_head = File.read(
      File.expand_path("dummy/app/views/recording_studio/_default_layout_head.html.erb", __dir__)
    )

    assert_includes default_layout_head, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes default_layout_head, "recording_studio_root_switch_dropdown"
    assert_includes default_layout_head, "recording_studio_page_nav_right"
    assert_includes default_layout_head, "Sign out"
    assert_includes default_layout_head, "destroy_user_session_path"
    refute_includes default_layout_head, "dummy_page_nav"
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))

    assert_includes tailwind_source, "../../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}"
    assert_includes tailwind_source, "flatpack-*/app/components/**/*.{rb,erb}"
    assert_includes tailwind_source, "../../../vendor/bundle/**/recording_studio/app/views/**/*.erb"
    assert_includes tailwind_source, "recordingstudio-*/app/views/**/*.erb"
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"
  end

  def test_recording_studio_keeps_strict_recordable_declarations_enabled
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, "config.recordable_types = [ \"Workspace\", \"Folder\", \"Page\" ]"
    assert_includes initializer_source, 'config.app_name = "Dummy host"'
    refute_includes initializer_source, "Addon Template"
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to prove Recording Studio Sitemaps"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "redirects to `/`"
    refute_includes readme_source, "flat_pack_sidebar"
    refute_includes readme_source, "/docs/"
  end

  def test_product_readme_is_the_sitemaps_guide
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "Recording Studio Sitemaps"
    assert_includes readme, "v4.2.0"
    assert_includes readme, "v0.6.1"
    assert_includes readme, "v0.1.133"
    assert_includes readme, "does not ship `/sitemap.xml`"
    refute_includes readme, "v3 declarations"
    refute_includes readme, "RecordingStudio v3"
    refute_includes readme, "ExampleService"
    refute_includes readme, "internal template"
    refute_includes readme, "admin@admin.com"
    refute_includes readme, "recording_studio/v3.0.0"
  end

  def test_dummy_home_page_is_a_workspace_slice_not_a_landing
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)
    controller_source = File.read(File.expand_path("dummy/app/controllers/home_controller.rb", __dir__))
    kwargs_source = File.read(
      File.expand_path("dummy/config/initializers/recording_studio_page_nav_kwargs.rb", __dir__)
    )

    assert_includes controller_source, "current_root_recordable"
    assert_includes view_source, "recording_studio_page_nav"
    assert_includes view_source, "page_nav_back_url:"
    assert_includes view_source, "page_nav_anchor_url:"
    assert_includes view_source, "FlatPack::PageTitle::Component"
    assert_includes kwargs_source, "anchor_href"
    assert_includes kwargs_source, "FlatPack::PageNav::Component.prepend"
    refute_includes view_source, "Dummy host"
    refute_includes view_source, "proves the"
    refute_includes view_source, "admin@admin.com"
    refute_includes view_source, "Sitemap XML"
    refute_includes view_source, "FlatPack::Card::Component"
    refute_includes view_source, "dummy_page_nav"
    refute_includes view_source, "Sign out"
    refute_includes view_source, "recording_studio_root_switch_dropdown"
    refute_includes view_source, "Template Demo"
    refute_includes view_source, "FlatPack::Breadcrumb::Component"
  end

  def test_dummy_does_not_ship_starter_docs
    refute File.exist?(File.expand_path("dummy/app/controllers/docs_controller.rb", __dir__))
    assert_empty Dir[File.expand_path("dummy/app/views/docs/**/*.erb", __dir__)]
  end

  def test_engine_does_not_ship_a_home_view
    view_path = File.expand_path("../app/views/recording_studio_sitemaps/home/index.html.erb", __dir__)

    refute File.exist?(view_path)
  end

  def test_slice_does_not_claim_sitemap_xml_or_admin
    refute File.exist?(File.expand_path("../app/controllers/recording_studio_sitemaps/sitemaps_controller.rb", __dir__))
    refute File.exist?(File.expand_path("../app/views/recording_studio_sitemaps/sitemaps/show.xml.erb", __dir__))
    engine_routes = File.read(File.expand_path("../config/routes.rb", __dir__))
    refute_includes engine_routes, "sitemap.xml"
    refute_includes engine_routes, "admin"
  end
end
