# Maybe Architecture Overview

## System Architecture

Maybe is a personal finance application built with Ruby on Rails that provides comprehensive financial data management, AI-powered insights, and multi-currency support. The application follows a modern Rails architecture with a focus on simplicity, maintainability, and performance.

### Core Architecture Principles

1. **Minimize Dependencies**: Prefer vanilla Rails over external gems when possible
2. **Fat Models, Skinny Controllers**: Business logic lives in models and concerns
3. **Server-Side Rendering**: Leverage Hotwire for SPA-like experience without heavy JavaScript
4. **Event-Driven Design**: Use background jobs for async processing
5. **Provider Pattern**: Abstract external services behind consistent interfaces

## Application Modes

The application supports two distinct deployment modes:

### Managed Mode
- Maybe team operates and manages servers
- Full feature set including AI, Plaid, and Stripe integrations
- Multi-tenant architecture
- Automatic updates and maintenance

### Self-Hosted Mode
- Users host on their own infrastructure (typically Docker)
- Optional external integrations (AI, Plaid, Stripe)
- Single-tenant architecture
- User-controlled updates

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 7.2
- **Database**: PostgreSQL with UUID primary keys
- **Background Jobs**: Sidekiq + Redis
- **Asset Pipeline**: Propshaft
- **Authentication**: Session-based + OAuth2 (Doorkeeper)

### Frontend
- **Hotwire Stack**: Turbo + Stimulus for reactive UI
- **Styling**: TailwindCSS v4.x with custom design system
- **Icons**: Lucide Icons
- **Charts**: D3.js for financial visualizations
- **Components**: ViewComponent for reusable UI elements

### External Services
- **AI**: OpenAI (GPT-4, GPT-3.5-turbo)
- **Bank Data**: Plaid (US/EU regions)
- **Payments**: Stripe
- **Market Data**: Synth API (custom)
- **Monitoring**: Sentry, Skylight, Logtail

## Domain Model Architecture

### Core Entities

The application is built around financial data management with these key relationships:

```
Family (1) → (many) Users
Family (1) → (many) Accounts
Account (1) → (many) Entries
Entry (1) → (1) Entryable (Transaction/Valuation/Trade)
```

### Financial Data Hierarchy

1. **Family**: Top-level container for all financial data
   - Manages currency preferences and normalization
   - Contains users, accounts, and financial settings
   - Handles subscription and billing

2. **Account**: Central financial entity
   - Represents a single financial account (checking, credit card, investment, etc.)
   - Uses delegated types for different account types
   - Tracks balance, currency, and status

3. **Entry**: Event-sourced financial transactions
   - All financial changes go through entries
   - Supports different entry types (Transaction, Valuation, Trade)
   - Maintains audit trail and historical data

4. **Balance**: Daily balance snapshots
   - Calculated from entries for each account
   - Enables historical analysis and trend calculations
   - Supports multi-currency normalization

### Account Types (Delegated Types)

**Asset Accounts:**
- `Depository`: Bank accounts (checking, savings)
- `Investment`: Brokerage accounts with holdings
- `Crypto`: Cryptocurrency wallets
- `Property`: Real estate investments
- `Vehicle`: Vehicle assets
- `OtherAsset`: Miscellaneous assets

**Liability Accounts:**
- `CreditCard`: Credit card debt
- `Loan`: Personal loans, mortgages
- `OtherLiability`: Miscellaneous debts

## Data Flow Architecture

### 1. Data Ingestion
- **Plaid Integration**: Real-time bank account syncing
- **CSV Import**: Manual data import with field mapping
- **Manual Entry**: Direct user input

### 2. Data Processing
- **Sync System**: Background processing of financial data
- **Balance Calculation**: Daily balance snapshots
- **Transfer Matching**: Automatic detection of account transfers
- **AI Enhancement**: Auto-categorization and merchant detection

### 3. Data Presentation
- **Real-time Updates**: Turbo streams for live data
- **Historical Analysis**: Time-series data for charts
- **Multi-currency**: Automatic currency conversion
- **Caching**: Strategic caching for performance

## Integration Architecture

### Provider Pattern

External services are abstracted behind a consistent provider interface:

```ruby
# Concept-based providers (exchangeable)
Provider::Registry.for_concept(:exchange_rates)
Provider::Registry.for_concept(:securities)

# Direct providers (service-specific)
Provider::Registry.get_provider(:stripe)
Provider::Registry.get_provider(:plaid)
```

### AI Integration

- **Chat System**: Real-time AI conversations with financial context
- **Auto-categorization**: Intelligent transaction categorization
- **Merchant Detection**: Automatic merchant identification
- **Function Calling**: AI can execute financial queries

### Bank Integration (Plaid)

- **Account Linking**: Secure bank account connection
- **Transaction Sync**: Real-time transaction updates
- **Investment Data**: Holdings and trade synchronization
- **Webhook Processing**: Event-driven updates

### Payment Integration (Stripe)

- **Subscription Management**: Recurring billing
- **Checkout Sessions**: Payment processing
- **Billing Portal**: Customer self-service
- **Webhook Handling**: Payment event processing

## Security Architecture

### Authentication
- **Web Users**: Session-based authentication
- **API Users**: OAuth2 + API key authentication
- **Multi-factor**: TOTP support for enhanced security

### Authorization
- **Family-based**: All data scoped to family
- **Role-based**: Admin vs member permissions
- **API Scopes**: Granular API access control

### Data Protection
- **Encryption**: Sensitive data encrypted at rest
- **CSRF Protection**: Built-in Rails protection
- **Rate Limiting**: API rate limiting with Rack::Attack
- **Audit Trail**: Comprehensive logging and monitoring

## Performance Architecture

### Caching Strategy
- **Query Caching**: ActiveRecord query caching
- **Fragment Caching**: View fragment caching
- **Redis Caching**: Background job caching
- **CDN**: Static asset delivery

### Background Processing
- **Sidekiq**: Reliable background job processing
- **Job Scheduling**: Cron-based scheduled tasks
- **Error Handling**: Comprehensive error recovery
- **Monitoring**: Job performance tracking

### Database Optimization
- **Indexing**: Strategic database indexing
- **Query Optimization**: N+1 query prevention
- **Connection Pooling**: Efficient database connections
- **Read Replicas**: Read scaling (when needed)

## Scalability Considerations

### Horizontal Scaling
- **Stateless Design**: No server-side session storage
- **Database Scaling**: Read replicas and connection pooling
- **Background Jobs**: Distributed job processing
- **CDN**: Global content delivery

### Vertical Scaling
- **Memory Optimization**: Efficient object allocation
- **CPU Optimization**: Background job processing
- **I/O Optimization**: Database query optimization
- **Caching**: Strategic data caching

## Monitoring and Observability

### Application Monitoring
- **Error Tracking**: Sentry for exception monitoring
- **Performance**: Skylight for application performance
- **Logging**: Structured logging with Logtail
- **Health Checks**: Built-in health endpoints

### Business Metrics
- **Usage Analytics**: User behavior tracking
- **Financial Metrics**: Account and transaction analytics
- **API Usage**: External API consumption tracking
- **System Health**: Infrastructure monitoring

## Development Workflow

### Code Organization
- **Conventions**: Consistent coding patterns
- **Testing**: Comprehensive test coverage
- **Code Review**: Peer review process
- **Documentation**: Living documentation

### Deployment
- **Docker**: Containerized deployment
- **CI/CD**: Automated testing and deployment
- **Environment Management**: Development, staging, production
- **Rollback Strategy**: Safe deployment rollbacks

## Future Considerations

### Mobile App Support
- **API-First Design**: RESTful API for mobile clients
- **Real-time Updates**: WebSocket support for live data
- **Offline Support**: Data synchronization capabilities
- **Push Notifications**: Mobile notification system

### Microservices Migration
- **Service Boundaries**: Clear service separation
- **API Gateway**: Centralized API management
- **Event Sourcing**: Event-driven architecture
- **Data Consistency**: Distributed data management
