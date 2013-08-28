require 'erb'
require 'icalendar'
require 'media_wiki'
require 'pathname'
require 'open-uri'
require 'tilt'

class InfoBot
  ERB_OPTIONS = {trim: '-'}

  def initialize options = []
    @options ||= options
  end

  def build_static_files!
    static_files.each do |static_file|
      template = Tilt.new(static_file.path, ERB_OPTIONS)
      output = template.render(self)

      IO.write static_file.destination_path, output
    end
  end

  def next_meeting_end
    @_next_meeting_end ||= begin
      raise 'No next meeting found.' unless next_meeting

      next_meeting.dtend.to_time.getlocal
    end
  end

  def next_meeting_location
    @_next_meeting_location ||= begin
      raise 'No next meeting found.' unless next_meeting

      location = next_meeting.location

      location unless location.empty?
    end
  end

  def next_meeting_start
    @_next_meeting_start ||= begin
      raise 'No next meeting found.' unless next_meeting

      next_meeting.dtstart.to_time.getlocal
    end
  end

  def update_wiki_templates!
    wiki_pages.each do |wiki_page|
      template = Tilt.new(wiki_page.path, ERB_OPTIONS)
      output = template.render(self)

      mediawiki.edit wiki_page.name, output, bot: true
    end
  end

  private

  def build_path
    @_build_path ||= Pathname.new(@options['paths']['file_builds'])
  end

  def calendar
    @_calendar ||= begin
      calendars = open(@options['calendar']['feed_url']) do |file|
        Icalendar.parse(file)
      end

      calendars.first
    end
  end

  def mediawiki
    @_mediawiki ||= begin
      gateway = MediaWiki::Gateway.new(@options['mediawiki']['endpoint'])
      gateway.login @options['mediawiki']['username'],
                    @options['mediawiki']['password']

      gateway
    end
  end

  def next_meeting
    @_next_meeting ||= begin
      meeting_regex = Regexp.new(@options['calendar']['meeting_regex'])

      calendar.events.select { |event|
        event.summary =~ meeting_regex &&
        event.dtstart > DateTime.now
      }.sort { |a, b|
        a.dtstart <=> b.dtstart
      }.first
    end
  end

  def static_files
    @_static_files ||= begin
      paths = Dir.glob(File.join(@options['paths']['file_templates'], '*.erb'))

      paths.map do |path|
        StaticFile.new(path, build_path)
      end
    end
  end

  def wiki_pages
    @_wiki_pages ||= begin
      paths = Dir.glob(File.join(@options['paths']['wiki_pages'], '*.wiki.erb'))

      paths.map do |path|
        WikiPage.new(path)
      end
    end
  end
end

class StaticFile
  def initialize path, build_path
    @build_path ||= build_path
    @pathname ||= Pathname.new(path)
  end

  def destination_path
    @_destination_path ||= begin
      @build_path + @pathname.basename('.erb')
    end
  end

  def path
    @_path ||= @pathname.to_s
  end
end

class WikiPage
  def initialize path
    @pathname ||= Pathname.new(path)
  end

  def name
    @_name ||= @pathname.basename('.wiki.erb').to_s
  end

  def path
    @_path ||= @pathname.to_s
  end
end