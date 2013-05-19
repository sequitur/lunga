require 'simple-rss'
require 'singleton'
require 'open-uri'
require 'erb'
require 'time'

class Lunga

  def self.begin
    rcfile = File.join ENV['HOME'], '.lunga', 'feeds.rb'
    load rcfile
    ReadingList.instance.populate_feed_list!
    FeedList.instance.populate_post_list!
    SpoolWriter.write
  end

end

class Feed

  attr :raw

  def initialize(rss)
    @raw = rss
  end

  def title
    raw.channel.title
  end

  def link
    raw.channel.link
  end

  def items
    raw.items.map do |item|
      Post.new(item, self)
    end
  end

end

class Post

  attr :channel, :raw_item

  def initialize(item, channel)
    @raw_item = item
    @channel = channel
  end

  def title
    @raw_item[:title]
  end

  def date
    @raw_item[:pubDate] # rubocop:disable all
  end

  def link
    @raw_item[:link]
  end

  def description
    text = @raw_item[:content_encoded] || @raw_item[:description]
    text.gsub(/<\/?div>/, '')
  end

end

class ReadingList < Array
  include Singleton

  def populate_feed_list!
    generate_feeds.each { |feed| FeedList.instance << feed }
  end

  def generate_feeds
    map do |feed_entry|
      feed_entry.generate
    end
  end

end

class FeedList < Array
  include Singleton

  def populate_post_list!
    generate_posts.each { |post| PostList.instance << post }
  end

  def generate_posts
    map do |feed|
      feed.items
    end.flatten
  end

end

class PostList < Array
  include Singleton

end

class Configuration
  include Singleton

  attr_accessor :cutoff, :stylesheet, :template, :script, :spool

  def initialize
    @cutoff = Time.now - 60 * 60 * 24
    @stylesheet = File.expand_path('lunga/css/style.css',
                                   File.dirname(__FILE__))
    @template = File.expand_path('lunga/layout/default.html.erb',
                                 File.dirname(__FILE__))
    @script = File.expand_path('lunga/script/lunga.js',
                                 File.dirname(__FILE__))
    @spool = File.join ENV['HOME'], '.lunga', 'spool.html'
  end

end

class ConfigSetter

  def cutoff (value)
    Configuration.instance.cutoff = Time.now - 60 * 60 * value
  end

end

class FeedEntry
  attr :name, :url

  def initialize(name, &proc)
    @name = name
    instance_eval(&proc)
  end

  def channel (url)
    @url = url
  end

  def generate
    rss = SimpleRSS.parse(open(@url))
    Feed.new(rss)
  end

end

class Templater

  def initialize (template: Configuration.instance.template)
    @template_file = template
  end

  def spool
    template = File.new(@template_file, 'r')
    ERB.new(template.read).result binding
  end

  def stylesheet
    Configuration.instance.stylesheet
  end

  def script
    Configuration.instance.script
  end

  def posts
    PostList.instance
  end

end

class SpoolWriter

  def self.write (spool_file: Configuration.instance.spool)
    spool = File.new File.expand_path(spool_file), 'w'
    spool.write Templater.new.spool
  end

end

def feed (name, &proc)
  ReadingList.instance << FeedEntry.new(name, &proc)
end

def settings (&proc)
  ConfigSetter.new.instance_eval(&proc)
end
