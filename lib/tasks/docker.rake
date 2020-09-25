# frozen_string_literal: true

namespace :docker do
  desc 'Build docker image for development'
  task :build do
    exec('docker build -t dawn .')
  end
end
