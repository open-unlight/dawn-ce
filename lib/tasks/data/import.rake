# frozen_string_literal: true

require 'dawn/services/data_importer'

namespace :data do
  desc 'Import game data'
  task import: :environment do
    Unlight::DB.logger = nil
    importer = Dawn::DataImporter.new
    importer.import do |dataset|
      puts "Importing #{dataset.model_name}"
    end
  end
end
