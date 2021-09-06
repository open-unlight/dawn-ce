# frozen_string_literal: true

require 'dawn/services/data_importer'

namespace :data do
  desc 'Import game data'
  task import: :environment do
    importer = Dawn::DataImporter.new
    importer.import do |dataset|
      puts "Importing #{dataset.model_name}"
    end
  end

  desc 'Initialize CPU Decks'
  task initialize_cpu_decks: :environment do
    Unlight::CharaCardDeck.initialize_CPU_deck
  end
end
