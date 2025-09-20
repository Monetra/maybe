# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/transactions', type: :request do
  path '/api/v1/transactions' do
    get('list transactions') do
      tags 'Transactions'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for pagination'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Number of items per page (max 100)'
      parameter name: :account_id, in: :query, type: :string, required: false, description: 'Filter by account ID'
      parameter name: :account_ids, in: :query, type: :array, items: { type: :string }, required: false, description: 'Filter by multiple account IDs'
      parameter name: :category_id, in: :query, type: :string, required: false, description: 'Filter by category ID'
      parameter name: :category_ids, in: :query, type: :array, items: { type: :string }, required: false, description: 'Filter by multiple category IDs'
      parameter name: :merchant_id, in: :query, type: :string, required: false, description: 'Filter by merchant ID'
      parameter name: :merchant_ids, in: :query, type: :array, items: { type: :string }, required: false, description: 'Filter by multiple merchant IDs'
      parameter name: :start_date, in: :query, type: :string, format: :date, required: false, description: 'Filter transactions from this date'
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false, description: 'Filter transactions to this date'
      parameter name: :min_amount, in: :query, type: :number, required: false, description: 'Filter by minimum amount'
      parameter name: :max_amount, in: :query, type: :number, required: false, description: 'Filter by maximum amount'
      parameter name: :tag_ids, in: :query, type: :array, items: { type: :string }, required: false, description: 'Filter by tag IDs'
      parameter name: :type, in: :query, type: :string, enum: %w[income expense], required: false, description: 'Filter by transaction type'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search in transaction name, notes, or merchant'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 transactions: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/transaction' }
                 },
                 pagination: {
                   type: :object,
                   properties: {
                     page: { type: :integer, example: 1 },
                     per_page: { type: :integer, example: 25 },
                     total_count: { type: :integer, example: 100 },
                     total_pages: { type: :integer, example: 4 }
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
    end

    post('create transaction') do
      tags 'Transactions'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          account_id: { type: :string, example: 'uuid', description: 'Account ID (required)' },
          date: { type: :string, format: :date, example: '2024-01-15' },
          amount: { type: :number, example: 100.50 },
          name: { type: :string, example: 'Grocery Store Purchase' },
          description: { type: :string, example: 'Weekly groceries' },
          notes: { type: :string, example: 'Organic produce' },
          currency: { type: :string, example: 'USD' },
          category_id: { type: :string, example: 'uuid' },
          merchant_id: { type: :string, example: 'uuid' },
          nature: { type: :string, enum: %w[income expense inflow outflow], example: 'expense' },
          tag_ids: { type: :array, items: { type: :string }, example: [ 'tag1', 'tag2' ] }
        },
        required: %w[account_id date amount]
      }

      response(201, 'transaction created successfully') do
        schema { '$ref' => '#/components/schemas/transaction' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:transaction) do
          {
            account_id: 'valid_account_id',
            date: '2024-01-15',
            amount: 100.50,
            name: 'Grocery Store Purchase',
            nature: 'expense'
          }
        end

        run_test!
      end

      response(422, 'validation failed') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'validation_failed' },
                 message: { type: :string, example: 'Transaction could not be created' },
                 errors: {
                   type: :array,
                   items: { type: :string },
                   example: [ 'Account ID is required', 'Amount must be present' ]
                 }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:transaction) do
          {
            date: '2024-01-15',
            amount: 100.50
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/transactions/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Transaction ID'

    get('show transaction') do
      tags 'Transactions'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      response(200, 'successful') do
        schema { '$ref' => '#/components/schemas/transaction' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_transaction_id' }
        run_test!
      end

      response(404, 'transaction not found') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'not_found' },
                 message: { type: :string, example: 'Transaction not found' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'non_existent_id' }
        run_test!
      end
    end

    patch('update transaction') do
      tags 'Transactions'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          date: { type: :string, format: :date, example: '2024-01-15' },
          amount: { type: :number, example: 100.50 },
          name: { type: :string, example: 'Updated Transaction Name' },
          notes: { type: :string, example: 'Updated notes' },
          category_id: { type: :string, example: 'uuid' },
          merchant_id: { type: :string, example: 'uuid' },
          tag_ids: { type: :array, items: { type: :string }, example: [ 'tag1', 'tag2' ] }
        }
      }

      response(200, 'transaction updated successfully') do
        schema { '$ref' => '#/components/schemas/transaction' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_transaction_id' }
        let(:transaction) do
          {
            name: 'Updated Transaction Name',
            notes: 'Updated notes'
          }
        end

        run_test!
      end

      response(422, 'validation failed') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'validation_failed' },
                 message: { type: :string, example: 'Transaction could not be updated' },
                 errors: {
                   type: :array,
                   items: { type: :string },
                   example: [ 'Amount must be present' ]
                 }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_transaction_id' }
        let(:transaction) do
          {
            amount: nil
          }
        end

        run_test!
      end
    end

    delete('delete transaction') do
      tags 'Transactions'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      response(200, 'transaction deleted successfully') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Transaction deleted successfully' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_transaction_id' }
        run_test!
      end

      response(404, 'transaction not found') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'not_found' },
                 message: { type: :string, example: 'Transaction not found' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'non_existent_id' }
        run_test!
      end
    end
  end
end
