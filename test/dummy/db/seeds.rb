# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable,
    trashed_at: nil
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
indexable_page = Page.find_or_create_by!(title: "Getting Started")
excluded_page = Page.find_or_create_by!(title: "Staff-only notes")
admin_root = AdminRoot.find_or_create_by!(name: "Admin")

previous_actor = Current.actor
Current.actor = user

begin
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)
  admin_root_recording = RecordingStudio.root_recording_for(admin_root)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)
  indexable_page_recording = find_or_record_child.call(indexable_page, root_recording, folder_recording)
  excluded_page_recording = find_or_record_child.call(excluded_page, root_recording, folder_recording)

  if defined?(RecordingStudioAccessible)
    RecordingStudioAccessible.bootstrap_owner_access!(
      recording: admin_root_recording,
      actor: user
    )
  end

  RecordingStudioPublishable::Services::Publishables::Update.call(
    parent_recording: indexable_page_recording,
    actor: user,
    attributes: {
      slug: "getting-started",
      status: "published",
      seo_title: "Getting Started",
      seo_description: "A findable page for the public sitemap.",
      meta_robots: "index,follow"
    }
  )

  RecordingStudioPublishable::Services::Publishables::Update.call(
    parent_recording: excluded_page_recording,
    actor: user,
    attributes: {
      slug: "staff-only-notes",
      status: "published",
      seo_title: "Staff-only notes",
      seo_description: "Live, but hidden from search.",
      meta_robots: "noindex,follow"
    }
  )

  RecordingStudioSitemaps.rebuild!(source: :seed)
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: Admin root '#{admin_root.name}' with root recording ##{admin_root_recording.id}"
puts "Seeded: Findable page '#{indexable_page.title}' and excluded page '#{excluded_page.title}'"
