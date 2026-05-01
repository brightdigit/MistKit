# Merge MistDemo + MistDemoApp & PR Feedback Fixes

PR #273 review feedback. Web CRUD (#274) and public DB (#275) deferred to future PRs.

**Key principle:** All code belongs in Swift Package library targets. The Xcode project only contains the thin `@main` App entry point.

---

## 1. Delete stale plan file
- Delete `.claude/plans/mistdemo-improvements-271.md`

## 2. Merge directories into `Examples/MistDemo/`

### Final structure
```
Examples/MistDemo/
├── Package.swift              # modified — adds MistDemoAppKit library target
├── project.yml                # moved from MistDemoApp, modified
├── Makefile                   # moved from MistDemoApp
├── MistDemoApp.entitlements   # moved from MistDemoApp
├── README.md                  # moved from MistDemoApp, paths updated
├── .env.example               # moved from MistDemoApp, extended
├── schema.ckdb
├── .gitignore
├── examples/                  # existing CLI shell scripts
├── App/                       # NEW — thin @main only, referenced by Xcode project
│   └── MistDemoApp.swift      # just @main + WindowGroup, imports MistDemoAppKit
├── Sources/
│   ├── ConfigKeyKit/          # existing
│   ├── MistDemoKit/           # existing
│   ├── MistDemo/              # existing CLI entry point
│   └── MistDemoAppKit/        # NEW library target (moved from MistDemoApp sources)
│       ├── Models/CloudKitModels.swift
│       ├── Services/NativeCloudKitService.swift
│       └── Views/
│           ├── RootView.swift
│           ├── AccountView.swift
│           ├── ZoneListView.swift
│           ├── QueryView.swift
│           ├── NoteEditView.swift
│           └── RecordDetailView.swift
└── Tests/MistDemoTests/       # existing
```

### Move operations (`git mv` to preserve history)
1. `git mv Examples/MistDemoApp/Sources/MistDemoApp Examples/MistDemo/Sources/MistDemoAppKit`
2. Remove `MistDemoApp.swift` from `Sources/MistDemoAppKit/` (it becomes the thin App file)
3. Create `Examples/MistDemo/App/MistDemoApp.swift` — thin `@main` that imports `MistDemoAppKit`
4. `git mv Examples/MistDemoApp/project.yml Examples/MistDemo/project.yml`
5. `git mv Examples/MistDemoApp/Makefile Examples/MistDemo/Makefile`
6. `git mv Examples/MistDemoApp/MistDemoApp.entitlements Examples/MistDemo/MistDemoApp.entitlements`
7. `git mv Examples/MistDemoApp/.env.example Examples/MistDemo/.env.example`
8. `git mv Examples/MistDemoApp/README.md Examples/MistDemo/README.md`
9. Delete remaining `Examples/MistDemoApp/` (Package.swift, .gitignore)

### Package.swift changes
- Add `.iOS(.v17)` to platforms: `[.macOS(.v15), .iOS(.v17)]`
- Add new library product: `.library(name: "MistDemoAppKit", targets: ["MistDemoAppKit"])`
- Add new target:
  ```swift
  .target(
      name: "MistDemoAppKit",
      dependencies: [],  // no SPM deps, uses Apple frameworks only
      swiftSettings: swiftSettings
  )
  ```
- CLI targets (MistDemoKit, MistDemo, ConfigKeyKit) unchanged — Hummingbird etc. are macOS-only, but SPM only builds targets you request

### MistDemoAppKit visibility changes
Only types used by the thin App entry point need `public` access:
- `NativeCloudKitService` — make `public` (class, init, `demoContainerIdentifier`, published properties, methods)
- `RootView` — make `public` (struct + `init` + `body`)

Everything else (`Note`, `ZoneRow`, `SidebarItem`, other views) stays `internal` — used only within the library.

### Thin App/MistDemoApp.swift
```swift
import MistDemoAppKit
import SwiftUI

@main
struct MistDemoAppMain: App {
    @StateObject private var service = NativeCloudKitService(
        containerIdentifier: NativeCloudKitService.demoContainerIdentifier
    )

    var body: some Scene {
        WindowGroup("MistDemo (Native CloudKit)") {
            RootView()
                .environmentObject(service)
        }
        #if os(macOS)
        .defaultSize(width: 880, height: 600)
        #endif
    }
}
```

## 3. Modify project.yml

**File:** `Examples/MistDemo/project.yml` (after move)

- Add local package reference:
  ```yaml
  packages:
    MistDemo:
      path: .
  ```
- Change sources from `Sources/MistDemoApp` → `App`
- Add dependency on `MistDemoAppKit` from the local package to both targets
- Replace `bundleIdPrefix: com.brightdigit` → `bundleIdPrefix: ${BUNDLE_ID_PREFIX}`
- Replace `PRODUCT_BUNDLE_IDENTIFIER: com.brightdigit.MistDemoApp` → `${BUNDLE_ID_PREFIX}.MistDemoApp`
- Add `DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}` to `settings.base`
- Update scheme comment paths

## 4. Update .env.example
Add new variables:
```
BUNDLE_ID_PREFIX=com.brightdigit
DEVELOPMENT_TEAM=
```

## 5. Update path references
- **README.md**: Change `../MistDemo/` refs to current-dir, update `cd Examples/MistDemoApp` → `cd Examples/MistDemo`
- **CloudKitModels.swift**: Update doc comment path for schema.ckdb (now same directory)
- **NativeCloudKitService.swift**: Update doc comment `Examples/MistDemo/schema.ckdb` → `schema.ckdb`

## 6. Delete `Examples/MistDemoApp/`
Remove remaining files and directory.

## Verification
1. `cd Examples/MistDemo && swift build` — CLI still builds
2. `cd Examples/MistDemo && swift test` — tests still pass
3. `cd Examples/MistDemo && make generate` — Xcode project generates (requires xcodegen)
4. Open .xcodeproj — both MistDemoApp-macOS and MistDemoApp-iOS schemes build
