# frozen_string_literal: true

require 'test_helper'

class CacheManagerTest < Minitest::Test
  def setup
    @client = RenderScreenshot::Client.new(TEST_API_KEY)
    @cache = @client.cache
  end

  def test_get_returns_binary_data
    stub_request(:get, "#{TEST_BASE_URL}/v1/cache/cache_key_123")
      .to_return(status: 200, body: 'binary_data', headers: { 'Content-Type' => 'image/png' })

    result = @cache.get('cache_key_123')

    assert_equal 'binary_data', result
  end

  def test_get_returns_nil_for_not_found
    stub_request(:get, "#{TEST_BASE_URL}/v1/cache/missing_key")
      .to_return(
        status: 404,
        body: { 'error' => { 'message' => 'Not found' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.get('missing_key')

    assert_nil result
  end

  def test_delete_returns_true_on_success
    stub_request(:delete, "#{TEST_BASE_URL}/v1/cache/cache_key_123")
      .to_return(
        status: 200,
        body: { 'deleted' => true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.delete('cache_key_123')

    assert result
  end

  def test_delete_returns_false_for_not_found
    stub_request(:delete, "#{TEST_BASE_URL}/v1/cache/missing_key")
      .to_return(
        status: 404,
        body: { 'error' => { 'message' => 'Not found' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.delete('missing_key')

    refute result
  end

  def test_purge_with_keys
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { keys: %w[key1 key2 key3] })
      .to_return(
        status: 200,
        body: { 'purged' => 3, 'keys' => %w[key1 key2 key3] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.purge(%w[key1 key2 key3])

    assert_equal 3, result['purged']
    assert_equal %w[key1 key2 key3], result['keys']
  end

  def test_purge_url
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { url: 'https://example.com/*' })
      .to_return(
        status: 200,
        body: { 'purged' => 10 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.purge_url('https://example.com/*')

    assert_equal 10, result['purged']
  end

  def test_purge_before_with_time
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { before: '2024-01-15T00:00:00Z' })
      .to_return(
        status: 200,
        body: { 'purged' => 42 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.purge_before(Time.utc(2024, 1, 15))

    assert_equal 42, result['purged']
  end

  def test_purge_before_with_date
    # Date.to_time converts to local time, so we match on any valid ISO8601 format
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with { |request| JSON.parse(request.body)['before'] =~ /2024-01-15T\d{2}:00:00Z/ }
      .to_return(
        status: 200,
        body: { 'purged' => 42 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.purge_before(Date.new(2024, 1, 15))

    assert_equal 42, result['purged']
  end

  def test_purge_before_with_string
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { before: '2024-01-15T00:00:00Z' })
      .to_return(
        status: 200,
        body: { 'purged' => 42 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.purge_before('2024-01-15T00:00:00Z')

    assert_equal 42, result['purged']
  end

  def test_purge_pattern
    stub_request(:post, "#{TEST_BASE_URL}/v1/cache/purge")
      .with(body: { pattern: 'screenshots/2024/01/*' })
      .to_return(
        status: 200,
        body: { 'purged' => 15 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @cache.purge_pattern('screenshots/2024/01/*')

    assert_equal 15, result['purged']
  end
end
