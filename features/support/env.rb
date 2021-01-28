# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'faker'

SimpleCov.start do
  load_profile 'test_frameworks'

  add_filter %r{^/vendor/}
  add_filter %r{^/config/}
  add_filter %r{^/db/}

  add_group 'Controllers', 'src/controller'
  add_group 'Models', 'src/model'
  add_group 'Protocols' do |src|
    src.filename.include?('src/protocol/') &&
      !src.filename.include?('command')
  end
  add_group 'Commands', 'src/protocol/command'
  add_group 'Rules', 'src/rule'
  add_group 'Libraries', 'lib/'
end

require_relative '../../src/unlight'
