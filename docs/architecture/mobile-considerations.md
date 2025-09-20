# Mobile Consumer Considerations

## Overview

This document outlines the considerations and requirements for building a mobile consumer application that integrates with the Maybe backend. The current Rails application provides a solid foundation with existing API endpoints, but several enhancements would be needed for optimal mobile experience.

## Current Mobile-Ready Features

### Existing API Endpoints
The application already provides RESTful APIs:

```ruby
# Authentication
POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/refresh

# Core Resources
GET /api/v1/accounts
GET /api/v1/transactions
POST /api/v1/transactions
PUT /api/v1/transactions/:id
DELETE /api/v1/transactions/:id

# AI Chat
GET /api/v1/chats
POST /api/v1/chats
POST /api/v1/chats/:id/messages
```

### PWA Support
The application already includes Progressive Web App features:

```erb
<!-- Service Worker -->
<%= javascript_include_tag "service-worker", type: "module" %>

<!-- Manifest -->
<%= link_to "manifest", pwa_manifest_path, rel: "manifest" %>
```

### Responsive Design
Mobile-first responsive design with TailwindCSS:

```erb
<!-- Mobile Navigation -->
<nav class="lg:hidden flex justify-between items-center p-3">
  <%= icon("panel-left", as_button: true, data: { action: "app-layout#openMobileSidebar"}) %>
  <%= link_to root_path do %>
    <%= image_tag "logomark-color.svg", class: "w-9 h-9" %>
  <% end %>
</nav>
```

## Required Mobile Enhancements

### 1. Enhanced API Endpoints

#### Pagination and Filtering
```ruby
# Enhanced transaction endpoint
GET /api/v1/transactions?page=1&per_page=20&filter[category]=food&sort=date_desc

# Response format
{
  "transactions": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total_count": 150,
    "total_pages": 8
  },
  "filters": {
    "categories": [...],
    "merchants": [...],
    "date_range": {...}
  }
}
```

#### Bulk Operations
```ruby
# Bulk transaction operations
POST /api/v1/transactions/bulk_update
{
  "transaction_ids": ["uuid1", "uuid2"],
  "updates": {
    "category_id": "uuid",
    "tags": ["tag1", "tag2"]
  }
}

DELETE /api/v1/transactions/bulk_delete
{
  "transaction_ids": ["uuid1", "uuid2"]
}
```

#### Search and Analytics
```ruby
# Search transactions
GET /api/v1/transactions/search?q=coffee&category=food

# Analytics endpoints
GET /api/v1/analytics/spending_summary?period=month
GET /api/v1/analytics/balance_trends?account_id=uuid&days=30
GET /api/v1/analytics/category_breakdown?period=month
```

### 2. Real-Time Features

#### WebSocket Integration
```ruby
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: maybe_production
```

#### Real-Time Updates
```ruby
# app/channels/transactions_channel.rb
class TransactionsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "transactions_#{current_family.id}"
  end
  
  def unsubscribed
    # Cleanup
  end
end
```

#### Turbo Streams for Mobile
```ruby
# Broadcast updates to mobile clients
class Transaction < ApplicationRecord
  after_create_commit :broadcast_to_mobile
  
  private
  
  def broadcast_to_mobile
    broadcast_append_to "transactions_#{family.id}",
      partial: "api/v1/transactions/transaction",
      locals: { transaction: self }
  end
end
```

### 3. Offline Data Management

#### Data Synchronization
```ruby
# Sync endpoint for offline data
POST /api/v1/sync
{
  "last_sync_at": "2024-01-01T00:00:00Z",
  "changes": {
    "transactions": [
      {
        "id": "uuid",
        "action": "create",
        "data": {...}
      }
    ]
  }
}

# Response
{
  "sync_token": "new_token",
  "conflicts": [...],
  "updates": {
    "transactions": [...],
    "accounts": [...]
  }
}
```

#### Conflict Resolution
```ruby
# Conflict resolution endpoint
POST /api/v1/sync/resolve_conflict
{
  "conflict_id": "uuid",
  "resolution": "server_wins" | "client_wins" | "merge"
}
```

### 4. Push Notifications

#### Notification Service
```ruby
# app/services/push_notification_service.rb
class PushNotificationService
  def send_transaction_alert(user, transaction)
    # Send push notification for new transaction
  end
  
  def send_balance_alert(user, account)
    # Send push notification for balance changes
  end
  
  def send_budget_alert(user, budget)
    # Send push notification for budget alerts
  end
end
```

#### Device Registration
```ruby
# Device registration endpoint
POST /api/v1/devices
{
  "device_token": "fcm_token",
  "platform": "ios" | "android",
  "app_version": "1.0.0"
}
```

### 5. Mobile-Specific Endpoints

#### Quick Actions
```ruby
# Quick transaction creation
POST /api/v1/transactions/quick
{
  "amount": 10.50,
  "merchant": "Starbucks",
  "category": "food"
}

# Recent transactions
GET /api/v1/transactions/recent?limit=10

# Favorite merchants
GET /api/v1/merchants/favorites
POST /api/v1/merchants/:id/favorite
DELETE /api/v1/merchants/:id/favorite
```

#### Dashboard Data
```ruby
# Mobile dashboard
GET /api/v1/dashboard
{
  "total_balance": 5000.00,
  "monthly_spending": 1200.00,
  "recent_transactions": [...],
  "upcoming_bills": [...],
  "budget_status": {...}
}
```

### 6. Enhanced Authentication

#### Biometric Authentication
```ruby
# Biometric authentication endpoint
POST /api/v1/auth/biometric
{
  "biometric_token": "encrypted_biometric_data",
  "device_id": "uuid"
}
```

#### Session Management
```ruby
# Enhanced session management
GET /api/v1/sessions
DELETE /api/v1/sessions/:id

# Multi-device support
POST /api/v1/sessions/trust_device
{
  "device_name": "iPhone 15 Pro",
  "trust_duration": "30_days"
}
```

## Mobile App Architecture Recommendations

### 1. Native Mobile App Structure

#### React Native / Flutter
- **Cross-platform**: Single codebase for iOS and Android
- **Performance**: Near-native performance
- **Ecosystem**: Rich library ecosystem

#### Native iOS / Android
- **Performance**: Maximum performance and platform integration
- **Platform Features**: Full access to platform-specific features
- **Maintenance**: Separate codebases for each platform

### 2. State Management

#### Redux / MobX (React Native)
```javascript
// Transaction store
const transactionStore = {
  transactions: [],
  loading: false,
  error: null,
  lastSyncAt: null
}
```

#### Provider Pattern (Flutter)
```dart
class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _loading = false;
  
  List<Transaction> get transactions => _transactions;
  bool get loading => _loading;
}
```

### 3. Data Synchronization Strategy

#### Offline-First Architecture
```javascript
// Offline data management
class OfflineManager {
  async syncData() {
    const lastSync = await this.getLastSyncTime();
    const localChanges = await this.getLocalChanges();
    
    const response = await api.post('/sync', {
      last_sync_at: lastSync,
      changes: localChanges
    });
    
    await this.applyServerChanges(response.updates);
    await this.resolveConflicts(response.conflicts);
  }
}
```

#### Conflict Resolution
```javascript
// Conflict resolution strategy
class ConflictResolver {
  resolveConflict(conflict) {
    switch (conflict.type) {
      case 'transaction_update':
        return this.resolveTransactionConflict(conflict);
      case 'account_update':
        return this.resolveAccountConflict(conflict);
      default:
        return 'server_wins';
    }
  }
}
```

### 4. Real-Time Updates

#### WebSocket Connection
```javascript
// WebSocket connection management
class WebSocketManager {
  connect() {
    this.socket = new WebSocket('wss://api.maybe.com/cable');
    this.socket.onmessage = this.handleMessage.bind(this);
  }
  
  handleMessage(event) {
    const data = JSON.parse(event.data);
    this.dispatchUpdate(data);
  }
}
```

#### Background Sync
```javascript
// Background sync for mobile
class BackgroundSync {
  async syncInBackground() {
    if (navigator.serviceWorker) {
      await navigator.serviceWorker.ready;
      await navigator.serviceWorker.sync.register('transaction-sync');
    }
  }
}
```

## Performance Considerations

### 1. API Optimization

#### Response Compression
```ruby
# Enable gzip compression
config.middleware.use Rack::Deflater
```

#### Caching Strategy
```ruby
# Redis caching for mobile API
class Api::V1::TransactionsController < Api::V1::BaseController
  def index
    @transactions = Rails.cache.fetch("transactions_#{Current.family.cache_key}", expires_in: 5.minutes) do
      Current.family.transactions.includes(:category, :merchant).to_a
    end
  end
end
```

#### Pagination Optimization
```ruby
# Cursor-based pagination for large datasets
class Api::V1::TransactionsController < Api::V1::BaseController
  def index
    @transactions = Current.family.transactions
      .where('id > ?', params[:cursor])
      .limit(params[:limit] || 20)
      .order(:id)
  end
end
```

### 2. Mobile-Specific Optimizations

#### Image Optimization
```ruby
# Optimized image delivery
class Api::V1::AccountsController < Api::V1::BaseController
  def logo
    account = Current.family.accounts.find(params[:id])
    
    if account.logo.attached?
      redirect_to account.logo.variant(
        resize_to_limit: [200, 200],
        format: :webp
      ).processed.url
    else
      head :not_found
    end
  end
end
```

#### Data Minimization
```ruby
# Minimal response format for mobile
class Api::V1::TransactionSerializer
  def self.minimal(transaction)
    {
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      category: transaction.category&.name
    }
  end
end
```

## Security Considerations

### 1. Mobile-Specific Security

#### Certificate Pinning
```javascript
// Certificate pinning for API calls
const apiClient = axios.create({
  baseURL: 'https://api.maybe.com',
  httpsAgent: new https.Agent({
    checkServerIdentity: (host, cert) => {
      // Verify certificate pin
      return undefined;
    }
  })
});
```

#### Biometric Authentication
```javascript
// Biometric authentication
import TouchID from 'react-native-touch-id';

const authenticateWithBiometrics = async () => {
  try {
    const result = await TouchID.authenticate('Authenticate to access Maybe');
    return result;
  } catch (error) {
    throw new Error('Biometric authentication failed');
  }
};
```

#### Data Encryption
```javascript
// Encrypt sensitive data locally
import CryptoJS from 'crypto-js';

const encryptData = (data, key) => {
  return CryptoJS.AES.encrypt(JSON.stringify(data), key).toString();
};

const decryptData = (encryptedData, key) => {
  const bytes = CryptoJS.AES.decrypt(encryptedData, key);
  return JSON.parse(bytes.toString(CryptoJS.enc.Utf8));
};
```

### 2. API Security

#### Rate Limiting
```ruby
# Mobile-specific rate limiting
Rack::Attack.throttle('api/mobile', limit: 1000, period: 1.hour) do |req|
  req.ip if req.path.start_with?('/api/v1/') && req.headers['User-Agent'].include?('MaybeMobile')
end
```

#### Token Refresh
```ruby
# Automatic token refresh
class Api::V1::BaseController < ApplicationController
  before_action :ensure_valid_token
  
  private
  
  def ensure_valid_token
    if token_expired? && can_refresh_token?
      refresh_access_token
    end
  end
end
```

## Testing Strategy

### 1. API Testing

#### Mobile API Tests
```ruby
# test/controllers/api/v1/mobile_test.rb
class Api::V1::MobileTest < ActionDispatch::IntegrationTest
  test "mobile dashboard returns correct data" do
    get "/api/v1/dashboard", headers: mobile_headers
    
    assert_response :success
    assert_includes response.body, "total_balance"
    assert_includes response.body, "recent_transactions"
  end
end
```

#### Performance Testing
```ruby
# test/performance/mobile_api_test.rb
class MobileApiPerformanceTest < ActionDispatch::IntegrationTest
  test "transactions endpoint responds within 200ms" do
    start_time = Time.current
    
    get "/api/v1/transactions", headers: mobile_headers
    
    assert_response :success
    assert (Time.current - start_time) < 0.2.seconds
  end
end
```

### 2. Mobile App Testing

#### Unit Tests
```javascript
// Transaction store tests
describe('TransactionStore', () => {
  it('should add new transaction', () => {
    const store = new TransactionStore();
    const transaction = { id: '1', amount: 10.50 };
    
    store.addTransaction(transaction);
    
    expect(store.transactions).toContain(transaction);
  });
});
```

#### Integration Tests
```javascript
// API integration tests
describe('API Integration', () => {
  it('should sync transactions with server', async () => {
    const offlineManager = new OfflineManager();
    const mockResponse = { transactions: [...] };
    
    api.post.mockResolvedValue(mockResponse);
    
    await offlineManager.syncData();
    
    expect(api.post).toHaveBeenCalledWith('/sync', expect.any(Object));
  });
});
```

## Deployment Considerations

### 1. Mobile App Distribution

#### App Store Deployment
- **iOS**: Apple App Store
- **Android**: Google Play Store
- **Beta Testing**: TestFlight (iOS), Internal Testing (Android)

#### Over-the-Air Updates
```javascript
// CodePush for React Native
import CodePush from 'react-native-code-push';

const App = () => {
  useEffect(() => {
    CodePush.sync({
      updateDialog: true,
      installMode: CodePush.InstallMode.IMMEDIATE
    });
  }, []);
};
```

### 2. Backend Scaling

#### Load Balancing
```yaml
# Docker Compose for mobile scaling
version: '3.8'
services:
  api:
    image: maybe-api:latest
    replicas: 3
    environment:
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgresql://postgres:password@db:5432/maybe
```

#### CDN Configuration
```ruby
# CDN for static assets
config.asset_host = 'https://cdn.maybe.com'
config.force_ssl = true
```

## Monitoring and Analytics

### 1. Mobile Analytics

#### User Behavior Tracking
```javascript
// Mobile analytics
import Analytics from 'react-native-analytics';

const trackTransactionCreated = (transaction) => {
  Analytics.track('Transaction Created', {
    amount: transaction.amount,
    category: transaction.category,
    platform: 'mobile'
  });
};
```

#### Performance Monitoring
```javascript
// Performance monitoring
import { Performance } from 'react-native-performance';

const measureApiCall = async (apiCall) => {
  const start = Performance.now();
  const result = await apiCall();
  const end = Performance.now();
  
  Analytics.track('API Performance', {
    duration: end - start,
    endpoint: apiCall.name
  });
  
  return result;
};
```

### 2. Backend Monitoring

#### Mobile-Specific Metrics
```ruby
# Mobile API metrics
class Api::V1::BaseController < ApplicationController
  after_action :track_mobile_usage
  
  private
  
  def track_mobile_usage
    if mobile_client?
      StatsD.increment('api.mobile.requests', tags: {
        endpoint: action_name,
        platform: request.headers['X-Platform']
      })
    end
  end
end
```

#### Error Tracking
```ruby
# Mobile error tracking
class Api::V1::BaseController < ApplicationController
  rescue_from StandardError, with: :handle_mobile_error
  
  private
  
  def handle_mobile_error(error)
    Sentry.capture_exception(error, tags: {
      platform: 'mobile',
      version: request.headers['X-App-Version']
    })
    
    render json: { error: 'Internal server error' }, status: 500
  end
end
```

## Conclusion

Building a mobile consumer app for Maybe would require:

1. **Enhanced API endpoints** for mobile-specific functionality
2. **Real-time features** using WebSockets and Turbo Streams
3. **Offline data management** with conflict resolution
4. **Push notifications** for important financial events
5. **Mobile-optimized authentication** with biometric support
6. **Performance optimizations** for mobile networks
7. **Comprehensive testing** strategy for mobile apps
8. **Monitoring and analytics** for mobile usage

The existing Rails application provides a solid foundation with its API-first design, but these enhancements would be necessary for a production-ready mobile experience.
