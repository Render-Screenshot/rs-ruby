# frozen_string_literal: true

module RenderScreenshot
  # Base error class for all RenderScreenshot errors
  class Error < StandardError
    attr_reader :http_status, :code, :request_id, :retry_after

    def initialize(message = nil, http_status: nil, code: nil, request_id: nil, retry_after: nil)
      super(message)
      @http_status = http_status
      @code = code
      @request_id = request_id
      @retry_after = retry_after
    end

    def retryable?
      false
    end

    # Factory method to create appropriate error from API response
    def self.from_response(http_status, body, retry_after: nil, request_id: nil)
      error_data = body.is_a?(Hash) ? body['error'] || body : {}
      message = error_data['message'] || "HTTP #{http_status} error"
      code = error_data['code']
      req_id = request_id || error_data['request_id'] || body['request_id']

      error_class = case http_status
                    when 400 then ValidationError
                    when 401 then AuthenticationError
                    when 403 then AuthorizationError
                    when 404 then NotFoundError
                    when 408 then TimeoutError
                    when 422
                      code == 'render_failed' ? RenderFailedError : ValidationError
                    when 429 then RateLimitError
                    when 500..599 then ServerError
                    else Error
                    end

      error_class.new(message, http_status: http_status, code: code, request_id: req_id, retry_after: retry_after)
    end
  end

  # Validation errors (400, 422)
  class ValidationError < Error
    def self.invalid_url(url)
      new("Invalid URL: #{url}", http_status: 400, code: 'invalid_url')
    end

    def self.invalid_request(message)
      new(message, http_status: 400, code: 'invalid_request')
    end

    def self.missing_required(param)
      new("Missing required parameter: #{param}", http_status: 400, code: 'missing_required')
    end
  end

  # Authentication errors (401)
  class AuthenticationError < Error
    def self.unauthorized
      new('Invalid or missing API key', http_status: 401, code: 'unauthorized')
    end

    def self.invalid_api_key
      new('Invalid API key', http_status: 401, code: 'invalid_api_key')
    end

    def self.expired_signature
      new('Signed URL has expired', http_status: 401, code: 'expired_signature')
    end
  end

  # Authorization errors (403)
  class AuthorizationError < Error
    def self.forbidden
      new('Access denied', http_status: 403, code: 'forbidden')
    end

    def self.insufficient_credits
      new('Insufficient credits', http_status: 403, code: 'insufficient_credits')
    end
  end

  # Not found errors (404)
  class NotFoundError < Error
    def self.not_found(resource = 'Resource')
      new("#{resource} not found", http_status: 404, code: 'not_found')
    end
  end

  # Rate limit errors (429)
  class RateLimitError < Error
    def retryable?
      true
    end

    def self.rate_limited(retry_after = nil)
      new('Rate limit exceeded', http_status: 429, code: 'rate_limited', retry_after: retry_after)
    end
  end

  # Timeout errors (408, 504)
  class TimeoutError < Error
    def retryable?
      true
    end

    def self.timeout
      new('Request timed out', http_status: 408, code: 'timeout')
    end
  end

  # Render failed errors (422 with render_failed code)
  class RenderFailedError < Error
    def retryable?
      true
    end

    def self.render_failed(message = 'Screenshot rendering failed')
      new(message, http_status: 422, code: 'render_failed')
    end
  end

  # Server errors (5xx)
  class ServerError < Error
    def retryable?
      true
    end

    def self.internal(message = 'Internal server error')
      new(message, http_status: 500, code: 'internal_error')
    end
  end

  # Network/connection errors
  class ConnectionError < Error
    def retryable?
      true
    end

    def self.connection_failed(message = 'Failed to connect to server')
      new(message, code: 'connection_error')
    end
  end
end
