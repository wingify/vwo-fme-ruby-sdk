# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-09

### Added

- First release of VWO Feature Management and Experimentation capabilities

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
    puts get_flag_response.is_enabled()
    puts get_flag_response.get_variables()
    puts get_flag_response.get_variable('variable_key', 'default_value')

    # track event for a user
    track_response = vwo_instance.track_event('event_name', { id: 'your_user_id'})

    # set attribute for a user
    set_attribute_response = vwo_instance.set_attribute('attribute_key', 'attribute_value', { id: 'your_user_id'})
    ```