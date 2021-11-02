# frozen_string_literal: true

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_, args|
    require 'dawn/database'
    Dawn::Database.migrate!(args[:version])
  end
end
