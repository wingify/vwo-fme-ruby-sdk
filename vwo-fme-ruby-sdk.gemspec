Gem::Specification.new do |spec|
  spec.name          = "vwo-fme-ruby-sdk"
  spec.version       = "1.0.0"  # Update this as necessary
  spec.summary       = "VWO FME Ruby SDK"
  spec.description   = "A Ruby SDK for Feature Management And Experimentation"
  spec.authors       = ['VWO']
  spec.email         = ['dev@wingify.com']
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ['lib']

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk/issues',
    'changelog_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk/blob/master/CHANGELOG.md',
    'homepage_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk',
    'source_code_uri' => 'https://github.com/wingify/vwo-fme-ruby-sdk'
  }

  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = '>= 2.5'

  # Declare gem dependencies
  spec.add_runtime_dependency 'net-http', '~> 0.1'
end