# frozen_string_literal: true

require 'test_helper'

class ConfigurationTest < Minitest::Test
  def teardown
    RenderScreenshot.reset_configuration!
  end

  def test_default_base_url
    assert_equal 'https://api.renderscreenshot.com', RenderScreenshot.configuration.base_url
  end

  def test_default_timeout
    assert_equal 30, RenderScreenshot.configuration.timeout
  end

  def test_configure_base_url
    RenderScreenshot.configure do |config|
      config.base_url = 'https://custom.api.com'
    end

    assert_equal 'https://custom.api.com', RenderScreenshot.configuration.base_url
  end

  def test_configure_timeout
    RenderScreenshot.configure do |config|
      config.timeout = 60
    end

    assert_equal 60, RenderScreenshot.configuration.timeout
  end

  def test_reset_configuration
    RenderScreenshot.configure do |config|
      config.base_url = 'https://custom.api.com'
      config.timeout = 60
    end

    RenderScreenshot.reset_configuration!

    assert_equal 'https://api.renderscreenshot.com', RenderScreenshot.configuration.base_url
    assert_equal 30, RenderScreenshot.configuration.timeout
  end

  def test_client_uses_configuration
    RenderScreenshot.configure do |config|
      config.base_url = 'https://custom.api.com'
      config.timeout = 45
    end

    client = RenderScreenshot.client('rs_live_test')

    assert_equal 'https://custom.api.com', client.http.base_url
    assert_equal 45, client.http.timeout
  end

  def test_client_overrides_configuration
    RenderScreenshot.configure do |config|
      config.base_url = 'https://custom.api.com'
      config.timeout = 45
    end

    client = RenderScreenshot.client('rs_live_test', base_url: 'https://override.api.com', timeout: 90)

    assert_equal 'https://override.api.com', client.http.base_url
    assert_equal 90, client.http.timeout
  end
end
