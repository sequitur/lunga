require 'simple-rss'
require 'open-uri'
require 'erb'
require 'time'

class Lunga

  def self.generate
    # "Main"
    rcfile = File.join(ENV['HOME'], '.lunga', 'feeds.rb')
    load rcfile

    template = Templater.new

    spoolfile = File.join(ENV['HOME'], '.lunga', 'spool.html')
    spool = File.new(spoolfile, 'w')
    spool.write(template.generate_template)

    # End of normal execution.
  end

end

def group (name, &proc)
  # This Kernel method provides the top of the interface to the feeds.rb DSL.
  Grouper.group_add(name, &proc)
end

class Grouper

  # Grouper holds all the feed groups as class instance data.

  @groups = []

  def self.group_add (name, &proc)
    @groups << Group.new(name, &proc)
  end

  def self.groups
    @groups
  end

  def self.items_to_print
    # Figure out what's to be converted to html.
    to_print = []
    puts 'Warning: Nothing to print' unless self.groups
    self.groups.each do |group|
      puts 'Warning: No feeds' unless group.feeds
      puts "Picking feeds for #{group}"
      group.feeds.each do |f|
        puts "Getting recent for #{f}"
        puts 'Warning: Nothing new' unless f.recent
        to_print << f.recent
      end
    end
    puts "To print: #{to_print}"
    to_print.flatten.sort do |a, b|
      b.data.date <=> a.data.date
    end
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
    @feeds << FeedEntry.new(name, &proc).feed_obj
  end

end

class MissingAddressError < StandardError; end

class FeedEntry

  # FeedEntry holds the DSL methods that actually define the Feed objects.
  # It acts as a factory of sorts; each instance is initialized only long
  # enough to run the DSL code and then promptly spit out the actual Feed.

  attr :feed_obj

  def initialize (name, &proc)
    @name = name
    instance_eval(&proc)
    unless @feed_addr
      fail MissingAddressError, "No address given for feed #{name}"
    end
    @feed_obj = Feed.new(@feed_addr)
  end

  private

  def cutoff (x)
    @cutoff = x
  end

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

class Feed

  # Holds the actual feed data.
  attr :cutoff, :url

  def initialize (url, cutoff: (Time.now - 60 * 60 * 24))
    @url = url
    @cutoff = cutoff
  end

  def recent
    return [] if data == :not_available
    recent_items = data.items.select do |item|
      item[:date] && item> @cutoff
      true
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

  def title
    # Alias for data nested deep in the rss object model.
    data.feed.title
  end

  private

  def fetch!
    puts "Fetching #{@url}"
    open(@url) do |io|
      @data = SimpleRSS.parse io
    end
    rescue StandardError => error
      puts "Cannot open feed: #{error}, skipping"
      @data = :not_available
  end

end

class Post

  attr :data, :feed

  def initialize(data, feed)
    @data = data
    @feed = feed
  end

  def link
    @data[:link]
  end

  def channel
    @feed.title
  end

  def description
    text = @data[:content_encoded]
    text ||= @data[:description]

    # Strip out all <div> tags, so post content can't break formatting. We
    # wouldn't have to do this if html wasn't permissive.
    text.gsub(/<\/?div.*>/n, '')
  end

  def title
    @data[:title]
  end

  def date
    @data[:date]
  end

end

class Templater

  def initialize
  end

  def generate_template
    template_file = File.join(Gem.datadir('lunga'),
                              'layout',
                              'default.html.erb')
    template = File.new(template_file, 'r')

    ERB.new(template.read).result binding
  end

  def posts
    puts "Listing posts..."
    puts "To print: #{Grouper.items_to_print}"
    Grouper.items_to_print
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


