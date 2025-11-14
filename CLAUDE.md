# CORTEX - Second Brain MacOS Application

## Project Overview
Cortex is a personal Second Brain application deeply integrated into the Apple ecosystem. It serves as a unified dashboard combining knowledge management, AI assistant integration (Claude & ChatGPT), and Siri automation capabilities.

**Vision:** A local-first, privacy-focused knowledge hub that seamlessly connects with AI services while maintaining complete data sovereignty.

## Tech Stack
- **Platform:** macOS 26 (Tahoe) exclusive
- **Language:** Swift 6.0
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Storage:** SwiftData (local persistence, CloudKit-ready for future migration)
- **AI Integration:**
  - Claude (web-based, no API)
  - ChatGPT Business (via Siri integration)
  - Context7 (semantic search, direct API)
- **System Integration:** Siri Intents, App Intents

## Project Structure
```
Cortex/
├── App/
│   ├── CortexApp.swift           # App entry point
│   ├── ContentView.swift         # Main navigation & migration
│   └── AppDelegate.swift         # System integration
├── Core/
│   ├── Models/                   # Data models
│   │   ├── KnowledgeEntry.swift  # @Model class (SwiftData)
│   │   └── Context7Models.swift
│   ├── Services/                 # Business logic
│   │   ├── Context7Service.swift
│   │   └── KeychainManager.swift
│   └── Utilities/
│       └── CortexError.swift
├── Features/
│   ├── BlockEditor/              # 🆕 Notion-like block editor
│   │   ├── Models/
│   │   │   ├── BlockType.swift
│   │   │   ├── ContentBlock.swift       # @Model for blocks
│   │   │   └── BlockFormatting.swift
│   │   ├── Views/
│   │   │   ├── BlockEditorView.swift    # Main editor
│   │   │   └── Components/
│   │   │       ├── SlashMenuView.swift  # "/" menu for block types
│   │   │       ├── FormattingToolbar.swift
│   │   │       └── MigrationProgressView.swift
│   │   ├── ViewModels/
│   │   │   └── BlockEditorViewModel.swift
│   │   └── Services/
│   │       ├── MarkdownParser.swift     # Markdown ↔ Blocks
│   │       └── BlockMigrationService.swift
│   ├── Dashboard/                # Main dashboard
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   ├── Knowledge/                # Knowledge management
│   │   ├── Views/
│   │   │   ├── KnowledgeListView.swift
│   │   │   ├── KnowledgeDetailView.swift  # Supports block editor
│   │   │   ├── AddKnowledgeView.swift     # Toggle block/markdown
│   │   │   └── Components/
│   │   ├── ViewModels/
│   │   │   ├── KnowledgeListViewModel.swift
│   │   │   └── KnowledgeDetailViewModel.swift
│   │   └── Services/
│   │       ├── KnowledgeServiceProtocol.swift
│   │       ├── SwiftDataKnowledgeService.swift
│   │       └── MockKnowledgeService.swift
│   ├── AIIntegration/            # Claude/ChatGPT integration
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   ├── Siri/                     # Siri Intents
│   │   ├── Intents/
│   │   └── Shortcuts/
│   └── Settings/                 # App settings
│       ├── Views/
│       └── ViewModels/
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
- **Models:** Data structures, SwiftData @Model classes
- **Services:** API clients, data persistence, AI integration

### Data Flow
1. View observes ViewModel
2. ViewModel coordinates Services
3. Services handle SwiftData, Context7, AI APIs, system integration
4. Changes flow back through @Published or @Observable properties

### SwiftData Strategy (Current)
- **Local Persistence:** All data stored locally on Mac
- **No iCloud Required:** Works without Apple Developer Program
- **ModelContainer:** Single container for all KnowledgeEntry objects
- **ModelContext:** Main actor-isolated context for all operations
- **In-Memory Cache:** Additional caching layer in service for performance
- **CloudKit-Ready:** Protocol architecture allows seamless migration

### Future CloudKit Migration
- **Private Database:** User's personal knowledge base (when ready)
- **Record Types:**
  - `KnowledgeEntry` (id, title, content, tags, created, modified)
  - `AIConversation` (id, service, messages, context, timestamp)
  - `UserPreferences` (settings, configurations)
- **Sync:** Automatic background sync
- **Offline:** Local caching with proper conflict resolution
- **Schema:** Define custom record types in CloudKit Dashboard

## Development Guidelines

### Swift Conventions
- Swift 6 strict concurrency enabled
- Use async/await for asynchronous operations
- Actor isolation for thread safety
- Structured concurrency (Task groups, async let)
- Explicit `@MainActor` for UI code

### SwiftUI Best Practices
- Small, focused views (<300 lines)
- Extract reusable components into separate files
- Use @Observable for ViewModels (macOS 26+)
- Prefer @State for view-local state
- @Environment for dependency injection
- @Binding for two-way data flow

### Code Style
- Clear, descriptive names (no abbreviations unless standard)
- Document complex logic with comments
- Use `// MARK:` for code organization sections
- Group related functionality together
- SwiftLint compliance (to be configured later)
- Prefer composition over inheritance

### Testing Strategy
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- Mock services for testing (MockKnowledgeService)
- Test coverage goal: >80% for business logic
- Use Swift Testing framework (new in Swift 6)

## SwiftData Integration (Current Implementation)

### KnowledgeEntry Model
SwiftData @Model class with CloudKit compatibility:

```swift
@Model
final class KnowledgeEntry {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var tags: [String]
    var createdAt: Date
    var modifiedAt: Date
    var linkedReminderID: String?
    var linkedCalendarEventID: String?

    init(id: String = UUID().uuidString, title: String, content: String, ...) {
        // Initialize properties
    }
}

// CloudKit conformance preserved for future migration
extension KnowledgeEntry: CloudKitRecord {
    static let recordType = "KnowledgeEntry"
    func toCKRecord() -> CKRecord { /* ... */ }
    convenience init?(from record: CKRecord) { /* ... */ }
}
```

### SwiftDataKnowledgeService
Main actor-isolated service for local persistence:

```swift
@MainActor
final class SwiftDataKnowledgeService: KnowledgeServiceProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let tagExtractor: TagExtractionService
    private var cache: [String: KnowledgeEntry] = [:]

    init() throws {
        let schema = Schema([KnowledgeEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        self.modelContext = ModelContext(modelContainer)
        self.tagExtractor = TagExtractionService()
    }

    // CRUD operations using SwiftData
    func create(title: String, content: String, tags: [String], autoTag: Bool) async throws -> KnowledgeEntry
    func fetch(id: String) async throws -> KnowledgeEntry
    func fetchAll(forceRefresh: Bool) async throws -> [KnowledgeEntry]
    func update(_ entry: KnowledgeEntry) async throws -> KnowledgeEntry
    func delete(_ entry: KnowledgeEntry) async throws
    // ... more methods
}
```

### KnowledgeServiceProtocol
Protocol-based architecture for easy service swapping:

```swift
protocol KnowledgeServiceProtocol {
    func create(title: String, content: String, tags: [String], autoTag: Bool) async throws -> KnowledgeEntry
    func fetch(id: String) async throws -> KnowledgeEntry
    func fetchAll(forceRefresh: Bool) async throws -> [KnowledgeEntry]
    // ... all CRUD operations
}
```

**Implementations:**
- `SwiftDataKnowledgeService` - Current (local storage)
- `KnowledgeService` - CloudKit (ready for future)
- `MockKnowledgeService` - Testing

## CloudKit Integration (Future Migration)

### CloudKitRecord Protocol
Models can conform to this for CloudKit compatibility:

```swift
protocol CloudKitRecord {
    static var recordType: String { get }
    var id: String { get }

    func toCKRecord() -> CKRecord
    init?(from record: CKRecord)
}
```

### CloudKitService Pattern
```swift
actor CloudKitService {
    private let container: CKContainer
    private let database: CKDatabase
    
    // Generic CRUD operations
    func save<T: CloudKitRecord>(_ record: T) async throws -> T
    func fetch<T: CloudKitRecord>(ofType type: T.Type, predicate: NSPredicate) async throws -> [T]
    func delete<T: CloudKitRecord>(_ record: T) async throws
    func fetchByIDs<T: CloudKitRecord>(_ ids: [UUID]) async throws -> [T]
}
```

### Error Handling
```swift
enum CortexError: LocalizedError {
    case cloudKitError(Error)
    case networkError
    case invalidData
    case context7Error(String)
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        case .networkError:
            return "Network connection failed"
        case .invalidData:
            return "Invalid data received"
        case .context7Error(let message):
            return "Context7 error: \(message)"
        case .keychainError:
            return "Keychain access failed"
        }
    }
}
```

## Context7 Integration

### Overview
Context7 provides semantic search and RAG capabilities. Implemented as direct Swift service (no MCP server).

### Architecture
- **Direct API Integration:** URLSession-based REST API calls
- **API Key Storage:** Secure storage in macOS Keychain
- **Indexing Strategy:** Background, non-blocking indexing after CloudKit saves
- **Search:** Semantic search via Context7 REST API
- **Fallback:** Graceful degradation to CloudKit text search if Context7 unavailable

### Context7Service Implementation

```swift
actor Context7Service {
    private let apiKey: String
    private let baseURL = "https://api.context7.com/v1"
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func index(id: String, content: String, metadata: [String: String]) async throws
    func search(query: String, limit: Int) async throws -> [Context7SearchResult]
    func delete(id: String) async throws
    func update(id: String, content: String, metadata: [String: String]) async throws
}
```

### Integration with KnowledgeService

```swift
actor KnowledgeService {
    private let cloudKit: CloudKitService
    private let context7: Context7Service?
    
    func save(_ entry: KnowledgeEntry) async throws -> KnowledgeEntry {
        // 1. Save to CloudKit (primary)
        let saved = try await cloudKit.save(entry)
        
        // 2. Index in Context7 (background, non-blocking)
        Task {
            try? await context7?.index(
                id: saved.id.uuidString,
                content: "\(saved.title)\n\n\(saved.content)",
                metadata: [
                    "title": saved.title,
                    "tags": saved.tags.joined(separator: ","),
                    "created": saved.createdAt.ISO8601Format()
                ]
            )
        }
        
        return saved
    }
    
    func semanticSearch(query: String) async throws -> [KnowledgeEntry] {
        guard let context7 = context7 else {
            // Fallback to CloudKit text search
            return try await cloudKit.search(query: query)
        }
        
        let results = try await context7.search(query: query, limit: 20)
        let ids = results.compactMap { UUID(uuidString: $0.id) }
        return try await cloudKit.fetchByIDs(ids)
    }
}
```

### API Key Management

```swift
actor KeychainManager {
    static let shared = KeychainManager()
    
    func save(key: String, value: String) throws
    func get(key: String) throws -> String?
    func delete(key: String) throws
}
```

**First-Time Setup:**
- Prompt user for Context7 API key on first launch
- Store securely in Keychain
- Allow updating in Settings
- Never commit API keys to git

### Context7 Models

```swift
struct Context7SearchResult: Codable {
    let id: String
    let score: Double
    let metadata: [String: String]
}

struct Context7IndexRequest: Codable {
    let id: String
    let content: String
    let metadata: [String: String]
}

struct Context7SearchRequest: Codable {
    let query: String
    let limit: Int
    let threshold: Double?
}
```

## AI Integration Patterns

### Claude Web Integration

```swift
@MainActor
class ClaudeWebService: NSObject, ObservableObject, WKNavigationDelegate {
    private var webView: WKWebView?
    @Published var isLoaded = false
    
    func initialize() {
        let config = WKWebViewConfiguration()
        // Configure JavaScript bridge for interaction
        let contentController = WKUserContentController()
        config.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self
        webView?.load(URLRequest(url: URL(string: "https://claude.ai")!))
    }
    
    // JavaScript bridge methods for interaction
    func sendContext(_ context: String) async throws
    func getResponse() async throws -> String
}
```

### ChatGPT Siri Integration

```swift
actor ChatGPTIntentService {
    func executeQuery(_ query: String) async throws -> String {
        // Use SiriKit/App Intents to route to ChatGPT
        // Leverage system-level ChatGPT integration
    }
}
```

## Siri Integration

### App Intents

```swift
struct AddKnowledgeIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Cortex"
    static var description = IntentDescription("Add a new knowledge entry to Cortex")
    
    @Parameter(title: "Title")
    var title: String
    
    @Parameter(title: "Content")
    var content: String
    
    @Parameter(title: "Tags", default: [])
    var tags: [String]
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let service = KnowledgeService.shared
        let entry = KnowledgeEntry(
            id: UUID(),
            title: title,
            content: content,
            tags: tags,
            createdAt: Date(),
            modifiedAt: Date()
        )
        _ = try await service.save(entry)
        return .result(dialog: "Added '\(title)' to your knowledge base")
    }
}
```

### Supported Siri Phrases

- "Hey Siri, add to Cortex"
- "Hey Siri, search my Cortex for [query]"
- "Hey Siri, ask Claude about [topic]"
- "Hey Siri, open my Cortex dashboard"

### App Shortcuts Configuration

```swift
// App/CortexApp.swift
@main
struct CortexApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Cortex Help") {
                    // Open help
                }
            }
        }
        .defaultSize(width: 1200, height: 800)
    }
    
    init() {
        // Register App Shortcuts
        AppShortcuts.provider = CortexShortcutsProvider()
    }
}
```

## Security & Privacy

### Data Protection
- SwiftData local storage (all data stays on device)
- No third-party analytics or tracking
- Local-first architecture (fully offline-capable)
- macOS system-level encryption for data at rest
- Keychain for API keys and credentials
- Future: CloudKit private database option (no shared/public databases)

### API Keys & Secrets
- Store in Keychain Services (never in UserDefaults)
- Never commit to version control
- Use .env for development (already in .gitignore)
- Environment-specific configuration

### Privacy Considerations
- User controls all data (100% local storage)
- No data leaves device except to user-configured services (Context7, AI)
- Clear privacy policy in Settings
- Option to disable Context7 semantic search
- Option to disable AI integrations
- No Apple Developer account or iCloud required

## Build & Run

### Requirements
- Xcode 26+
- macOS 26 (Tahoe)
- GitHub CLI (for development workflow)
- Claude Code CLI (for AI-assisted development)
- Optional: Apple Developer Account (for future CloudKit migration)

### Build Schemes
- **Cortex (Development):** Debug configuration, local SwiftData storage
- **Cortex (Release):** Optimized build, local SwiftData storage

### Current Setup (SwiftData)
1. Open Xcode Project: `cortex.xcodeproj`
2. Select scheme: `cortex`
3. Build and run: `Cmd+R`
4. Data stored in: `~/Library/Application Support/cortex/`

### Future CloudKit Configuration (When Ready)
1. Open Xcode Project
2. Select Cortex target → Signing & Capabilities
3. Enable iCloud capability
4. Check CloudKit
5. Select/create container: `iCloud.wieland.cortex`
6. Update `KnowledgeListViewModel` to use `KnowledgeService` instead of `SwiftDataKnowledgeService`

### Environment Setup

**Development (.env file - DO NOT COMMIT):**
```bash
CONTEXT7_API_KEY=sk-ctx7-your-key-here
DEBUG_MODE=true
```

**Keychain (Production):**
- Context7 API key stored in Keychain
- Retrieved at runtime via KeychainManager

## Block Editor - Notion-Like Editing

### Overview
The block editor provides a Notion-like editing experience with full Notion parity. All knowledge entries can be created in either Markdown or Block mode.

### Features Implemented ✅

**Block Types:**
- Text (Paragraph)
- Heading 1, 2, 3, 4, 5, 6
- Bulleted List
- Numbered List
- Checkbox List (with completion state)
- Code Block (with language selection)
- Quote
- Divider
- Callout (with customizable icon)

**Slash Menu (/):**
- Type `/` to open block type menu
- Search by name, description, or keywords
- Keyboard navigation (↑↓ arrows, Enter)
- Visual selection indicator
- Smooth animations and transitions

**Markdown Auto-Formatting:**
- `# ` → Heading 1
- `## ` → Heading 2
- `### ` → Heading 3
- `- ` or `* ` → Bulleted List
- `1. ` → Numbered List
- `> ` → Quote
- ` ``` ` → Code Block
- `[ ] ` → Checkbox (unchecked)
- `[x] ` → Checkbox (checked)
- `---` or `***` → Divider

**Keyboard Shortcuts:**
- `Cmd+B` → Bold
- `Cmd+I` → Italic
- `Cmd+E` → Inline Code
- `Cmd+K` → Link
- `Cmd+Shift+X` → Strikethrough

**Drag & Drop:**
- Click and drag block icon to reorder
- Smooth animations during drag
- Auto-save new order
- Undo/Redo support

**Block Operations:**
- Convert block type via menu
- Indent/Outdent (up to 6 levels)
- Delete blocks
- Add blocks with Enter key
- Focus management

**UI/UX Polish:**
- Smooth spring animations for all interactions
- Hover effects on blocks and controls
- Focus indicators with accent color
- Visual feedback for all actions
- Modern, rounded design language
- Proper spacing and typography

### Architecture

**Models:**
- `ContentBlock` (@Model) - SwiftData model for blocks
- `BlockType` (enum) - All available block types
- `BlockFormatting` - Inline formatting state

**Services:**
- `MarkdownParser` - Bidirectional Markdown ↔ Blocks conversion
- `BlockMigrationService` - Automatic migration of old Markdown entries

**ViewModels:**
- `BlockEditorViewModel` - Manages blocks, focus, undo/redo

**Views:**
- `BlockEditorView` - Main editor container
- `SlashMenuView` - Slash menu for block selection
- `FormattingToolbar` - Inline formatting controls

### Migration Strategy

**Automatic Migration:**
- Runs on first app launch
- Converts legacy Markdown entries to blocks
- Non-destructive (preserves original content)
- Shows progress UI for bulk operations

**Toggle Support:**
- Users can toggle between Markdown and Block mode
- Seamless conversion in both directions
- Content preserved during conversion

### Usage

**Creating Block-Based Entry:**
1. Click "+" to create new entry
2. Toggle to "Blocks" mode
3. Enter title
4. Click "Save"
5. Edit entry to add blocks

**Editing with Blocks:**
1. Select entry in Knowledge list
2. Click "Edit"
3. Toggle to "Blocks" if not already
4. Use slash menu `/` or Markdown shortcuts
5. Drag blocks to reorder
6. Click "Save" when done

**Converting Markdown to Blocks:**
1. Open Markdown entry
2. Click "Edit"
3. Toggle to "Block-Editor"
4. Content is automatically converted
5. Edit as needed

## Dependencies (Swift Package Manager)

### Current
- None (pure SwiftUI/SwiftData/Foundation)

### Planned
- To be determined based on feature needs
- Prefer Apple frameworks over third-party when possible

## Known Gotchas

### SwiftData
- @Model classes cannot conform to Sendable (use @unchecked Sendable if needed)
- Models must be classes, not structs
- ModelContext is MainActor-isolated
- Identifiable conformance is automatic with @Model
- Changes are auto-saved when context changes

### Future CloudKit Migration
- Will require valid Apple Developer account
- Container must be properly configured in Signing & Capabilities
- Development vs Production environments are completely separate
- Record type changes require schema updates in CloudKit Dashboard
- First launch requires network for CloudKit initialization

### macOS 26 Specific
- Some APIs only available on Tahoe
- @Observable requires macOS 26+ (use @ObservableObject for older versions if needed)
- App Intents enhancements in macOS 26

### WKWebView for Claude
- Need proper entitlements for web content
- JavaScript bridge requires careful security handling
- Session management for persistence
- Cookie/localStorage may need special handling

### Context7
- API rate limits apply
- Indexing is asynchronous and non-blocking
- Search requires network (falls back to local if unavailable)
- API key must be valid and active

## External References

### Apple Documentation
- [CloudKit](https://developer.apple.com/documentation/cloudkit)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

### Third-Party Services
- [Context7 Documentation](https://context7.com/docs)

### Design Inspiration
- Keep UI clean and minimal
- Follow macOS Human Interface Guidelines
- Native macOS look and feel (no custom chrome)
- Keyboard-first navigation where possible

## Development Phases

### Phase 1: Foundation ✅ (COMPLETED)
- [x] Project setup
- [x] GitHub integration
- [x] Claude Code configuration with MCP servers
- [x] CLAUDE.md documentation
- [x] Skills creation
- [x] Basic SwiftUI structure
- [x] MVVM architecture skeleton
- [x] **SwiftData integration** (local persistence)
- [x] KnowledgeEntry @Model class
- [x] SwiftDataKnowledgeService with CRUD operations
- [x] KnowledgeServiceProtocol for service abstraction
- [x] CloudKitRecord protocol (ready for future migration)
- [x] KeychainManager for secure API key storage
- [x] KnowledgeListViewModel with @Observable
- [x] Knowledge management UI (List, Detail, Add)
- [x] Auto-tagging with TagExtractionService
- [x] Reminders integration (EventKit)
- [x] Calendar integration (EventKit)
- [x] Voice input for entries
- [x] Unit tests for models
- [x] App builds and runs successfully

### Phase 2: Block Editor ✅ (COMPLETED)
- [x] **Notion-like block editor implementation**
- [x] ContentBlock @Model with SwiftData
- [x] BlockEditorView with full editing capabilities
- [x] BlockEditorViewModel with undo/redo
- [x] Block types: Text, Headings, Lists, Code, Quote, Divider, Callout
- [x] **Slash Menu (/)** for block type selection
- [x] **Markdown auto-formatting** (# → H1, - → List, etc.)
- [x] **Keyboard shortcuts** (Cmd+B, Cmd+I, Cmd+E, Cmd+K)
- [x] **Drag & Drop** block reordering
- [x] Indent/Outdent support (6 levels)
- [x] MarkdownParser for bidirectional conversion
- [x] BlockMigrationService for automatic migration
- [x] Toggle between Markdown and Block mode
- [x] **UI/UX Polish:**
  - [x] Smooth spring animations
  - [x] Hover effects on all interactive elements
  - [x] Focus indicators with accent colors
  - [x] Modern rounded design language
  - [x] Proper spacing and typography
  - [x] Visual feedback for all actions

### Phase 3: Core Features (Current - In Progress)
- [x] SwiftData persistence working
- [x] Knowledge CRUD operations
- [x] Search functionality (local text search)
- [x] Tagging system with auto-extraction
- [x] Apple Reminders integration
- [x] Apple Calendar integration
- [ ] Dashboard UI skeleton
- [ ] Add data export/import
- [ ] Implement proper error alerts in UI

### Phase 3: Context7 Integration
- [ ] Context7Service implementation
- [ ] API key setup flow
- [ ] Background indexing integration
- [ ] Semantic search UI
- [ ] Fallback to local search
- [ ] Settings for Context7 configuration

### Phase 4: AI Integration
- [ ] Claude WebView integration
- [ ] JavaScript bridge for Claude interaction
- [ ] ChatGPT Siri integration
- [ ] Context passing between services
- [ ] Conversation history
- [ ] AI service selection

### Phase 5: Siri & Automation
- [ ] App Intents implementation
- [ ] Siri phrase training
- [ ] Shortcuts support
- [ ] Quick actions from menu bar
- [ ] System-wide keyboard shortcuts

### Phase 6: Polish & Release
- [ ] Performance optimization
- [ ] UI/UX refinement
- [ ] Comprehensive testing
- [ ] Bug fixes
- [ ] User documentation
- [ ] App Store preparation

## Notes for Claude Code

When working on this project, always:

1. **Read this file first** before implementing any feature
2. **Maintain MVVM separation** strictly - Views don't talk to Services directly
3. **Use CloudKit best practices** for data modeling and sync
4. **Consider offline-first** approach in all features
5. **Prioritize privacy and security** in every decision
6. **Keep Apple ecosystem integration native** - no web views unless necessary
7. **Document complex patterns** especially AI integration
8. **Test Siri intents thoroughly** - they're user-facing
9. **Update this CLAUDE.md** when architecture changes
10. **Apply Swift-SwiftUI-Standards skill** for all code
11. **Apply Cortex-Architecture skill** for structural decisions
12. **Apply Cortex-Documentation skill** for consistent docs

### Code Quality Checklist
Before considering any feature complete:
- [ ] MVVM separation maintained
- [ ] Proper error handling implemented
- [ ] Unit tests written for business logic
- [ ] @MainActor applied to UI code and main-thread services
- [ ] SwiftData operations are async/await
- [ ] Code documented with comments
- [ ] No force unwrapping (!)
- [ ] SwiftLint compliant (when configured)
- [ ] Protocol-based architecture maintained for service abstraction

## MCP Servers Available

### XcodeBuildMCP
- Build, test, run simulators
- Project discovery
- Scheme management
- Clean operations

Commands:
```bash
# Build for simulator
mcp__xcodebuildmcp__build_sim_name_proj

# Run tests
mcp__xcodebuildmcp__test_sim_name_proj

# List simulators
mcp__xcodebuildmcp__list_sims
```

### Filesystem
- Read/write project files
- Directory operations
- File search

### Memory
- Session persistence
- Cross-conversation context

### Sequential Thinking
- Complex problem solving
- Multi-step reasoning

### GitHub (via gh CLI)
```bash
# Create PR
gh pr create --title "..." --body "..."

# List issues
gh issue list

# Push changes
git push origin main
```

## Quick Start Commands

```bash
# Build project
claude mcp invoke XcodeBuildMCP build_sim_name_proj

# Run tests
claude mcp invoke XcodeBuildMCP test_sim_name_proj

# Open in Xcode
open Cortex.xcodeproj

# Git operations
git status
git add .
git commit -m "message"
git push

# Claude Code
claude code

# MCP Status
claude mcp list
```

## Troubleshooting

### SwiftData Issues
- Data not persisting: Check `~/Library/Application Support/cortex/`
- Model schema changes: Delete app data and rebuild
- @Model macro errors: Ensure class (not struct), no Sendable conformance
- MainActor isolation errors: Ensure services are @MainActor

### Build Failures
- Clean build folder: `Cmd+Shift+K`
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Verify all dependencies are resolved
- Check Swift 6 concurrency compliance

### Future CloudKit Issues
- Verify Apple Developer account is active
- Check Signing & Capabilities in Xcode
- Ensure network connectivity
- Check CloudKit Dashboard for record types

### Context7 Issues
- Check API key is valid in Keychain
- Verify network connectivity
- Check Context7 service status
- Review error logs for specifics

### Git Issues
- Ensure GitHub CLI is authenticated: `gh auth status`
- Check remote configuration: `git remote -v`
- Verify no merge conflicts

## Success Metrics

### Phase 1 Complete When: ✅ DONE
- [x] Project structure created
- [x] GitHub connected
- [x] Claude Code configured
- [x] SwiftData integration working
- [x] Can CRUD knowledge entries
- [x] Unit tests written (models)
- [x] App builds without errors
- [x] App launches and displays UI
- [x] Reminders & Calendar integration working
- [x] Voice input working
- [x] Auto-tagging working

### MVP Complete When:
- Knowledge management fully functional
- SwiftData persistence stable
- Context7 semantic search operational
- Basic UI polished
- No critical bugs
- Ready for personal daily use
- Optional: CloudKit sync as upgrade path

### v1.0 Complete When:
- All features implemented
- Siri integration working
- AI services integrated
- Comprehensive testing done
- Documentation complete
- Ready for wider distribution

---

**Last Updated:** 2025-11-14
**Project Status:** Phase 1 COMPLETED ✅ | Phase 2 In Progress
**Storage:** SwiftData (local) - CloudKit migration ready when needed
**Next Milestone:** UI Polish & Context7 Integration