require 'rake/clean'
require 'rspec/core/rake_task'''
CLEAN.include %w(**/*.*~ **/\#*.*\#)

desc "Run rspec"

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--format', 'documentation', '--color']
end

desc "Run rspec and rcov"

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rspec_opts = ['--format', 'specdoc', '--color']
  t.rcov_opts = ["-x", "spec","--no-rcovrt"]
end

desc "Create spec file.(spec/*_spec.rb)"
task :create_spec_file, :file do |t,args|
  ruby "./script/create_spec.rb #{args[:file]}"
end

desc "Create documment(Rdoc) "
task :create_doc do |t|
  Dir.chdir("src"){sh 'rdoc -c "utf-8" -U -o "../doc" -t "Unlight Server Rdoc"'}
end

desc "Reset Model Table"
task :reset_model do |t,args|
  puts args
  ruby "./script/reset_model.rb #{args}"
end
