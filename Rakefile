require 'rake/testtask'
require 'bundler/gem_tasks'
require 'bump/tasks'
require 'rubocop/rake_task'

begin
  require 'rspec/core/rake_task'
rescue LoadError
  puts "WARN: #{$ERROR_INFO.message} Continuing..."
end

if defined?(RSpec)
  desc "Run specs"
  RSpec::Core::RakeTask.new("spec") do |t|
    t.pattern = "spec/core/**/*_spec.rb"
  end

  desc 'Default: run specs.'
  task :default => "spec"
end
