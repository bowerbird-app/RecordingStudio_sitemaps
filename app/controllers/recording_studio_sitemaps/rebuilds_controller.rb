# frozen_string_literal: true

module RecordingStudioSitemaps
  class RebuildsController < ::ApplicationController
    before_action :authorize_sitemaps_rebuild!

    def create
      log = RecordingStudioSitemaps.rebuild!(source: :admin)
      return redirect_to(sitemaps_admin_path, notice: rebuilt_notice) if log&.success?

      redirect_to sitemaps_admin_path, alert: rebuild_failed_alert
    end

    private

    def rebuilt_notice
      Copy.t("flashes.rebuilt", default: "Sitemap rebuilt.")
    end

    def rebuild_failed_alert
      Copy.t(
        "flashes.rebuild_failed",
        default: "Sitemap rebuild hit a snag. Check the last build."
      )
    end

    def authorize_sitemaps_rebuild!
      actor = current_admin_actor
      recording = admin_access_recording
      authorized = actor.present? && recording.present? &&
                   RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)

      head :forbidden unless authorized
    end

    def current_admin_actor
      return current_user if respond_to?(:current_user, true)

      Current.actor if defined?(Current)
    end

    def admin_access_recording
      return unless defined?(RecordingStudioAdmin)

      resolver = RecordingStudioAdmin.configuration.access_recording_resolver
      return unless resolver

      resolver.call(rebuild_admin_context)
    end

    def rebuild_admin_context
      Struct.new(:controller).new(self)
    end

    def sitemaps_admin_path
      if respond_to?(:recording_studio_admin_admin)
        recording_studio_admin_admin.section_path("sitemaps")
      else
        "/admin/sections/sitemaps"
      end
    end
  end
end
