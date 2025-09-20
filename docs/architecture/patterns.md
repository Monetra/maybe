# Architectural Patterns

## Design Patterns Used in Maybe

This document outlines the key architectural patterns and design principles used throughout the Maybe codebase.

## 1. Domain-Driven Design (DDD)

### Bounded Contexts
The application is organized around clear domain boundaries:

- **Financial Management**: Core financial data and operations
- **User Management**: Authentication, authorization, and user preferences
- **Integration**: External service integrations (Plaid, Stripe, AI)
- **Analytics**: Reporting, charts, and financial insights

### Domain Models
Rich domain models with business logic:

```ruby
class Account < ApplicationRecord
  # Business logic methods
  def current_holdings
    # Complex business logic for holdings calculation
  end
  
  def balance_type
    # Business rules for account classification
  end
end
```

## 2. Provider Pattern

### Abstract External Services
External services are abstracted behind consistent interfaces:

```ruby
# Concept-based providers (exchangeable)
module ExchangeRate::Provided
  def self.provider
    Provider::Registry.for_concept(:exchange_rates)
  end
end

# Direct providers (service-specific)
class Provider::Stripe
  def create_checkout_session(plan:, family_id:, ...)
    # Stripe-specific implementation
  end
end
```

### Benefits
- **Testability**: Easy to mock external services
- **Flexibility**: Swap providers without changing business logic
- **Self-hosting**: Optional external services for self-hosted deployments

## 3. Event Sourcing

### Entry-Based Architecture
All financial changes are recorded as entries:

```ruby
class Entry < ApplicationRecord
  # All financial changes go through entries
  belongs_to :account
  belongs_to :entryable, polymorphic: true # Transaction, Valuation, Trade
end
```

### Benefits
- **Audit Trail**: Complete history of all changes
- **Replay Capability**: Rebuild state from events
- **Temporal Queries**: Query data at any point in time

## 4. State Machine Pattern

### Account Lifecycle
Accounts use state machines for lifecycle management:

```ruby
class Account < ApplicationRecord
  aasm column: :status do
    state :active, initial: true
    state :draft
    state :disabled
    state :pending_deletion
    
    event :activate do
      transitions from: [:draft, :disabled], to: :active
    end
  end
end
```

### Benefits
- **Clear States**: Explicit state transitions
- **Validation**: Ensure valid state changes
- **Business Rules**: Enforce business logic in transitions

## 5. Concern Pattern

### Modular Business Logic
Business logic is organized into focused concerns:

```ruby
class Account < ApplicationRecord
  include Syncable, Monetizable, Chartable, Linkable, Enrichable
end

module Syncable
  extend ActiveSupport::Concern
  
  def sync_later
    # Sync logic
  end
end
```

### Benefits
- **Single Responsibility**: Each concern has one purpose
- **Reusability**: Share logic across models
- **Organization**: Keep related methods together

## 6. Delegated Type Pattern

### Polymorphic Account Types
Different account types share common interface:

```ruby
class Account < ApplicationRecord
  delegated_type :accountable, types: Accountable::TYPES
end

class Depository < ApplicationRecord
  # Checking, savings accounts
end

class Investment < ApplicationRecord
  # Brokerage accounts
end
```

### Benefits
- **Type Safety**: Compile-time type checking
- **Polymorphism**: Treat different types uniformly
- **Extensibility**: Easy to add new account types

## 7. Repository Pattern

### Data Access Abstraction
Complex queries are encapsulated in repository-like classes:

```ruby
class BalanceSheet
  def initialize(family)
    @family = family
  end
  
  def assets
    # Complex query logic
  end
end
```

### Benefits
- **Encapsulation**: Hide complex query logic
- **Testability**: Easy to mock data access
- **Reusability**: Share query logic across controllers

## 8. Command Pattern

### Background Job Processing
Long-running operations are encapsulated as commands:

```ruby
class SyncJob < ApplicationJob
  def perform(syncable)
    syncable.sync_data
  end
end

class Account < ApplicationRecord
  def sync_later
    SyncJob.perform_later(self)
  end
end
```

### Benefits
- **Asynchronous**: Non-blocking operations
- **Reliability**: Job retry and error handling
- **Scalability**: Distribute work across workers

## 9. Observer Pattern

### Event-Driven Updates
Changes trigger cascading updates:

```ruby
class Account < ApplicationRecord
  after_update :sync_later, if: :saved_change_to_balance?
end
```

### Benefits
- **Loose Coupling**: Decoupled components
- **Extensibility**: Easy to add new observers
- **Consistency**: Ensure data consistency

## 10. Strategy Pattern

### Algorithm Selection
Different algorithms for similar operations:

```ruby
class BalanceCalculator
  def initialize(account)
    @account = account
  end
  
  def balance
    case account.balance_type
    when :cash
      CashBalanceCalculator.new(account).calculate
    when :investment
      InvestmentBalanceCalculator.new(account).calculate
    end
  end
end
```

### Benefits
- **Flexibility**: Switch algorithms at runtime
- **Extensibility**: Easy to add new strategies
- **Testability**: Test each strategy independently

## 11. Factory Pattern

### Object Creation
Complex object creation is encapsulated:

```ruby
class Account::OpeningBalanceManager
  def set_opening_balance(balance:)
    # Complex account creation logic
  end
end
```

### Benefits
- **Encapsulation**: Hide complex creation logic
- **Consistency**: Ensure objects are created correctly
- **Flexibility**: Easy to modify creation process

## 12. Adapter Pattern

### External Service Integration
External services are adapted to internal interfaces:

```ruby
class Provider::Plaid
  def fetch_transactions(access_token, start_date, end_date)
    # Adapt Plaid API to internal format
  end
end
```

### Benefits
- **Abstraction**: Hide external service complexity
- **Consistency**: Uniform interface across providers
- **Testability**: Easy to mock external services

## 13. Template Method Pattern

### Common Algorithm Structure
Base classes define algorithm structure:

```ruby
class BaseCalculator
  def calculate
    validate_inputs
    perform_calculation
    format_result
  end
  
  private
  
  def validate_inputs
    # Default implementation
  end
  
  def perform_calculation
    raise NotImplementedError
  end
end
```

### Benefits
- **Code Reuse**: Share common algorithm structure
- **Consistency**: Ensure consistent behavior
- **Extensibility**: Easy to add new implementations

## 14. Chain of Responsibility

### Request Processing
Requests are processed through a chain of handlers:

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user
  before_action :set_current_family
  before_action :authorize_family_access
end
```

### Benefits
- **Separation of Concerns**: Each handler has one responsibility
- **Flexibility**: Easy to add/remove handlers
- **Reusability**: Share handlers across controllers

## 15. Decorator Pattern

### Enhanced Functionality
Objects are enhanced with additional functionality:

```ruby
class Monetizable
  def balance_money
    Money.new(balance, currency)
  end
end
```

### Benefits
- **Flexibility**: Add functionality without modifying base class
- **Composition**: Combine multiple decorators
- **Single Responsibility**: Each decorator has one purpose

## Pattern Benefits Summary

### Maintainability
- **Clear Structure**: Patterns provide clear code organization
- **Consistent Approach**: Similar problems solved similarly
- **Easy to Understand**: Well-known patterns are familiar

### Testability
- **Dependency Injection**: Easy to mock dependencies
- **Single Responsibility**: Test individual components
- **Isolation**: Test components in isolation

### Extensibility
- **Open/Closed Principle**: Open for extension, closed for modification
- **Plugin Architecture**: Easy to add new functionality
- **Configuration**: Behavior can be configured

### Performance
- **Lazy Loading**: Load data only when needed
- **Caching**: Strategic caching for performance
- **Background Processing**: Non-blocking operations

## Anti-Patterns to Avoid

### God Objects
- **Problem**: Classes with too many responsibilities
- **Solution**: Break into smaller, focused classes

### Anemic Domain Models
- **Problem**: Models with only data, no behavior
- **Solution**: Move business logic into models

### Service Objects Overuse
- **Problem**: Too many service objects for simple operations
- **Solution**: Use concerns and model methods

### Tight Coupling
- **Problem**: Classes directly dependent on each other
- **Solution**: Use dependency injection and interfaces

### Premature Optimization
- **Problem**: Optimizing before understanding performance needs
- **Solution**: Measure first, optimize second
