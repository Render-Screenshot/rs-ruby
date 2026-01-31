# frozen_string_literal: true

require 'test_helper'

class ErrorTest < Minitest::Test
  def test_base_error_attributes
    error = RenderScreenshot::Error.new(
      'Test error',
      http_status: 400,
      code: 'test_code',
      request_id: 'req_123',
      retry_after: 60
    )

    assert_equal 'Test error', error.message
    assert_equal 400, error.http_status
    assert_equal 'test_code', error.code
    assert_equal 'req_123', error.request_id
    assert_equal 60, error.retry_after
    refute error.retryable?
  end

  def test_from_response_creates_validation_error_for_400
    error = RenderScreenshot::Error.from_response(400, { 'error' => { 'message' => 'Bad request', 'code' => 'invalid_url' } })

    assert_instance_of RenderScreenshot::ValidationError, error
    assert_equal 'Bad request', error.message
    assert_equal 'invalid_url', error.code
    assert_equal 400, error.http_status
  end

  def test_from_response_creates_authentication_error_for_401
    error = RenderScreenshot::Error.from_response(401, { 'error' => { 'message' => 'Unauthorized' } })

    assert_instance_of RenderScreenshot::AuthenticationError, error
    assert_equal 401, error.http_status
  end

  def test_from_response_creates_authorization_error_for_403
    error = RenderScreenshot::Error.from_response(403, { 'error' => { 'message' => 'Forbidden' } })

    assert_instance_of RenderScreenshot::AuthorizationError, error
    assert_equal 403, error.http_status
  end

  def test_from_response_creates_not_found_error_for_404
    error = RenderScreenshot::Error.from_response(404, { 'error' => { 'message' => 'Not found' } })

    assert_instance_of RenderScreenshot::NotFoundError, error
    assert_equal 404, error.http_status
  end

  def test_from_response_creates_rate_limit_error_for_429
    error = RenderScreenshot::Error.from_response(429, { 'error' => { 'message' => 'Rate limited' } }, retry_after: 30)

    assert_instance_of RenderScreenshot::RateLimitError, error
    assert_equal 429, error.http_status
    assert_equal 30, error.retry_after
    assert error.retryable?
  end

  def test_from_response_creates_timeout_error_for_408
    error = RenderScreenshot::Error.from_response(408, { 'error' => { 'message' => 'Timeout' } })

    assert_instance_of RenderScreenshot::TimeoutError, error
    assert error.retryable?
  end

  def test_from_response_creates_server_error_for_5xx
    error = RenderScreenshot::Error.from_response(500, { 'error' => { 'message' => 'Internal error' } })

    assert_instance_of RenderScreenshot::ServerError, error
    assert error.retryable?
  end

  def test_validation_error_factory_methods
    error = RenderScreenshot::ValidationError.invalid_url('bad-url')
    assert_equal 'Invalid URL: bad-url', error.message
    assert_equal 'invalid_url', error.code

    error = RenderScreenshot::ValidationError.missing_required('url')
    assert_equal 'Missing required parameter: url', error.message
    assert_equal 'missing_required', error.code
  end

  def test_authentication_error_factory_methods
    error = RenderScreenshot::AuthenticationError.unauthorized
    assert_equal 'Invalid or missing API key', error.message
    assert_equal 401, error.http_status
  end

  def test_connection_error_is_retryable
    error = RenderScreenshot::ConnectionError.connection_failed
    assert error.retryable?
  end

  def test_render_failed_error_is_retryable
    error = RenderScreenshot::RenderFailedError.render_failed
    assert error.retryable?
  end

  def test_render_failed_error_factory_method
    error = RenderScreenshot::RenderFailedError.render_failed('Custom render error')
    assert_equal 'Custom render error', error.message
    assert_equal 422, error.http_status
    assert_equal 'render_failed', error.code
    assert error.retryable?
  end

  def test_from_response_creates_render_failed_error_for_422_with_render_failed_code
    error = RenderScreenshot::Error.from_response(
      422,
      { 'error' => { 'message' => 'Screenshot rendering failed', 'code' => 'render_failed' } }
    )

    assert_instance_of RenderScreenshot::RenderFailedError, error
    assert_equal 'Screenshot rendering failed', error.message
    assert_equal 'render_failed', error.code
    assert_equal 422, error.http_status
    assert error.retryable?
  end

  def test_from_response_creates_validation_error_for_422_without_render_failed_code
    error = RenderScreenshot::Error.from_response(
      422,
      { 'error' => { 'message' => 'Invalid parameter', 'code' => 'invalid_parameter' } }
    )

    assert_instance_of RenderScreenshot::ValidationError, error
    assert_equal 'Invalid parameter', error.message
    assert_equal 422, error.http_status
  end
end
