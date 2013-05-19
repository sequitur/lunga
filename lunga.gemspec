Gem::Specification.new do |gem|
  gem.name        = 'lunga'
  gem.version     = '0.2.0'
  gem.date        = '2013-05-18'
  gem.summary     = 'An anxiety-free, static HTML RSS aggregator.'
  gem.authors     = ['Bruno Dias']
  gem.email       = 'bruno.r.dias@gmail.com'
  gem.files       = ['lib/lunga.rb',
                     'bin/lunga',
                     'lib/lunga/css/style.css',
                     'lib/lunga/layout/default.html.erb',
                     'lib/lunga/script/lunga.js']
  gem.homepage    = 'http://github.com/sequitur/lunga'
  gem.executables = ['lunga']
  gem.license     = 'MIT'

  gem.description = <<-EOF
  Lunga is an RSS aggregator meant to be run periodically as a system service.
  It creates a static html file containing the last 24 hours (Or so) of posts.
  It does not keep track of which posts have been seen, nor does it keep track
  of posts older than the cutoff date, making the RSS-reading experience more
  like reading a newspaper than catching up with email.
  EOF
end
