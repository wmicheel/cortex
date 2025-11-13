# CORTEX - Second Brain MacOS Application

## Project Overview
Cortex is a personal Second Brain application deeply integrated into the Apple ecosystem. It serves as a unified dashboard combining knowledge management, AI assistant integration (Claude & ChatGPT), and Siri automation capabilities.

**Vision:** A local-first, privacy-focused knowledge hub that seamlessly connects with AI services while maintaining complete data sovereignty.

## Tech Stack
- **Platform:** macOS 26 (Tahoe) exclusive
- **Language:** Swift 6.0
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Storage:** CloudKit (private database)
- **AI Integration:** 
  - Claude (web-based, no API)
  - ChatGPT Business (via Siri integration)
- **System Integration:** Siri Intents, App Intents

## Project Structure
```
Cortex/
├── App/
│   ├── CortexApp.swift           # App entry point
│   └── AppDelegate.swift         # System integration
├── Core/
│   ├── Models/                   # Data models
│   ├── ViewModels/               # MVVM ViewModels
│   └── Services/                 # Business logic
├── Features/
│   ├── Dashboard/                # Main dashboard
│   ├── Knowledge/                # Knowledge management
│   ├── AIIntegration/            # Claude/ChatGPT integration
│   └── Siri/                     # Siri Intents
├── Resources/
│   ├── Assets.xcassets
│   └── Localizations/
└── Tests/
    ├── CortexTests/
    └── CortexUITests/
```

## Architecture Principles

### MVVM Pattern
- **Views:** SwiftUI views (purely presentational)
- **ViewModels:** Business logic, state management, @Observable
- **Models:** Data structures, CloudKit records
- **Services:** API clients, data persistence, AI integration

### Data Flow
1. View observes ViewModel
2. ViewModel coordinates Services
3. Services handle CloudKit, AI APIs, system integration
4. Changes flow back through @Published properties

### CloudKit Strategy
- **Private Database:** User's personal knowledge base
- **Record Types:**
  - Note (title, content, tags, created, modified)
  - AIConversation (service, messages, context)
  - SiriIntent (command, parameters, result)
- **Sync:** Automatic background sync
- **Offline:** Local caching with NSPersistentCloudKitContainer

## Development Guidelines

### Swift Conventions
- Swift 6 strict concurrency enabled
- Use async/await for asynchronous operations
- Actor isolation for thread safety
- Structured concurrency (Task groups, async let)

### SwiftUI Best Practices
- Small, focused views (<300 lines)
- Extract reusable components
- Use @Observable for ViewModels (macOS 26+)
- Prefer @State for view-local state
- Environment for dependency injection

### Code Style
- Clear, descriptive names (no abbreviations unless standard)
- Document complex logic with comments
- Use // MARK: for code organization
- Group related functionality
- SwiftLint compliance (to be configured)

### Testing Strategy
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- CloudKit mock services for testing
- Test coverage goal: >80%

## AI Integration Patterns

### Claude Integration
- Embed WKWebView for claude.ai
- JavaScript bridge for interaction
- Clipboard integration for context passing
- Session persistence

### ChatGPT Integration
- Leverage Siri/App Intents
- System-level integration
- Voice command routing

## Siri Integration

### App Intents
- AddKnowledgeIntent
- SearchKnowledgeIntent
- AskAIIntent (routes to Claude/ChatGPT)
- OpenDashboardIntent

### Phrases Examples
- "Hey Siri, add to Cortex"
- "Hey Siri, search my brain for"
- "Hey Siri, ask Claude about"

## Security & Privacy

### Data Protection
- CloudKit private database only
- No third-party analytics
- Local-first architecture
- Encrypted storage for sensitive data
- Keychain for credentials

### API Keys & Secrets
- Store in Keychain Services
- Never commit to version control
- Environment-specific configuration

## Build & Run

### Requirements
- Xcode 26+
- macOS 26 (Tahoe)
- Apple Developer Account (for CloudKit)
- GitHub CLI (for development)

### Build Schemes
- **Cortex (Development):** Debug configuration, local testing
- **Cortex (Release):** Optimized, App Store ready

### CloudKit Configuration
- Development environment: Default during dev
- Production environment: For release builds

## Dependencies (Swift Package Manager)

### Current
- None (pure SwiftUI/CloudKit initially)

### Planned
- To be determined based on features

## Known Gotchas

### CloudKit
- Requires valid Apple Developer account
- Container must be properly configured in Signing & Capabilities
- Development vs Production environments are separate

### macOS 26 Specific
- Some APIs only available on Tahoe
- Test backwards compatibility if supporting older macOS versions later

### WKWebView for Claude
- Need proper entitlements for web content
- JavaScript bridge requires careful security handling
- Session management for persistence

## External References

### Apple Documentation
- [CloudKit](https://developer.apple.com/documentation/cloudkit)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)

### Design Inspiration
- Keep UI clean and minimal
- Follow macOS Human Interface Guidelines
- Native macOS look and feel

## Development Phases

### Phase 1: Foundation (Current)
- [ ] Project setup
- [ ] Basic SwiftUI structure
- [ ] CloudKit integration
- [ ] MVVM architecture skeleton

### Phase 2: Core Features
- [ ] Knowledge management (CRUD)
- [ ] Dashboard UI
- [ ] Search functionality
- [ ] Tagging system

### Phase 3: AI Integration
- [ ] Claude WebView integration
- [ ] ChatGPT Siri integration
- [ ] Context passing between services
- [ ] Conversation history

### Phase 4: Siri & Automation
- [ ] App Intents implementation
- [ ] Siri phrase training
- [ ] Shortcuts support
- [ ] Quick actions

### Phase 5: Polish
- [ ] Performance optimization
- [ ] UI/UX refinement
- [ ] Testing & bug fixes
- [ ] Documentation

## Notes for Claude Code

When working on this project:
1. Always maintain MVVM separation
2. Use CloudKit best practices for data modeling
3. Consider offline-first approach
4. Prioritize privacy and security
5. Keep Apple ecosystem integration native
6. Document complex AI integration patterns
7. Test Siri intents thoroughly
8. Maintain this CLAUDE.md file when architecture changes

## Quick Start Commands
```bash
# Build project
claude mcp XcodeBuildMCP build_sim_name_proj

# Run tests
claude mcp XcodeBuildMCP test_sim_name_proj

# Open in Xcode
open Cortex.xcodeproj

# Git operations
git status
git add .
git commit -m "message"
git push
```
