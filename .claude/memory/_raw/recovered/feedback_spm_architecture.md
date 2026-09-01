---
name: All code in Swift Packages
description: All code belongs in SPM library targets; Xcode projects should only contain the thin @main App entry point file
type: feedback
---

All code belongs in Swift Packages. Xcode Project only needs one App SwiftUI file.

**Why:** Standard layout for Xcode project with Swift package means the Xcode project is a thin shell — just the @main App entry point. All views, models, services, and logic live in SPM library targets so they're testable, cross-platform where possible, and not tied to Xcode.

**How to apply:** When structuring projects that have both SPM packages and Xcode projects, put all code into SPM library targets. The Xcode project's source should be minimal — typically just the `@main` App struct that imports the library.
