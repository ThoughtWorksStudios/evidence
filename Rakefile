
task :default => :test

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :install do
  puts `gem build evidence.gemspec`
  g = Dir['evidence-*'].sort.last
  puts `gem install #{g}`
  puts `rm -rf evidence-*`
end
