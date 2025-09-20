# frozen_string_literal: true

# This file contains shared schema definitions for the API documentation

def transaction_schema
  {
    type: :object,
    properties: {
      id: { type: :string, example: 'uuid' },
      date: { type: :string, format: :date, example: '2024-01-15' },
      amount: { type: :string, example: '$100.50' },
      currency: { type: :string, example: 'USD' },
      name: { type: :string, example: 'Grocery Store Purchase' },
      notes: { type: :string, example: 'Weekly groceries' },
      classification: { type: :string, enum: %w[income expense], example: 'expense' },
      account: {
        type: :object,
        properties: {
          id: { type: :string, example: 'uuid' },
          name: { type: :string, example: 'Chase Checking' },
          account_type: { type: :string, example: 'depository' }
        }
      },
      category: {
        type: :object,
        nullable: true,
        properties: {
          id: { type: :string, example: 'uuid' },
          name: { type: :string, example: 'Groceries' },
          classification: { type: :string, example: 'expense' },
          color: { type: :string, example: '#FF6B6B' },
          icon: { type: :string, example: 'shopping-cart' }
        }
      },
      merchant: {
        type: :object,
        nullable: true,
        properties: {
          id: { type: :string, example: 'uuid' },
          name: { type: :string, example: 'Whole Foods' }
        }
      },
      tags: {
        type: :array,
        items: {
          type: :object,
          properties: {
            id: { type: :string, example: 'uuid' },
            name: { type: :string, example: 'organic' },
            color: { type: :string, example: '#4ECDC4' }
          }
        }
      },
      transfer: {
        type: :object,
        nullable: true,
        properties: {
          id: { type: :string, example: 'uuid' },
          amount: { type: :string, example: '$100.50' },
          currency: { type: :string, example: 'USD' },
          other_account: {
            type: :object,
            properties: {
              id: { type: :string, example: 'uuid' },
              name: { type: :string, example: 'Savings Account' },
              account_type: { type: :string, example: 'depository' }
            }
          }
        }
      },
      created_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' },
      updated_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' }
    }
  }
end

def chat_summary_schema
  {
    type: :object,
    properties: {
      id: { type: :string, example: 'uuid' },
      title: { type: :string, example: 'Budget Planning Discussion' },
      last_message_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' },
      message_count: { type: :integer, example: 5 },
      error: { type: :string, nullable: true, example: nil },
      created_at: { type: :string, format: :date_time, example: '2024-01-15T10:00:00Z' },
      updated_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' }
    }
  }
end

def chat_schema
  {
    type: :object,
    properties: {
      id: { type: :string, example: 'uuid' },
      title: { type: :string, example: 'Budget Planning Discussion' },
      error: { type: :string, nullable: true, example: nil },
      created_at: { type: :string, format: :date_time, example: '2024-01-15T10:00:00Z' },
      updated_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' }
    }
  }
end

def chat_with_messages_schema
  {
    type: :object,
    allOf: [
      { '$ref' => '#/components/schemas/chat' },
      {
        type: :object,
        properties: {
          messages: {
            type: :array,
            items: { '$ref' => '#/components/schemas/message' }
          },
          pagination: {
            type: :object,
            properties: {
              page: { type: :integer, example: 1 },
              per_page: { type: :integer, example: 50 },
              total_count: { type: :integer, example: 2 },
              total_pages: { type: :integer, example: 1 }
            }
          }
        }
      }
    ]
  }
end

def message_schema
  {
    type: :object,
    properties: {
      id: { type: :string, example: 'uuid' },
      type: { type: :string, enum: %w[user_message assistant_message], example: 'user_message' },
      role: { type: :string, enum: %w[user assistant], example: 'user' },
      content: { type: :string, example: 'What is my current spending on groceries?' },
      model: { type: :string, example: 'gpt-4' },
      created_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' },
      updated_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' },
      tool_calls: {
        type: :array,
        items: {
          type: :object,
          properties: {
            id: { type: :string, example: 'uuid' },
            function_name: { type: :string, example: 'get_accounts' },
            function_arguments: { type: :object, example: {} },
            function_result: { type: :object, example: { accounts: [] } },
            created_at: { type: :string, format: :date_time, example: '2024-01-15T10:30:00Z' }
          }
        }
      }
    }
  }
end

def error_schema
  {
    type: :object,
    properties: {
      error: { type: :string, example: 'unauthorized' },
      message: { type: :string, example: 'Human readable error message' },
      details: {
        type: :array,
        items: { type: :string },
        example: [ 'Additional error details' ]
      }
    }
  }
end
