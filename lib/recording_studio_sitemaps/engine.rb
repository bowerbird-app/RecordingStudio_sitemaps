# frozen_string_literal: true

module RecordingStudioSitemaps
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioSitemaps

    # Run before_initialize hooks
    initializer "recording_studio_sitemaps.before_initialize", before: "recording_studio_sitemaps.load_config" do |_app|
      RecordingStudioSitemaps.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_sitemaps.load_config" do |app|
      yaml_path = RecordingStudioSitemaps::Engine.yaml_config_path(app)
      if yaml_path && app.respond_to?(:config_for)
        yaml = app.config_for(:recording_studio_sitemaps)
        RecordingStudioSitemaps.configuration.merge!(yaml) if yaml.respond_to?(:each)
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_sitemaps)
        xcfg = app.config.x.recording_studio_sitemaps
        RecordingStudioSitemaps.configuration.merge!(xcfg.to_h) if xcfg.respond_to?(:to_h)
      end

      RecordingStudioSitemaps.configuration.hooks.run(:on_configuration, RecordingStudioSitemaps.configuration)
    end

    # Run after_initialize hooks
    initializer "recording_studio_sitemaps.after_initialize", after: "recording_studio_sitemaps.load_config" do |_app|
      RecordingStudioSitemaps.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_sitemaps.publish_hooks" do
      config.to_prepare do
        RecordingStudioSitemaps::PublishHooks.install!
      end
    end

    initializer "recording_studio_sitemaps.admin" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)

      config.to_prepare do
        RecordingStudioSitemaps::Admin.register!
        RecordingStudioSitemaps::Metrics.register!
      end
    end

    class << self
      def yaml_config_path(app)
        return unless app.respond_to?(:root) && app.root

        %w[recording_studio_sitemaps.yml recording_studio_sitemaps.yml.erb].each do |name|
          path = File.join(app.root.to_s, "config", name)
          return path if File.exist?(path)
        end

        nil
      end
    end
  end
end
