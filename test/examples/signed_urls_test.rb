# frozen_string_literal: true

require 'test_helper'

# Example tests demonstrating signed URL workflows
# These tests serve as documentation and verify signed URL functionality
class SignedUrlsTest < Minitest::Test
  SIGNING_KEY = 'rs_secret_test12345678901234567890'
  PUBLIC_KEY_ID = 'rs_pub_test12345678901234567890ab'

  def setup
    @client = RenderScreenshot::Client.new(
      TEST_API_KEY,
      signing_key: SIGNING_KEY,
      public_key_id: PUBLIC_KEY_ID
    )
  end

  # Example: Generate a signed URL with Time expiration
  def test_generate_signed_url_with_time
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .preset('og_card')

    # Expires 1 hour from now
    expires_at = Time.now + 3600

    url = @client.generate_url(options, expires_at: expires_at)

    assert_includes url, 'https://api.renderscreenshot.com/v1/screenshot?'
    assert_includes url, 'url=https%3A%2F%2Fexample.com'
    assert_includes url, 'preset=og_card'
    assert_includes url, "expires=#{expires_at.to_i}"
    assert_includes url, "key_id=#{PUBLIC_KEY_ID}"
    assert_includes url, 'signature='
  end

  # Example: Generate a signed URL with Unix timestamp
  def test_generate_signed_url_with_unix_timestamp
    options = RenderScreenshot::TakeOptions.url('https://example.com')

    # Specific expiration timestamp
    expires_at = 1_705_600_000

    url = @client.generate_url(options, expires_at: expires_at)

    assert_includes url, 'expires=1705600000'
    assert_includes url, "key_id=#{PUBLIC_KEY_ID}"
    assert_includes url, 'signature='
  end

  # Example: Signed URL for client-side usage
  def test_signed_url_for_client_side
    options = RenderScreenshot::TakeOptions
              .url('https://user-content.example.com/page')
              .width(800)
              .height(600)

    # Short expiration for security
    expires_at = Time.now + 300 # 5 minutes

    url = @client.generate_url(options, expires_at: expires_at)

    # This URL can be given to the client/browser
    # No API key exposed, signature validates the request
    assert_includes url, "key_id=#{PUBLIC_KEY_ID}"
    refute_includes url, TEST_API_KEY # API key not in URL
    refute_includes url, SIGNING_KEY # Secret key not in URL
  end

  # Example: Signed URL includes all parameters
  def test_signed_url_with_all_parameters
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .width(1920)
              .height(1080)
              .format('jpeg')
              .quality(85)

    url = @client.generate_url(options, expires_at: Time.now + 3600)

    # All parameters included in signed URL
    assert_includes url, 'url='
    assert_includes url, 'width=1920'
    assert_includes url, 'height=1080'
    assert_includes url, 'format=jpeg'
    assert_includes url, 'quality=85'
  end

  # Example: Hash options work with signed URLs too
  def test_signed_url_with_hash_options
    options = {
      url: 'https://example.com',
      preset: 'twitter_card'
    }

    url = @client.generate_url(options, expires_at: Time.now + 3600)

    assert_includes url, 'url='
    assert_includes url, 'preset=twitter_card'
    assert_includes url, 'signature='
  end

  # Example: Pass signing credentials inline
  def test_signed_url_with_inline_credentials
    client = RenderScreenshot::Client.new(TEST_API_KEY)
    options = RenderScreenshot::TakeOptions.url('https://example.com')

    url = client.generate_url(
      options,
      expires_at: Time.now + 3600,
      signing_key: SIGNING_KEY,
      public_key_id: PUBLIC_KEY_ID
    )

    assert_includes url, "key_id=#{PUBLIC_KEY_ID}"
    assert_includes url, 'signature='
  end

  # Example: Error when signing credentials missing
  def test_signed_url_without_credentials_raises_error
    client = RenderScreenshot::Client.new(TEST_API_KEY)
    options = RenderScreenshot::TakeOptions.url('https://example.com')

    error = assert_raises(RenderScreenshot::ValidationError) do
      client.generate_url(options, expires_at: Time.now + 3600)
    end

    assert_includes error.message, 'signing_key'
    assert_includes error.message, 'public_key_id'
  end

  # Example: Cache operations - get cached screenshot
  def test_cache_get
    stub_request(:get, "#{TEST_BASE_URL}/v1/cache/cache_key_abc123")
      .to_return(
        status: 200,
        body: 'CACHED_BINARY_DATA',
        headers: { 'Content-Type' => 'image/png' }
      )

    cache = @client.cache
    result = cache.get('cache_key_abc123')

    assert_equal 'CACHED_BINARY_DATA', result
  end

  # Example: Cache operations - get returns nil for miss
  def test_cache_miss
    stub_request(:get, "#{TEST_BASE_URL}/v1/cache/nonexistent_key")
      .to_return(
        status: 404,
        body: { 'error' => { 'message' => 'Not found' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cache = @client.cache
    result = cache.get('nonexistent_key')

    assert_nil result
  end

  # Example: Cache operations - delete entry
  def test_cache_delete
    stub_request(:delete, "#{TEST_BASE_URL}/v1/cache/cache_key_to_delete")
      .to_return(
        status: 200,
        body: { 'deleted' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cache = @client.cache
    result = cache.delete('cache_key_to_delete')

    assert result
  end

  # Example: Cache operations - purge multiple keys
  def test_cache_purge_keys
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { keys: %w[key1 key2 key3] })
      .to_return(
        status: 200,
        body: { 'purged' => 3, 'keys' => %w[key1 key2 key3] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cache = @client.cache
    result = cache.purge(%w[key1 key2 key3])

    assert_equal 3, result['purged']
  end

  # Example: Cache operations - purge by URL pattern
  def test_cache_purge_by_url
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { url: 'https://example.com/*' })
      .to_return(
        status: 200,
        body: { 'purged' => 15 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cache = @client.cache
    result = cache.purge_url('https://example.com/*')

    assert_equal 15, result['purged']
  end

  # Example: Cache operations - purge by date
  def test_cache_purge_before_date
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { before: '2024-01-15T00:00:00Z' })
      .to_return(
        status: 200,
        body: { 'purged' => 50 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    cache = @client.cache
    result = cache.purge_before(Time.utc(2024, 1, 15))

    assert_equal 50, result['purged']
  end

  # Example: Webhook verification
  def test_webhook_verification
    webhook_secret = 'whsec_your_webhook_secret'
    timestamp = Time.now.to_i.to_s
    payload = '{"type": "screenshot.completed", "id": "evt_123"}'

    # Create valid signature (sha256= prefix required)
    signed_payload = "#{timestamp}.#{payload}"
    hash = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, signed_payload)
    signature = "sha256=#{hash}"

    # Verify webhook
    valid = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: signature,
      timestamp: timestamp,
      secret: webhook_secret
    )

    assert valid
  end

  # Example: Webhook parsing
  def test_webhook_parsing
    payload = '{"type": "screenshot.completed", "id": "evt_abc123", "data": {"url": "https://example.com", "image_url": "https://cdn/img.png"}}'

    event = RenderScreenshot::Webhook.parse(payload)

    assert_equal 'screenshot.completed', event[:event]
    assert_equal 'evt_abc123', event[:id]
    assert_equal 'https://example.com', event[:data]['url']
  end

  # Example: Extract headers from webhook request
  def test_webhook_extract_headers
    headers = {
      'X-Webhook-Signature' => 'sha256=abc123',
      'X-Webhook-Timestamp' => '1705600000',
      'X-Webhook-ID' => 'whk_test123'
    }

    result = RenderScreenshot::Webhook.extract_headers(headers)

    assert_equal 'sha256=abc123', result[:signature]
    assert_equal '1705600000', result[:timestamp]
    assert_equal 'whk_test123', result[:id]
  end

  # Example: Full webhook handling flow
  def test_complete_webhook_flow
    webhook_secret = 'whsec_example_secret'
    timestamp = Time.now.to_i.to_s
    payload = {
      type: 'screenshot.completed',
      id: 'evt_webhook_test',
      timestamp: Time.now.to_i,
      data: {
        url: 'https://example.com',
        image_url: 'https://cdn.renderscreenshot.com/screenshots/abc123.png',
        cache_key: 'cache_abc123'
      }
    }.to_json

    # Simulate signature from headers (sha256= prefix required)
    signed_payload = "#{timestamp}.#{payload}"
    hash = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, signed_payload)
    signature = "sha256=#{hash}"

    headers = {
      'X-Webhook-Signature' => signature,
      'X-Webhook-Timestamp' => timestamp,
      'X-Webhook-ID' => 'whk_flow_test'
    }

    # Step 1: Extract headers
    extracted = RenderScreenshot::Webhook.extract_headers(headers)

    # Step 2: Verify signature
    valid = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: extracted[:signature],
      timestamp: extracted[:timestamp],
      secret: webhook_secret
    )
    assert valid, 'Webhook signature should be valid'

    # Step 3: Parse event
    event = RenderScreenshot::Webhook.parse(payload)

    assert_equal 'screenshot.completed', event[:event]
    assert_equal 'https://cdn.renderscreenshot.com/screenshots/abc123.png', event[:data]['image_url']
  end
end
