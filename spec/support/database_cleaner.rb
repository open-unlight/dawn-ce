# frozen_string_literal: true

require 'database_cleaner'
require 'database_cleaner-sequel'

DatabaseCleaner[:sequel].db = Dawn::Database.current

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning do
      example.run
    end
  end
end
