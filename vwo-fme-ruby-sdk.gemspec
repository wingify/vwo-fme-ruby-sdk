Gem::Specification.new do |spec|
    spec.name          = 'vwo-fme-ruby-sdk'
    spec.version       = '1.1.0'
    spec.authors       = ['VWO']
    spec.email         = ['dev@wingify.com']

    spec.summary       = 'VWO FME Ruby SDK'
    spec.description   = 'A Ruby SDK for Feature Management And Experimentation'
    spec.license       = 'Apache-2.0'

    spec.files         = Dir['lib/**/*.rb']
    spec.require_paths = ['lib']

    spec.metadata = {
      'bug_tracker_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk/issues',
      'changelog_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk/blob/master/CHANGELOG.md',
      'homepage_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk',
      'source_code_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk'
    }

    spec.add_dependency 'uuidtools', '~> 2.2.0'
    spec.add_dependency 'dry-schema', '~> 1.8.0'
    spec.add_dependency 'murmurhash3', '~> 0.1.6'
    spec.add_dependency 'net-http', '~> 0.2.0'
    spec.add_dependency 'concurrent-ruby', '~> 1.2.0'

    spec.required_ruby_version = '>= 2.6.0'

    # Testing dependencies (development only)
    spec.add_development_dependency 'minitest', '~> 5.0'
    spec.add_development_dependency 'mocha', '~> 2.7'
    spec.add_development_dependency 'json', '~> 2.5'
    spec.add_development_dependency 'rake', '~> 13.0'
  end
