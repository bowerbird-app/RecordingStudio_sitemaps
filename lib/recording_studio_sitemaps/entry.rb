# frozen_string_literal: true

module RecordingStudioSitemaps
  # One URL a source offers to the sitemap.
  #
  # `loc` and `lastmod` are the sitemap fields. `changefreq` and `priority`
  # are optional and are written only when a source sets them. `title` and
  # `type` are for Admin. `recording` is the tree row when the source has one.
  Entry = Struct.new(
    :loc,
    :lastmod,
    :changefreq,
    :priority,
    :title,
    :type,
    :recording,
    keyword_init: true
  )
end
