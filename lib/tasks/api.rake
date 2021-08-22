# frozen_string_literal: true

require 'forwardable'
require 'grape-swagger'
require 'grape-swagger-entity'

# :nodoc:
class APIDocumentGenerator
  extend Forwardable
  delegate [:combined_namespace_routes, :endpoints, :add_swagger_documentation] => :@klass

  def initialize(klass, options = {})
    @klass = klass
    @options = GrapeSwagger::DocMethods::DEFAULTS.merge(options)

    add_swagger_documentation
  end

  def to_json(options = {})
    GrapeSwagger::DocMethods
      .output_path_definitions(combined_namespace_routes, endpoint, @klass, @options)
      .to_json(options)
  end

  def endpoint
    @endpoint ||=
      begin
        endpoint, = endpoints
        endpoint.instance_variable_set('@request', request)
        endpoint
      end
  end

  def request
    @request ||= Rack::Request.new(Rack::MockRequest.env_for('https://beta.unlight.dev'))
  end
end

namespace :api do
  desc 'Generate Game API Document'
  task game: :environment do
    options = {
      info: {
        title: 'Unlight Game API',
        description: 'The API for players to access their data'
      },
      host: 'beta.unlight.dev',
      doc_version: Dawn::VERSION,
      security_definitions: {
        api_key: {
          type: :apiKey,
          name: 'dawn-hmac-sha256',
          in: :header
        }
      },
      security: [
        {
          api_key: []
        }
      ]
    }
    puts 'Create Game API Swagger Document...'
    File.write(Dawn.root.join('tmp/game_api.json'), APIDocumentGenerator.new(GameAPI, options).to_json)
  end
end
