# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  load_profile "test_frameworks"

  add_filter %r{^/vendor/}
  add_filter %r{^/config/}
  add_filter %r{^/db/}

  add_group "Controllers", "src/controller"
  add_group "Models", "src/model"
  add_group "Protocols" do |src|
    src.filename.include?("src/protocol/") &&
      !src.filename.include?('command')
  end
  add_group "Commands", "src/protocol/command"
  add_group "Rules", "src/rule"
  add_group "Libraries", "lib/"
end

require_relative '../src/unlight'

Dir[Bundler.root.join('spec/support/**/*.rb')].sort.each { |support| require support }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
