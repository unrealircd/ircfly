require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :validate

desc 'Validate Package'
task validate: [:rubocop, :spec]

desc 'Run RuboCop'
task :rubocop do
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end
