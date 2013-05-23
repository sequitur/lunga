require 'singleton'
require 'erb'
require 'time'

require 'feedzirra'

NO_POST_CONTENT = <<EOF
<p>
  Oops! Something went wrong. I can't locate the content for this post.
</p>
EOF

DATA_MISSING = 'Oops! There should be something here.'

class Lunga

  def self.begin
    rcfile = File.join ENV['HOME'], '.lunga', 'feeds.rb'
    load rcfile
    SpoolWriter.write
  end

end

class Post

  attr :entry, :feed

  def initialize(entry, feed)
    @entry = entry
    @feed = feed
  end

  def title
    entry.title
  end

  def date
    entry.published
  end

  def link
    entry.url
  end

  def description
    entry.content or entry.summary
  end

end

class PostList < Array
  include Singleton

  def to_print
    sort do |a, b|
      b.date <=> a.date
    end
  end

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

class FeedConfig
  attr :name, :url

  def initialize(name, &proc)
    @name = name
    instance_eval(&proc)
  end

  def channel (url)
    @url = url
  end

  def generate
    feed = Feedzirra::Feed.fetch_and_parse(url)
    if feed.is_a? Fixnum
      puts "Can't open #{name}: #{feed} error."
      return
    end
    unless feed.last_modified
      puts "Can't find last modified date for #{name}"
      return
    end
    add_feed(feed)
  end

  private

  def add_feed (feed)
    if feed.last_modified > Configuration.instance.cutoff
      # feed.sanitize_entries!
      new_posts = feed.entries.select do |entry|
        entry.published > Configuration.instance.cutoff
      end
      new_posts.each do |post|
        PostList.instance << Post.new(post, feed)
      end
    end
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
    PostList.instance.to_print
  end

end

class SpoolWriter

  def self.write (spool_file: Configuration.instance.spool)
    spool = File.new File.expand_path(spool_file), 'w'
    spool.write Templater.new.spool
  end

end

def feed (name, &proc)
  FeedConfig.new(name, &proc).generate
end

def settings (&proc)
  ConfigSetter.new.instance_eval(&proc)
end
