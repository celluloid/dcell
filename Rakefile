require "bundler/gem_tasks"
require "coveralls/rake/task"

Dir["tasks/**/*.task"].each { |task| load task }
Dir["tasks/**/*.rb"].each { |task| load task }

Coveralls::RakeTask.new

task :default => ['testnode:bg', :spec, 'testnode:finish', 'coveralls:push']
