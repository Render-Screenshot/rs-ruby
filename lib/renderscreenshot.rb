# frozen_string_literal: true

require_relative 'renderscreenshot/version'
require_relative 'renderscreenshot/configuration'
require_relative 'renderscreenshot/error'
require_relative 'renderscreenshot/http_client'
require_relative 'renderscreenshot/take_options'
require_relative 'renderscreenshot/cache_manager'
require_relative 'renderscreenshot/webhook'
require_relative 'renderscreenshot/client'

# RenderScreenshot Ruby SDK
# A developer-friendly screenshot API for capturing web pages programmatically
module RenderScreenshot
  class << self
    # Create a new client with the given API key
    # @param api_key [String] API key
    # @param base_url [String, nil] Custom base URL
    # @param timeout [Integer, nil] Request timeout in seconds
    # @return [Client]
    def client(api_key, base_url: nil, timeout: nil)
      Client.new(api_key, base_url: base_url, timeout: timeout)
    end
  end
end
