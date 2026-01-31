# frozen_string_literal: true

require 'test_helper'

class WebhookTest < Minitest::Test
  WEBHOOK_SECRET = 'whsec_test_secret_key'

  def test_verify_with_valid_signature
    timestamp = Time.now.to_i.to_s
    payload = '{"event": "screenshot.completed", "id": "evt_123"}'
    signature = compute_signature(timestamp, payload)

    result = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: signature,
      timestamp: timestamp,
      secret: WEBHOOK_SECRET
    )

    assert result
  end

  def test_verify_with_invalid_signature
    timestamp = Time.now.to_i.to_s
    payload = '{"event": "screenshot.completed"}'

    result = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: 'sha256=invalid_signature',
      timestamp: timestamp,
      secret: WEBHOOK_SECRET
    )

    refute result
  end

  def test_verify_with_expired_timestamp
    # Timestamp from 10 minutes ago (beyond default 5 min tolerance)
    timestamp = (Time.now.to_i - 600).to_s
    payload = '{"event": "screenshot.completed"}'
    signature = compute_signature(timestamp, payload)

    result = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: signature,
      timestamp: timestamp,
      secret: WEBHOOK_SECRET
    )

    refute result
  end

  def test_verify_with_future_timestamp
    # Timestamp 10 minutes in the future
    timestamp = (Time.now.to_i + 600).to_s
    payload = '{"event": "screenshot.completed"}'
    signature = compute_signature(timestamp, payload)

    result = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: signature,
      timestamp: timestamp,
      secret: WEBHOOK_SECRET
    )

    refute result
  end

  def test_verify_with_custom_tolerance
    # Timestamp from 10 minutes ago
    timestamp = (Time.now.to_i - 600).to_s
    payload = '{"event": "screenshot.completed"}'
    signature = compute_signature(timestamp, payload)

    # With 15 minute tolerance, should pass
    result = RenderScreenshot::Webhook.verify(
      payload: payload,
      signature: signature,
      timestamp: timestamp,
      secret: WEBHOOK_SECRET,
      tolerance: 900
    )

    assert result
  end

  def test_verify_with_nil_params
    refute RenderScreenshot::Webhook.verify(payload: nil, signature: 'sig', timestamp: '123', secret: 'sec')
    refute RenderScreenshot::Webhook.verify(payload: 'data', signature: nil, timestamp: '123', secret: 'sec')
    refute RenderScreenshot::Webhook.verify(payload: 'data', signature: 'sig', timestamp: nil, secret: 'sec')
    refute RenderScreenshot::Webhook.verify(payload: 'data', signature: 'sig', timestamp: '123', secret: nil)
  end

  def test_verify_with_invalid_timestamp
    result = RenderScreenshot::Webhook.verify(
      payload: 'data',
      signature: 'sig',
      timestamp: 'not-a-number',
      secret: WEBHOOK_SECRET
    )

    refute result
  end

  def test_parse_with_json_string
    payload = '{"type": "screenshot.completed", "id": "evt_123", "timestamp": 1705600000, "data": {"url": "https://example.com"}}'

    result = RenderScreenshot::Webhook.parse(payload)

    assert_equal 'screenshot.completed', result[:event]
    assert_equal 'evt_123', result[:id]
    assert_equal 1_705_600_000, result[:timestamp]
    assert_equal 'https://example.com', result[:data]['url']
  end

  def test_parse_with_hash
    payload = {
      'type' => 'batch.completed',
      'id' => 'evt_456',
      'timestamp' => 1_705_600_000,
      'data' => { 'batch_id' => 'batch_123' }
    }

    result = RenderScreenshot::Webhook.parse(payload)

    assert_equal 'batch.completed', result[:event]
    assert_equal 'evt_456', result[:id]
  end

  def test_parse_with_event_key
    # Some webhooks might use 'event' instead of 'type'
    payload = '{"event": "screenshot.failed", "id": "evt_789"}'

    result = RenderScreenshot::Webhook.parse(payload)

    assert_equal 'screenshot.failed', result[:event]
  end

  def test_parse_with_invalid_json
    assert_raises(RenderScreenshot::ValidationError) do
      RenderScreenshot::Webhook.parse('not valid json')
    end
  end

  def test_extract_headers_with_standard_headers
    headers = {
      'X-Webhook-Signature' => 'sha256=abc123',
      'X-Webhook-Timestamp' => '1705600000',
      'X-Webhook-ID' => 'whk_123'
    }

    result = RenderScreenshot::Webhook.extract_headers(headers)

    assert_equal 'sha256=abc123', result[:signature]
    assert_equal '1705600000', result[:timestamp]
    assert_equal 'whk_123', result[:id]
  end

  def test_extract_headers_with_lowercase_headers
    headers = {
      'x-webhook-signature' => 'sha256=abc123',
      'x-webhook-timestamp' => '1705600000',
      'x-webhook-id' => 'whk_456'
    }

    result = RenderScreenshot::Webhook.extract_headers(headers)

    assert_equal 'sha256=abc123', result[:signature]
    assert_equal '1705600000', result[:timestamp]
    assert_equal 'whk_456', result[:id]
  end

  def test_extract_headers_with_underscore_headers
    # Some frameworks convert dashes to underscores
    headers = {
      'x_webhook_signature' => 'sha256=abc123',
      'x_webhook_timestamp' => '1705600000',
      'x_webhook_id' => 'whk_789'
    }

    result = RenderScreenshot::Webhook.extract_headers(headers)

    assert_equal 'sha256=abc123', result[:signature]
    assert_equal '1705600000', result[:timestamp]
    assert_equal 'whk_789', result[:id]
  end

  def test_extract_headers_with_symbol_keys
    headers = {
      'X-Webhook-Signature': 'sha256=abc123',
      'X-Webhook-Timestamp': '1705600000',
      'X-Webhook-ID': 'whk_sym'
    }

    result = RenderScreenshot::Webhook.extract_headers(headers)

    assert_equal 'sha256=abc123', result[:signature]
    assert_equal '1705600000', result[:timestamp]
    assert_equal 'whk_sym', result[:id]
  end

  private

  def compute_signature(timestamp, payload)
    signed_payload = "#{timestamp}.#{payload}"
    hash = OpenSSL::HMAC.hexdigest('SHA256', WEBHOOK_SECRET, signed_payload)
    "sha256=#{hash}"
  end
end
