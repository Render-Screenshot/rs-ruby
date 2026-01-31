# frozen_string_literal: true

require 'test_helper'

# Example tests demonstrating basic screenshot workflows
# These tests serve as documentation and verify SDK functionality
class QuickStartTest < Minitest::Test
  def setup
    @client = RenderScreenshot::Client.new(TEST_API_KEY)
  end

  # Example: Take a basic screenshot and get binary data
  def test_basic_screenshot
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(url: 'https://example.com'))
      .to_return(
        status: 200,
        body: 'PNG_BINARY_DATA',
        headers: { 'Content-Type' => 'image/png' }
      )

    # Using TakeOptions builder
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')

    binary_data = @client.take(options)

    assert_equal 'PNG_BINARY_DATA', binary_data
  end

  # Example: Take a screenshot with JSON response containing metadata
  def test_screenshot_with_json_response
    response_body = {
      'id' => 'req_abc123',
      'status' => 'completed',
      'image' => {
        'url' => 'https://cdn.renderscreenshot.com/screenshots/abc123.png',
        'width' => 1200,
        'height' => 630
      },
      'cache' => {
        'hit' => false,
        'key' => 'cache_xyz789'
      }
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

    assert_equal 'completed', result['status']
    assert_equal 1200, result['image']['width']
    assert_equal 'cache_xyz789', result['cache']['key']
  end

  # Example: Using presets for common use cases
  def test_using_presets
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(url: 'https://example.com', preset: 'og_card'))
      .to_return(status: 200, body: 'image_data', headers: { 'Content-Type' => 'image/png' })

    # Open Graph card preset (1200x630)
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .preset('og_card')

    result = @client.take(options)
    assert_equal 'image_data', result
  end

  # Example: Using device emulation
  def test_using_device_emulation
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(url: 'https://example.com', viewport: hash_including(device: 'iphone_14_pro')))
      .to_return(status: 200, body: 'mobile_screenshot', headers: { 'Content-Type' => 'image/png' })

    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .device('iphone_14_pro')

    result = @client.take(options)
    assert_equal 'mobile_screenshot', result
  end

  # Example: Custom viewport dimensions
  def test_custom_viewport
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(
        url: 'https://example.com',
        viewport: { width: 1920, height: 1080 }
      ))
      .to_return(status: 200, body: 'hd_screenshot', headers: { 'Content-Type' => 'image/png' })

    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .width(1920)
              .height(1080)

    result = @client.take(options)
    assert_equal 'hd_screenshot', result
  end

  # Example: Full page screenshot
  def test_full_page_screenshot
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(url: 'https://example.com', capture: hash_including(mode: 'full_page')))
      .to_return(status: 200, body: 'full_page_data', headers: { 'Content-Type' => 'image/png' })

    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .full_page

    result = @client.take(options)
    assert_equal 'full_page_data', result
  end

  # Example: Screenshot as PDF
  def test_pdf_output
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(url: 'https://example.com', output: hash_including(format: 'pdf')))
      .to_return(status: 200, body: 'PDF_BINARY', headers: { 'Content-Type' => 'application/pdf' })

    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .format('pdf')

    result = @client.take(options)
    assert_equal 'PDF_BINARY', result
  end

  # Example: Screenshot with wait strategies
  def test_wait_for_selector
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(
        url: 'https://example.com',
        wait: hash_including(for_selector: '#main-content')
      ))
      .to_return(status: 200, body: 'screenshot', headers: { 'Content-Type' => 'image/png' })

    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .wait_for_selector('#main-content')

    result = @client.take(options)
    assert_equal 'screenshot', result
  end

  # Example: Using Hash instead of TakeOptions
  def test_using_hash_options
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .with(body: hash_including(
        url: 'https://example.com',
        preset: 'twitter_card',
        format: 'jpeg'
      ))
      .to_return(status: 200, body: 'jpeg_data', headers: { 'Content-Type' => 'image/jpeg' })

    # Plain hash also works
    result = @client.take(
      url: 'https://example.com',
      preset: 'twitter_card',
      format: 'jpeg'
    )

    assert_equal 'jpeg_data', result
  end

  # Example: Listing available presets
  def test_list_presets
    stub_request(:get, "#{TEST_BASE_URL}/v1/presets")
      .to_return(
        status: 200,
        body: {
          'presets' => [
            { 'id' => 'og_card', 'name' => 'Open Graph Card', 'width' => 1200, 'height' => 630 },
            { 'id' => 'twitter_card', 'name' => 'Twitter Card', 'width' => 1200, 'height' => 600 },
            { 'id' => 'full_page', 'name' => 'Full Page', 'full_page' => true }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    presets = @client.presets

    assert_equal 3, presets.length
    assert_equal 'og_card', presets[0]['id']
  end

  # Example: Listing available devices
  def test_list_devices
    stub_request(:get, "#{TEST_BASE_URL}/v1/devices")
      .to_return(
        status: 200,
        body: {
          'devices' => [
            { 'id' => 'iphone_14_pro', 'name' => 'iPhone 14 Pro', 'width' => 393, 'height' => 852 },
            { 'id' => 'pixel_7', 'name' => 'Google Pixel 7', 'width' => 412, 'height' => 915 }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    devices = @client.devices

    assert_equal 2, devices.length
    assert_equal 'iphone_14_pro', devices[0]['id']
  end

  # Example: Error handling
  def test_error_handling
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 400,
        body: { 'error' => { 'message' => 'Invalid URL format', 'code' => 'invalid_url' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    error = assert_raises(RenderScreenshot::ValidationError) do
      @client.take(url: 'not-a-valid-url')
    end

    assert_equal 'Invalid URL format', error.message
    assert_equal 'invalid_url', error.code
    assert_equal 400, error.http_status
  end

  # Example: Rate limit handling with retry
  def test_rate_limit_with_retry_after
    stub_request(:post, "#{TEST_BASE_URL}/v1/screenshot")
      .to_return(
        status: 429,
        body: { 'error' => { 'message' => 'Rate limit exceeded' } }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
      )

    error = assert_raises(RenderScreenshot::RateLimitError) do
      @client.take(url: 'https://example.com')
    end

    assert error.retryable?
    assert_equal 30, error.retry_after
    # Can use error.retry_after to implement backoff
  end
end
