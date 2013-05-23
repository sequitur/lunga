require 'lunga'

EXAMPLE_FEED = <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
 <title>RSS Title</title>
 <description>This is an example of an RSS feed</description>
 <link>http://www.someexamplerssdomain.com/main.html</link>
 <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000 </lastBuildDate>
 <pubDate>Mon, 06 Sep 2009 16:45:00 +0000 </pubDate>
 <ttl>1800</ttl>

 <item>
  <title>Example entry</title>
  <description>
    Here is some text containing an interesting description.
  </description>
  <link>http://www.wikipedia.org/</link>
  <guid>unique string per item</guid>
  <pubDate>Mon, 06 Sep 2009 16:45:00 +0000 </pubDate>
 </item>

</channel>
</rss>
EOF

CUTOFF_DEFAULT = Time.now - 60 * 60 * 24
CSS_DEFAULT = File.expand_path('../lib/lunga/css/style.css',
                               File.dirname(__FILE__))
TEMPLATE_DEFAULT = File.expand_path('../lib/lunga/layout/default.html.erb',
                                    File.dirname(__FILE__))

shared_context 'rss' do
  let(:feed) { Feedzirra::Feed.parse(EXAMPLE_FEED) }
  let(:post) { Post.new(feed.entries.first, feed) }
end

describe Post do
  context 'rss feed' do
    include_context 'rss'

    it 'knows about the feed object that spawned it' do
      post.feed.should eq feed
    end

    it 'has convenience methods for post data' do
      post.title.should eq 'Example entry'
      post.date.should eq Time.parse('Mon, 06 Sep 2009 16:45:00 +0000')
    end

  end

end

describe Configuration do
  it 'holds configuration options, with defaults' do
    config = Configuration.instance
    config.should eq Configuration.instance
    config.cutoff.should be_within(600).of(CUTOFF_DEFAULT)
    config.stylesheet.should eq (CSS_DEFAULT)
    config.template.should eq (TEMPLATE_DEFAULT)
  end

  it 'can be configured with Kernel#settings' do
    new_cutoff = Time.now - 60 * 60 * 48

    settings do
      cutoff 48 # 48 hours
    end

    Configuration.instance.cutoff.should be_within(600).of new_cutoff

  end

end

describe Templater do
  context 'with a dummy template file' do
    templater = Templater.new(template: 'spec/data/exampletemplate.html.erb')

    it 'generates a spool file from PostList' do
      spool = templater.spool
      spool.should be_a String
      spool.should =~ /<!doctype html>/
    end

  end

  # FIXME: This test is broken by the post selection logic.

  # context 'with a real template file' do
  #   templater = Templater.new

  #   it 'generates a spool file from PostList' do
  #     spool = templater.spool
  #     spool.should be_a String
  #     spool.should =~ /<!doctype html>/
  #     spool.should =~ /Balaclava balaclava balaclava\?/
  #   end
  # end

end
