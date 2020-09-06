# frozen_string_literal: true

$:.unshift Bundler.root.join('lib')
$:.unshift Bundler.root.join('src')

Bundler.root.join('lib/tasks').glob('**/*.rake').each { |task| load task }

$stdout.sync = true
$stderr.sync = true

task :environment do
  require 'unlight'
end
