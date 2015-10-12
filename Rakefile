require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)
task :default => ['spec']
task :test => ['spec']

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
  # t.options = ['--any', '--extra', '--opts']
  t.stats_options = ['--list-undoc']
end
task :doc => ['yard']
