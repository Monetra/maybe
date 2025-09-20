# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/accounts', type: :request do
  path '/api/v1/accounts' do
    get('list accounts') do
      tags 'Accounts'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for pagination'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Number of items per page (max 100)'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 accounts: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, example: 'uuid' },
                       name: { type: :string, example: 'Chase Checking' },
                       balance: { type: :string, example: '$1,234.56' },
                       currency: { type: :string, example: 'USD' },
                       classification: { type: :string, enum: %w[asset liability], example: 'asset' },
                       account_type: { type: :string, example: 'depository' }
                     }
                   }
                 },
                 pagination: {
                   type: :object,
                   properties: {
                     page: { type: :integer, example: 1 },
                     per_page: { type: :integer, example: 25 },
                     total_count: { type: :integer, example: 50 },
                     total_pages: { type: :integer, example: 2 }
                   }
                 }
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

      response(403, 'insufficient scope') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'insufficient_scope' },
                 message: { type: :string, example: 'This action requires the \'read\' scope' }
               }

        let(:Authorization) { 'Bearer token_without_read_scope' }
        run_test!
      end
    end
  end
end
