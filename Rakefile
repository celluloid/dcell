require 'bundler/gem_tasks'
require 'coveralls/rake/task'

Dir['tasks/**/*.task'].each { |task| load task }
Dir['tasks/**/*.rb'].each { |task| load task }

Coveralls::RakeTask.new

task :default do
  res = 0
  tasks = [:clean, 'testnode:bg', :spec, 'testnode:finish', 'coveralls:push']
  tasks << 'rubocop' unless ENV['CI']
  tasks.each do |tsk|
    if tsk == :spec
      sh 'rake spec' do |r|
        res = 1 unless r
      end
    else
      Rake::Task[tsk].invoke
    end
  end
  exit res
end
