# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new

task default: %i[test rubocop]

desc 'Run security audit'
task :audit do
  sh 'bundle exec bundler-audit check --update'
end

desc 'Generate YARD documentation'
task :yard do
  sh 'bundle exec yard doc'
end

desc 'Open YARD documentation in browser'
task :docs do
  sh 'bundle exec yard server --reload'
end
