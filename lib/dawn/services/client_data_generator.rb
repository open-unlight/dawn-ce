# frozen_string_literal: true

require 'date'
# NOTE: Add String#singularize support
require 'sequel'
require 'sequel/extensions/inflector'

require 'dawn'
require 'dawn/dataset'

Sequel::Model.plugin :json_serializer

module Dawn
  # Export Game Data for Client
  #
  # @since 0.1.0
  class ClientDataGenerator
    # @since 0.1.0
    MODELS = %w[
      CharaCard
      CharaCardStory
      CharaCardRequirement
      ActionCard
      Feat
      AvatarItem
      EventCard
      Quest
      QuestLand
      QuestMap
      TreasureData
      FeatInventory
      WeaponCard
      RareCardLot
      RealMoneyItem
      AvatarPart
      Shop
      Achievement
      ProfoundData
      ProfoundTreasureData
      PassiveSkill
      PassiveSkillInventory
    ].freeze

    # @param block [Proc] the callback when rows imported
    #
    # @since 0.1.0
    def export
      destination.mkpath unless destination.exist?

      datasets.each do |dataset|
        yield dataset if block_given?
        # TODO: Use `only` options to select necessary columns
        json_data = dataset.to_json(except: %i[created_at updated_at])
        File.write(destination.join("#{dataset.table_name}.json"), json_data)
      end
    end

    # @return [Pathname] the export data destination
    #
    # @since 0.1.0
    def destination
      @destination ||= Dawn.root.join('tmp/export')
    end

    # @return [Array<Sequel::Dataset>] the models to export
    #
    # @since 0.1.0
    def datasets
      @datasets = MODELS.map { |name| Unlight.const_get(name) }
    end
  end
end
