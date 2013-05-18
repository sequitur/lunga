require 'rss'
require 'open-uri'
require 'erb'

class Feed

  def initialize (url)
    @url = url
  end

  def recent(cutoff)
    return [] if data == :not_available
    recent_items = data.items.select do |item|
      item.date && item.date > cutoff
    end

    recent_items.map do |item|
      Post.new(item, self)
    end

  end

  def data
    if @data
      @data
    else
      fetch!
      @data
    end
  end

  private

  def fetch!
    puts "Fetching #{@url}"
    begin
    open(@url) do |io|
      @data = RSS::Parser.parse(io, false, false)
    end
    rescue OpenURI::HTTPError => error
      puts "Cannot open feed: #{error}, skipping"
      @data = :not_available
    end
  end

end

class Post

  attr :data, :feed

  def initialize(data, feed)
    @data = data
    @feed = feed
  end

  def link
    @data.link
  end

  def channel
    @feed.data.channel.title
  end

  def description
    text = @data.content_encoded
    text ||= @data.description
    text.gsub(/<\/?div.*>/, '')
  end

  def title
    @data.title
  end

  def date
    @data.date
  end

end

class Group

  attr :name, :feeds

  def initialize (name, &proc)
    @name = name
    @feeds = []
    instance_eval(&proc)
  end

  private

  def feed (name, &proc)
    @feeds << FeedEntry.new(name, &proc)
  end

end

class FeedEntry

  attr :feed_obj

  def initialize (name, &proc)
    @name = name
    instance_eval(&proc)
    @feed_obj = Feed.new(@feed_addr) if @link
  end

  private

  def feed (feed)
    @feed_addr = feed
  end

  def format (format)
    @format = format
  end

  def link (link)
    @link = link
  end

end

class Grouper

  @groups = []

  def self.group_add (name, &proc)
    @groups << Group.new(name, &proc)
  end

  def self.groups
    @groups
  end

  def self.items_to_print (cutoff)
    to_print = []
    self.groups.each do |group|
      group.feeds.each do |f|
        to_print << f.feed_obj.recent(cutoff)
      end
    end
    to_print.flatten.sort do |a, b|
      b.data.date <=> a.data.date
    end
  end

end

class Templater

  def initialize(cutoff)
    @cutoff = cutoff
  end

  def generate_template
    template_file = File.join(Gem.datadir('lunga'),
                              'layout',
                              'default.html.erb')
    template = File.new(template_file, 'r')

    ERB.new(template.read).result binding
  end

  def posts
    Grouper.items_to_print(@cutoff)
  end

  def stylesheet
    File.join(Gem.datadir('lunga'),
              'css',
              'style.css')
  end

  def script
    File.join(Gem.datadir('lunga'),
              'script',
              'lunga.js')
  end

end

def group (name, &proc)
  Grouper.group_add(name, &proc)
end

class Lunga

  def self.generate
    rcfile = File.join(ENV['HOME'], '.lunga', 'feeds.rb')
    load rcfile

    template = Templater.new(Time.now - (60 * 60 * 24))

    spoolfile = File.join(ENV['HOME'], '.lunga', 'spool.html')
    spool = File.new(spoolfile, 'w')
    spool.write(template.generate_template)

  end

end
