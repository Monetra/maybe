# Maybe Documentation

Welcome to the Maybe documentation. This comprehensive guide covers the architecture, patterns, and implementation details of the Maybe personal finance application.

## Table of Contents

### Architecture Overview
- [System Architecture](architecture/overview.md) - High-level system design and principles
- [Architectural Patterns](architecture/patterns.md) - Design patterns used throughout the codebase
- [Domain Models](architecture/domain-models.md) - Core domain entities and relationships
- [Web Integration](architecture/web-integration.md) - Hotwire/Turbo frontend integration
- [External Integrations](architecture/integrations.md) - AI, Plaid, Stripe, and Synth API integrations
- [Mobile Considerations](architecture/mobile-considerations.md) - Mobile app development requirements

### API Documentation
- [Chat API](api/chats.md) - AI chat functionality endpoints

### Deployment
- [Docker Deployment](hosting/docker.md) - Self-hosting with Docker Compose

## Quick Start

### For Developers
1. Read the [System Architecture](architecture/overview.md) to understand the overall design
2. Review [Architectural Patterns](architecture/patterns.md) to understand coding patterns
3. Study [Domain Models](architecture/domain-models.md) to understand the data model
4. Check [Web Integration](architecture/web-integration.md) for frontend development

### For Mobile Developers
1. Start with [Mobile Considerations](architecture/mobile-considerations.md)
2. Review [External Integrations](architecture/integrations.md) for API capabilities
3. Check [Chat API](api/chats.md) for AI integration

### For DevOps/Deployment
1. Read [Docker Deployment](hosting/docker.md) for self-hosting
2. Review [System Architecture](architecture/overview.md) for infrastructure needs

## Architecture Highlights

### Core Principles
- **Minimize Dependencies**: Prefer vanilla Rails over external gems
- **Fat Models, Skinny Controllers**: Business logic in models and concerns
- **Server-Side Rendering**: Hotwire for SPA-like experience
- **Event-Driven Design**: Background jobs for async processing
- **Provider Pattern**: Abstract external services

### Technology Stack
- **Backend**: Ruby on Rails 7.2, PostgreSQL, Redis, Sidekiq
- **Frontend**: Hotwire (Turbo + Stimulus), TailwindCSS, ViewComponent
- **External Services**: OpenAI, Plaid, Stripe, Synth API
- **Deployment**: Docker, self-hosted or managed

### Key Features
- **Multi-Currency Support**: Automatic currency conversion and normalization
- **AI Integration**: Chat functionality and auto-categorization
- **Bank Integration**: Real-time account syncing via Plaid
- **Investment Tracking**: Holdings, securities, and market data
- **Event Sourcing**: Complete audit trail of all financial changes
- **Real-Time Updates**: Live data updates via Turbo Streams

## Development Guidelines

### Code Organization
- Models contain business logic and domain rules
- Controllers are thin and delegate to models
- Concerns organize related functionality
- ViewComponents provide reusable UI elements
- Stimulus controllers handle client-side interactivity

### Testing Strategy
- Comprehensive test coverage using Minitest
- Fixtures for test data (avoid FactoryBot)
- VCR for external API testing
- System tests for critical user flows

### Performance Considerations
- Strategic database indexing
- Query optimization to prevent N+1 queries
- Background job processing for heavy operations
- Caching for expensive calculations

## Contributing

When contributing to Maybe:

1. **Read the Architecture**: Understand the system design and patterns
2. **Follow Conventions**: Use established patterns and conventions
3. **Write Tests**: Ensure comprehensive test coverage
4. **Document Changes**: Update relevant documentation
5. **Consider Performance**: Optimize for performance and scalability

## Support

For questions or issues:

1. Check the relevant documentation section
2. Review the codebase for examples
3. Ask questions in the project discussions
4. Create issues for bugs or feature requests

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

*This documentation is maintained alongside the codebase and should be updated when making significant changes to the architecture or functionality.*
