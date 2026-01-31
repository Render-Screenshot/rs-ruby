# frozen_string_literal: true

require 'test_helper'

# Example tests demonstrating batch processing workflows
# These tests serve as documentation and verify batch functionality
class BatchTest < Minitest::Test
  def setup
    @client = RenderScreenshot::Client.new(TEST_API_KEY)
  end

  # Example: Batch process multiple URLs with shared options
  def test_batch_with_shared_options
    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(
        urls: %w[https://example1.com https://example2.com https://example3.com],
        options: hash_including(preset: 'og_card')
      ))
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_abc123',
          'status' => 'processing',
          'total' => 3,
          'completed' => 0
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    urls = %w[
      https://example1.com
      https://example2.com
      https://example3.com
    ]

    # Shared options apply to all URLs
    options = RenderScreenshot::TakeOptions
              .url('') # URL not needed, just for options
              .preset('og_card')

    result = @client.batch(urls, options: options)

    assert_equal 'batch_abc123', result['id']
    assert_equal 'processing', result['status']
  end

  # Example: Batch process without options
  def test_batch_urls_only
    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: { urls: %w[https://site1.com https://site2.com] })
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_xyz789',
          'status' => 'completed',
          'total' => 2,
          'completed' => 2,
          'results' => [
            { 'url' => 'https://site1.com', 'status' => 'completed', 'image_url' => 'https://cdn/1.png' },
            { 'url' => 'https://site2.com', 'status' => 'completed', 'image_url' => 'https://cdn/2.png' }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    urls = %w[https://site1.com https://site2.com]
    result = @client.batch(urls)

    assert_equal 'completed', result['status']
    assert_equal 2, result['results'].length
  end

  # Example: Batch with per-URL options using batch_advanced
  def test_batch_with_per_url_options
    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(
        requests: [
          hash_including(url: 'https://desktop-site.com', preset: 'og_card'),
          hash_including(url: 'https://mobile-site.com', device: 'iphone_14_pro'),
          hash_including(url: 'https://pdf-site.com', format: 'pdf')
        ]
      ))
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_advanced123',
          'status' => 'processing',
          'total' => 3,
          'completed' => 0
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Each request can have different options
    requests = [
      { url: 'https://desktop-site.com', options: { preset: 'og_card' } },
      { url: 'https://mobile-site.com', options: { device: 'iphone_14_pro' } },
      { url: 'https://pdf-site.com', options: { format: 'pdf' } }
    ]

    result = @client.batch_advanced(requests)

    assert_equal 'batch_advanced123', result['id']
    assert_equal 3, result['total']
  end

  # Example: Check batch job status
  def test_check_batch_status
    stub_request(:get, "#{TEST_BASE_URL}/v1/batch/batch_abc123")
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_abc123',
          'status' => 'processing',
          'total' => 10,
          'completed' => 7,
          'failed' => 1,
          'results' => [
            { 'url' => 'https://example1.com', 'status' => 'completed', 'image_url' => 'https://cdn/1.png' },
            { 'url' => 'https://example2.com', 'status' => 'failed', 'error' => 'Page not found' }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @client.get_batch('batch_abc123')

    assert_equal 'processing', result['status']
    assert_equal 10, result['total']
    assert_equal 7, result['completed']
    assert_equal 1, result['failed']
  end

  # Example: Poll batch until completion
  def test_polling_batch_status
    # First call - still processing
    stub_request(:get, "#{TEST_BASE_URL}/v1/batch/batch_poll")
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_poll',
          'status' => 'completed',
          'total' => 5,
          'completed' => 5,
          'results' => [
            { 'url' => 'https://url1.com', 'status' => 'completed' },
            { 'url' => 'https://url2.com', 'status' => 'completed' },
            { 'url' => 'https://url3.com', 'status' => 'completed' },
            { 'url' => 'https://url4.com', 'status' => 'completed' },
            { 'url' => 'https://url5.com', 'status' => 'completed' }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Simulates polling loop (simplified for test)
    result = @client.get_batch('batch_poll')

    # In real code, you'd loop until status != 'processing'
    assert_equal 'completed', result['status']
    assert_equal 5, result['results'].length
  end

  # Example: Batch with hash options instead of TakeOptions
  def test_batch_with_hash_options
    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(
        urls: ['https://example.com'],
        options: { width: 1920, height: 1080, format: 'jpeg' }
      ))
      .to_return(
        status: 200,
        body: { 'id' => 'batch_hash' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @client.batch(
      ['https://example.com'],
      options: { width: 1920, height: 1080, format: 'jpeg' }
    )

    assert_equal 'batch_hash', result['id']
  end

  # Example: Large batch processing
  def test_large_batch
    large_url_list = (1..100).map { |i| "https://example#{i}.com" }

    stub_request(:post, "#{TEST_BASE_URL}/v1/batch")
      .with(body: hash_including(urls: large_url_list))
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_large',
          'status' => 'queued',
          'total' => 100,
          'completed' => 0
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @client.batch(large_url_list)

    assert_equal 'queued', result['status']
    assert_equal 100, result['total']
  end

  # Example: Handle batch with partial failures
  def test_batch_with_partial_failures
    stub_request(:get, "#{TEST_BASE_URL}/v1/batch/batch_partial")
      .to_return(
        status: 200,
        body: {
          'id' => 'batch_partial',
          'status' => 'completed',
          'total' => 3,
          'completed' => 2,
          'failed' => 1,
          'results' => [
            { 'url' => 'https://good1.com', 'status' => 'completed', 'image_url' => 'https://cdn/good1.png' },
            { 'url' => 'https://bad.com', 'status' => 'failed', 'error' => 'Connection timeout' },
            { 'url' => 'https://good2.com', 'status' => 'completed', 'image_url' => 'https://cdn/good2.png' }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @client.get_batch('batch_partial')

    # Filter successful and failed results
    completed = result['results'].select { |r| r['status'] == 'completed' }
    failed = result['results'].select { |r| r['status'] == 'failed' }

    assert_equal 2, completed.length
    assert_equal 1, failed.length
    assert_equal 'Connection timeout', failed.first['error']
  end
end
