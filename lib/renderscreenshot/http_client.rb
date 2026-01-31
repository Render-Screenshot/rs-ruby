# frozen_string_literal: true

require 'faraday'
require 'json'

module RenderScreenshot
  # HTTP client wrapper using Faraday
  class HttpClient
    USER_AGENT = "renderscreenshot-ruby/#{VERSION}"

    # Default base delay for exponential backoff (in seconds)
    DEFAULT_RETRY_DELAY = 1.0
    # Maximum delay between retries (in seconds)
    MAX_RETRY_DELAY = 30.0

    attr_reader :api_key, :base_url, :timeout, :max_retries, :retry_delay

    # Initialize a new HTTP client
    # @param api_key [String] API key for authentication
    # @param base_url [String, nil] Custom base URL
    # @param timeout [Integer, nil] Request timeout in seconds
    # @param max_retries [Integer] Maximum number of retries for retryable errors (default: 0)
    # @param retry_delay [Float] Base delay between retries in seconds (default: 1.0)
    def initialize(api_key, base_url: nil, timeout: nil, max_retries: 0, retry_delay: DEFAULT_RETRY_DELAY)
      @api_key = api_key
      @base_url = base_url || RenderScreenshot.configuration.base_url
      @timeout = timeout || RenderScreenshot.configuration.timeout
      @max_retries = max_retries
      @retry_delay = retry_delay
      @connection_mutex = Mutex.new
    end

    def get(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers)
    end

    def get_binary(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers, binary: true)
    end

    def post(path, body: nil, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    def post_binary(path, body: nil, headers: {})
      request(:post, path, body: body, headers: headers, binary: true)
    end

    def delete(path, params: {}, headers: {})
      request(:delete, path, params: params, headers: headers)
    end

    private

    def connection
      @connection || @connection_mutex.synchronize do
        @connection ||= Faraday.new(url: base_url) do |faraday|
          faraday.options.timeout = timeout
          faraday.options.open_timeout = 10
          faraday.adapter Faraday.default_adapter
        end
      end
    end

    def request(method, path, params: {}, body: nil, headers: {}, binary: false)
      attempts = 0

      begin
        attempts += 1
        response = execute_request(method, path, params, body, headers)
        handle_response(response, binary)
      rescue Faraday::TimeoutError
        error = TimeoutError.timeout
        raise error unless should_retry?(error, attempts)

        sleep_before_retry(error, attempts)
        retry
      rescue Faraday::ConnectionFailed => e
        error = ConnectionError.connection_failed(e.message)
        raise error unless should_retry?(error, attempts)

        sleep_before_retry(error, attempts)
        retry
      rescue Error => e
        raise e unless should_retry?(e, attempts)

        sleep_before_retry(e, attempts)
        retry
      end
    end

    def should_retry?(error, attempts)
      return false unless error.retryable?
      return false if attempts > max_retries

      true
    end

    def sleep_before_retry(error, attempts)
      # Use retry_after header if available (from rate limit errors)
      delay = if error.respond_to?(:retry_after) && error.retry_after
                error.retry_after.to_f
              else
                # Exponential backoff with jitter: base_delay * 2^(attempt-1) + random jitter
                calculated = retry_delay * (2**(attempts - 1))
                jitter = rand * retry_delay * 0.5
                [calculated + jitter, MAX_RETRY_DELAY].min
              end

      sleep(delay)
    end

    def execute_request(method, path, params, body, headers)
      connection.send(method) do |req|
        req.url path
        req.headers['Authorization'] = "Bearer #{api_key}"
        req.headers['User-Agent'] = USER_AGENT
        req.headers['Content-Type'] = 'application/json' if body

        headers.each { |k, v| req.headers[k] = v }
        req.params = params if params.any?
        req.body = body.is_a?(String) ? body : JSON.generate(body) if body
      end
    end

    def handle_response(response, binary)
      retry_after = parse_retry_after(response.headers['Retry-After'])
      request_id = response.headers['X-Request-Id']

      unless response.success?
        body = parse_body(response)
        raise Error.from_response(response.status, body, retry_after: retry_after, request_id: request_id)
      end

      if binary
        {
          body: response.body,
          headers: response.headers.to_h
        }
      else
        parse_body(response)
      end
    end

    def parse_body(response)
      return {} if response.body.nil? || response.body.empty?

      content_type = response.headers['Content-Type'] || ''
      if content_type.include?('application/json')
        JSON.parse(response.body)
      else
        response.body
      end
    rescue JSON::ParserError
      response.body
    end

    def parse_retry_after(value)
      return nil unless value

      Integer(value)
    rescue ArgumentError
      nil
    end
  end
end
