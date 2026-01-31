# frozen_string_literal: true

require 'test_helper'

class ClientTest < Minitest::Test
  def setup
    @client = RenderScreenshot::Client.new(TEST_API_KEY)
  end

  def test_initialization_with_api_key
    client = RenderScreenshot::Client.new('rs_live_abc123')
    assert_instance_of RenderScreenshot::Client, client
  end

  def test_initialization_raises_without_api_key
    assert_raises(RenderScreenshot::AuthenticationError) do
      RenderScreenshot::Client.new(nil)
    end

    assert_raises(RenderScreenshot::AuthenticationError) do
      RenderScreenshot::Client.new('')
    end
  end

  def test_initialization_with_custom_base_url
    client = RenderScreenshot::Client.new(TEST_API_KEY, base_url: 'https://custom.api.com')
    assert_equal 'https://custom.api.com', client.http.base_url
  end

  def test_initialization_with_custom_timeout
    client = RenderScreenshot::Client.new(TEST_API_KEY, timeout: 60)
    assert_equal 60, client.http.timeout
  end

  def test_take_returns_binary_data
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(
        headers: { 'Authorization' => "Bearer #{TEST_API_KEY}" },
        body: hash_including(url: 'https://example.com')
      )
      .to_return(
        status: 200,
        body: 'binary_image_data',
        headers: { 'Content-Type' => 'image/png' }
      )

    options = RenderScreenshot::TakeOptions.url('https://example.com')
    result = @client.take(options)

    assert_equal 'binary_image_data', result
  end

  def test_take_with_hash_options
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(url: 'https://example.com', preset: 'og_card'))
      .to_return(status: 200, body: 'image_data', headers: { 'Content-Type' => 'image/png' })

    result = @client.take(url: 'https://example.com', preset: 'og_card')
    assert_equal 'image_data', result
  end

  def test_take_json_returns_hash
    response_body = {
      'id' => 'req_123',
      'status' => 'completed',
      'image' => { 'url' => 'https://cdn.example.com/img.png', 'width' => 1200, 'height' => 630 }
    }

    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    options = RenderScreenshot::TakeOptions.url('https://example.com')
    result = @client.take_json(options)

    assert_equal 'req_123', result['id']
    assert_equal 'completed', result['status']
    assert_equal 1200, result['image']['width']
  end

  def test_generate_url
    client = RenderScreenshot::Client.new(
      TEST_API_KEY,
      signing_key: 'rs_secret_abc123',
      public_key_id: 'rs_pub_xyz789'
    )
    options = RenderScreenshot::TakeOptions.url('https://example.com').preset('og_card')
    expires_at = Time.at(1_705_600_000)

    url = client.generate_url(options, expires_at: expires_at)

    assert_includes url, 'https://api.renderscreenshot.com/v1/screenshot?'
    assert_includes url, 'url=https%3A%2F%2Fexample.com'
    assert_includes url, 'expires=1705600000'
    assert_includes url, 'key_id=rs_pub_xyz789'
    assert_includes url, 'signature='
  end

  def test_generate_url_with_unix_timestamp
    client = RenderScreenshot::Client.new(
      TEST_API_KEY,
      signing_key: 'rs_secret_abc123',
      public_key_id: 'rs_pub_xyz789'
    )
    options = RenderScreenshot::TakeOptions.url('https://example.com')
    url = client.generate_url(options, expires_at: 1_705_600_000)

    assert_includes url, 'expires=1705600000'
    assert_includes url, 'key_id=rs_pub_xyz789'
  end

  def test_generate_url_with_inline_credentials
    options = RenderScreenshot::TakeOptions.url('https://example.com')
    url = @client.generate_url(
      options,
      expires_at: 1_705_600_000,
      signing_key: 'rs_secret_inline',
      public_key_id: 'rs_pub_inline'
    )

    assert_includes url, 'key_id=rs_pub_inline'
    assert_includes url, 'signature='
  end

  def test_generate_url_without_credentials_raises_error
    options = RenderScreenshot::TakeOptions.url('https://example.com')

    error = assert_raises(RenderScreenshot::ValidationError) do
      @client.generate_url(options, expires_at: 1_705_600_000)
    end

    assert_includes error.message, 'signing_key'
    assert_includes error.message, 'public_key_id'
  end

  def test_batch_with_urls
    response_body = {
      'id' => 'batch_123',
      'status' => 'completed',
      'results' => [
        { 'url' => 'https://example1.com', 'status' => 'completed' },
        { 'url' => 'https://example2.com', 'status' => 'completed' }
      ]
    }

    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(urls: ['https://example1.com', 'https://example2.com']))
      .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.batch(['https://example1.com', 'https://example2.com'])

    assert_equal 'batch_123', result['id']
    assert_equal 2, result['results'].length
  end

  def test_batch_with_options
    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(
        urls: ['https://example.com'],
        options: hash_including(preset: 'og_card')
      ))
      .to_return(status: 200, body: '{"id": "batch_123"}', headers: { 'Content-Type' => 'application/json' })

    options = RenderScreenshot::TakeOptions.url('https://example.com').preset('og_card')
    result = @client.batch(['https://example.com'], options: options)

    assert_equal 'batch_123', result['id']
  end

  def test_batch_advanced
    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(requests: [
                                   hash_including(url: 'https://example1.com'),
                                   hash_including(url: 'https://example2.com')
                                 ]))
      .to_return(status: 200, body: '{"id": "batch_123"}', headers: { 'Content-Type' => 'application/json' })

    requests = [
      { url: 'https://example1.com', options: { preset: 'og_card' } },
      { url: 'https://example2.com', options: { preset: 'twitter_card' } }
    ]
    result = @client.batch_advanced(requests)

    assert_equal 'batch_123', result['id']
  end

  def test_get_batch
    response_body = {
      'id' => 'batch_123',
      'status' => 'processing',
      'total' => 10,
      'completed' => 5
    }

    stub_request(:get, "#{TEST_BASE_URL}/v1/batch/batch_123")
      .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.get_batch('batch_123')

    assert_equal 'batch_123', result['id']
    assert_equal 'processing', result['status']
  end

  def test_presets
    response_body = {
      'presets' => [
        { 'id' => 'og_card', 'name' => 'Open Graph Card' },
        { 'id' => 'twitter_card', 'name' => 'Twitter Card' }
      ]
    }

    stub_request(:get, "#{TEST_BASE_URL}/v1/presets")
      .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.presets

    assert_equal 2, result.length
    assert_equal 'og_card', result[0]['id']
  end

  def test_preset
    response_body = { 'id' => 'og_card', 'name' => 'Open Graph Card', 'width' => 1200, 'height' => 630 }

    stub_request(:get, "#{TEST_BASE_URL}/v1/presets/og_card")
      .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.preset('og_card')

    assert_equal 'og_card', result['id']
    assert_equal 1200, result['width']
  end

  def test_devices
    response_body = {
      'devices' => [
        { 'id' => 'iphone_14_pro', 'name' => 'iPhone 14 Pro' },
        { 'id' => 'pixel_7', 'name' => 'Google Pixel 7' }
      ]
    }

    stub_request(:get, "#{TEST_BASE_URL}/v1/devices")
      .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.devices

    assert_equal 2, result.length
    assert_equal 'iphone_14_pro', result[0]['id']
  end

  def test_usage
    response_body = {
      'credits' => 1000,
      'used' => 250,
      'remaining' => 750,
      'period_start' => '2024-01-01T00:00:00Z',
      'period_end' => '2024-02-01T00:00:00Z'
    }

    stub_request(:get, "#{TEST_BASE_URL}/v1/usage")
      .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.usage

    assert_equal 1000, result['credits']
    assert_equal 250, result['used']
    assert_equal 750, result['remaining']
  end

  def test_cache_returns_cache_manager
    cache = @client.cache
    assert_instance_of RenderScreenshot::CacheManager, cache

    # Returns same instance
    assert_same cache, @client.cache
  end

  def test_handles_api_errors
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 400,
        body: { 'error' => { 'message' => 'Invalid URL', 'code' => 'invalid_url' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_raises(RenderScreenshot::ValidationError) do
      @client.take(url: 'invalid')
    end
  end

  def test_handles_rate_limit_with_retry_after
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 429,
        body: { 'error' => { 'message' => 'Rate limited' } }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Retry-After' => '60' }
      )

    error = assert_raises(RenderScreenshot::RateLimitError) do
      @client.take(url: 'https://example.com')
    end

    assert_equal 60, error.retry_after
    assert error.retryable?
  end

  def test_handles_server_error
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 500,
        body: { 'error' => { 'message' => 'Internal error' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    error = assert_raises(RenderScreenshot::ServerError) do
      @client.take(url: 'https://example.com')
    end

    assert error.retryable?
  end

  # Retry tests

  def test_initialization_with_retry_options
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 3, retry_delay: 2.0)
    assert_equal 3, client.http.max_retries
    assert_equal 2.0, client.http.retry_delay
  end

  def test_default_retry_options
    assert_equal 0, @client.http.max_retries
    assert_equal 1.0, @client.http.retry_delay
  end

  def test_retry_on_server_error
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 2, retry_delay: 0.01)

    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        { status: 500, body: { 'error' => { 'message' => 'Server error' } }.to_json,
          headers: { 'Content-Type' => 'application/json' } },
        { status: 500, body: { 'error' => { 'message' => 'Server error' } }.to_json,
          headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: 'image_data', headers: { 'Content-Type' => 'image/png' } }
      )

    result = client.take(url: 'https://example.com')
    assert_equal 'image_data', result
  end

  def test_retry_exhausted_raises_error
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 2, retry_delay: 0.01)

    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 500,
        body: { 'error' => { 'message' => 'Server error' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_raises(RenderScreenshot::ServerError) do
      client.take(url: 'https://example.com')
    end

    # Should have made 3 attempts (1 initial + 2 retries)
    assert_requested :post, "#{TEST_BASE_URL}/v1/screenshot", times: 3
  end

  def test_no_retry_on_validation_error
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 2, retry_delay: 0.01)

    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 400,
        body: { 'error' => { 'message' => 'Invalid URL' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_raises(RenderScreenshot::ValidationError) do
      client.take(url: 'invalid')
    end

    # Should have made only 1 attempt (no retries for non-retryable errors)
    assert_requested :post, "#{TEST_BASE_URL}/v1/screenshot", times: 1
  end

  def test_retry_on_rate_limit_respects_retry_after
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 1, retry_delay: 0.01)

    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        { status: 429, body: { 'error' => { 'message' => 'Rate limited' } }.to_json,
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '0' } },
        { status: 200, body: 'image_data', headers: { 'Content-Type' => 'image/png' } }
      )

    result = client.take(url: 'https://example.com')
    assert_equal 'image_data', result
  end

  def test_retry_on_timeout_error
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 1, retry_delay: 0.01)

    call_count = 0
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return do |_request|
        call_count += 1
        raise Faraday::TimeoutError if call_count == 1

        { status: 200, body: 'image_data', headers: { 'Content-Type' => 'image/png' } }
      end

    result = client.take(url: 'https://example.com')
    assert_equal 'image_data', result
  end

  def test_retry_on_connection_error
    client = RenderScreenshot::Client.new(TEST_API_KEY, max_retries: 1, retry_delay: 0.01)

    call_count = 0
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return do |_request|
        call_count += 1
        raise Faraday::ConnectionFailed, 'Connection refused' if call_count == 1

        { status: 200, body: 'image_data', headers: { 'Content-Type' => 'image/png' } }
      end

    result = client.take(url: 'https://example.com')
    assert_equal 'image_data', result
  end
end
