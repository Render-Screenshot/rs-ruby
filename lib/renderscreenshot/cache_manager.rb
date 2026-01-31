# frozen_string_literal: true

module RenderScreenshot
  # Cache management operations
  class CacheManager
    def initialize(http_client)
      @http = http_client
    end

    # Get cached screenshot by key
    # @param key [String] Cache key
    # @return [String, nil] Binary data or nil if not found
    def get(key)
      response = @http.get_binary("/v1/cache/#{key}")
      response[:body]
    rescue NotFoundError
      nil
    end

    # Delete a single cached entry
    # @param key [String] Cache key
    # @return [Boolean] true if deleted
    def delete(key)
      @http.delete("/v1/cache/#{key}")
      true
    rescue NotFoundError
      false
    end

    # Purge multiple cache entries by keys
    # @param keys [Array<String>] Cache keys to purge
    # @return [Hash] { "purged" => Integer, "keys" => Array<String> }
    def purge(keys)
      @http.post('/v1/cache/purge', body: { keys: keys })
    end

    # Purge cache entries by URL pattern
    # @param pattern [String] URL pattern (glob syntax)
    # @return [Hash] { "purged" => Integer }
    def purge_url(pattern)
      @http.post('/v1/cache/purge', body: { url: pattern })
    end

    # Purge cache entries before a date
    # @param date [Time, Date, String] Date/time threshold
    # @return [Hash] { "purged" => Integer }
    def purge_before(date)
      date_str = case date
                 when Time then date.utc.iso8601
                 when Date then date.to_time.utc.iso8601
                 else date.to_s
                 end
      @http.post('/v1/cache/purge', body: { before: date_str })
    end

    # Purge cache entries by storage path pattern
    # @param pattern [String] Storage path pattern
    # @return [Hash] { "purged" => Integer }
    def purge_pattern(pattern)
      @http.post('/v1/cache/purge', body: { pattern: pattern })
    end
  end
end
