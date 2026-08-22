===============================================================================

RecordingStudioSitemaps has been installed.

Public sitemap: /sitemap.xml
Engine rebuild: /recording_studio_sitemaps/rebuild

Next:
1. Set public_base_url in config/initializers/recording_studio_sitemaps.rb
2. Run bin/rails generate recording_studio_sitemaps:migrations && bin/rails db:migrate
3. Enable Publishable on the types that should appear
4. Enable `section :sitemaps` on your admin root and grant Accessible access
5. Rebuild Tailwind if you use it

===============================================================================
