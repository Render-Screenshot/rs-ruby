# frozen_string_literal: true

require 'openssl'
require 'cgi'

module RenderScreenshot
  # Main API client for RenderScreenshot
  class Client
    attr_reader :http

    # Initialize a new client
    # @param api_key [String] API key (rs_live_*, rs_test_*)
    # @param base_url [String, nil] Custom base URL
    # @param timeout [Integer, nil] Request timeout in seconds
    # @param signing_key [String, nil] Secret key for signed URLs (rs_secret_*)
    # @param public_key_id [String, nil] Public key ID for signed URLs (rs_pub_*)
    # @param max_retries [Integer] Maximum retries for retryable errors (default: 0)
    # @param retry_delay [Float] Base delay between retries in seconds (default: 1.0)
    def initialize(api_key, base_url: nil, timeout: nil, signing_key: nil, public_key_id: nil,
                   max_retries: 0, retry_delay: 1.0)
      raise AuthenticationError.unauthorized if api_key.nil? || api_key.empty?

      @api_key = api_key
      @signing_key = signing_key
      @public_key_id = public_key_id
      @http = HttpClient.new(api_key, base_url: base_url, timeout: timeout,
                                      max_retries: max_retries, retry_delay: retry_delay)
      @cache_manager = nil
    end

    # Take a screenshot and return binary data
    # @param options [TakeOptions, Hash] Screenshot options
    # @return [String] Binary image/PDF data
    def take(options)
      params = normalize_options(options)
      response = @http.post_binary('/v1/screenshot', body: params)
      response[:body]
    end

    # Take a screenshot and return JSON response with metadata
    # @param options [TakeOptions, Hash] Screenshot options
    # @return [Hash] Screenshot response with URL, dimensions, cache info
    def take_json(options)
      params = normalize_options(options)
      @http.post('/v1/screenshot', body: params, headers: { 'Accept' => 'application/json' })
    end

    # Generate a signed URL for client-side use
    # Requires signing credentials (signing_key and public_key_id) to be configured
    # @param options [TakeOptions, Hash] Screenshot options
    # @param expires_at [Time, Integer] Expiration time or Unix timestamp
    # @param signing_key [String, nil] Override signing key (rs_secret_*)
    # @param public_key_id [String, nil] Override public key ID (rs_pub_*)
    # @return [String] Signed URL
    # @raise [ValidationError] if signing credentials are not configured
    def generate_url(options, expires_at:, signing_key: nil, public_key_id: nil)
      secret = signing_key || @signing_key
      key_id = public_key_id || @public_key_id

      unless secret && key_id
        raise ValidationError.invalid_request(
          'Signed URLs require signing_key (rs_secret_*) and public_key_id (rs_pub_*). ' \
          'Pass them to Client.new or to generate_url directly.'
        )
      end

      config = options.is_a?(TakeOptions) ? options.to_h : options
      expires = expires_at.is_a?(Time) ? expires_at.to_i : expires_at

      # Build query params in alphabetical order (required for signature verification)
      params = build_signed_params(config, key_id, expires)
      query_string = params.sort.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')

      # Sign with HMAC-SHA256 using the secret key
      signature = OpenSSL::HMAC.hexdigest('SHA256', secret, query_string)

      "#{@http.base_url}/v1/screenshot?#{query_string}&signature=#{signature}"
    end

    # Batch process multiple URLs with the same options
    # @param urls [Array<String>] URLs to screenshot
    # @param options [TakeOptions, Hash, nil] Common options for all URLs
    # @return [Hash] Batch response
    def batch(urls, options: nil)
      body = { urls: urls }
      body[:options] = normalize_options(options) if options
      @http.post('/v1/batch', body: body)
    end

    # Batch process with per-URL options
    # @param requests [Array<Hash>] Array of { url:, options: } hashes
    # @return [Hash] Batch response
    def batch_advanced(requests)
      formatted = requests.map do |req|
        {
          url: req[:url] || req['url'],
          **(normalize_options(req[:options] || req['options'] || {}) || {})
        }
      end
      @http.post('/v1/batch', body: { requests: formatted })
    end

    # Get batch job status
    # @param batch_id [String] Batch job ID
    # @return [Hash] Batch response
    def get_batch(batch_id)
      @http.get("/v1/batch/#{batch_id}")
    end

    # List all available presets
    # @return [Array<Hash>] Array of preset info
    def presets
      response = @http.get('/v1/presets')
      response['presets'] || response
    end

    # Get a specific preset
    # @param id [String] Preset ID
    # @return [Hash] Preset info
    def preset(id)
      @http.get("/v1/presets/#{id}")
    end

    # List all available device presets
    # @return [Array<Hash>] Array of device info
    def devices
      response = @http.get('/v1/devices')
      response['devices'] || response
    end

    # Get account usage and credits information
    # @return [Hash] Usage info with credits, requests, etc.
    def usage
      @http.get('/v1/usage')
    end

    # Get cache manager for cache operations
    # @return [CacheManager]
    def cache
      @cache_manager ||= CacheManager.new(@http)
    end

    private

    def normalize_options(options)
      case options
      when TakeOptions
        options.to_params
      when Hash
        options
      when nil
        {}
      else
        raise ValidationError.invalid_request('Options must be a TakeOptions or Hash')
      end
    end

    def build_signed_params(config, key_id, expires)
      params = {}

      # Add expires first (alphabetically before key_id)
      params['expires'] = expires

      # Add key_id (public identifier)
      params['key_id'] = key_id

      # Add URL or html
      params['url'] = config[:url] if config[:url]
      params['html'] = config[:html] if config[:html]

      # Add other params
      flat_params = flatten_config(config)
      flat_params.each do |key, value|
        next if %w[url html].include?(key)

        params[key] = value
      end

      params
    end

    def flatten_config(config)
      result = {}
      config.each do |key, value|
        next if value.nil?

        str_key = key.to_s
        if value.is_a?(Hash)
          value.each do |sub_key, sub_value|
            result["#{str_key}_#{sub_key}"] = sub_value unless sub_value.nil?
          end
        elsif value.is_a?(Array)
          result[str_key] = value.join(',')
        else
          result[str_key] = value
        end
      end
      result
    end
  end
end
