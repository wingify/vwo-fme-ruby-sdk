# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-04-07

### Fixed

- Fixed issue where JSON files were not getting included in gem build by updating gemspec file patterns

## [1.1.0] - 2025-03-19

### Added

- First release of VWO Feature Management and Experimentation capabilities for Ruby

    ```ruby
    require 'vwo'

    # Initialize VWO client
    vwo_client = VWO.init({
        sdk_key: '32-alpha-numeric-sdk-key',
        account_id: '123456'
    })

    # Check if feature is enabled for user
    user_context = { id: 'unique_user_id' }
    flag = vwo_client.get_flag('feature_key', user_context)

    if flag.is_enabled
        puts 'Feature is enabled!'

        # Get feature variable
        value = flag.get_variable('feature_variable', 'default_value')
        puts "Variable value: #{value}"
    end

    # Track an event
    vwo_client.track_event('event_name', user_context)

    # Set attribute(s)
    vwo_client.set_attribute({ attribute_key: 'attribute_value' }, user_context)
    ```
