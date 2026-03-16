---
name: dx-env-switcher
description: Build the Environment Switcher tool for DX Tools. Manage env configs per project — save profiles, swap .env files with one click, track which is active. Uses FileManager only, no external deps. Follow dx-tools-feature skill for architecture.
---

# Environment Switcher

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `envSwitcher`
- **Category**: `.devops`
- **Display name**: "Env Switcher"
- **Icon**: `"arrow.triangle.swap"`
- **Description**: "Manage env configs per project — save profiles, swap with one click"

## Service: `EnvSwitcherService.swift`

### Models

```swift
struct Project: Identifiable, Codable {
    var id: UUID
    var name: String
    var path: String               // Project directory path
    var envFileName: String        // Usually ".env"
    var profiles: [EnvProfile]
    var activeProfileId: UUID?
    var lastSwitched: Date?
}

struct EnvProfile: Identifiable, Codable {
    var id: UUID
    var name: String               // "Development", "Staging", "Production"
    var color: String              // Hex color for visual identification
    var content: String            // The full .env file content
    var createdAt: Date
    var lastUsed: Date?
    var variables: Int             // Count of variables
}
```

### Storage

Store project configs in `~/Library/Application Support/DX Tools/env-profiles.json`.

```swift
static func saveProjects(_ projects: [Project])
static func loadProjects() -> [Project]
```

### Core Methods

```swift
// Project management
static func addProject(name: String, path: String, envFileName: String) -> Project
static func removeProject(_ id: UUID)
static func detectEnvFile(in directory: String) -> String?  // Finds .env, .env.local, etc.

// Profile management
static func createProfile(name: String, color: String, content: String) -> EnvProfile
static func importFromFile(_ path: String) -> EnvProfile?
static func importCurrentEnv(from projectPath: String, envFile: String) -> EnvProfile?

// Switching
static func switchProfile(project: Project, profile: EnvProfile) -> Result<Void, String>
// 1. Backup current .env as .env.backup
// 2. Write profile content to .env
// 3. Update activeProfileId

static func readCurrentEnv(project: Project) -> String?
static func diffProfiles(_ a: EnvProfile, _ b: EnvProfile) -> [(key: String, inA: String?, inB: String?)]

// Validation
static func parseEnvContent(_ content: String) -> [(key: String, value: String)]
static func findConflicts(_ profiles: [EnvProfile]) -> [String]  // Keys that differ between profiles
```

## ViewModel: `EnvSwitcherViewModel.swift`

```swift
@Observable
class EnvSwitcherViewModel {
    var projects: [EnvSwitcherService.Project] = []
    var selectedProject: EnvSwitcherService.Project?
    var selectedProfile: EnvSwitcherService.EnvProfile?
    var showAddProject: Bool = false
    var showAddProfile: Bool = false
    var newProjectName: String = ""
    var newProjectPath: String = ""
    var newProfileName: String = ""
    var newProfileColor: String = "#4ADE80"
    var profileContent: String = ""
    var error: String?
    var lastAction: String?

    func loadProjects() { }
    func addProject() { }
    func removeProject(_ id: UUID) { }
    func browseForProject() { /* NSOpenPanel for directory */ }
    func addProfile() { }
    func importCurrentAsProfile() { }
    func switchTo(_ profile: EnvSwitcherService.EnvProfile) { }
    func deleteProfile(_ id: UUID) { }
    func editProfile(_ profile: EnvSwitcherService.EnvProfile) { }
}
```

## View: `EnvSwitcherView.swift`

### Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ToolHeader: "Env Switcher"  [+ Add Project] [Browse]        │
├──────────────┬──────────────────────────────────────────────┤
│ PROJECTS     │  my-api  ·  Active: 🟢 Development           │
│              │                                              │
│ 🟢 my-api    │  ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│ ⚪ website   │  │ 🟢 Dev    │ │ 🟡 Stage  │ │ 🔴 Prod   │     │
│ ⚪ worker    │  │ ACTIVE   │ │ Switch → │ │ Switch → │     │
│              │  │ 12 vars  │ │ 14 vars  │ │ 14 vars  │     │
│              │  └──────────┘ └──────────┘ └──────────┘     │
│              │                                              │
│              │  [+ New Profile] [Import Current .env]       │
│              │                                              │
│              │  PREVIEW: .env                               │
│              │  DATABASE_URL=postgres://localhost:5432/mydb  │
│              │  REDIS_URL=redis://localhost:6379             │
│              │  API_KEY=sk-dev-xxxxxxxxxxxx                  │
│              │  NODE_ENV=development                         │
│              │                                              │
│              │  [Diff Profiles ▼]                           │
└──────────────┴──────────────────────────────────────────────┘
```

**Left sidebar:**
- Project list with active profile color indicator
- Click to select project
- Add/remove project buttons
- Drag a folder to add project

**Right panel — Profile cards:**
- Grid of profile cards with color-coded borders
- Active profile has green badge + "ACTIVE" label
- Each card shows: name, variable count, last used date
- "Switch →" button on inactive profiles
- Click card to preview its content

**Below cards:**
- Import current `.env` as new profile button
- Preview of the current `.env` content (read-only CodeEditor)
- Diff button: compare two profiles side by side (reuse TextDiffService)

### Color coding for profiles

Suggest colors for common environments:
- Development: green (#4ADE80)
- Staging: yellow (#FBBF24)
- Production: red (#F87171)
- Testing: blue (#60A5FA)
- Custom: user picks

### Safety features

- Confirmation dialog before switching to production
- Auto-backup of current `.env` before every switch
- Show diff of what will change before switching

## Tests: `EnvSwitcherServiceTests.swift`

- `testParseEnvContent` — key=value pairs parsed correctly
- `testParseEnvWithQuotes` — handles `KEY="value with spaces"`
- `testParseEnvWithComments` — ignores `# comment` lines
- `testParseEnvEmpty` — empty string returns empty array
- `testDiffProfiles` — detects added, removed, changed keys
- `testDiffIdentical` — empty diff for same content
- `testCreateProfile` — profile has ID, name, content, timestamp
- `testFindConflicts` — finds keys with different values across profiles
- `testDetectEnvFile` — finds .env in directory (use temp directory)
- `testSaveLoadProjects` — round-trip serialization
