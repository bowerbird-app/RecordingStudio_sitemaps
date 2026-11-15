# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]
  config.access_actor_types += ["RecordingStudioApi::ApiClient"]

  # Site-wide admin screens (blast_radius :site) resolve only against this root.
  config.admin_root_resolver = lambda do |context: nil|
    admin_root = AdminRoot.find_by(name: "Admin")
    next unless admin_root

    RecordingStudio::Recording.kept.find_by(recordable: admin_root)
  end

  config.avatar_resolver = lambda do |access_holder|
    next unless access_holder.is_a?(User)

    email = access_holder.email.to_s.strip
    next if email.blank?

    {
      name: email.split("@").first.tr("._-", " ").squish.titleize,
      alt: email,
      href: "/users/#{access_holder.id}"
    }
  end
end
