require 'lunga'
require 'time'

describe Post do

  it 'holds post and feed data' do
    date = Date.parse('2013-05-18')
    rss = double('rss')
    rss.stub(:content_encoded => '<p>Hello!</p>',
             :link            => 'http://link.to',
             :date            => date)

    feed = double('feed')
    feed.stub(:title => 'My brilliant feed')

    post = Post.new(rss, feed)

    post.link.should eq('http://link.to')
    post.description.should eq('<p>Hello!</p>')
    post.date.should eq(date)
    post.channel.should eq('My brilliant feed')
  end

end

shared_context 'after fetching a feed' do |feed|

  it 'fetches data if it has not already' do
    feed.should_receive(:fetch!).and_call_original
    feed.data
  end

  it 'Holds some sort of data object' do
    data = feed.data
    data.should be_a_kind_of(SimpleRSS)
  end

  it 'has a title method that gets its title from the channel data' do
    feed.data.channel.title.should be_a_kind_of(String)
  end

end

describe Feed do

  it 'has a default cutoff' do
    feed = Feed.new('http://xkcd.com/rss')

    # Ten minutes is enough time to run the test suite, surely?
    feed.cutoff.should be_within(600).of( Time.now - 60 * 60 * 24 )
  end

  context 'using rss' do
    feed = Feed.new('http://xkcd.com/rss.xml')
    include_examples 'after fetching a feed', feed
  end

  context 'using atom' do
    feed = Feed.new('http://xkcd.com/atom.xml')
    include_examples 'after fetching a feed', feed
  end

end
