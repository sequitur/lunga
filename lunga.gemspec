Gem::Specification.new do |gem|
  gem.name      = 'lunga'
  gem.version   = '0.1.0'
  gem.date      = '2013-05-18'
  gem.summary   = 'An anxiety-free, static HTML RSS aggregator.'
  gem.authors   = ['Bruno Dias']
  gem.email     = 'bruno.r.dias@gmail.com'
  gem.files     = ['lib/lunga.rb',
                   'bin/lunga',
                   'data/lunga/css/style.css',
                   'data/lunga/layout/default.html.erb',
                   'data/lunga/script/lunga.js']
  gem.homepage  = 'http://github.com/sequitur/lunga'
  gem.executables = ['lunga']
end
