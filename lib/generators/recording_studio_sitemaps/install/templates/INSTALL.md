RecordingStudioSitemaps install complete.

Next steps:

1. Set `config.public_base_url` in `config/initializers/recording_studio_sitemaps.rb` to the public host search engines should see.
2. Run `bin/rails generate recording_studio_sitemaps:migrations` and `bin/rails db:migrate`.
3. Enable Publishable on the types that should appear, with `include RecordingStudio::Capabilities::Publishable.to(...)`.
4. Enable the Admin sitemaps section on your admin root:

```ruby
recording_studio_admin_sections do
  section :sitemaps
end
```

5. Grant Accessible access on that admin root. Do not use `user.admin?`.
6. `/sitemap.xml` is public. Rebuild from Admin or after publish/unpublish uses the same `RecordingStudioSitemaps.rebuild!` action.
