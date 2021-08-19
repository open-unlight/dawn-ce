# frozen_string_literal: true

require 'csv'
require 'date'
# NOTE: Add String#singularize support
require 'sequel'
require 'sequel/extensions/inflector'

require 'dawn'
require 'dawn/dataset'

module Dawn
  # Import Game Data
  #
  # @since 0.1.0
  class DataImporter
    # @since 0.1.0
    LANGUAGE_SET = /(_tcn|_en|_scn|_kr|_fr|_ina|_thai)$/

    # @since 0.1.0
    attr_reader :language

    # @param language [String|Symbol] the language to import
    #
    # @since 0.1.0
    def initialize(language = :tcn)
      @language = language
    end

    # FIXME: Console freeze if SQL print to STDOUT
    # @param block [Proc] the callback when rows imported
    #
    # @since 0.1.0
    def import(&block)
      datasets.each do |dataset|
        yield dataset if block
        dataset.model.truncate
        dataset.import
      end
    end

    # @return [Array<Pathname>] the dataset csv paths
    def sources
      @sources ||=
        Dawn.root.glob("data/csv/{ja,#{language}}/*.csv")
    end

    # @return [Array<Dawn::Dataset>] the dataset for import
    def datasets
      @datasets ||=
        sources.map { |path| Dawn::Dataset.new(path, language) }
    end
  end
end
