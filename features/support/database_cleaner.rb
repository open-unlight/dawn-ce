# frozen_string_literal: true

require 'database_cleaner'
require 'database_cleaner-sequel'

DatabaseCleaner[:sequel].db = Dawn::Database.current
DatabaseCleaner[:sequel].strategy = :truncation

Around do |_scenario, block|
  DatabaseCleaner[:sequel].cleaning(&block)
end
