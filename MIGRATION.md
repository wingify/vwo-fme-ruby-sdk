# Migrate to the Wingify Ruby FME SDK

This guide explains how to adopt the **Wingify** public API on the Ruby FME SDK. Existing **VWO** integrations (`vwo-fme-ruby-sdk`) continue to work without changes.

For installation, requirements, and advanced configuration (storage, logger, gateway, proxy, polling, and more), see [README.md](README.md).

---

## Overview

The FME SDK is published as **two RubyGems packages** built from the **same codebase** at the same version:

| RubyGems package | Require | Public types |
| --- | --- | --- |
| [`wingify-fme-ruby-sdk`](https://rubygems.org/gems/wingify-fme-ruby-sdk/) | `require 'wingify'` | `Wingify::init`, `WingifyClient`, … |
| [`vwo-fme-ruby-sdk`](https://rubygems.org/gems/vwo-fme-ruby-sdk/) | `require 'vwo'` | `VWO::init`, `VWOClient`, … (legacy) |

Pick **one** package for your app — do **not** add both `vwo-fme-ruby-sdk` and `wingify-fme-ruby-sdk` to your `Gemfile`.

New integrations should use the **Wingify** package and types. When you install and initialize through `wingify-fme-ruby-sdk`, the SDK uses Wingify edge/collect endpoints and Wingify-branded logging (see [Runtime behavior](#runtime-behavior-wingify-build) below).

---

## Wingify API — implementation guide

Use the RubyGems package `wingify-fme-ruby-sdk`. Public types use the `Wingify*` prefix.

Legacy `VWO*` types on `vwo-fme-ruby-sdk` remain supported; they are thin aliases over the same core implementation.

### Implementation steps

1. **Add the dependency** — use only the Wingify gem in your `Gemfile` (same semver you use on VWO today):

   ```ruby
   gem 'wingify-fme-ruby-sdk', '~> 1.50.0'
   ```

2. **Initialize** — call `Wingify.init(options)` with `account_id` and `sdk_key`. Returns a `WingifyClient`.

3. **Build user context** — pass a plain hash with at least `id` (string). Optional: `customVariables`, `userAgent`, `ipAddress`, `bucketingSeed`, etc. See [README.md](README.md).

4. **Evaluate flags** — `client.get_flag(feature_key, context)`.

5. **Track and attribute** — `track_event` and `set_attribute` on the initialized client.

### Ruby Example

```ruby
require 'wingify'

client = Wingify.init({
  account_id: '123456',
  sdk_key: '32-alpha-numeric-sdk-key',
  logger: { level: 'DEBUG' }
})

context = { id: 'unique_user_id', customVariables: { plan: 'pro' } }

flag = client.get_flag('feature_key', context)

if flag.is_enabled
  variable = flag.get_variable('feature_variable', 'default-value')
  puts "Variable: #{variable}"
end

client.track_event('event_name', context, { cartValue: 10 })
client.set_attribute('attribute_key', 'attribute_value', context)
```

For the legacy VWO package, substitute `VWO.init` — behavior is exactly the same.

---

## Public API mapping

| Legacy (VWO package) | Wingify package |
| --- | --- |
| `require 'vwo'` | `require 'wingify'` |
| `VWO.init` | `Wingify.init` |
| `VWO.get_uuid` | `Wingify.get_uuid` |
| `VWOClient` | `WingifyClient` |
| `VWOBuilder` | `WingifyBuilder` |
| `vwo_builder` on options | `wingify_builder` (preferred); `vwo_builder` still accepted |

### Options that stay VWO-named (platform compatibility)

| Option / field | Notes |
| --- | --- |
| Event / payload keys (e.g. `_vwo_meta` in network payloads) | Unchanged for server compatibility |
| Local storage key | `vwo_fme_settings` for both brands |

---

## Legacy VWO API

The following remain available for existing apps on **`vwo-fme-ruby-sdk`**:

- `require 'vwo'` with `VWO.init`, `VWO.get_uuid`
- `VWOClient`, `VWOBuilder`
- VWO build-time hosts and `VWO-SDK` log prefix

No breaking change is required to stay on the VWO package.

---

## Runtime behavior (Wingify build)

When you install and run the **Wingify** gem (not `vwo-fme-ruby-sdk`):

| Area | Wingify build | VWO build (legacy package) |
| --- | --- | --- |
| Settings / pull / location | `edge.wingify.net` | `dev.visualwebsiteoptimizer.com` |
| Events / batch | `collect.wingify.net` | Same host as settings (single host) |
| Log prefix | `Wingify-SDK` | `VWO-SDK` |
| Log message branding | Wingify where templated | VWO |
| Gem `name` in metadata | `wingify-fme-ruby-sdk` | `vwo-fme-ruby-sdk` |

With **`gateway_service`** or **`proxy_url`**, all requests go to your proxy/gateway host. Without them, the SDK selects hosts automatically per build brand.

Event and API payload field names (for example `vwo_*` event names) are **unchanged** for compatibility with the FME platform.

---

## Migrating from `vwo-fme-ruby-sdk` to `wingify-fme-ruby-sdk`

1. In your `Gemfile`, replace the dependency:

   ```diff
   - gem 'vwo-fme-ruby-sdk', '~> 1.50.0'
   + gem 'wingify-fme-ruby-sdk', '~> 1.50.0'
   ```

2. Update requires:

   ```diff
   - require 'vwo'
   + require 'wingify'
   ```

3. Rename init calls: `VWO.init` → `Wingify.init`.

4. Reinstall bundles (`bundle install`) and run your existing tests — flag evaluation, tracking, and attributes behave the same; only the package name, default hosts, and log branding change.

### What you do **not** need to change

- `account_id`, `sdk_key`, feature keys, event names
- User context shape (`{ id: '...' }` and optional fields)
- Method signatures on the client (`get_flag`, `track_event`, etc.)
- Server-side campaign / settings JSON

---

## Architecture note

The SDK follows a **Single Repo Two Package Approach**:

| Package | Role |
| --- | --- |
| `wingify/` | **Core** — `api/`, `constants/`, `enums/`, `services/`, `utils/`, `packages/`, `wingify_client.rb`, … |
| `vwo.rb` | **Legacy facade only** — Maps legacy `VWOClient` to `WingifyClient` and forwards `VWO.init` to `Wingify.init` with the `is_via_vwo: true` flag. |

Both `.gem` packages ship `wingify/` (core) and `vwo.rb` (facade). Existing apps use `require 'vwo'`; new apps use `require 'wingify'`. Brand-specific hosts, SDK name, and log prefix are selected at **runtime** via `is_via_vwo` (`VWO.init` sets it to `true`; `Wingify.init` defaults to `false`). The `.gemspec` builds different package names and metadata based on `SDK_BRAND` at build time.

---

## Related documents

| Document | Content |
| --- | --- |
| [README.md](README.md) | Installation, requirements, configuration |
| [CHANGELOG.md](CHANGELOG.md) | Version history and rebranding notes |
