# Cortex - Initial Development Prompt

## Project Context
You are helping develop **Cortex**, a Second Brain macOS application for personal knowledge management with deep Apple ecosystem integration.

## Project State
- ✅ Xcode 26 project initialized
- ✅ GitHub repository connected (private)
- ✅ CloudKit configured
- ✅ Claude Code with MCP servers ready
- ✅ Custom Skills installed
- 🚧 Ready for initial feature development

## Technical Foundation
- **Platform:** macOS 26 (Tahoe) only
- **Architecture:** MVVM with SwiftUI
- **Storage:** CloudKit private database
- **AI Integration:** Claude (WebView), ChatGPT (Siri)
- **System Integration:** Siri Intents, App Intents

## Current Task: Foundation Implementation

### Phase 1 Objectives
1. **Project Structure Setup**
   - Create proper folder structure (Core/, Features/, Resources/)
   - Set up MVVM skeleton
   - Configure CloudKit container

2. **Core Models**
   - KnowledgeEntry (title, content, tags, timestamps)
   - CloudKit record conformance
   - Basic CRUD operations

3. **First Feature: Knowledge Management**
   - List view of knowledge entries
   - Add new entry form
   - Basic search functionality
   - CloudKit sync

4. **Service Layer**
   - CloudKitService (generic CRUD)
   - KnowledgeService (domain-specific)
   - Proper error handling

### Implementation Guidelines

**Follow these rules strictly:**
1. Read CLAUDE.md before starting any feature
2. Apply Swift-SwiftUI-Standards skill for all code
3. Use Cortex-Architecture skill for structure decisions
4. Document with Cortex-Documentation skill
5. All CloudKit operations must be async/actor-based
6. Use @Observable for ViewModels (macOS 26)
7. Keep views small and focused
8. Write unit tests for ViewModels and Services

### CloudKit Configuration
Before coding, ensure:
- iCloud capability enabled in Xcode
- CloudKit container created/selected
- Development environment active
- Signing configured

### First Code To Generate

**Start with Core CloudKit Service:**
```swift
// Core/Services/CloudKitService.swift
actor CloudKitService {
    // Generic CRUD for CloudKit records
    // Proper error handling
    // Query support
}
```

**Then Knowledge Domain:**
```swift
// Core/Models/KnowledgeEntry.swift
struct KnowledgeEntry: CloudKitRecord, Identifiable {
    // CloudKit-backed knowledge entry
}

// Features/Knowledge/Services/KnowledgeService.swift
actor KnowledgeService {
    // Domain-specific operations
}

// Features/Knowledge/ViewModels/KnowledgeListViewModel.swift
@Observable
final class KnowledgeListViewModel {
    // List management, search, CRUD
}

// Features/Knowledge/Views/KnowledgeListView.swift
struct KnowledgeListView: View {
    // Main list interface
}
```

### Testing Strategy
For each service/viewmodel:
- Create mock version
- Write unit tests
- Test CloudKit sync scenarios
- Verify error handling

### Expected File Structure After Phase 1
```
Cortex/
├── App/
│   ├── CortexApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Models/
│   │   └── KnowledgeEntry.swift
│   ├── Services/
│   │   ├── CloudKitService.swift
│   │   └── CloudKitRecord.swift
│   └── Utilities/
│       └── CortexError.swift
├── Features/
│   └── Knowledge/
│       ├── Views/
│       │   ├── KnowledgeListView.swift
│       │   ├── KnowledgeDetailView.swift
│       │   └── AddKnowledgeView.swift
│       ├── ViewModels/
│       │   ├── KnowledgeListViewModel.swift
│       │   └── KnowledgeDetailViewModel.swift
│       └── Services/
│           └── KnowledgeService.swift
└── Tests/
    └── CortexTests/
        ├── Services/
        └── ViewModels/
```

## Next Steps After This Prompt

1. **Build Foundation**
   - Set up folder structure
   - Create CloudKitService
   - Implement KnowledgeEntry model
   
2. **First Feature**
   - Knowledge list view
   - Add/edit functionality
   - CloudKit integration
   
3. **Test & Verify**
   - Unit tests pass
   - App builds and runs
   - CloudKit sync works
   
4. **Commit & Push**
   - Commit initial implementation
   - Push to GitHub
   - Update CLAUDE.md if needed

## How To Use This Prompt

**In Claude Code terminal:**
```bash
cd /path/to/cortex
claude code

# Then paste or reference this prompt
# Claude will use all configured skills and MCP servers
```

## Available MCP Tools

You have access to:
- **XcodeBuildMCP:** Build, test, run simulator
- **GitHub (via gh CLI):** Repo operations
- **Filesystem:** Read/write project files
- **Memory:** Session persistence
- **Sequential Thinking:** Complex problem solving

## Available Skills

You have access to:
- **Swift-SwiftUI-Standards:** Code quality enforcement
- **Cortex-Documentation:** Consistent docs
- **Cortex-Architecture:** Pattern enforcement

## Success Criteria

Phase 1 is complete when:
- [ ] Clean folder structure exists
- [ ] CloudKit integration works
- [ ] Can create/read/update/delete knowledge entries
- [ ] List view shows synced entries
- [ ] Unit tests cover core logic
- [ ] Code follows all standards
- [ ] App builds without errors
- [ ] Changes committed to GitHub

## Ready To Start!

You now have everything needed to begin development. Start with the CloudKit foundation and build up from there. Use the skills to maintain quality and consistency.

**Remember:** Read CLAUDE.md before each feature, apply skills automatically, and keep the architecture clean!
