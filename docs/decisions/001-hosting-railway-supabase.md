# Decision Log: Hosting Strategy - Railway + Supabase

## Status
**ACCEPTED** - 2024-01-XX

## Context
We need to host the Maybe personal finance application for development, testing, and potentially production use. The application is a Ruby on Rails 7.2 app with PostgreSQL, Redis, and external integrations (OpenAI, Plaid, Stripe, Synth API).

### Current Application Requirements
- **Backend**: Ruby on Rails 7.2 with PostgreSQL
- **Background Jobs**: Sidekiq + Redis
- **External Services**: OpenAI, Plaid, Stripe, Synth API
- **Frontend**: Hotwire (Turbo + Stimulus) with TailwindCSS
- **Deployment**: Docker support with `compose.example.yml`
- **Modes**: Managed and self-hosted deployment options

### Constraints
- **Budget**: Prefer free/low-cost hosting options
- **Simplicity**: Easy setup and maintenance
- **Scalability**: Room to grow from development to production
- **Integration**: Need for social authentication and real-time features
- **Avoidance**: Explicitly avoiding Firebase

## Decision
We will use **Railway** for application hosting and **Supabase** for database, authentication, and real-time features.

## Options Considered

### 1. Railway + Supabase ✅ **SELECTED**

#### Pros
- **Railway Benefits**:
  - Excellent Rails support with automatic deployments
  - Built-in PostgreSQL and Redis support
  - $5/month free tier (500 hours) - generous for development
  - GitHub integration for automatic deployments
  - Easy environment variable management
  - Professional hosting with good performance
  - Built-in monitoring and logging

- **Supabase Benefits**:
  - PostgreSQL-native (perfect fit for Maybe)
  - Built-in authentication with social login providers
  - Real-time subscriptions for live financial data updates
  - Generous free tier (50MB database, 100MB storage, 2GB bandwidth)
  - Edge functions for webhooks and background processing
  - Storage for document uploads and account logos
  - Row Level Security (RLS) for multi-tenant data isolation
  - Excellent developer experience with TypeScript/JavaScript SDKs

#### Cons
- **Railway**:
  - Limited free tier hours (500/month)
  - Can get expensive with scaling
  - Newer platform (less mature than Heroku)

- **Supabase**:
  - Additional complexity for authentication migration
  - Learning curve for team unfamiliar with Supabase
  - Vendor lock-in for database and auth

#### Cost
- **Development**: $0/month (free tiers)
- **Production**: ~$10-15/month (Railway $5 + Supabase Pro $25, but can start with free tiers)

### 2. Render + Supabase

#### Pros
- Good Rails support
- Free tier with PostgreSQL
- Automatic SSL certificates
- GitHub integration

#### Cons
- Free tier spins down after inactivity (poor UX)
- Limited resources on free tier
- Less mature than Railway for Rails apps

#### Cost
- **Development**: $0/month (with spin-down issues)
- **Production**: ~$7-10/month

### 3. Fly.io + Supabase

#### Pros
- Excellent Docker support (Maybe has Dockerfile)
- Global edge deployment
- Generous free tier
- Great performance

#### Cons
- Requires Docker knowledge
- More complex setup than Railway
- Steeper learning curve

#### Cost
- **Development**: $0/month
- **Production**: ~$5-10/month

### 4. Self-Hosting + Supabase

#### Pros
- Complete control
- No hosting costs
- Can use existing infrastructure

#### Cons
- Requires server management
- Security and maintenance overhead
- Need to expose via ngrok/localtunnel (unreliable)
- No automatic deployments
- Single point of failure

#### Cost
- **Development**: $0/month (but time cost)
- **Production**: Server costs + maintenance time

### 5. Heroku + Supabase

#### Pros
- Mature Rails hosting platform
- Excellent add-ons ecosystem
- Well-documented

#### Cons
- No free tier anymore (minimum $5/month)
- Can get expensive quickly
- Dyno limitations

#### Cost
- **Development**: $5/month minimum
- **Production**: $25-50/month

## Rationale

### Why Railway?

1. **Rails-First Approach**: Railway is built with Rails developers in mind, offering seamless integration and automatic detection of Rails applications.

2. **Generous Free Tier**: 500 hours/month is sufficient for development and testing, allowing us to evaluate the platform without cost.

3. **Built-in Services**: Native support for PostgreSQL and Redis eliminates the need for external service configuration.

4. **Developer Experience**: 
   - GitHub integration for automatic deployments
   - Easy environment variable management
   - Built-in monitoring and logging
   - Simple scaling options

5. **Performance**: Good performance characteristics for Rails applications with proper resource allocation.

### Why Supabase?

1. **Perfect Technology Fit**: 
   - PostgreSQL-native (Maybe already uses PostgreSQL)
   - No database migration complexity
   - Familiar SQL interface

2. **Authentication System**:
   - Built-in social login providers (Google, GitHub, Apple, etc.)
   - JWT-based authentication
   - Multi-factor authentication support
   - User management dashboard

3. **Real-Time Features**:
   - WebSocket-based real-time subscriptions
   - Perfect for live financial data updates
   - Automatic reconnection and error handling

4. **Additional Features**:
   - Edge functions for webhooks and background processing
   - Storage for file uploads (account logos, documents)
   - Row Level Security for multi-tenant data isolation
   - Excellent TypeScript/JavaScript SDKs

5. **Cost-Effective**: Generous free tier allows development and small-scale production use.

### Why Not Other Options?

- **Firebase**: Explicitly avoided per requirements
- **Self-hosting**: Too much operational overhead for our needs
- **Heroku**: Too expensive and no free tier
- **Render**: Free tier limitations (spin-down) create poor user experience
- **Fly.io**: More complex setup, though excellent for Docker-based apps

## Implementation Plan

### Phase 1: Basic Deployment (Week 1)
1. **Railway Setup**:
   - Connect GitHub repository
   - Configure environment variables
   - Deploy Maybe application
   - Set up custom domain (optional)

2. **Supabase Setup**:
   - Create Supabase project
   - Migrate database schema
   - Configure basic authentication

### Phase 2: Integration (Week 2-3)
1. **Database Migration**:
   - Migrate existing schema to Supabase
   - Update database configuration
   - Test data integrity

2. **Authentication Integration**:
   - Implement Supabase auth in Rails
   - Add social login providers
   - Update user management

3. **Real-Time Features**:
   - Implement real-time subscriptions
   - Update frontend for live data
   - Test WebSocket connections

### Phase 3: Production Readiness (Week 4)
1. **Security Hardening**:
   - Configure Row Level Security
   - Set up proper CORS policies
   - Implement rate limiting

2. **Monitoring and Logging**:
   - Set up error tracking
   - Configure performance monitoring
   - Implement health checks

3. **Backup and Recovery**:
   - Configure database backups
   - Test disaster recovery procedures
   - Document operational procedures

## Migration Strategy

### Database Migration
```ruby
# 1. Export existing schema
rails db:schema:dump

# 2. Update database configuration
# config/database.yml
production:
  adapter: postgresql
  url: <%= ENV['SUPABASE_DATABASE_URL'] %>

# 3. Run migrations on Supabase
rails db:migrate RAILS_ENV=production
```

### Authentication Migration
```ruby
# 1. Add Supabase configuration
# config/initializers/supabase.rb
Rails.application.configure do
  config.supabase_url = ENV['SUPABASE_URL']
  config.supabase_anon_key = ENV['SUPABASE_ANON_KEY']
  config.supabase_service_key = ENV['SUPABASE_SERVICE_KEY']
end

# 2. Update User model
class User < ApplicationRecord
  def self.from_supabase_auth(supabase_user)
    find_or_create_by(supabase_id: supabase_user.id) do |user|
      user.email = supabase_user.email
      user.name = supabase_user.user_metadata['name']
    end
  end
end

# 3. Update authentication flow
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create_with_supabase
    auth_data = params[:auth]
    supabase_user = verify_supabase_token(auth_data[:access_token])
    
    @user = User.from_supabase_auth(supabase_user)
    session[:user_id] = @user.id
    redirect_to root_path
  end
end
```

## Success Criteria

### Technical Success
- [ ] Application deploys successfully on Railway
- [ ] Database migrates without data loss
- [ ] Authentication works with social providers
- [ ] Real-time features function correctly
- [ ] Performance meets requirements (< 2s page load)

### Business Success
- [ ] Development team can deploy changes easily
- [ ] Cost remains within budget
- [ ] System is reliable and available
- [ ] Easy to scale as user base grows

## Risks and Mitigation

### Risks
1. **Vendor Lock-in**: Heavy dependence on Railway and Supabase
   - **Mitigation**: Keep Docker configuration, maintain database exports

2. **Cost Escalation**: Costs could grow with usage
   - **Mitigation**: Monitor usage, implement cost alerts, plan for migration if needed

3. **Learning Curve**: Team needs to learn Supabase
   - **Mitigation**: Provide training, documentation, gradual migration

4. **Integration Complexity**: Supabase integration might be complex
   - **Mitigation**: Start with basic features, iterate gradually

### Contingency Plans
- **If Railway becomes too expensive**: Migrate to Fly.io or self-hosting
- **If Supabase has issues**: Fall back to PostgreSQL + custom auth
- **If performance is poor**: Optimize queries, add caching, consider CDN

## Monitoring and Review

### Key Metrics
- Application uptime and performance
- Database performance and usage
- Authentication success rates
- Real-time connection stability
- Cost tracking and optimization

### Review Schedule
- **Weekly**: Performance and cost review
- **Monthly**: Architecture and feature review
- **Quarterly**: Strategic hosting review

## Conclusion

The Railway + Supabase combination provides the best balance of:
- **Cost-effectiveness** (free/low-cost tiers)
- **Ease of use** (simple setup and management)
- **Feature completeness** (auth, real-time, storage)
- **Scalability** (room to grow)
- **Technology fit** (PostgreSQL-native, Rails-friendly)

This decision enables rapid development and deployment while providing a solid foundation for future growth and feature development.

---

**Decision Made By**: Development Team  
**Date**: 2024-01-XX  
**Next Review**: 2024-04-XX
