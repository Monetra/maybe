# External Integrations

## Integration Architecture Overview

Maybe integrates with several external services to provide comprehensive financial management capabilities. All integrations follow a consistent provider pattern that allows for easy testing, mocking, and optional deployment in self-hosted environments.

## Provider Pattern

### Registry System
External services are managed through a centralized registry:

```ruby
# app/models/provider/registry.rb
class Provider::Registry
  def self.get_provider(name)
    # Returns configured provider instance
  end
  
  def self.for_concept(concept)
    # Returns concept-specific provider registry
  end
end
```

### Provider Base Class
All providers inherit from a common base class:

```ruby
# app/models/provider.rb
class Provider
  def with_provider_response
    # Wraps provider calls with error handling
  end
end
```

## AI Integration (OpenAI)

### Overview
Provides AI-powered chat functionality, auto-categorization, and merchant detection.

### Architecture
- **Provider**: `Provider::Openai`
- **Concepts**: LLM (Large Language Model)
- **Models**: GPT-4, GPT-4-turbo, GPT-3.5-turbo

### Key Components

#### Chat System
```ruby
# app/models/assistant.rb
class Assistant
  def respond_to(message)
    # Processes user messages and generates AI responses
  end
end
```

#### Function Calling
AI can execute financial queries through function calls:

```ruby
# app/models/assistant/function_tool_caller.rb
class Assistant::FunctionToolCaller
  def call_function(name, arguments)
    # Executes financial queries on behalf of AI
  end
end
```

#### Auto-categorization
```ruby
# app/models/provider/openai/auto_categorizer.rb
class Provider::Openai::AutoCategorizer
  def auto_categorize(transactions)
    # Uses AI to categorize transactions
  end
end
```

### API Endpoints
- `POST /api/v1/chats` - Create new chat
- `POST /api/v1/chats/:id/messages` - Send message
- `POST /api/v1/chats/:id/messages/retry` - Retry last message

### Configuration
```ruby
# config/initializers/openai.rb
Rails.application.config.openai_api_key = ENV['OPENAI_API_KEY']
```

## Synth API Integration

### Overview
Custom market data API providing exchange rates and security prices.

### Architecture
- **Provider**: `Provider::Synth`
- **Concepts**: Exchange Rates, Securities
- **Data**: Historical prices, exchange rates, security information

### Key Components

#### Exchange Rate Provider
```ruby
# app/models/exchange_rate/provided.rb
module ExchangeRate::Provided
  def self.provider
    Provider::Registry.for_concept(:exchange_rates)
  end
  
  def self.find_or_fetch_rate(from:, to:, date:)
    # Fetches exchange rate from provider
  end
end
```

#### Security Provider
```ruby
# app/models/security/provided.rb
module Security::Provided
  def self.provider
    Provider::Registry.for_concept(:securities)
  end
  
  def self.search_securities(symbol)
    # Searches for securities by symbol
  end
end
```

### Data Synchronization
```ruby
# app/models/market_data_importer.rb
class MarketDataImporter
  def import_all
    import_security_prices
    import_exchange_rates
  end
end
```

### Configuration
```ruby
# config/initializers/synth.rb
Rails.application.config.synth_api_key = ENV['SYNTH_API_KEY']
```

## Plaid Integration

### Overview
Bank account connection and transaction synchronization for US and EU regions.

### Architecture
- **Provider**: `Provider::Plaid`
- **Regions**: US, EU
- **Data**: Accounts, transactions, holdings, liabilities

### Key Components

#### Plaid Item Management
```ruby
# app/models/plaid_item.rb
class PlaidItem < ApplicationRecord
  def import_latest_plaid_data
    # Fetches latest data from Plaid
  end
  
  def process_accounts
    # Processes fetched data into internal models
  end
end
```

#### Account Processing
```ruby
# app/models/plaid_account/processor.rb
class PlaidAccount::Processor
  def process_account!
    # Creates/updates internal account from Plaid data
  end
  
  def process_transactions
    # Processes transaction data
  end
end
```

#### Webhook Processing
```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  def plaid
    # Processes Plaid webhooks
  end
end
```

### Data Flow
1. **Link Token Creation**: Generate secure link tokens
2. **User Authentication**: User connects bank account
3. **Data Fetching**: Retrieve account and transaction data
4. **Data Processing**: Transform Plaid data to internal format
5. **Sync Scheduling**: Schedule background sync jobs

### Configuration
```ruby
# config/initializers/plaid.rb
Rails.application.config.plaid_client_id = ENV['PLAID_CLIENT_ID']
Rails.application.config.plaid_secret = ENV['PLAID_SECRET']
```

## Stripe Integration

### Overview
Payment processing and subscription management.

### Architecture
- **Provider**: `Provider::Stripe`
- **Features**: Subscriptions, billing portal, webhooks
- **Plans**: Monthly, annual subscriptions

### Key Components

#### Subscription Management
```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  enum :status, {
    trialing: "trialing",
    active: "active",
    canceled: "canceled"
  }
end
```

#### Checkout Sessions
```ruby
# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController
  def new
    checkout_session = stripe.create_checkout_session(
      plan: params[:plan],
      family_id: Current.family.id,
      family_email: Current.family.billing_email
    )
    redirect_to checkout_session.url
  end
end
```

#### Webhook Processing
```ruby
# app/models/provider/stripe/subscription_event_processor.rb
class Provider::Stripe::SubscriptionEventProcessor
  def process
    # Processes Stripe webhook events
  end
end
```

### Configuration
```ruby
# config/initializers/stripe.rb
Rails.application.config.stripe_secret_key = ENV['STRIPE_SECRET_KEY']
Rails.application.config.stripe_webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
```

## Integration Patterns

### 1. Provider Registration
```ruby
# config/initializers/providers.rb
Provider::Registry.register(:stripe, Provider::Stripe.new(
  secret_key: Rails.application.config.stripe_secret_key,
  webhook_secret: Rails.application.config.stripe_webhook_secret
))
```

### 2. Concept-Based Providers
```ruby
# app/models/provider/concepts/exchange_rate.rb
module Provider::Concepts::ExchangeRate
  def fetch_exchange_rate(from:, to:, date:)
    # Interface for exchange rate providers
  end
end
```

### 3. Error Handling
```ruby
# app/models/provider.rb
class Provider
  def with_provider_response
    yield
  rescue => e
    ProviderResponse.new(success: false, error: e.message)
  end
end
```

### 4. Caching
```ruby
# app/models/exchange_rate.rb
class ExchangeRate < ApplicationRecord
  def self.find_or_fetch_rate(from:, to:, date:, cache: true)
    rate = find_by(from_currency: from, to_currency: to, date: date)
    return rate if rate.present?
    
    # Fetch from provider and cache
  end
end
```

## Self-Hosting Considerations

### Optional Integrations
In self-hosted mode, external integrations are optional:

```ruby
# app/models/family.rb
def requires_data_provider?
  # Check if family needs external data providers
  trades.any? || accounts.where.not(currency: self.currency).any?
end

def missing_data_provider?
  requires_data_provider? && Provider::Registry.get_provider(:synth).nil?
end
```

### Configuration Validation
```ruby
# app/controllers/concerns/self_hostable.rb
module SelfHostable
  def self_hosted?
    Rails.application.config.app_mode.self_hosted?
  end
  
  def require_integration!(integration)
    return if Provider::Registry.get_provider(integration).present?
    
    redirect_to settings_path, alert: "#{integration.titleize} integration required"
  end
end
```

## Testing Integrations

### Provider Mocking
```ruby
# test/support/provider_mocks.rb
module ProviderMocks
  def mock_stripe_provider
    mock_provider = mock
    mock_provider.expects(:create_checkout_session).returns(
      OpenStruct.new(url: "https://checkout.stripe.com/test", customer_id: "test")
    )
    Provider::Registry.stubs(:get_provider).with(:stripe).returns(mock_provider)
  end
end
```

### VCR Cassettes
```ruby
# test/vcr_cassettes/stripe_webhook.yml
---
http_interactions:
- request:
    method: post
    uri: https://api.stripe.com/v1/webhooks
    body:
      string: '{"type":"customer.subscription.created",...}'
  response:
    status:
      code: 200
      message: OK
```

## Security Considerations

### API Key Management
- Store sensitive keys in Rails credentials
- Use environment variables for configuration
- Rotate keys regularly

### Webhook Security
```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def stripe
    signature = request.headers['Stripe-Signature']
    event = stripe.construct_event(request.body.read, signature)
    # Process webhook
  end
end
```

### Data Encryption
```ruby
# app/models/plaid_item.rb
class PlaidItem < ApplicationRecord
  if Rails.application.credentials.active_record_encryption.present?
    encrypts :access_token, deterministic: true
  end
end
```

## Monitoring and Observability

### Error Tracking
```ruby
# app/models/provider.rb
class Provider
  def with_provider_response
    yield
  rescue => e
    Sentry.capture_exception(e)
    ProviderResponse.new(success: false, error: e.message)
  end
end
```

### Usage Tracking
```ruby
# app/models/provider/synth.rb
def usage
  response = client.get("#{base_url}/user")
  parsed = JSON.parse(response.body)
  
  UsageData.new(
    used: parsed.dig("api_calls_used"),
    limit: parsed.dig("api_limit"),
    utilization: parsed.dig("api_calls_used").to_f / parsed.dig("api_limit") * 100
  )
end
```

### Health Checks
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    providers = {
      stripe: Provider::Registry.get_provider(:stripe)&.healthy?,
      plaid: Provider::Registry.get_provider(:plaid)&.healthy?,
      synth: Provider::Registry.get_provider(:synth)&.healthy?
    }
    
    render json: { providers: providers }
  end
end
```

## Performance Optimization

### Background Processing
```ruby
# app/jobs/sync_job.rb
class SyncJob < ApplicationJob
  def perform(syncable)
    syncable.sync_data
  end
end
```

### Rate Limiting
```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/stripe', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api/stripe')
end
```

### Caching
```ruby
# app/models/exchange_rate.rb
def self.find_or_fetch_rate(from:, to:, date:, cache: true)
  Rails.cache.fetch("exchange_rate_#{from}_#{to}_#{date}", expires_in: 1.day) do
    provider.fetch_exchange_rate(from: from, to: to, date: date)
  end
end
```

This integration architecture provides a flexible, testable, and maintainable way to work with external services while supporting both managed and self-hosted deployment modes.
