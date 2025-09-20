# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/auth', type: :request do
  path '/api/v1/auth/signup' do
    post('create user account') do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: 'user@example.com' },
              password: { type: :string, minLength: 8, example: 'SecurePass123!' },
              first_name: { type: :string, example: 'John' },
              last_name: { type: :string, example: 'Doe' }
            },
            required: %w[email password first_name last_name]
          },
          device: {
            type: :object,
            properties: {
              device_id: { type: :string, example: 'device-123' },
              device_name: { type: :string, example: 'iPhone 15' },
              device_type: { type: :string, example: 'mobile' },
              os_version: { type: :string, example: 'iOS 17.0' },
              app_version: { type: :string, example: '1.0.0' }
            },
            required: %w[device_id device_name device_type os_version app_version]
          },
          invite_code: { type: :string, example: 'INVITE123' }
        },
        required: %w[user device]
      }

      response(201, 'user created successfully') do
        schema type: :object,
               properties: {
                 access_token: { type: :string, example: 'eyJhbGciOiJIUzI1NiJ9...' },
                 refresh_token: { type: :string, example: 'refresh_token_123' },
                 token_type: { type: :string, example: 'Bearer' },
                 expires_in: { type: :integer, example: 2592000 },
                 created_at: { type: :integer, example: 1640995200 },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :string, example: 'uuid' },
                     email: { type: :string, example: 'user@example.com' },
                     first_name: { type: :string, example: 'John' },
                     last_name: { type: :string, example: 'Doe' }
                   }
                 }
               }

        let(:user) do
          {
            user: {
              email: 'newuser@example.com',
              password: 'SecurePass123!',
              first_name: 'John',
              last_name: 'Doe'
            },
            device: {
              device_id: 'device-123',
              device_name: 'iPhone 15',
              device_type: 'mobile',
              os_version: 'iOS 17.0',
              app_version: '1.0.0'
            }
          }
        end

        run_test!
      end

      response(422, 'validation failed') do
        schema type: :object,
               properties: {
                 errors: {
                   type: :array,
                   items: { type: :string },
                   example: [ 'Email has already been taken', 'Password is too short' ]
                 }
               }

        let(:user) do
          {
            user: {
              email: 'invalid-email',
              password: '123',
              first_name: '',
              last_name: ''
            },
            device: {
              device_id: 'device-123',
              device_name: 'iPhone 15',
              device_type: 'mobile',
              os_version: 'iOS 17.0',
              app_version: '1.0.0'
            }
          }
        end

        run_test!
      end

      response(400, 'bad request') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Device information is required' }
               }

        let(:user) do
          {
            user: {
              email: 'user@example.com',
              password: 'SecurePass123!',
              first_name: 'John',
              last_name: 'Doe'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/auth/login' do
    post('authenticate user') do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'user@example.com' },
          password: { type: :string, example: 'SecurePass123!' },
          otp_code: { type: :string, example: '123456' },
          device: {
            type: :object,
            properties: {
              device_id: { type: :string, example: 'device-123' },
              device_name: { type: :string, example: 'iPhone 15' },
              device_type: { type: :string, example: 'mobile' },
              os_version: { type: :string, example: 'iOS 17.0' },
              app_version: { type: :string, example: '1.0.0' }
            },
            required: %w[device_id device_name device_type os_version app_version]
          }
        },
        required: %w[email password device]
      }

      response(200, 'login successful') do
        schema type: :object,
               properties: {
                 access_token: { type: :string, example: 'eyJhbGciOiJIUzI1NiJ9...' },
                 refresh_token: { type: :string, example: 'refresh_token_123' },
                 token_type: { type: :string, example: 'Bearer' },
                 expires_in: { type: :integer, example: 2592000 },
                 created_at: { type: :integer, example: 1640995200 },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :string, example: 'uuid' },
                     email: { type: :string, example: 'user@example.com' },
                     first_name: { type: :string, example: 'John' },
                     last_name: { type: :string, example: 'Doe' }
                   }
                 }
               }

        let(:credentials) do
          {
            email: 'user@example.com',
            password: 'SecurePass123!',
            device: {
              device_id: 'device-123',
              device_name: 'iPhone 15',
              device_type: 'mobile',
              os_version: 'iOS 17.0',
              app_version: '1.0.0'
            }
          }
        end

        run_test!
      end

      response(401, 'unauthorized') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Invalid email or password' }
               }

        let(:credentials) do
          {
            email: 'user@example.com',
            password: 'wrongpassword',
            device: {
              device_id: 'device-123',
              device_name: 'iPhone 15',
              device_type: 'mobile',
              os_version: 'iOS 17.0',
              app_version: '1.0.0'
            }
          }
        end

        run_test!
      end

      response(401, 'mfa required') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Two-factor authentication required' },
                 mfa_required: { type: :boolean, example: true }
               }

        let(:credentials) do
          {
            email: 'user@example.com',
            password: 'SecurePass123!',
            device: {
              device_id: 'device-123',
              device_name: 'iPhone 15',
              device_type: 'mobile',
              os_version: 'iOS 17.0',
              app_version: '1.0.0'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/auth/refresh' do
    post('refresh access token') do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :refresh_data, in: :body, schema: {
        type: :object,
        properties: {
          refresh_token: { type: :string, example: 'refresh_token_123' },
          device: {
            type: :object,
            properties: {
              device_id: { type: :string, example: 'device-123' }
            },
            required: %w[device_id]
          }
        },
        required: %w[refresh_token device]
      }

      response(200, 'token refreshed successfully') do
        schema type: :object,
               properties: {
                 access_token: { type: :string, example: 'eyJhbGciOiJIUzI1NiJ9...' },
                 refresh_token: { type: :string, example: 'new_refresh_token_123' },
                 token_type: { type: :string, example: 'Bearer' },
                 expires_in: { type: :integer, example: 2592000 },
                 created_at: { type: :integer, example: 1640995200 }
               }

        let(:refresh_data) do
          {
            refresh_token: 'valid_refresh_token',
            device: {
              device_id: 'device-123'
            }
          }
        end

        run_test!
      end

      response(401, 'invalid refresh token') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Invalid refresh token' }
               }

        let(:refresh_data) do
          {
            refresh_token: 'invalid_token',
            device: {
              device_id: 'device-123'
            }
          }
        end

        run_test!
      end

      response(400, 'refresh token required') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Refresh token is required' }
               }

        let(:refresh_data) do
          {
            device: {
              device_id: 'device-123'
            }
          }
        end

        run_test!
      end
    end
  end
end
