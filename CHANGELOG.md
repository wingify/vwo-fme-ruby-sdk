# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2025-09-12

### Added

- Post-segmentation variables are now automatically included as unregistered attributes, enabling post-segmentation without requiring manual setup.
- Added support for built-in targeting conditions, including `browser version`, `OS version`, and `IP address`, with advanced operator support (greaterThan, lessThan, regex).`

## [1.5.0] - 2025-08-26

### Added

- Sends usage statistics to VWO servers automatically during SDK initialization

## [1.4.1] - 2025-08-06

### Fixed

- Typecast `account_id` to string in `network_util` before using.
- Fixed broken test cases

## [1.4.0] - 2025-08-06

### Added

- Added support for sending a one-time initialization event to the server to verify correct SDK setup.

## [1.3.2] - 2025-07-24

### Added

- Send the SDK name and version in the settings call to VWO as query parameters.


## [1.3.1] - 2025-06-12

### Added

- Added a feature to track and collect usage statistics related to various SDK features and configurations which can be useful for analytics, and gathering insights into how different features are being utilized by end users.

## [1.3.0] - 2025-06-11

### Added

- Added support for `batch_event_data` configuration to optimize network requests by batching multiple events together. This allows you to:

    - Configure `request_time_interval` to flush events after a specified time interval
    - Set `events_per_request` to control maximum events per batch
    - Implement `flush_callback` to handle batch processing results
    - Manually trigger event flushing via `flush_events()` method

    ```ruby
    require 'vwo'

    # flushCallBack method
    def call(error, data)
        # custom implementation here
    end

    # Initialize VWO client
    vwo_client = VWO.init({
        sdk_key: '32-alpha-numeric-sdk-key',
        account_id: '123456',
        batch_event_data: {
            events_per_request: 50, # Optional: 50 events per request (default is 100)
            request_time_interval: 60 # Optional: send events every 60 seconds (default is 600 seconds)
            flush_callback: method(:call) # Optional: callback to execute after flush
        },
    })
    ```

    - You can also manually flush events using the `flush_events()` method:

    ```ruby
    vwo_client.flush_events()
    ```
- Added support for polling intervals to periodically fetch and update settings:
    - If `poll_interval` is set in options (must be >= 1000 milliseconds), that interval will be used
    - If `poll_interval` is configured in VWO application settings, that will be used
    - If neither is set, defaults to 10 minute polling interval

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
