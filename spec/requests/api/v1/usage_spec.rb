# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/usage', type: :request do
  path '/api/v1/usage' do
    get('get usage information') do
      tags 'Usage'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      response(200, 'successful - API key authentication') do
        schema type: :object,
               properties: {
                 api_key: {
                   type: :object,
                   properties: {
                     name: { type: :string, example: 'My API Key' },
                     scopes: { type: :array, items: { type: :string }, example: [ 'read', 'write' ] },
                     last_used_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' },
                     created_at: { type: :string, format: :date_time, example: '2024-01-01T00:00:00Z' }
                   }
                 },
                 rate_limit: {
                   type: :object,
                   properties: {
                     tier: { type: :string, example: 'free' },
                     limit: { type: :integer, example: 1000 },
                     current_count: { type: :integer, example: 150 },
                     remaining: { type: :integer, example: 850 },
                     reset_in_seconds: { type: :integer, example: 3600 },
                     reset_at: { type: :string, format: :date_time, example: '2024-01-15T11:30:00Z' }
                   }
                 }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        run_test!
      end

      response(200, 'successful - OAuth authentication') do
        schema type: :object,
               properties: {
                 authentication_method: { type: :string, example: 'oauth' },
                 message: { type: :string, example: 'Detailed usage tracking is available for API key authentication' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        run_test!
      end

      response(400, 'invalid authentication method') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'invalid_authentication_method' },
                 message: { type: :string, example: 'Unable to determine usage information' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        run_test!
      end

      response(401, 'unauthorized') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'unauthorized' },
                 message: { type: :string, example: 'Access token is invalid, expired, or missing' }
               }

        let(:Authorization) { 'Bearer invalid_token' }
        run_test!
      end
    end
  end
end
