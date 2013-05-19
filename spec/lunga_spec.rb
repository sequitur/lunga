require 'lunga'

EXAMPLE_FEED = <<EOF
<?xml version="2.0" encoding="UTF-8"?>
<channel>
  <title>My Awesome Feed</title>
  <link>http://awesome.to</link>
  <item>
    <title>My Sweet Post</title>
    <link>http://awesome.to/sweet</link>
    <pubDate>Sat, 18 may 2013 16:00:00 +0000</pubDate>
    <description>Awesome, relevant post content.</description>
    <content:encoded>
      <![CDATA[<p>Awesome, relevant post content - in a paragraph!<p>]]>
    </content:encoded>
  </item>
</channel>
EOF

MALFORMED_FEED = <<EOF
<?xml version="2.0" encoding="UTF-8"?>
<channel>
  <title>My Awesome Feed</title>
  <link>http://awesome.to</link>
  <item>
    <title>My Sweet Post</title>
    <link>http://awesome.to/sweet</link>
    <pubDate>Sat, 18 may 2013 16:00:00 +0000</pubDate>
    <description>Awesome, relevant post content.</description>
    <content:encoded>
      <![CDATA[<div>
      <p>Awesome, relevant post content - in a paragraph!<p></div>]]>
    </content:encoded>
  </item>
</channel>
EOF

CUTOFF_DEFAULT = Time.now - 60 * 60 * 24
CSS_DEFAULT = File.expand_path('../lib/lunga/css/style.css',
                               File.dirname(__FILE__))
TEMPLATE_DEFAULT = File.expand_path('../lib/lunga/layout/default.html.erb',
                                    File.dirname(__FILE__))

shared_context 'rss' do
  let(:feed) { Feed.new(SimpleRSS.parse EXAMPLE_FEED) }
  let(:post) { feed.items[0] }
end

describe Feed do
  context 'with a valid feed' do
    include_context 'rss'

    it 'wraps a raw SimpleRSS object' do
      feed.raw.should be_a_kind_of SimpleRSS
    end

    it 'provides convenience methods for channel data' do
      feed.title.should eq 'My Awesome Feed'
      feed.link.should eq 'http://awesome.to'
    end

    it 'generates a list of feed items' do
      feed.items.should be_a_kind_of Array
      feed.items[0].should be_a_kind_of Post
    end
  end
end

describe Post do
  context 'rss feed' do
    include_context 'rss'

    it 'knows about the feed object that spawned it' do
      post.channel.should eq feed
    end

    it 'contains a raw hash of post attributes' do
      post.raw_item.should be_a_kind_of Hash
    end

    it 'has convenience methods for post data' do
      post.title.should eq 'My Sweet Post'
      post.date.should eq Time.parse('Sat, 18 may 2013 16:00:00 +0000')
    end

  end

  context 'bad feeds' do
    feed = Feed.new(SimpleRSS.parse(MALFORMED_FEED))
    post = feed.items[0]

    it 'strips out all divs' do
      post.description.should_not =~ /<div>/
      post.description.should_not =~ /<\/div>/
    end
  end

end

describe FeedEntry do
  context 'adding new entries to ReadingList with Kernel#feed' do
    # We take advantage, here, of the fact that open doesn't care whether it
    # gets a local filename or a remote url.
    feed 'Example Feed' do
      channel 'spec/data/examplefeed.xml'
    end

    it 'holds a name and URL to the feed itself' do
      entry = ReadingList.instance[-1]
      entry.should be_a_kind_of FeedEntry
      entry.name.should eq 'Example Feed'
      entry.url.should eq 'spec/data/examplefeed.xml'
    end

    it 'can create a real, faithful Feed object from its data' do
      entry = FeedEntry.new('Example Feed') do
        channel 'spec/data/examplefeed.xml'
      end

      feed = entry.generate
      feed.should be_a_kind_of Feed
      feed.title.should eq 'Balaclava Fashion'
    end

  end

end

describe ReadingList do
  it 'is a singleton' do
    a, b = ReadingList.instance, ReadingList.instance
    a.should eq b
  end

  it 'can produce an array of Feed objects' do
    feed_list = ReadingList.instance.generate_feeds
    feed_list.should be_a_kind_of Array
  end

end

describe FeedList do
  it 'is a singleton array of Feed objects taken from ReadingList' do
    a, b = FeedList.instance, FeedList.instance
    a.should eq b
    ReadingList.instance.populate_feed_list!
    FeedList.instance[0].should be_a Feed
  end
end

describe PostList do
  it 'is a flat, singleton array of Post objects taken from FeedList' do
    a, b = PostList.instance, PostList.instance
    a.should eq b
    FeedList.instance.populate_post_list!
    PostList.instance.should be_a Array
    PostList.instance[0].should be_a Post
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
