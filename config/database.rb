# Unlight
# Copyright (c) 2019 CPA
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

# TODO: Prevent use global variable
$SERVER_NAME = "CLI" unless $SERVER_NAME

module Unlight
  # Adapter
  #
  # Possible values: [:csv, :sqlite3, :mysql2]
  STORE_TYPE = (ENV['DB_ADAPTER'] || :sqlite3).to_sym

  # Memcache Server
  MEMCACHE_CONFIG = (ENV['MEMCACHED_HOST'] || 'localhost:11211')
  MEMCACHE_OPTIONS = {
    timeout: 1,
    namespace: 'unlight'
  }

  # MySQL Connection config
  MYSQL_CONFIG = {
    host: ENV['DB_HOST'] || 'db',
    user: ENV['MYSQL_USER'] || 'unlight',
    password: ENV['MYSQL_PASSWORD'] || 'unlight',
    database: ENV['MYSQL_DATABASE'] || 'unlight_db',
    encoding: 'utf8',
    port: (ENV['DB_PORT'] || 3306).to_i,
    max_connections: (ENV['DB_POOL_SIZE'] || 5).to_i,
    loggers: Logger.new(STDOUT)
  }
end
