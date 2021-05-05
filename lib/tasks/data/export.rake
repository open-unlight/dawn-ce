# frozen_string_literal: true

require 'dawn/services/client_data_generator'

namespace :data do
  desc 'Generate game data for client'
  task generate_client_data: :environment do
    Unlight::DB.logger = nil
    generator = Dawn::ClientDataGenerator.new
    generator.export do |dataset|
      puts "Generating #{generator.destination}/#{dataset.table_name}.json"
    end
  end
end
