# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_group 'Library', 'lib'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'renderscreenshot'

require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'
require 'timecop'
require 'json'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Disable external connections during tests
WebMock.disable_net_connect!

# Test API key
TEST_API_KEY = 'rs_live_test_key_123'
TEST_BASE_URL = 'https://api.renderscreenshot.com'
