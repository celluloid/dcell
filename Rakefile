require "bundler/gem_tasks"
Dir["tasks/**/*.task"].each { |task| load task }

if ENV['CI']
  task :default => %w(redis spec)
else
  task :default => :spec
end