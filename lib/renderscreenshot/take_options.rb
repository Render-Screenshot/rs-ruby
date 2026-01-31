# frozen_string_literal: true

require 'cgi'

module RenderScreenshot
  # Immutable fluent builder for screenshot options
  # All methods return a new instance, preserving immutability
  class TakeOptions
    attr_reader :config

    def initialize(config = {})
      @config = config.dup.freeze
    end

    # Factory methods
    def self.url(url)
      new(url: url)
    end

    def self.html(html)
      new(html: html)
    end

    def self.from(hash)
      new(hash)
    end

    # Viewport methods
    def width(value)
      with(width: value)
    end

    def height(value)
      with(height: value)
    end

    def scale(value)
      with(scale: value)
    end

    def mobile(value = true)
      with(mobile: value)
    end

    # Capture methods
    def full_page(value = true)
      with(full_page: value)
    end

    def element(selector)
      with(element: selector)
    end

    def format(value)
      with(format: value)
    end

    def quality(value)
      with(quality: value)
    end

    # Wait methods
    def wait_for(value)
      with(wait_for: value)
    end

    def delay(value)
      with(delay: value)
    end

    def wait_for_selector(selector)
      with(wait_for_selector: selector)
    end

    def wait_for_timeout(value)
      with(wait_for_timeout: value)
    end

    # Preset methods
    def preset(value)
      with(preset: value)
    end

    def device(value)
      with(device: value)
    end

    # Blocking methods
    def block_ads(value = true)
      with(block_ads: value)
    end

    def block_trackers(value = true)
      with(block_trackers: value)
    end

    def block_cookie_banners(value = true)
      with(block_cookie_banners: value)
    end

    def block_chat_widgets(value = true)
      with(block_chat_widgets: value)
    end

    def block_urls(patterns)
      with(block_urls: patterns)
    end

    def block_resources(types)
      with(block_resources: types)
    end

    # Page manipulation methods
    def inject_script(script)
      with(inject_script: script)
    end

    def inject_style(style)
      with(inject_style: style)
    end

    def click(selector)
      with(click: selector)
    end

    def hide(selectors)
      with(hide: Array(selectors))
    end

    def remove(selectors)
      with(remove: Array(selectors))
    end

    # Browser emulation methods
    def dark_mode(value = true)
      with(dark_mode: value)
    end

    def reduced_motion(value = true)
      with(reduced_motion: value)
    end

    def media_type(value)
      with(media_type: value)
    end

    def user_agent(value)
      with(user_agent: value)
    end

    def timezone(value)
      with(timezone: value)
    end

    def locale(value)
      with(locale: value)
    end

    def geolocation(latitude, longitude, accuracy: nil)
      geo = { latitude: latitude, longitude: longitude }
      geo[:accuracy] = accuracy if accuracy
      with(geolocation: geo)
    end

    # Network methods
    def headers(value)
      with(headers: value)
    end

    def cookies(value)
      with(cookies: value)
    end

    def auth_basic(username, password)
      with(auth_basic: { username: username, password: password })
    end

    def auth_bearer(token)
      with(auth_bearer: token)
    end

    def bypass_csp(value = true)
      with(bypass_csp: value)
    end

    # Cache methods
    def cache_ttl(value)
      with(cache_ttl: value)
    end

    def cache_refresh(value = true)
      with(cache_refresh: value)
    end

    # PDF methods
    def pdf_paper_size(value)
      with(pdf_paper_size: value)
    end

    def pdf_width(value)
      with(pdf_width: value)
    end

    def pdf_height(value)
      with(pdf_height: value)
    end

    def pdf_landscape(value = true)
      with(pdf_landscape: value)
    end

    def pdf_margin(value)
      with(pdf_margin: value)
    end

    def pdf_margin_top(value)
      with(pdf_margin_top: value)
    end

    def pdf_margin_right(value)
      with(pdf_margin_right: value)
    end

    def pdf_margin_bottom(value)
      with(pdf_margin_bottom: value)
    end

    def pdf_margin_left(value)
      with(pdf_margin_left: value)
    end

    def pdf_scale(value)
      with(pdf_scale: value)
    end

    def pdf_print_background(value = true)
      with(pdf_print_background: value)
    end

    def pdf_page_ranges(value)
      with(pdf_page_ranges: value)
    end

    def pdf_header(value)
      with(pdf_header: value)
    end

    def pdf_footer(value)
      with(pdf_footer: value)
    end

    def pdf_fit_one_page(value = true)
      with(pdf_fit_one_page: value)
    end

    def pdf_prefer_css_page_size(value = true)
      with(pdf_prefer_css_page_size: value)
    end

    # Storage methods
    def storage_enabled(value = true)
      with(storage_enabled: value)
    end

    def storage_path(value)
      with(storage_path: value)
    end

    def storage_acl(value)
      with(storage_acl: value)
    end

    # Output methods
    def to_h
      config.dup
    end

    # Convert to nested JSON params for POST requests
    def to_params
      result = {}

      # Top-level params
      %i[url html preset].each do |key|
        result[key] = config[key] if config.key?(key)
      end

      # Viewport group
      viewport = {}
      { width: :width, height: :height, scale: :scale, mobile: :mobile, device: :device }.each do |config_key, api_key|
        viewport[api_key] = config[config_key] if config.key?(config_key)
      end
      result[:viewport] = viewport unless viewport.empty?

      # Capture group
      capture = {}
      capture[:mode] = 'full_page' if config[:full_page]
      capture[:selector] = config[:element] if config[:element]
      result[:capture] = capture unless capture.empty?

      # Output group
      output = {}
      output[:format] = config[:format] if config[:format]
      output[:quality] = config[:quality] if config[:quality]
      result[:output] = output unless output.empty?

      # Wait group
      wait = {}
      wait[:until] = config[:wait_for] if config[:wait_for]
      wait[:delay] = config[:delay] if config[:delay]
      wait[:for_selector] = config[:wait_for_selector] if config[:wait_for_selector]
      wait[:timeout] = config[:wait_for_timeout] if config[:wait_for_timeout]
      result[:wait] = wait unless wait.empty?

      # Block group
      block = {}
      block[:ads] = config[:block_ads] if config.key?(:block_ads)
      block[:trackers] = config[:block_trackers] if config.key?(:block_trackers)
      block[:cookie_banners] = config[:block_cookie_banners] if config.key?(:block_cookie_banners)
      block[:chat_widgets] = config[:block_chat_widgets] if config.key?(:block_chat_widgets)
      block[:requests] = config[:block_urls] if config[:block_urls]
      block[:resources] = config[:block_resources] if config[:block_resources]
      result[:block] = block unless block.empty?

      # Page group
      page = {}
      page[:scripts] = [config[:inject_script]] if config[:inject_script]
      page[:styles] = [config[:inject_style]] if config[:inject_style]
      page[:click] = config[:click] if config[:click]
      page[:hide] = config[:hide] if config[:hide]
      page[:remove] = config[:remove] if config[:remove]
      result[:page] = page unless page.empty?

      # Browser group
      browser = {}
      browser[:dark_mode] = config[:dark_mode] if config.key?(:dark_mode)
      browser[:reduced_motion] = config[:reduced_motion] if config.key?(:reduced_motion)
      browser[:media] = config[:media_type] if config[:media_type]
      browser[:user_agent] = config[:user_agent] if config[:user_agent]
      browser[:timezone] = config[:timezone] if config[:timezone]
      browser[:locale] = config[:locale] if config[:locale]
      browser[:geolocation] = config[:geolocation] if config[:geolocation]
      result[:browser] = browser unless browser.empty?

      # Network group
      network = {}
      network[:headers] = config[:headers] if config[:headers]
      network[:cookies] = config[:cookies] if config[:cookies]
      network[:bypass_csp] = config[:bypass_csp] if config.key?(:bypass_csp)
      if config[:auth_basic]
        network[:auth] = { type: 'basic' }.merge(config[:auth_basic])
      elsif config[:auth_bearer]
        network[:auth] = { type: 'bearer', token: config[:auth_bearer] }
      end
      result[:network] = network unless network.empty?

      # Cache group
      cache = {}
      cache[:ttl] = config[:cache_ttl] if config[:cache_ttl]
      cache[:refresh] = config[:cache_refresh] if config.key?(:cache_refresh)
      result[:cache] = cache unless cache.empty?

      # PDF group
      pdf = {}
      pdf[:paper] = config[:pdf_paper_size] if config[:pdf_paper_size]
      pdf[:width] = config[:pdf_width] if config[:pdf_width]
      pdf[:height] = config[:pdf_height] if config[:pdf_height]
      pdf[:landscape] = config[:pdf_landscape] if config.key?(:pdf_landscape)
      pdf[:scale] = config[:pdf_scale] if config[:pdf_scale]
      pdf[:background] = config[:pdf_print_background] if config.key?(:pdf_print_background)
      pdf[:page_ranges] = config[:pdf_page_ranges] if config[:pdf_page_ranges]
      pdf[:header] = config[:pdf_header] if config[:pdf_header]
      pdf[:footer] = config[:pdf_footer] if config[:pdf_footer]
      pdf[:fit_one_page] = config[:pdf_fit_one_page] if config.key?(:pdf_fit_one_page)
      pdf[:prefer_css_page_size] = config[:pdf_prefer_css_page_size] if config.key?(:pdf_prefer_css_page_size)

      # PDF margins - supports uniform margin (string like "2cm") or individual margins (hash)
      if config[:pdf_margin]
        # Uniform margin specified - use directly (string or hash)
        pdf[:margin] = config[:pdf_margin]
      else
        # Build margin hash from individual margin settings
        margin = {}
        margin[:top] = config[:pdf_margin_top] if config[:pdf_margin_top]
        margin[:right] = config[:pdf_margin_right] if config[:pdf_margin_right]
        margin[:bottom] = config[:pdf_margin_bottom] if config[:pdf_margin_bottom]
        margin[:left] = config[:pdf_margin_left] if config[:pdf_margin_left]
        pdf[:margin] = margin unless margin.empty?
      end
      result[:pdf] = pdf unless pdf.empty?

      # Storage group
      storage = {}
      storage[:enabled] = config[:storage_enabled] if config.key?(:storage_enabled)
      storage[:path] = config[:storage_path] if config[:storage_path]
      storage[:acl] = config[:storage_acl] if config[:storage_acl]
      result[:storage] = storage unless storage.empty?

      result
    end

    # Convert to flat query string for GET requests
    def to_query_string
      params = []

      # Map config keys to query param names
      query_mappings = {
        url: 'url',
        html: 'html',
        preset: 'preset',
        width: 'width',
        height: 'height',
        device: 'device',
        scale: 'scale',
        full_page: 'full_page',
        element: 'selector',
        format: 'format',
        quality: 'quality',
        delay: 'delay',
        wait_for_timeout: 'timeout',
        block_ads: 'block_ads',
        block_cookie_banners: 'block_cookies',
        dark_mode: 'dark_mode',
        cache_ttl: 'cache_ttl'
      }

      query_mappings.each do |config_key, param_name|
        next unless config.key?(config_key)

        value = config[config_key]
        params << "#{param_name}=#{CGI.escape(value.to_s)}"
      end

      params.join('&')
    end

    private

    def with(updates)
      self.class.new(config.merge(updates))
    end
  end
end
