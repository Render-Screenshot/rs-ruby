# frozen_string_literal: true

require_relative 'lib/renderscreenshot/version'

Gem::Specification.new do |spec|
  spec.name = 'renderscreenshot'
  spec.version = RenderScreenshot::VERSION
  spec.authors = ['RenderScreenshot']
  spec.email = ['support@renderscreenshot.com']

  spec.summary = 'Official Ruby SDK for RenderScreenshot API'
  spec.description = 'A developer-friendly screenshot API for capturing web pages programmatically. ' \
                     'Create social cards, link previews, documentation screenshots, and more.'
  spec.homepage = 'https://renderscreenshot.com'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/renderscreenshot/renderscreenshot-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/renderscreenshot/renderscreenshot-ruby/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://docs.renderscreenshot.com/sdks/ruby'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) ||
        f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '>= 2.0', '< 3.0'

  # Development dependencies are in Gemfile
end
