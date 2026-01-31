# frozen_string_literal: true

require 'test_helper'

class TakeOptionsTest < Minitest::Test
  def test_url_factory_method
    options = RenderScreenshot::TakeOptions.url('https://example.com')

    assert_equal({ url: 'https://example.com' }, options.to_h)
  end

  def test_html_factory_method
    options = RenderScreenshot::TakeOptions.html('<html></html>')

    assert_equal({ html: '<html></html>' }, options.to_h)
  end

  def test_from_factory_method
    options = RenderScreenshot::TakeOptions.from(url: 'https://example.com', width: 1280)

    assert_equal({ url: 'https://example.com', width: 1280 }, options.to_h)
  end

  def test_immutability
    original = RenderScreenshot::TakeOptions.url('https://example.com')
    modified = original.width(1280)

    refute_same original, modified
    assert_equal({ url: 'https://example.com' }, original.to_h)
    assert_equal({ url: 'https://example.com', width: 1280 }, modified.to_h)
  end

  def test_method_chaining
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .width(1200)
              .height(630)
              .format('png')
              .quality(90)

    config = options.to_h
    assert_equal 'https://example.com', config[:url]
    assert_equal 1200, config[:width]
    assert_equal 630, config[:height]
    assert_equal 'png', config[:format]
    assert_equal 90, config[:quality]
  end

  def test_viewport_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .width(1920)
              .height(1080)
              .scale(2)
              .mobile(true)

    config = options.to_h
    assert_equal 1920, config[:width]
    assert_equal 1080, config[:height]
    assert_equal 2, config[:scale]
    assert config[:mobile]
  end

  def test_capture_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .full_page
              .element('#main')
              .format('webp')
              .quality(85)

    config = options.to_h
    assert config[:full_page]
    assert_equal '#main', config[:element]
    assert_equal 'webp', config[:format]
    assert_equal 85, config[:quality]
  end

  def test_wait_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .wait_for('networkidle')
              .delay(500)
              .wait_for_selector('.loaded')
              .wait_for_timeout(30_000)

    config = options.to_h
    assert_equal 'networkidle', config[:wait_for]
    assert_equal 500, config[:delay]
    assert_equal '.loaded', config[:wait_for_selector]
    assert_equal 30_000, config[:wait_for_timeout]
  end

  def test_preset_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .preset('og_card')
              .device('iphone_14_pro')

    config = options.to_h
    assert_equal 'og_card', config[:preset]
    assert_equal 'iphone_14_pro', config[:device]
  end

  def test_blocking_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .block_ads
              .block_trackers
              .block_cookie_banners
              .block_chat_widgets
              .block_urls(['*.ads.com'])
              .block_resources(%w[font media])

    config = options.to_h
    assert config[:block_ads]
    assert config[:block_trackers]
    assert config[:block_cookie_banners]
    assert config[:block_chat_widgets]
    assert_equal ['*.ads.com'], config[:block_urls]
    assert_equal %w[font media], config[:block_resources]
  end

  def test_page_manipulation_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .inject_script('console.log("test")')
              .inject_style('body { color: red }')
              .click('.accept-cookies')
              .hide(['.popup', '.banner'])
              .remove('.sidebar')

    config = options.to_h
    assert_equal 'console.log("test")', config[:inject_script]
    assert_equal 'body { color: red }', config[:inject_style]
    assert_equal '.accept-cookies', config[:click]
    assert_equal ['.popup', '.banner'], config[:hide]
    assert_equal ['.sidebar'], config[:remove]
  end

  def test_browser_emulation_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .dark_mode
              .reduced_motion
              .media_type('print')
              .user_agent('CustomBot/1.0')
              .timezone('America/New_York')
              .locale('en-US')
              .geolocation(40.7128, -74.0060, accuracy: 100)

    config = options.to_h
    assert config[:dark_mode]
    assert config[:reduced_motion]
    assert_equal 'print', config[:media_type]
    assert_equal 'CustomBot/1.0', config[:user_agent]
    assert_equal 'America/New_York', config[:timezone]
    assert_equal 'en-US', config[:locale]
    assert_equal({ latitude: 40.7128, longitude: -74.0060, accuracy: 100 }, config[:geolocation])
  end

  def test_network_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .headers({ 'X-Custom' => 'value' })
              .cookies([{ name: 'session', value: 'abc' }])
              .auth_basic('user', 'pass')
              .bypass_csp

    config = options.to_h
    assert_equal({ 'X-Custom' => 'value' }, config[:headers])
    assert_equal [{ name: 'session', value: 'abc' }], config[:cookies]
    assert_equal({ username: 'user', password: 'pass' }, config[:auth_basic])
    assert config[:bypass_csp]
  end

  def test_auth_bearer
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .auth_bearer('my-token')

    assert_equal 'my-token', options.to_h[:auth_bearer]
  end

  def test_cache_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .cache_ttl(86_400)
              .cache_refresh

    config = options.to_h
    assert_equal 86_400, config[:cache_ttl]
    assert config[:cache_refresh]
  end

  def test_pdf_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .format('pdf')
              .pdf_paper_size('a4')
              .pdf_width('210mm')
              .pdf_height('297mm')
              .pdf_landscape
              .pdf_margin('1cm')
              .pdf_scale(0.9)
              .pdf_print_background
              .pdf_page_ranges('1-5')
              .pdf_header('<div>Header</div>')
              .pdf_footer('<div>Footer</div>')
              .pdf_fit_one_page
              .pdf_prefer_css_page_size

    config = options.to_h
    assert_equal 'pdf', config[:format]
    assert_equal 'a4', config[:pdf_paper_size]
    assert_equal '210mm', config[:pdf_width]
    assert_equal '297mm', config[:pdf_height]
    assert config[:pdf_landscape]
    assert_equal '1cm', config[:pdf_margin]
    assert_equal 0.9, config[:pdf_scale]
    assert config[:pdf_print_background]
    assert_equal '1-5', config[:pdf_page_ranges]
    assert_equal '<div>Header</div>', config[:pdf_header]
    assert_equal '<div>Footer</div>', config[:pdf_footer]
    assert config[:pdf_fit_one_page]
    assert config[:pdf_prefer_css_page_size]
  end

  def test_pdf_margin_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .pdf_margin_top('2cm')
              .pdf_margin_right('1cm')
              .pdf_margin_bottom('2cm')
              .pdf_margin_left('1cm')

    config = options.to_h
    assert_equal '2cm', config[:pdf_margin_top]
    assert_equal '1cm', config[:pdf_margin_right]
    assert_equal '2cm', config[:pdf_margin_bottom]
    assert_equal '1cm', config[:pdf_margin_left]
  end

  def test_storage_methods
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .storage_enabled
              .storage_path('screenshots/{date}/{hash}.{ext}')
              .storage_acl('public-read')

    config = options.to_h
    assert config[:storage_enabled]
    assert_equal 'screenshots/{date}/{hash}.{ext}', config[:storage_path]
    assert_equal 'public-read', config[:storage_acl]
  end

  def test_to_params_basic
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .preset('og_card')

    params = options.to_params
    assert_equal 'https://example.com', params[:url]
    assert_equal 'og_card', params[:preset]
  end

  def test_to_params_with_viewport
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .width(1200)
              .height(630)
              .scale(2)
              .mobile

    params = options.to_params
    assert_equal({ width: 1200, height: 630, scale: 2, mobile: true }, params[:viewport])
  end

  def test_to_params_with_capture
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .full_page
              .element('#content')

    params = options.to_params
    assert_equal 'full_page', params[:capture][:mode]
    assert_equal '#content', params[:capture][:selector]
  end

  def test_to_params_with_block
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .block_ads
              .block_trackers
              .block_urls(['*.ad.com'])

    params = options.to_params
    assert params[:block][:ads]
    assert params[:block][:trackers]
    assert_equal ['*.ad.com'], params[:block][:requests]
  end

  def test_to_params_with_network_auth_basic
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .auth_basic('user', 'pass')

    params = options.to_params
    assert_equal({ type: 'basic', username: 'user', password: 'pass' }, params[:network][:auth])
  end

  def test_to_params_with_network_auth_bearer
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .auth_bearer('token123')

    params = options.to_params
    assert_equal({ type: 'bearer', token: 'token123' }, params[:network][:auth])
  end

  def test_to_params_with_pdf
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .format('pdf')
              .pdf_paper_size('a4')
              .pdf_landscape
              .pdf_margin_top('2cm')
              .pdf_margin_bottom('2cm')

    params = options.to_params
    assert_equal 'pdf', params[:output][:format]
    assert_equal 'a4', params[:pdf][:paper]
    assert params[:pdf][:landscape]
    assert_equal({ top: '2cm', bottom: '2cm' }, params[:pdf][:margin])
  end

  def test_to_query_string
    options = RenderScreenshot::TakeOptions
              .url('https://example.com')
              .width(1200)
              .height(630)
              .format('png')
              .block_ads

    query = options.to_query_string
    assert_includes query, 'url=https%3A%2F%2Fexample.com'
    assert_includes query, 'width=1200'
    assert_includes query, 'height=630'
    assert_includes query, 'format=png'
    assert_includes query, 'block_ads=true'
  end
end
