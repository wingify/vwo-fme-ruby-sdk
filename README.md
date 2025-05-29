# VWO Feature Management and Experimentation SDK for Ruby

[![Gem Version](https://img.shields.io/gem/v/vwo-fme-ruby-sdk?style=for-the-badge)](https://rubygems.org/gems/vwo-fme-ruby-sdk)
[![License](https://img.shields.io/github/license/wingify/vwo-fme-ruby-sdk?style=for-the-badge&color=blue)](http://www.apache.org/licenses/LICENSE-2.0)

[![CI](https://img.shields.io/github/actions/workflow/status/wingify/vwo-fme-ruby-sdk/main.yml?style=for-the-badge&logo=github)](https://github.com/wingify/vwo-fme-ruby-sdk/actions?query=workflow%3ACI)
[![codecov](https://img.shields.io/codecov/c/github/wingify/vwo-fme-ruby-sdk?token=813UYYMWGM&style=for-the-badge&logo=codecov)](https://codecov.io/gh/wingify/vwo-fme-ruby-sdk)

## Overview

The **VWO Feature Management and Experimentation SDK** (VWO FME Ruby SDK) enables Ruby developers to integrate feature flagging and experimentation into their applications. This SDK provides full control over feature rollout, A/B testing, and event tracking, allowing teams to manage features dynamically and gain insights into user behavior.

## Requirements

- **Ruby 2.6 or later**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vwo-fme-ruby-sdk'
```

Or install it directly:

```bash
gem install vwo-fme-ruby-sdk
```

## Basic Usage Example

The following example demonstrates initializing the SDK with a VWO account ID and SDK key, setting a user context, checking if a feature flag is enabled, and tracking a custom event.

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

## Advanced Configuration Options

To customize the SDK further, additional parameters can be passed to the `init` method. Here's a table describing each option:

| **Parameter**                | **Description**                                                                                                                                             | **Required** | **Type** | **Example**                     |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | -------- | ------------------------------- |
| `account_id`                 | VWO Account ID for authentication.                                                                                                                          | Yes          | String   | `'123456'`                      |
| `sdk_key`                    | SDK key corresponding to the specific environment to initialize the VWO SDK Client. You can get this key from VWO Application.                              | Yes          | String   | `'32-alpha-numeric-sdk-key'`    |
| `poll_interval`              | Time interval for fetching updates from VWO servers (in seconds).                                                                                           | No           | Integer  | `60000`                            |
| `gateway_service`            | A hash representing configuration for integrating VWO Gateway Service.                                                                                      | No           | Hash     | see [Gateway](#gateway) section |
| `storage`                    | Custom storage connector for persisting user decisions and campaign data.                                                                                   | No           | Object   | See [Storage](#storage) section |
| `logger`                     | Toggle log levels for more insights or for debugging purposes. You can also customize your own transport in order to have better control over log messages. | No           | Hash     | See [Logger](#logger) section   |
| `integrations`               | A hash representing configuration for integrating VWO with other services. | No           | Hash     | See [Integrations](#integrations) section |
| `threading`                  | Toggle threading for better (enabled by default) performance.                                                                               | No           | Hash     | See [Threading](#threading) section |

Refer to the [official VWO documentation](https://developers.vwo.com/v2/docs/fme-ruby-install) for additional parameter details.

### User Context

The `context` object uniquely identifies users and is crucial for consistent feature rollouts. A typical `context` includes an `id` for identifying the user. It can also include other attributes that can be used for targeting and segmentation, such as `customVariables`, `userAgent` and `ipAddress`.

#### Parameters Table

The following table explains all the parameters in the `context` hash:

| **Parameter**      | **Description**                                                            | **Required** | **Type** | **Example**                       |
| ----------------- | -------------------------------------------------------------------------- | ------------ | -------- | --------------------------------- |
| `id`              | Unique identifier for the user.                                            | Yes          | String   | `'unique_user_id'`                |
| `customVariables`| Custom attributes for targeting.                                           | No           | Hash     | `{ age: 25, location: 'US' }`     |
| `userAgent`      | User agent string for identifying the user's browser and operating system. | No           | String   | `'Mozilla/5.0 ... Safari/537.36'` |
| `ipAddress`      | IP address of the user.                                                    | No           | String   | `'1.1.1.1'`                       |

#### Example

```ruby
user_context = {
  id: 'unique_user_id',
  customVariables: { age: 25, location: 'US' },
  userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  ipAddress: '1.1.1.1'
}
```

### Basic Feature Flagging

Feature Flags serve as the foundation for all testing, personalization, and rollout rules within FME.
To implement a feature flag, first use the `get_flag` API to retrieve the flag configuration.
The `get_flag` API provides a simple way to check if a feature is enabled for a specific user and access its variables. It returns a feature flag object that contains methods for checking the feature's status and retrieving any associated variables.

| Parameter     | Description                                                      | Required | Type   | Example              |
| ------------ | ---------------------------------------------------------------- | -------- | ------ | -------------------- |
| `feature_key`| Unique identifier of the feature flag                            | Yes      | String | `'new_checkout'`     |
| `context`    | Hash containing user identification and contextual information   | Yes      | Hash   | `{ id: 'user_123' }` |

Example usage:

```ruby
flag = vwo_client.get_flag('feature_key', user_context)
is_enabled = flag.is_enabled

if is_enabled
  puts 'Feature is enabled!'

  # Get and use feature variable with type safety
  variable_value = flag.get_variable('feature_variable', 'default_value')
  puts "Variable value: #{variable_value}"
else
  puts 'Feature is not enabled!'
end
```

### Custom Event Tracking

Feature flags can be enhanced with connected metrics to track key performance indicators (KPIs) for your features. These metrics help measure the effectiveness of your testing rules by comparing control versus variation performance, and evaluate the impact of personalization and rollout campaigns. Use the `track_event` API to track custom events like conversions, user interactions, and other important metrics:

| Parameter          | Description                                                            | Required | Type   | Example                |
| ----------------- | ---------------------------------------------------------------------- | -------- | ------ | ---------------------- |
| `event_name`      | Name of the event you want to track                                    | Yes      | String | `'purchase_completed'` |
| `context`         | Hash containing user identification and other contextual information   | Yes      | Hash   | `{ id: 'user_123' }`   |
| `event_properties`| Additional properties/metadata associated with the event               | No       | Hash   | `{ amount: 49.99 }`    |

Example usage:

```ruby
vwo_client.track_event('event_name', user_context, { amount: 49.99 })
```

See [Tracking Conversions](https://developers.vwo.com/v2/docs/fme-ruby-metrics#usage) documentation for more information.

### Pushing Attributes

User attributes provide rich contextual information about users, enabling powerful personalization. The `set_attribute` method provides a simple way to associate these attributes with users in VWO for advanced segmentation. Here's what you need to know about the method parameters:

| Parameter          | Description                                                            | Required | Type   | Example                |
| ----------------- | ---------------------------------------------------------------------- | -------- | ------ | ---------------------- |
| `attribute_map`   | A hash of attributes to set.                                          | Yes      | Hash   | `{ userType: 'paid'}` |
| `context` | Hash containing user identification and other contextual information   | Yes      | Hash   | `{ id: 'user_123' }`   |

```ruby
vwo_client.set_attribute({ userType: 'paid' }, user_context)
```
See [Pushing Attributes](https://developers.vwo.com/v2/docs/fme-ruby-attributes#usage) documentation for additional information.

### Polling

The `poll_interval` is an optional parameter that allows the SDK to automatically fetch and update settings from the VWO server at specified intervals. Setting this parameter ensures your application always uses the latest configuration.

```ruby
# poll_interval is in milliseconds
vwo_client = VWO.init({ account_id: '123456', sdk_key: '32-alpha-numeric-sdk-key', poll_interval: 60000 })
```

### Gateway

The VWO FME Gateway Service is an optional but powerful component that enhances VWO's Feature Management and Experimentation (FME) SDKs. It acts as a critical intermediary for pre-segmentation capabilities based on user location and user agent (UA). By deploying this service within your infrastructure, you benefit from minimal latency and strengthened security for all FME operations.

#### Why Use a Gateway?

The Gateway Service is required in the following scenarios:

- When using pre-segmentation features based on user location or user agent.
- For applications requiring advanced targeting capabilities.
- It's mandatory when using any thin-client SDK (e.g., Go).

#### How to Use the Gateway

The gateway can be customized by passing the `gateway_service` parameter in the `init` configuration.

```ruby
vwo_client = VWO.init({
  account_id: '123456',
  sdk_key: '32-alpha-numeric-sdk-key',
  gateway_service: {
    url: 'http://custom.gateway.com',
  },
});
```

Refer to the [Gateway Documentation](https://developers.vwo.com/v2/docs/gateway-service) for further details.

### Storage

The SDK operates in a stateless mode by default, meaning each `get_flag` call triggers a fresh evaluation of the flag against the current user context.

To optimize performance and maintain consistency, you can implement a custom storage mechanism by passing a `storage` parameter during initialization. This allows you to persist feature flag decisions in your preferred database system (like Redis, MongoDB, or any other data store).

Key benefits of implementing storage:

- Improved performance by caching decisions
- Consistent user experience across sessions
- Reduced load on your application

The storage mechanism ensures that once a decision is made for a user, it remains consistent even if campaign settings are modified in the VWO Application. This is particularly useful for maintaining a stable user experience during A/B tests and feature rollouts.

```ruby
class StorageConnector
  def get(feature_key, user_id)
    # Return stored data based on feature_key and user_id
  end

  def set(data)
    # Store data using data[:feature_key] and data[:user_id]
  end
end

vwo_client = VWO.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    storage: StorageConnector.new
})
```

### Logger

VWO by default logs all `ERROR` level messages to your server console.
To gain more control over VWO's logging behaviour, you can use the `logger` parameter in the `init` configuration.

| **Parameter** | **Description** | **Required** | **Type** | **Example** |
| ------------- | --------------- | ------------ | -------- | ----------- |
| `level`       | Log level to filter messages. | No | Symbol | `DEBUG` |
| `prefix`      | Prefix for log messages. | No | String | `'CUSTOM LOG PREFIX'` |

#### Example 1: Set log level to control verbosity of logs

```ruby
# Set log level
vwo_client = VWO.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    logger: {
        level: 'DEBUG'
    }
})
```

#### Example 2: Add custom prefix to log messages for easier identification

```ruby
# Set log level
vwo_client = VWO.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    logger: {
        level: 'DEBUG',
        prefix: 'CUSTOM LOG PREFIX'
    }
})
```

### Integrations

VWO FME SDKs help you integrate with several third-party tools, be it analytics, monitoring, customer data platforms, messaging, etc., by implementing a very basic and generic callback capable of receiving VWO-specific properties that can then be pushed to any third-party tool.

```ruby
def callback(data)
    puts "Integration data: #{data}"
end

vwo_client = VWO.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    integrations: {
        callback: method(:callback)
    }
})
```

### Threading

The SDK leverages threading to efficiently manage concurrent operations. Threading is enabled by default, but can be disabled by configuring the `threading` parameter during initialization. This gives you control over the SDK's concurrency behavior based on your application's needs.

| Parameter | Description | Required | Type | Default |
| --------- | ----------- | -------- | ---- | ------- |
| `enabled` | Enable or disable threading. | No | Boolean | `true` |
| `max_pool_size` | Maximum number of threads to use. | No | Integer | `5` |

#### Disable Threading

When threading is disabled, all tracking calls will block the main execution thread until they complete. This means your application will wait for each VWO operation before continuing.

Example showing blocking behavior:

```ruby
# By disabling threading, the SDK will wait for the response from the server for each tracking call.
vwo_client = VWO.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    threading: {
        enabled: false
    },
})
```

#### Enable Threading (Default)

Threading in the VWO SDK provides several important benefits:

1. **Asynchronous Event Tracking**: When enabled, all tracking calls are processed asynchronously in the background. This prevents these network calls from blocking your application's main execution flow.

2. **Improved Performance**: By processing tracking and network operations in separate threads, your application remains responsive and can continue serving user requests without waiting for VWO operations to complete.

Example of how threading improves performance:
- Without threading: Each tracking call blocks until the server responds
- With threading: Tracking calls return immediately while processing happens in background

The SDK uses a thread pool to manage these concurrent operations efficiently. The default pool size of 5 threads is suitable for most applications, but you can adjust it based on your needs:

```ruby
# By default, threading is enabled and the max_pool_size is set to 5.
# you can customize the max_pool_size by passing the max_pool_size parameter in the threading configuration.
vwo_client = VWO.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    threading: {
        enabled: true,
        max_pool_size: 10
    },
})
```

## Version History

The version history tracks changes, improvements, and bug fixes in each version. For a full history, see the [CHANGELOG.md](https://github.com/wingify/vwo-fme-ruby-sdk/blob/master/CHANGELOG.md).

## Development and Testing

```bash
chmod +x ./start-dev.sh
bash start-dev.sh
bundle install
```

## Running Unit Tests

```bash
ruby tests/e2e/run_all_tests.rb
```

## Contributing

We welcome contributions to improve this SDK! Please read our [contributing guidelines](https://github.com/wingify/vwo-fme-ruby-sdk/blob/master/CONTRIBUTING.md) before submitting a PR.

## Code of Conduct

Our [Code of Conduct](https://github.com/wingify/vwo-fme-ruby-sdk/blob/master/CODE_OF_CONDUCT.md) outlines expectations for all contributors and maintainers.

## License

[Apache License, Version 2.0](https://github.com/wingify/vwo-fme-ruby-sdk/blob/master/LICENSE)

Copyright 2025 Wingify Software Pvt. Ltd.
