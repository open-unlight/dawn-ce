# frozen_string_literal: true

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_, args|
    require 'dawn/database'
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel::Migrator.run(Dawn::Database.current, Dawn.root.join('db/migrations'), target: version)
  end
end
