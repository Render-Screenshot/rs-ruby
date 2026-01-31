# RenderScreenshot Ruby SDK

The official Ruby SDK for [RenderScreenshot](https://renderscreenshot.com) - a developer-friendly screenshot API for capturing web pages programmatically.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'renderscreenshot'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install renderscreenshot
```

## Requirements

- Ruby 3.0 or higher

## Quick Start

```ruby
require 'renderscreenshot'

# Create a client
client = RenderScreenshot.client('rs_live_your_api_key')

# Take a screenshot
image_data = client.take(
  RenderScreenshot::TakeOptions
    .url('https://example.com')
    .width(1200)
    .height(630)
    .format('png')
)

# Save to file
File.binwrite('screenshot.png', image_data)
```

## Configuration

### Global Configuration

```ruby
RenderScreenshot.configure do |config|
  config.base_url = 'https://api.renderscreenshot.com'  # Default
  config.timeout = 30  # Default timeout in seconds
end
```

### Per-Client Configuration

```ruby
client = RenderScreenshot.client(
  'rs_live_your_api_key',
  base_url: 'https://custom.api.com',
  timeout: 60
)
```

## Usage

### Taking Screenshots

#### Binary Response

```ruby
# Get screenshot as binary data
image_data = client.take(
  RenderScreenshot::TakeOptions
    .url('https://example.com')
    .preset('og_card')
)
```

#### JSON Response (with metadata)

```ruby
# Get screenshot URL and metadata
response = client.take_json(
  RenderScreenshot::TakeOptions
    .url('https://example.com')
    .preset('og_card')
)

puts response['image']['url']      # CDN URL
puts response['image']['width']    # 1200
puts response['image']['height']   # 630
puts response['cache']['key']      # Cache key for later reference
```

### Screenshot Options

The `TakeOptions` class provides a fluent interface for configuring screenshots:

```ruby
options = RenderScreenshot::TakeOptions
  .url('https://example.com')
  # Viewport
  .width(1920)
  .height(1080)
  .scale(2)
  .mobile(true)
  # Capture
  .full_page
  .element('#main-content')
  .format('webp')
  .quality(90)
  # Wait conditions
  .wait_for('networkidle')
  .delay(500)
  .wait_for_selector('.loaded')
  # Blocking
  .block_ads
  .block_trackers
  .block_cookie_banners
  # Browser emulation
  .dark_mode
  .timezone('America/New_York')
  .locale('en-US')
```

### Using Presets

```ruby
# Social card presets
options = RenderScreenshot::TakeOptions
  .url('https://example.com')
  .preset('og_card')  # 1200x630 for Open Graph

# Device presets
options = RenderScreenshot::TakeOptions
  .url('https://example.com')
  .device('iphone_14_pro')
```

### PDF Generation

```ruby
options = RenderScreenshot::TakeOptions
  .url('https://example.com')
  .format('pdf')
  .pdf_paper_size('a4')
  .pdf_landscape
  .pdf_print_background
  .pdf_margin('1cm')

pdf_data = client.take(options)
File.binwrite('document.pdf', pdf_data)
```

### Batch Processing

```ruby
# Simple batch (same options for all URLs)
response = client.batch(
  ['https://example1.com', 'https://example2.com', 'https://example3.com'],
  options: RenderScreenshot::TakeOptions.url('').preset('og_card')
)

response['results'].each do |result|
  puts "#{result['url']}: #{result['status']}"
end

# Advanced batch (per-URL options)
response = client.batch_advanced([
  { url: 'https://example1.com', options: { preset: 'og_card' } },
  { url: 'https://example2.com', options: { preset: 'twitter_card' } }
])
```

### Signed URLs

Generate signed URLs for client-side use without exposing your API key:

```ruby
options = RenderScreenshot::TakeOptions
  .url('https://example.com')
  .preset('og_card')

# URL expires in 24 hours
signed_url = client.generate_url(options, expires_at: Time.now + 86400)

# Use in HTML
# <img src="#{signed_url}" />
```

### Cache Management

```ruby
cache = client.cache

# Get cached screenshot
data = cache.get('cache_key_123')

# Delete cached entry
cache.delete('cache_key_123')

# Bulk purge
cache.purge(['key1', 'key2', 'key3'])

# Purge by URL pattern
cache.purge_url('https://example.com/*')

# Purge by date
cache.purge_before(Time.now - 86400 * 7)  # Older than 7 days

# Purge by storage path pattern
cache.purge_pattern('screenshots/2024/01/*')
```

### Presets and Devices

```ruby
# List all presets
presets = client.presets
presets.each { |p| puts "#{p['id']}: #{p['name']}" }

# Get specific preset
preset = client.preset('og_card')

# List all devices
devices = client.devices
devices.each { |d| puts "#{d['id']}: #{d['name']} (#{d['width']}x#{d['height']})" }
```

### Webhook Verification

```ruby
# In your webhook endpoint
def webhook_handler(request)
  payload = request.body.read
  signature, timestamp = RenderScreenshot::Webhook.extract_headers(request.headers)

  unless RenderScreenshot::Webhook.verify(
    payload: payload,
    signature: signature,
    timestamp: timestamp,
    secret: ENV['WEBHOOK_SECRET']
  )
    return [401, 'Invalid signature']
  end

  event = RenderScreenshot::Webhook.parse(payload)

  case event[:event]
  when 'screenshot.completed'
    handle_screenshot_completed(event[:data])
  when 'screenshot.failed'
    handle_screenshot_failed(event[:data])
  when 'batch.completed'
    handle_batch_completed(event[:data])
  end

  [200, 'OK']
end
```

## Error Handling

All API errors inherit from `RenderScreenshot::Error`:

```ruby
begin
  client.take(RenderScreenshot::TakeOptions.url('https://example.com'))
rescue RenderScreenshot::ValidationError => e
  puts "Invalid request: #{e.message}"
rescue RenderScreenshot::AuthenticationError => e
  puts "Auth failed: #{e.message}"
rescue RenderScreenshot::RateLimitError => e
  puts "Rate limited. Retry after #{e.retry_after} seconds"
  sleep(e.retry_after) if e.retry_after
  retry
rescue RenderScreenshot::TimeoutError => e
  puts "Request timed out" if e.retryable?
rescue RenderScreenshot::ServerError => e
  puts "Server error: #{e.message}"
  retry if e.retryable?
rescue RenderScreenshot::ConnectionError => e
  puts "Connection failed: #{e.message}"
end
```

Error properties:
- `http_status` - HTTP status code
- `code` - Error code from API
- `message` - Human-readable message
- `request_id` - Request ID for support
- `retry_after` - Seconds to wait (rate limits)
- `retryable?` - Whether the error can be retried

## Complete Options Reference

| Category | Methods |
|----------|---------|
| **Viewport** | `width`, `height`, `scale`, `mobile` |
| **Capture** | `full_page`, `element`, `format`, `quality` |
| **Wait** | `wait_for`, `delay`, `wait_for_selector`, `wait_for_timeout` |
| **Preset** | `preset`, `device` |
| **Blocking** | `block_ads`, `block_trackers`, `block_cookie_banners`, `block_chat_widgets`, `block_urls`, `block_resources` |
| **Page** | `inject_script`, `inject_style`, `click`, `hide`, `remove` |
| **Browser** | `dark_mode`, `reduced_motion`, `media_type`, `user_agent`, `timezone`, `locale`, `geolocation` |
| **Network** | `headers`, `cookies`, `auth_basic`, `auth_bearer`, `bypass_csp` |
| **Cache** | `cache_ttl`, `cache_refresh` |
| **PDF** | `pdf_paper_size`, `pdf_width`, `pdf_height`, `pdf_landscape`, `pdf_margin`, `pdf_margin_top`, `pdf_margin_right`, `pdf_margin_bottom`, `pdf_margin_left`, `pdf_scale`, `pdf_print_background`, `pdf_page_ranges`, `pdf_header`, `pdf_footer`, `pdf_fit_one_page`, `pdf_prefer_css_page_size` |
| **Storage** | `storage_enabled`, `storage_path`, `storage_acl` |

## Development

After checking out the repo:

```bash
bundle install
bundle exec rake test      # Run tests
bundle exec rubocop        # Run linter
bundle exec rake           # Run both
```

### Pre-commit Hooks

This project uses pre-commit hooks to prevent secrets from being committed:

```bash
# Install pre-commit (if not already installed)
brew install pre-commit    # macOS
pip install pre-commit     # or via pip

# Install the hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

The hooks include:
- **Gitleaks** - Scans for secrets and API keys
- **detect-private-key** - Prevents committing private keys
- **check-added-large-files** - Prevents large files (>500KB)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/renderscreenshot/renderscreenshot-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
