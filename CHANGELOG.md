# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-24

### Added

- Initial release of the RenderScreenshot Ruby SDK
- `Client` class for API interactions
  - `take` - Get screenshot as binary data
  - `take_json` - Get screenshot with JSON metadata
  - `generate_url` - Create signed URLs
  - `batch` - Batch process multiple URLs
  - `batch_advanced` - Batch with per-URL options
  - `get_batch` - Check batch status
  - `presets` - List available presets
  - `preset` - Get specific preset
  - `devices` - List device presets
  - `cache` - Access cache manager
- `TakeOptions` fluent builder with 58+ methods
  - Viewport: `width`, `height`, `scale`, `mobile`
  - Capture: `full_page`, `element`, `format`, `quality`
  - Wait: `wait_for`, `delay`, `wait_for_selector`, `wait_for_timeout`
  - Presets: `preset`, `device`
  - Blocking: `block_ads`, `block_trackers`, `block_cookie_banners`, `block_chat_widgets`, `block_urls`, `block_resources`
  - Page: `inject_script`, `inject_style`, `click`, `hide`, `remove`
  - Browser: `dark_mode`, `reduced_motion`, `media_type`, `user_agent`, `timezone`, `locale`, `geolocation`
  - Network: `headers`, `cookies`, `auth_basic`, `auth_bearer`, `bypass_csp`
  - Cache: `cache_ttl`, `cache_refresh`
  - PDF: All PDF-specific options
  - Storage: `storage_enabled`, `storage_path`, `storage_acl`
- `CacheManager` for cache operations
  - `get`, `delete`, `purge`, `purge_url`, `purge_before`, `purge_pattern`
- `Webhook` module for webhook verification
  - `verify` - HMAC-SHA256 signature verification
  - `parse` - Parse webhook payload
  - `extract_headers` - Extract signature/timestamp from headers
- Error hierarchy with `retryable?` support
  - `ValidationError`, `AuthenticationError`, `AuthorizationError`
  - `NotFoundError`, `RateLimitError`, `TimeoutError`
  - `ServerError`, `ConnectionError`
- Global configuration via `RenderScreenshot.configure`
- Dependabot for automated dependency updates
- Full test coverage with Minitest (142 tests, 97% coverage)

### Security

- Faraday minimum version set to >= 2.12.3 (AIKIDO-2025-10223 vulnerability in earlier versions)

### Requirements

- Ruby >= 3.2.0
- Faraday >= 2.12.3, < 3.0

[1.0.0]: https://github.com/Render-Screenshot/rs-ruby/releases/tag/v1.0.0
