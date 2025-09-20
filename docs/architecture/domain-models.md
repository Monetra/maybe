# Domain Models and Relationships

## Overview

The Maybe application is built around a rich domain model that represents the core concepts of personal finance management. The domain is organized around families, accounts, and financial transactions, with a focus on event-sourced architecture and multi-currency support.

## Core Domain Entities

### Family
The top-level container for all financial data and user management.

```ruby
class Family < ApplicationRecord
  include PlaidConnectable, Syncable, AutoTransferMatchable, Subscribeable
  
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :imports, dependent: :destroy
  has_many :family_exports, dependent: :destroy
  has_many :entries, through: :accounts
  has_many :transactions, through: :accounts
  has_many :rules, dependent: :destroy
  has_many :trades, through: :accounts
  has_many :holdings, through: :accounts
  has_many :tags, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :merchants, dependent: :destroy, class_name: "FamilyMerchant"
  has_many :budgets, dependent: :destroy
  has_many :budget_categories, through: :budgets
end
```

**Key Responsibilities:**
- Currency preference and normalization
- User management and permissions
- Subscription and billing
- Data synchronization coordination
- Financial reporting and analytics

### User
Represents individual users within a family.

```ruby
class User < ApplicationRecord
  belongs_to :family
  has_many :sessions, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  
  enum :role, { admin: "admin", member: "member" }
end
```

**Key Responsibilities:**
- Authentication and authorization
- Personal preferences and settings
- AI chat interactions
- API access management

### Account
The central financial entity representing a single financial account.

```ruby
class Account < ApplicationRecord
  include AASM, Syncable, Monetizable, Chartable, Linkable, Enrichable, Anchorable, Reconcileable
  
  belongs_to :family
  belongs_to :import, optional: true
  
  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"
  has_many :entries, dependent: :destroy
  has_many :transactions, through: :entries, source: :entryable, source_type: "Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Trade"
  has_many :holdings, dependent: :destroy
  has_many :balances, dependent: :destroy
  
  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy
end
```

**Key Responsibilities:**
- Financial data storage and management
- Balance tracking and calculation
- Account lifecycle management
- Data synchronization with external providers

## Account Types (Delegated Types)

### Asset Accounts

#### Depository
Bank accounts such as checking and savings accounts.

```ruby
class Depository < ApplicationRecord
  include Accountable
  
  validates :institution_name, presence: true
  
  def display_name
    "#{institution_name} #{subtype.humanize}"
  end
end
```

#### Investment
Brokerage accounts with holdings and securities.

```ruby
class Investment < ApplicationRecord
  include Accountable
  
  has_many :holdings, dependent: :destroy
  has_many :securities, through: :holdings
  
  def display_name
    "#{institution_name} Investment Account"
  end
end
```

#### Crypto
Cryptocurrency wallets and exchanges.

```ruby
class Crypto < ApplicationRecord
  include Accountable
  
  validates :wallet_address, presence: true
  
  def display_name
    "#{crypto_type} Wallet"
  end
end
```

#### Property
Real estate investments and properties.

```ruby
class Property < ApplicationRecord
  include Accountable
  
  has_one :address, as: :addressable, dependent: :destroy
  
  def display_name
    address&.line1 || "Property"
  end
end
```

#### Vehicle
Vehicle assets such as cars, boats, etc.

```ruby
class Vehicle < ApplicationRecord
  include Accountable
  
  validates :make, :model, :year, presence: true
  
  def display_name
    "#{year} #{make} #{model}"
  end
end
```

#### Other Asset
Miscellaneous assets that don't fit other categories.

```ruby
class OtherAsset < ApplicationRecord
  include Accountable
  
  def display_name
    name.presence || "Other Asset"
  end
end
```

### Liability Accounts

#### Credit Card
Credit card debt and payment tracking.

```ruby
class CreditCard < ApplicationRecord
  include Accountable
  
  validates :institution_name, presence: true
  
  def display_name
    "#{institution_name} Credit Card"
  end
end
```

#### Loan
Personal loans, mortgages, and other debt.

```ruby
class Loan < ApplicationRecord
  include Accountable
  
  validates :institution_name, presence: true
  
  def display_name
    "#{institution_name} #{loan_type.humanize}"
  end
end
```

#### Other Liability
Miscellaneous liabilities that don't fit other categories.

```ruby
class OtherLiability < ApplicationRecord
  include Accountable
  
  def display_name
    name.presence || "Other Liability"
  end
end
```

## Financial Data Model

### Entry (Event Sourcing)
All financial changes are recorded as entries in an event-sourced architecture.

```ruby
class Entry < ApplicationRecord
  include Monetizable
  
  belongs_to :account
  belongs_to :entryable, polymorphic: true
  
  validates :date, :amount, :currency, presence: true
  
  scope :transactions, -> { where(entryable_type: "Transaction") }
  scope :valuations, -> { where(entryable_type: "Valuation") }
  scope :trades, -> { where(entryable_type: "Trade") }
end
```

**Entry Types:**
- **Transaction**: Income, expenses, and transfers
- **Valuation**: Account value snapshots
- **Trade**: Investment buy/sell transactions

### Transaction
Represents income, expenses, and transfers.

```ruby
class Transaction < ApplicationRecord
  include Entryable, Transferable, Ruleable
  
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  
  enum :kind, {
    standard: "standard",
    funds_movement: "funds_movement",
    cc_payment: "cc_payment",
    loan_payment: "loan_payment",
    one_time: "one_time"
  }
end
```

### Valuation
Represents account value snapshots at specific points in time.

```ruby
class Valuation < ApplicationRecord
  include Entryable
  
  validates :amount, presence: true
  
  def display_name
    "Valuation on #{date.strftime('%B %d, %Y')}"
  end
end
```

### Trade
Represents investment buy/sell transactions.

```ruby
class Trade < ApplicationRecord
  include Entryable
  
  belongs_to :security
  belongs_to :holding, optional: true
  
  validates :qty, :price, presence: true
  
  def display_name
    "#{action.humanize} #{qty} #{security.symbol}"
  end
end
```

### Balance
Daily balance snapshots for each account.

```ruby
class Balance < ApplicationRecord
  include Monetizable
  
  belongs_to :account
  
  validates :account, :date, :balance, presence: true
  validates :flows_factor, inclusion: { in: [-1, 1] }
  
  scope :in_period, ->(period) { period.nil? ? all : where(date: period.date_range) }
  scope :chronological, -> { order(:date) }
end
```

## Supporting Models

### Category
Transaction categorization system.

```ruby
class Category < ApplicationRecord
  belongs_to :family
  has_many :transactions, dependent: :nullify, class_name: "Transaction"
  has_many :budget_categories, dependent: :destroy
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :nullify
  belongs_to :parent, class_name: "Category", optional: true
  
  enum :classification, { income: "income", expense: "expense" }
end
```

### Tag
Flexible tagging system for transactions.

```ruby
class Tag < ApplicationRecord
  belongs_to :family
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :transactions, through: :taggings, source: :taggable, source_type: "Transaction"
end
```

### Merchant
Merchant information and management.

```ruby
class FamilyMerchant < ApplicationRecord
  belongs_to :family
  has_many :transactions, dependent: :nullify
  
  validates :name, presence: true, uniqueness: { scope: :family_id }
end
```

### Security
Investment securities and market data.

```ruby
class Security < ApplicationRecord
  has_many :holdings, dependent: :destroy
  has_many :trades, dependent: :destroy
  
  validates :symbol, :name, presence: true
  validates :symbol, uniqueness: true
end
```

### Holding
Investment holdings and positions.

```ruby
class Holding < ApplicationRecord
  include Monetizable
  
  belongs_to :account
  belongs_to :security
  
  validates :qty, :price, :date, presence: true
  
  scope :current, -> { where.not(qty: 0) }
end
```

## Data Relationships

### Family Hierarchy
```
Family (1) → (many) Users
Family (1) → (many) Accounts
Family (1) → (many) Categories
Family (1) → (many) Tags
Family (1) → (many) Merchants
Family (1) → (many) Budgets
```

### Account Relationships
```
Account (1) → (many) Entries
Account (1) → (many) Balances
Account (1) → (many) Holdings (Investment accounts)
Account (1) → (1) Accountable (Depository, Investment, etc.)
```

### Entry Relationships
```
Entry (1) → (1) Entryable (Transaction, Valuation, Trade)
Entry (1) → (1) Account
```

### Transaction Relationships
```
Transaction (1) → (1) Category (optional)
Transaction (1) → (1) Merchant (optional)
Transaction (1) → (many) Taggings
Transaction (1) → (many) Tags (through taggings)
```

## Business Rules and Constraints

### Account Rules
- Each account belongs to exactly one family
- Each account has exactly one accountable type
- Account balance must be in the account's currency
- Account status follows state machine rules

### Entry Rules
- All entries must have a date, amount, and currency
- Entry amounts are signed (negative for inflows, positive for outflows)
- Entries cannot be modified after creation (event sourcing)
- Entry dates cannot be in the future

### Transaction Rules
- Transactions must have a description
- Transaction amounts must be non-zero
- Transfer transactions must be matched with opposite transactions
- Transaction categories must belong to the same family

### Balance Rules
- Balances are calculated from entries
- Each account has one balance per date
- Balance calculations are idempotent
- Balances are stored in the account's currency

## Data Synchronization

### Sync System
The application uses a comprehensive sync system to keep data up-to-date:

```ruby
class Sync < ApplicationRecord
  belongs_to :syncable, polymorphic: true
  
  enum :status, {
    pending: "pending",
    running: "running",
    completed: "completed",
    failed: "failed"
  }
end
```

### Syncable Models
Models that can be synchronized:

- **Account**: Syncs balances, holdings, and transactions
- **PlaidItem**: Syncs bank account data
- **Family**: Orchestrates all family-level syncs

### Sync Process
1. **Data Fetching**: Retrieve data from external sources
2. **Data Processing**: Transform external data to internal format
3. **Data Storage**: Store processed data in database
4. **Balance Calculation**: Recalculate account balances
5. **Transfer Matching**: Match transfer transactions
6. **Notification**: Notify users of changes

## Multi-Currency Support

### Currency Normalization
All financial data is normalized to the family's base currency:

```ruby
class Family < ApplicationRecord
  def normalize_amount(amount, from_currency, to_currency = self.currency)
    return amount if from_currency == to_currency
    
    exchange_rate = ExchangeRate.find_or_fetch_rate(
      from: from_currency,
      to: to_currency,
      date: Date.current
    )
    
    amount * exchange_rate.rate
  end
end
```

### Exchange Rate Management
```ruby
class ExchangeRate < ApplicationRecord
  validates :from_currency, :to_currency, :date, :rate, presence: true
  validates :rate, numericality: { greater_than: 0 }
  
  scope :for_currencies, ->(from, to) { where(from_currency: from, to_currency: to) }
  scope :on_date, ->(date) { where(date: date) }
end
```

## Performance Considerations

### Database Indexing
Strategic indexing for performance:

```ruby
# Account indexes
add_index :accounts, [:family_id, :status]
add_index :accounts, [:accountable_type, :accountable_id]
add_index :accounts, :currency

# Entry indexes
add_index :entries, [:account_id, :date]
add_index :entries, [:entryable_type, :entryable_id]
add_index :entries, :currency

# Transaction indexes
add_index :transactions, [:category_id, :date]
add_index :transactions, [:merchant_id, :date]
add_index :transactions, :date
```

### Query Optimization
- Use `includes` to prevent N+1 queries
- Use `select` to limit returned columns
- Use `joins` for complex queries
- Use database views for complex aggregations

### Caching Strategy
- Cache expensive calculations
- Cache frequently accessed data
- Use Rails.cache for temporary data
- Use database materialized views for complex queries

This domain model provides a solid foundation for personal finance management while maintaining flexibility and extensibility for future enhancements.
