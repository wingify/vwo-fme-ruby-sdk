Gem::Specification.new do |spec|
    is_wingify = ENV['SDK_BRAND'] == 'wingify'
    spec.name          = is_wingify ? 'wingify-fme-ruby-sdk' : 'vwo-fme-ruby-sdk'
    spec.version       = '1.50.0'
    spec.authors       = [is_wingify ? 'Wingify' : 'VWO']
    spec.email         = ['dev@wingify.com']

    spec.summary       = "#{is_wingify ? 'Wingify' : 'VWO'} FME Ruby SDK"
    spec.description   = 'A Ruby SDK for Feature Management And Experimentation'
    spec.license       = 'Apache-2.0'

    spec.files         = Dir['lib/**/*.rb', 'lib/**/*.json']
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
    # spec.add_dependency 'net-http', '~> 0.2.0'
    # spec.add_dependency 'concurrent-ruby', '~> 1.2.0'
    spec.add_dependency "concurrent-ruby", ">= 1.2.0", "< 2.0"
    spec.add_dependency "net-http", ">= 0.2", "< 1.0"
    spec.add_dependency "logger"
    spec.add_dependency "bigdecimal"
    spec.add_dependency "base64"
    spec.add_dependency "mutex_m"
    spec.required_ruby_version = '>= 2.6.0'

    # Testing dependencies (development only)
    spec.add_development_dependency 'minitest', '~> 5.0'
    spec.add_development_dependency 'mocha', '~> 2.7'
    spec.add_development_dependency 'json', '~> 2.5'
    spec.add_development_dependency 'rake', '~> 13.0'
  end
