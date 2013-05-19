# Lunga

Lunga is an RSS aggregator meant to be run periodically as a system service.
It creates a static html file containing the last 24 hours (Or so) of posts.
It does not keep track of which posts have been seen, nor does it keep track
of posts older than the cutoff date, making the RSS-reading experience more
like reading a newspaper than catching up with email.

Thus neatly cured of unread article anxiety, you're free to be more productive.
The html file itself makes use of FontAwesome and JQuery, which are currently
loaded from their respective CDN services (So, not included in the gem). Since
the html is static, Lunga doesn't require a server and can be read directly from
disk. Lunga's UI has two buttons: Hide, and delete. It does not, currently, keep
track of either one persistently.

Lunga is very much alpha software. It hasn't even seen its first refactoring.
Things can and will break.

## Features

-   No posts older than 24 hours!
-   No count of unread posts!
-   No server!
-   No social features!
-   Minimal use of JavaScript!

## Installation

Only from git for now. Clone the repository and do:

´´´bash
    gem build lunga.gemspec
    gem install simple-rss # If you don't have it already
    gem install lunga-0.2.0.gem
´´´

## Configuration

Lunga keeps its files in `$HOME/.lunga`. It's configured through a Ruby file called
`feeds.rb`. It looks like this:

```ruby
settings { cutoff 24 } # Posts older than 24 hours are discarded.

feed 'xkcd' { channel 'http://xkcd.com/rss.xml' }
```
## Usage

With a `feeds.rb` file in place, simply run `lunga`. After it's done fetching
all your feeds (Which could take a while), a file called `spool.html` will
magically appear in your `.lunga` directory. You can view this file and read
your news in any web browser that isn't completely ancient.

Oh, also, some feeds will be broken. Those may be bugs with Lunga, or with
SimpleRSS - I'm investigating some replacement for it.
