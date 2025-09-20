# frozen_string_literal: true

require 'rails_helper'
require_relative 'requests/api/v1/schemas'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Maybe Finance API',
        version: 'v1',
        description: 'Personal finance management API with AI-powered insights',
        contact: {
          name: 'Maybe Finance',
          url: 'https://maybefinance.com'
        }
      },
      paths: {},
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'api.maybefinance.com'
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          },
          api_key: {
            type: :apiKey,
            in: :header,
            name: 'X-Api-Key'
          }
        },
        schemas: {
          transaction: transaction_schema,
          chat_summary: chat_summary_schema,
          chat: chat_schema,
          chat_with_messages: chat_with_messages_schema,
          message: message_schema,
          error: error_schema
        }
      },
      security: [
        { bearer_auth: [] },
        { api_key: [] }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
