# VWO Feature Management and Experimentation SDK for Ruby

[![Gem version](https://badge.fury.io/rb/vwo-fme-ruby-sdk.svg)](https://rubygems.org/gems/vwo-fme-ruby-sdk)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

## Requirements

* Works with 2.2.10 onwards

## Installation

```bash
gem install vwo-fme-ruby-sdk
```

## Basic usage

**Importing and Instantiation**

```ruby
require 'vwo'

# options for initializing SDK
options = {
    sdk_key: 'your_sdk_key',
    account_id: 'your_account_id',
    gateway_service_url: 'http://your.host.com:port', # check section - How to Setup Gateway Service - for more details
}

# Initialize VWO
vwo_instance = VWO.init(options)

# get flag
get_flag_response = vwo_instance.get_flag('feature_key', { id: 'your_user_id'})
# check if feature is enabled
puts get_flag_response.is_enabled()
# get all variables
puts get_flag_response.get_variables()
# get specific variable
puts get_flag_response.get_variable('variable_key', 'default_value')

# track event for a user
track_response = vwo_instance.track_event('event_name', { id: 'your_user_id'})

# set attribute for a user
set_attribute_response = vwo_instance.set_attribute('attribute_key', 'attribute_value', { id: 'your_user_id'})
```

## How to Setup VWO Gateway Service

To Setup the VWO Gateway Service, refer to [this](https://hub.docker.com/r/wingifysoftware/vwo-fme-gateway-service).

### Authors

- [Abhishek Joshi](https://github.com/Abhi591)

### Changelog

Refer [CHANGELOG.md](CHANGELOG.md) for detailed changelog.

## Contributing

Please go through our [contributing guidelines](CONTRIBUTING.md)

## Code of Conduct

[Code of Conduct](CODE_OF_CONDUCT.md)

## License

[Apache License, Version 2.0](LICENSE)

Copyright 2024 Wingify Software Pvt. Ltd.
