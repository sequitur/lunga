require 'lunga'
require 'time'

describe Grouper do

  context 'DSL' do

    group 'my group' do

      feed 'my feed' do
        feed 'http://myaddre.ss'
      end

    end

    group = Grouper.groups[-1]

    it 'takes a DSL and spits out Group objects' do

      group.should be_a_kind_of(Group)
      group.name.should eq('my group')

    end

    it 'creates Group objects that hold feeds' do

      group.feeds[0].should be_a_kind_of(Feed)
      group.feeds[0].url.should eq('http://myaddre.ss')

    end

  end

  it 'raises an error if the DSL is invalid' do
    expect do

      group 'wrong group' do
        feed 'wrong feed' do
        end
      end

    end.to raise_error(MissingAddressError)

  end

end

describe Group do

end

describe Post do

  it 'holds post and feed data' do
    date = Date.parse('2013-05-18')
    rss = { content_encoded: '<p>Hello!</p>',
            link:            'http://link.to',
            date:            date}

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
    feed.title.should be_a_kind_of(String)
  end

  it 'holds a list of recent post objects, which may be empty' do
    feed.recent.should be_a_kind_of(Array)
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

