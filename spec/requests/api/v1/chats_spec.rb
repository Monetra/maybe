# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/chats', type: :request do
  path '/api/v1/chats' do
    get('list chats') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for pagination'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Number of items per page'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 chats: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/chat_summary' }
                 },
                 pagination: {
                   type: :object,
                   properties: {
                     page: { type: :integer, example: 1 },
                     per_page: { type: :integer, example: 20 },
                     total_count: { type: :integer, example: 50 },
                     total_pages: { type: :integer, example: 3 }
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

      response(403, 'ai features disabled') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'feature_disabled' },
                 message: { type: :string, example: 'AI features are not enabled for this user' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        run_test!
      end
    end

    post('create chat') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :chat, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Budget Planning Discussion' },
          message: { type: :string, example: 'Help me plan my monthly budget' },
          model: { type: :string, enum: %w[gpt-4 gpt-4-turbo gpt-3.5-turbo], example: 'gpt-4' }
        }
      }

      response(201, 'chat created successfully') do
        schema { '$ref' => '#/components/schemas/chat' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:chat) do
          {
            title: 'Budget Planning Discussion',
            message: 'Help me plan my monthly budget',
            model: 'gpt-4'
          }
        end

        run_test!
      end

      response(422, 'validation failed') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Failed to create chat' },
                 details: {
                   type: :array,
                   items: { type: :string },
                   example: [ 'Title is too long' ]
                 }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:chat) do
          {
            title: 'A' * 1000
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/chats/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Chat ID'

    get('show chat') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for messages pagination'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Number of messages per page'

      response(200, 'successful') do
        schema { '$ref' => '#/components/schemas/chat_with_messages' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_chat_id' }
        run_test!
      end

      response(404, 'chat not found') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Chat not found' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'non_existent_id' }
        run_test!
      end
    end

    patch('update chat') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :chat, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Updated Chat Title' }
        },
        required: %w[title]
      }

      response(200, 'chat updated successfully') do
        schema { '$ref' => '#/components/schemas/chat' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_chat_id' }
        let(:chat) do
          {
            title: 'Updated Chat Title'
          }
        end

        run_test!
      end

      response(422, 'validation failed') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Failed to update chat' },
                 details: {
                   type: :array,
                   items: { type: :string },
                   example: [ 'Title is too long' ]
                 }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_chat_id' }
        let(:chat) do
          {
            title: 'A' * 1000
          }
        end

        run_test!
      end
    end

    delete('delete chat') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      response(204, 'chat deleted successfully') do
        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'valid_chat_id' }
        run_test!
      end

      response(404, 'chat not found') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Chat not found' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:id) { 'non_existent_id' }
        run_test!
      end
    end
  end

  path '/api/v1/chats/{chat_id}/messages' do
    parameter name: :chat_id, in: :path, type: :string, description: 'Chat ID'

    post('create message') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :message, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string, example: 'What is my current spending on groceries?' },
          model: { type: :string, enum: %w[gpt-4 gpt-4-turbo gpt-3.5-turbo], example: 'gpt-4' }
        },
        required: %w[content]
      }

      response(201, 'message created successfully') do
        schema { '$ref' => '#/components/schemas/message' }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:chat_id) { 'valid_chat_id' }
        let(:message) do
          {
            content: 'What is my current spending on groceries?',
            model: 'gpt-4'
          }
        end

        run_test!
      end

      response(422, 'validation failed') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Failed to create message' },
                 details: {
                   type: :array,
                   items: { type: :string },
                   example: [ 'Content can\'t be blank' ]
                 }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:chat_id) { 'valid_chat_id' }
        let(:message) do
          {
            content: ''
          }
        end

        run_test!
      end
    end

    post('retry last message') do
      tags 'Chats'
      security [ { bearer_auth: [] }, { api_key: [] } ]
      produces 'application/json'

      response(202, 'retry initiated') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Retry initiated' },
                 message_id: { type: :string, example: 'uuid' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:chat_id) { 'valid_chat_id' }
        run_test!
      end

      response(422, 'no assistant message to retry') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'No assistant message to retry' }
               }

        let(:Authorization) { 'Bearer valid_jwt_token' }
        let(:chat_id) { 'valid_chat_id' }
        run_test!
      end
    end
  end
end
