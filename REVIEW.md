# Ruby SDK Code Review

## Critical Issues (Fixed)

### 1. Webhook Header Name Mismatch - FIXED
The SDK used `X-RenderScreenshot-Signature` and `X-RenderScreenshot-Timestamp` but the API sends `X-Webhook-Signature` and `X-Webhook-Timestamp`.

### 2. Signed URL Implementation Broken - FIXED
The `extract_key_id` method tried to derive `rs_pub_` from `rs_live_` via string replacement. The API requires separate public/secret key pairs. Now requires explicit `signing_key` and `public_key_id` parameters.

---

## Medium Issues (Fixed)

### 3. Inconsistent Response Key Types - FIXED
All API responses now consistently return **string keys**. Removed `symbolize_response` from CacheManager.

### 4. PDF Margin Handling - FIXED
Clarified logic: uniform margin (string like "2cm") is handled separately from individual margins (hash with top/right/bottom/left).

### 5. Thread Safety - FIXED
Added `Mutex` for thread-safe lazy initialization of the Faraday connection using double-checked locking pattern.

### 6. Missing API Endpoint: Usage - FIXED
Added `usage` method to Client that calls `GET /v1/usage`.

---

## Minor Issues / Suggestions

### 7. No Built-in Retry Logic - FIXED
Added built-in retry support with exponential backoff:
```ruby
client = RenderScreenshot::Client.new(api_key, max_retries: 3, retry_delay: 1.0)
```

Features:
- Automatic retries for retryable errors (server errors, rate limits, timeouts, connection errors)
- Exponential backoff with jitter
- Respects `Retry-After` header from rate limit responses
- Non-retryable errors (validation, auth) fail immediately

### 8. Global Configuration State
**Location:** `lib/renderscreenshot/configuration.rb`

`RenderScreenshot.configuration` is a global singleton. This makes testing harder and doesn't support multi-tenant scenarios where different parts of an app need different configurations.

**Recommendation:** The current design where `Client.new` accepts overrides is good. Document that users should pass configuration to the client rather than relying on global config.

### 9. No Input Validation
**Location:** `lib/renderscreenshot/take_options.rb`

`TakeOptions` accepts any values without validation:
- `quality` should be 1-100
- `format` should be png/jpeg/webp/pdf
- `scale` should be 0.1-2.0

**Recommendation:** Add optional validation:
```ruby
def quality(value)
  raise ValidationError, "quality must be 1-100" unless (1..100).include?(value)
  with(quality: value)
end
```

Or validate in `to_params` before sending to API.

### 10. Missing Faraday Middleware
**Location:** `lib/renderscreenshot/http_client.rb`

The HTTP client doesn't use Faraday middleware for:
- JSON encoding/decoding (manual `JSON.generate`/`JSON.parse`)
- Logging/instrumentation
- Automatic retries

**Recommendation:** Consider using standard middleware:
```ruby
Faraday.new(url: base_url) do |faraday|
  faraday.request :json
  faraday.response :json
  faraday.response :logger if debug?
  faraday.adapter Faraday.default_adapter
end
```

### 11. Ruby Version Requirement
**Location:** `renderscreenshot.gemspec:16`

```ruby
spec.required_ruby_version = '>= 3.0.0'
```

Ruby 3.0 was released December 2020. This excludes Ruby 2.7 which is still in use. However, Ruby 2.7 reached EOL in March 2023, so requiring 3.0+ is reasonable for a new gem.

**Recommendation:** No change needed, but document in README that Ruby 3.0+ is required.

### 12. Module vs Class for Webhook
**Location:** `lib/renderscreenshot/webhook.rb`

`Webhook` is a module with `module_function` which is an unusual pattern. Works fine but differs from the class-based approach used elsewhere.

**Recommendation:** Consider consistency - either use a class with class methods or keep as module. Current approach is fine, just document why.

---

## What's Good

- **Immutable `TakeOptions` builder pattern** - Clean, prevents side effects
- **`frozen_string_literal: true` everywhere** - Good practice
- **Well-structured error hierarchy** with `retryable?` method
- **Timing-safe comparison** in webhook verification (`secure_compare`)
- **Good test coverage** (96.32%) with WebMock for HTTP stubbing
- **Clean YARD documentation** on public methods
- **Faraday for HTTP** - Well-maintained, supports middleware

---

## Priority for Fixes

1. ~~**High:** Thread safety (#5) - Can cause production issues~~ ✅ FIXED
2. ~~**Medium:** Missing usage endpoint (#6) - Feature completeness~~ ✅ FIXED
3. ~~**Medium:** Inconsistent response keys (#3) - Developer experience~~ ✅ FIXED
4. ~~**Low:** PDF margin handling (#4) - Edge case~~ ✅ FIXED
5. **Low:** Input validation (#9) - Nice to have
6. ~~**Low:** Retry logic (#7) - Nice to have~~ ✅ FIXED
