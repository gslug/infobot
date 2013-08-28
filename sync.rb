#!/usr/bin/env ruby

require_relative 'infobot'

require 'pry'

# Initialize
options = {
  calendar_feed: 'http://www.google.com/calendar/ical/kvalhe.im_59rdgfook15n7enhoaii5ps5i0%40group.calendar.google.com/public/basic.ics',
  file_builds_path: './file_builds',
  file_templates_path: './file_templates',
  mediawiki_endpoint: 'http://gslug.org/api.php',
  mediawiki_password: ENV['MW_PASSWORD'],
  mediawiki_username: ENV['MW_USERNAME'],
  meeting_regex: /GSLUG Monthly Meeting/,
  wiki_pages_path: './wiki_pages'
}
infobot = InfoBot.new(options)

# Sync
infobot.build_static_files!
infobot.update_wiki_templates!