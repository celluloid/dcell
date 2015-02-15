require "bundler/gem_tasks"
require "coveralls/rake/task"

Dir["tasks/**/*.task"].each { |task| load task }
Dir["tasks/**/*.rb"].each { |task| load task }

Coveralls::RakeTask.new

task :default do
  res = 0
  [:clean, 'testnode:bg', :spec, 'testnode:finish', 'coveralls:push'].each do |tsk|
    if tsk == :spec
      sh "rake spec" do
        res = 1
      end
    else
      Rake::Task[tsk].invoke
    end
  end
  exit res
end
