# frozen_string_literal: true

module RenderScreenshot
  # Global configuration for RenderScreenshot SDK
  class Configuration
    DEFAULT_BASE_URL = 'https://api.renderscreenshot.com'
    DEFAULT_TIMEOUT = 30

    attr_accessor :base_url, :timeout

    def initialize
      @base_url = DEFAULT_BASE_URL
      @timeout = DEFAULT_TIMEOUT
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
