# frozen_string_literal: true

require 'openssl'
require 'json'

module RenderScreenshot
  # Webhook verification and parsing utilities
  module Webhook
    module_function

    SIGNATURE_HEADER = 'X-Webhook-Signature'
    TIMESTAMP_HEADER = 'X-Webhook-Timestamp'
    ID_HEADER = 'X-Webhook-ID'
    DEFAULT_TOLERANCE = 300 # 5 minutes

    # Verify webhook signature using HMAC-SHA256
    # @param payload [String] Raw request body
    # @param signature [String] Signature from header (format: "sha256=...")
    # @param timestamp [String] Timestamp from header
    # @param secret [String] Webhook secret
    # @param tolerance [Integer] Max age in seconds (default 300)
    # @return [Boolean] true if valid
    def verify(payload:, signature:, timestamp:, secret:, tolerance: DEFAULT_TOLERANCE)
      return false if payload.nil? || signature.nil? || timestamp.nil? || secret.nil?

      # Check timestamp is within tolerance (replay attack prevention)
      ts = Integer(timestamp)
      age = Time.now.to_i - ts
      return false if age.abs > tolerance

      # Compute expected signature
      signed_payload = "#{timestamp}.#{payload}"
      expected_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)
      expected = "sha256=#{expected_hash}"

      # Timing-safe comparison
      secure_compare(expected, signature)
    rescue ArgumentError
      false
    end

    # Parse webhook payload into structured data
    # @param payload [String, Hash] JSON payload or parsed hash
    # @return [Hash] { event: String, id: String, timestamp: Integer, data: Hash }
    def parse(payload)
      data = payload.is_a?(String) ? JSON.parse(payload) : payload

      {
        event: data['type'] || data['event'],
        id: data['id'],
        timestamp: data['timestamp'],
        data: data['data'] || {}
      }
    rescue JSON::ParserError
      raise ValidationError.invalid_request('Invalid webhook payload')
    end

    # Extract signature, timestamp, and ID from request headers
    # @param headers [Hash] Request headers
    # @return [Hash] { signature:, timestamp:, id: }
    def extract_headers(headers)
      # Normalize header keys (handle different header formats)
      normalized = normalize_headers(headers)

      {
        signature: normalized['x-webhook-signature'],
        timestamp: normalized['x-webhook-timestamp'],
        id: normalized['x-webhook-id']
      }
    end

    # Timing-safe string comparison
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack('C*')
      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end

    private_class_method :secure_compare

    def normalize_headers(headers)
      result = {}
      headers.each do |key, value|
        normalized_key = key.to_s.downcase.tr('_', '-')
        result[normalized_key] = value
      end
      result
    end

    private_class_method :normalize_headers
  end
end
