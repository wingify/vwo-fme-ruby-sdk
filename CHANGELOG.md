# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.60.0] - 2026-06-29

### Added

- Support for **Web Testing pre-segmentation**: campaign segmentation can use the `campaignVariation` operand. The SDK evaluates it against **`context.platform_variables[:webTestingCampaigns]`**, a map of Web Testing campaign ID → variation ID (plain object or JSON string). Supported operand values in settings: `122` (user in campaign), `122_2` (exact variation), `122_!1` (in campaign but not variation 1), `!122` (not in campaign).

    Example usage:
    ```ruby
    require 'wingify'

    wingify_client = Wingify.init({
      sdk_key: '32-alpha-numeric-sdk-key',
      account_id: '123456'
    })

    # Pass the assigned web testing campaigns in the platform variables
    context = {
      id: 'user-123',
      platformVariables: {
        webTestingCampaigns: {
          '122' => '2',
          '101' => '1'
        }
      }
    }
    
    # The flag will be evaluated based on the pre-segmentation conditions
    flag = wingify_client.get_flag('feature-key', context)
    ```

## [1.55.0] - 2026-06-15

### Added

- Added user tracking support: sends a `vwo_feTrackUsage` event when user tracking is enabled for the account and no variation-shown impression was dispatched for the evaluation..

## [1.50.0] - 2026-06-01

This release introduces **Wingify** as the primary SDK branding and a new gem package namespace, while keeping existing **VWO** integrations fully supported on `vwo-fme-ruby-sdk`.

### Added

- **Wingify gem package** — `wingify-fme-ruby-sdk` is built from the same codebase as the VWO package. Install the Wingify package for new integrations:

  ```bash
  gem install wingify-fme-ruby-sdk
  ```

- **Wingify public API** — use `Wingify.init`, `WingifyBuilder`, and `WingifyClient` as the recommended entry points for new integrations:

  ```ruby
  require 'wingify'

  client = Wingify.init({
    account_id: '123456',
    sdk_key: '32-alpha-numeric-sdk-key',
    logger: { level: 'DEBUG' }
  })

  context = { id: 'user-123' }

  flag = client.get_flag('feature-key', context)
  puts "#{flag.is_enabled} #{flag.get_variation}"
  ```

### Changed

- The SDK implementation now uses a shared core with build-time brand selection (`vwo` vs `wingify`). Wingify builds use Wingify-specific hosts (`edge.wingify.net` for settings, `collect.wingify.net` for events) and log prefix (`Wingify-SDK`).
- **No breaking changes for existing `vwo-fme-ruby-sdk` integrations** — public exports, method signatures, server event names, payload keys, and runtime behavior remain compatible with the VWO platform.

### Deprecated

Nothing is deprecated on **`vwo-fme-ruby-sdk`**. Existing requires and modules continue to work without modification.

For **new projects**, install `wingify-fme-ruby-sdk` instead of `vwo-fme-ruby-sdk`. The API surface is equivalent; only the package name and exported module names differ:

| Existing VWO package (`vwo-fme-ruby-sdk`)             | Wingify package (`wingify-fme-ruby-sdk`) |
| ----------------------------------------------------- | ---------------------------------------- |
| `VWO.init`, `VWO.get_uuid`                            | `Wingify.init`, `Wingify.get_uuid`       |
| `VWOBuilder`                                          | `WingifyBuilder`                         |
| `VWOClient`                                           | `WingifyClient`                          |

Existing code on **`vwo-fme-ruby-sdk` does not need to change**:

```ruby
require 'vwo'

vwo_client = VWO.init({
  account_id: '123456',
  sdk_key: '32-alpha-numeric-sdk-key'
})

context = { id: 'user-123' }

flag = vwo_client.get_flag('feature-key', context)
```

**Migration tip (optional, for new Wingify installs only):** Change the gem package from `vwo-fme-ruby-sdk` to `wingify-fme-ruby-sdk`, change `require 'vwo'` to `require 'wingify'`, and replace module references `VWO` → `Wingify`. Method signatures and SDK behavior are unchanged.

## [1.12.0] - 2026-03-24

### Fixed

- Settings are now validated even when fetched via polling.

## [1.11.0] - 2026-03-18

### Added

- Added support for **Custom Bucketing Seed** via the `bucketingSeed` key in the user context. When provided, the SDK uses this value instead of the user ID as input to the bucketing algorithm. This enables deterministic variation assignment across different users who share the same seed — useful for group testing.

    Example usage:
    ```ruby
    require 'vwo'

    vwo_client = VWO.init({
      sdk_key: '32-alpha-numeric-sdk-key',
      account_id: '123456'
    })

    # All employees of company-abc will get the same variation
    context = {
      id: 'employee-123',
      bucketingSeed: 'company-abc'
    }
    flag = vwo_client.get_flag('feature-key', context)
    ```

## [1.10.0] - 2026-03-06

### Added

-- Added support for newer versions of `net-http` and `concurrent-ruby` in client app

## [1.9.0] - 2026-02-25

### Added

- Added support to use the context `id` as the visitor UUID instead of auto-generating one. You can read the visitor UUID from the flag result via `flag.get_uuid` (e.g. to pass to the web client).

    Example usage:
    ```ruby
    require 'vwo'

    vwo_client = VWO.init({
      sdk_key: '32-alpha-numeric-sdk-key',
      account_id: 123456
    })

    # Default: SDK generates a UUID from id and account
    context_with_generated_uuid = { id: 'user-123' }
    flag1 = vwo_client.get_flag('feature-key', context_with_generated_uuid)
    # Get the UUID from the flag result (e.g. to pass to web client)
    uuid = flag1.get_uuid
    puts "Visitor UUID: #{uuid}"

    # Use your own UUID (e.g. from web client) by passing a valid web UUID in context[:id]
    context_with_custom_uuid = {
      id: 'D7E2EAA667909A2DB8A6371FF0975C2A5' # your existing UUID
    }
    flag2 = vwo_client.get_flag('feature-key', context_with_custom_uuid)
    ```

- Introduced `get_uuid` method for conveniently retrieving the UUID corresponding to a specific user ID.

    Example usage:
    ```ruby
    require 'vwo'

    uuid = VWO.get_uuid("unique_user_id", 'account_id')
    puts "Visitor UUID: #{uuid}"
    ```

## [1.8.0] - 2026-01-16

### Added

- Added support for redirecting all network calls through a custom proxy URL. This feature allows users to route all SDK network requests (settings, tracking, etc.) through their own proxy server.
    ```ruby
    vwo_client = VWO.init({
        sdk_key: '32-alpha-numeric-sdk-key',
        account_id: '123456',
        proxy_url: 'https://custom.proxy.com'
    })
    ```
    **Note:** If both `gateway_service` and `proxy_url` are provided, the SDK will give preference to the `gateway_service` for all network requests.

## [1.7.0] - 2026-01-08

### Added 

- Enhanced Logging capabilities at VWO by sending `vwo_sdkDebug` event with additional debug properties.

## [1.6.1] - 2025-12-08

### Fixed

- Fixed settings normalization: empty `features` and `campaigns` are now automatically set to empty arrays, ensuring schema validation passes even when no features or campaigns exist.

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
