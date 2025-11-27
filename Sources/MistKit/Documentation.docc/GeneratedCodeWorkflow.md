# Development Workflow for Generated Code

A comprehensive guide to managing swift-openapi-generator code throughout the development lifecycle, including version control, updates, CI/CD integration, and code review best practices.

## Overview

MistKit uses a **pre-generation workflow** where generated code is committed to version control. This article covers the complete development workflow for working with generated code, from initial setup through updates, reviews, and deployment.

## Workflow Philosophy: Pre-Generation vs. Build Plugin

### MistKit's Approach: Pre-Generation

```
Developer Machine                Git Repository             Consumer Machine
─────────────────                ──────────────             ────────────────
1. Edit openapi.yaml
2. Run generate script      →    3. Commit generated code   →   4. swift build
   Sources/Generated/*.swift                                        ↓
                                                                 Uses existing
                                                                 generated code
```

**Advantages:**

- ✅ **Fast consumer builds**: No generation during build time
- ✅ **No tool dependencies for consumers**: swift-openapi-generator not required
- ✅ **Reviewable changes**: Generated code visible in pull requests
- ✅ **Predictable builds**: Same generated code across all environments
- ✅ **Better IDE support**: Generated code always available for autocomplete
- ✅ **Easier debugging**: Can inspect and trace through generated code

**Disadvantages:**

- ⚠️ **Developer discipline required**: Must remember to regenerate after spec changes
- ⚠️ **Larger git diffs**: Generated code changes appear in commits
- ⚠️ **Potential for mistakes**: Forgetting to regenerate can cause drift

### Alternative: Build Plugin (Not Used)

```
Developer Machine                Git Repository             Consumer Machine
─────────────────                ──────────────             ────────────────
1. Edit openapi.yaml        →    2. Commit spec only       →   3. swift build
                                                                    ↓
                                                                 Generates code
                                                                 during build
```

**Why MistKit doesn't use this:**

- ❌ Requires consumers to install swift-openapi-generator
- ❌ Slower builds for everyone
- ❌ Generated code not visible in code reviews
- ❌ Harder to debug (generated code in derived data)
- ❌ IDE autocomplete delays while generating

## Development Workflow

### 1. Initial Project Setup

When starting a new MistKit-based project or contributing to MistKit:

```bash
# 1. Clone the repository
git clone https://github.com/your-org/MistKit.git
cd MistKit

# 2. Install Mint (if not already installed)
brew install mint  # macOS
# or follow Linux installation instructions

# 3. Bootstrap development tools
mint bootstrap -m Mintfile

# 4. Verify generated code exists
ls -la Sources/MistKit/Generated/
# Should see: Client.swift, Types.swift

# 5. Build to verify everything works
swift build

# 6. Run tests
swift test
```

**Expected output:**

```
✅ Sources/MistKit/Generated/Client.swift (exists)
✅ Sources/MistKit/Generated/Types.swift (exists)
✅ Build succeeded
✅ Tests passed
```

### 2. Making OpenAPI Specification Changes

#### Step 1: Edit the OpenAPI Specification

```bash
# Open the OpenAPI spec in your editor
vim openapi.yaml
# or
code openapi.yaml
```

**Common changes:**

- Adding new endpoints
- Modifying request/response schemas
- Updating parameter definitions
- Adding/changing enum values
- Updating documentation strings

#### Step 2: Validate the OpenAPI Spec (Optional but Recommended)

```bash
# Install openapi-spec-validator (if not installed)
pip install openapi-spec-validator

# Validate the spec
openapi-spec-validator openapi.yaml
```

**Expected output:**

```
✅ openapi.yaml is valid
```

#### Step 3: Regenerate Client Code

```bash
# Run the generation script
./Scripts/generate-openapi.sh
```

**Expected output:**

```
🔄 Generating OpenAPI code...
✅ OpenAPI code generation complete!
```

**What happens:**

1. Mint ensures swift-openapi-generator@1.10.0 is installed
2. Generator reads `openapi.yaml` and `openapi-generator-config.yaml`
3. Generates new `Client.swift` and `Types.swift` files
4. Overwrites existing files in `Sources/MistKit/Generated/`

#### Step 4: Verify Generated Code Compiles

```bash
# Clean build to ensure no cached artifacts
swift package clean

# Build with fresh generated code
swift build
```

**If build fails:**

1. Check for breaking changes in generated types
2. Update wrapper code (MistKitClient, etc.) to match new types
3. Fix compilation errors
4. Re-run `swift build`

#### Step 5: Update Tests

```bash
# Run existing tests
swift test

# Add new tests for new functionality
# Edit Tests/MistKitTests/*.swift
```

#### Step 6: Review Changes

```bash
# See what changed in generated code
git diff Sources/MistKit/Generated/

# See what changed in OpenAPI spec
git diff openapi.yaml
```

**Review checklist:**

- [ ] Generated code compiles successfully
- [ ] Tests pass
- [ ] New types match OpenAPI schema expectations
- [ ] No unexpected changes in generated code
- [ ] Documentation comments are accurate

### 3. Committing Changes

#### Commit Strategy: Separate Commits for Clarity

**Option A: Two commits (recommended for large changes)**

```bash
# Commit 1: OpenAPI spec change
git add openapi.yaml
git commit -m "feat: add uploadAssets endpoint to OpenAPI spec"

# Commit 2: Generated code update
git add Sources/MistKit/Generated/
git commit -m "chore: regenerate client code for uploadAssets endpoint

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Option B: Single commit (for small changes)**

```bash
# Commit both together
git add openapi.yaml Sources/MistKit/Generated/
git commit -m "feat: add uploadAssets endpoint

- Added /assets/upload endpoint to OpenAPI spec
- Regenerated client code with swift-openapi-generator

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

#### Commit Message Format

```
<type>(<scope>): <subject>

<body>

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:**
- `feat`: New feature or endpoint
- `fix`: Bug fix in OpenAPI spec
- `chore`: Regenerating code without spec changes
- `docs`: Documentation updates in OpenAPI spec
- `refactor`: Restructuring schemas without functional changes

**Examples:**

```bash
# New endpoint
git commit -m "feat(records): add bulk delete operation"

# Schema change
git commit -m "fix(schemas): correct FieldValue type definition"

# Regeneration only (e.g., after generator version update)
git commit -m "chore: regenerate code with swift-openapi-generator 1.10.0"

# Documentation update
git commit -m "docs(openapi): improve error response descriptions"
```

### 4. Code Review Process

#### What to Review

When reviewing pull requests with generated code changes:

**1. OpenAPI Spec Changes (Primary Focus)**

```diff
# openapi.yaml
  paths:
+   /database/{version}/{container}/{environment}/{database}/assets/upload:
+     post:
+       summary: Upload Assets
+       operationId: uploadAssets
+       ...
```

**Review checklist:**

- [ ] Is the endpoint path correct?
- [ ] Are parameter types appropriate?
- [ ] Is the schema well-defined?
- [ ] Are error responses documented?
- [ ] Is the operation ID meaningful?

**2. Generated Code Changes (Secondary Focus)**

```diff
# Sources/MistKit/Generated/Types.swift
+ internal enum uploadAssets {
+     internal static let id: Swift.String = "uploadAssets"
+     internal struct Input: Sendable, Hashable { ... }
+     internal enum Output: Sendable, Hashable { ... }
+ }
```

**Review checklist:**

- [ ] Does generated code match OpenAPI spec?
- [ ] Are types correctly generated?
- [ ] No manual edits to generated files?
- [ ] File headers intact (periphery:ignore, swift-format-ignore)?

**3. Wrapper Code Changes (Detailed Focus)**

```diff
# Sources/MistKit/MistKitClient.swift
+ internal func uploadAssets(
+     _ assetData: Data,
+     forRecord recordName: String
+ ) async throws -> UploadAssetsResponse {
+     let response = try await client.uploadAssets(...)
+     ...
+ }
```

**Review checklist:**

- [ ] Proper error handling?
- [ ] Follows MistKit conventions?
- [ ] Well-documented?
- [ ] Tests included?

#### Review Comments Examples

**Good comments:**

```markdown
In openapi.yaml, should the `assetData` field be required?

The generated types look correct, but I notice the error handling
in MistKitClient.swift doesn't account for the new 413 response.
Could we add handling for that case?

Nice work on the comprehensive test coverage for the new endpoint!
```

**Avoid these comments:**

```markdown
❌ Why did you change line 523 of Types.swift?
   (Generated code - should ask about OpenAPI spec instead)

❌ Can you rename this type to something shorter?
   (Generated types follow OpenAPI naming - change the spec)

❌ This code could be more efficient
   (Generated code optimization is out of scope - file upstream issue)
```

### 5. Handling Breaking Changes

#### Identifying Breaking Changes

Breaking changes occur when generated types change in incompatible ways:

**Common breaking changes:**

1. **Required fields added to request schemas**
2. **Required fields removed from response schemas**
3. **Enum cases removed or renamed**
4. **Parameter types changed**
5. **Response status codes changed**

#### Example: Adding a Required Field

**Before (`openapi.yaml`):**

```yaml
RecordQuery:
  type: object
  properties:
    recordType:
      type: string
  required:
    - recordType
```

**After (breaking change):**

```yaml
RecordQuery:
  type: object
  properties:
    recordType:
      type: string
    zoneID:
      $ref: '#/components/schemas/ZoneID'
  required:
    - recordType
    - zoneID  # New required field!
```

**Impact on generated code:**

```swift
// Before
internal struct RecordQuery {
    internal var recordType: String
    internal var zoneID: ZoneID?  // Optional

    internal init(recordType: String, zoneID: ZoneID? = nil) { ... }
}

// After (breaking!)
internal struct RecordQuery {
    internal var recordType: String
    internal var zoneID: ZoneID  // Now required!

    internal init(recordType: String, zoneID: ZoneID) { ... }
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // Compile error in existing code that doesn't pass zoneID
}
```

#### Managing Breaking Changes

**Option 1: Major Version Bump**

```bash
# Update version in Package.swift
# 1.2.3 → 2.0.0

git commit -m "feat!: add required zoneID to RecordQuery

BREAKING CHANGE: RecordQuery now requires zoneID parameter.
Update all query calls to include zoneID.

Migration:
  .init(recordType: \"User\")
→ .init(recordType: \"User\", zoneID: .default)
"
```

**Option 2: Provide Default Values (if possible)**

```yaml
# Add default in OpenAPI spec
zoneID:
  $ref: '#/components/schemas/ZoneID'
  default:
    zoneName: "_defaultZone"
```

**Option 3: Migration Period with Deprecations**

If the old field still exists:

```swift
// Wrapper layer provides backward compatibility
@available(*, deprecated, message: "Use init(recordType:zoneID:) instead")
internal init(recordType: String) {
    self.init(recordType: recordType, zoneID: .default)
}
```

#### Documenting Breaking Changes

**CHANGELOG.md entry:**

```markdown
## [2.0.0] - 2024-01-15

### Breaking Changes

- **RecordQuery now requires zoneID parameter**
  - **Migration**: Add zoneID to all RecordQuery initializations
  - **Before**: `.init(recordType: "User")`
  - **After**: `.init(recordType: "User", zoneID: .default)`
  - **Reason**: CloudKit Web Services now requires explicit zone specification

### Migration Guide

Update all code that creates RecordQuery instances:

\`\`\`swift
// Old code (won't compile)
let query = RecordQuery(recordType: "User")

// New code
let query = RecordQuery(
    recordType: "User",
    zoneID: ZoneID(zoneName: "_defaultZone")
)
\`\`\`
```

### 6. Version Control Best Practices

#### .gitignore Configuration

```gitignore
# DO NOT ignore generated code!
# Sources/MistKit/Generated/

# DO ignore build artifacts
.build/
.swiftpm/
*.xcodeproj/
DerivedData/

# DO ignore local tools
.mint/

# DO ignore sensitive files
.env
*.pem
```

**Important:** Generated code must be committed!

#### Git Attributes for Generated Files

Create `.gitattributes`:

```gitattributes
# Mark generated files for better GitHub diffs
Sources/MistKit/Generated/*.swift linguist-generated=true

# Ensure LF line endings for scripts
*.sh text eol=lf

# Ensure YAML formatting
*.yaml text
```

**Benefits:**

- GitHub collapses generated code diffs by default
- Scripts work correctly on all platforms
- Consistent YAML formatting

### 7. CI/CD Integration

#### GitHub Actions Workflow

**Purpose:** Verify generated code is up-to-date

```yaml
# .github/workflows/verify-generated-code.yml
name: Verify Generated Code

on:
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'openapi-generator-config.yaml'
      - 'Sources/MistKit/Generated/**'

jobs:
  verify-generated:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: swift-actions/setup-swift@v2
        with:
          swift-version: '6.2'

      - name: Install Mint
        run: |
          git clone https://github.com/yonaskolb/Mint.git
          cd Mint
          swift run mint bootstrap

      - name: Regenerate OpenAPI code
        run: ./Scripts/generate-openapi.sh

      - name: Check for differences
        run: |
          if ! git diff --exit-code Sources/MistKit/Generated/; then
            echo "❌ Generated code is out of date!"
            echo "Run: ./Scripts/generate-openapi.sh"
            exit 1
          fi
          echo "✅ Generated code is up to date"

      - name: Verify build
        run: swift build
```

**What this does:**

1. Triggers on changes to OpenAPI spec or generated code
2. Regenerates code from scratch
3. Compares regenerated code to committed code
4. Fails if they don't match
5. Verifies build succeeds

#### Alternative: Auto-Commit Generated Code

```yaml
# .github/workflows/auto-regenerate.yml
name: Auto-Regenerate Generated Code

on:
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'openapi-generator-config.yaml'

jobs:
  regenerate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}

      - uses: swift-actions/setup-swift@v2
        with:
          swift-version: '6.2'

      - name: Install Mint
        run: |
          git clone https://github.com/yonaskolb/Mint.git
          cd Mint
          swift run mint bootstrap

      - name: Regenerate OpenAPI code
        run: ./Scripts/generate-openapi.sh

      - name: Commit changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          if ! git diff --exit-code Sources/MistKit/Generated/; then
            git add Sources/MistKit/Generated/
            git commit -m "chore: regenerate OpenAPI client code [skip ci]"
            git push
          fi
```

**Benefits:**

- Developers don't need to manually regenerate
- Always up-to-date generated code

**Drawbacks:**

- Less visibility into what changed
- Potential for surprise commits

### 8. Updating swift-openapi-generator Version

#### When to Update

- 🆕 New swift-openapi-generator release with desired features
- 🐛 Bug fixes in code generation
- 🔒 Security updates

#### Update Process

**Step 1: Update Mintfile**

```diff
# Mintfile
  swiftlang/swift-format@601.0.0
  realm/SwiftLint@0.59.1
  peripheryapp/periphery@3.2.0
- apple/swift-openapi-generator@1.10.0
+ apple/swift-openapi-generator@1.11.0
```

**Step 2: Clear Mint Cache**

```bash
# Remove old version
rm -rf .mint/
```

**Step 3: Bootstrap New Version**

```bash
mint bootstrap -m Mintfile
```

**Step 4: Regenerate Code**

```bash
./Scripts/generate-openapi.sh
```

**Step 5: Review Differences**

```bash
git diff Sources/MistKit/Generated/
```

**Possible outcomes:**

- ✅ **No changes**: Generator improvements don't affect output
- ⚠️ **Formatting changes**: Code reformatted but semantically identical
- ⚠️ **New features**: Additional generated code (new helper methods, etc.)
- 🚨 **Breaking changes**: Generated code structure changed

**Step 6: Test Thoroughly**

```bash
# Clean build
swift package clean
swift build

# Run all tests
swift test

# Integration tests
swift test --filter IntegrationTests
```

**Step 7: Commit**

```bash
git add Mintfile .mint/ Sources/MistKit/Generated/
git commit -m "chore: update swift-openapi-generator to 1.11.0

- Updated Mintfile dependency
- Regenerated client code with new generator version
- Verified all tests pass

Generator changelog: https://github.com/apple/swift-openapi-generator/releases/tag/1.11.0
"
```

### 9. Troubleshooting Common Issues

#### Issue: Generated Code Out of Sync

**Symptoms:**

- Build errors referencing missing types
- Test failures with type mismatches
- IDE autocomplete shows wrong types

**Solution:**

```bash
# 1. Clean everything
swift package clean
rm -rf .build/

# 2. Regenerate from scratch
./Scripts/generate-openapi.sh

# 3. Rebuild
swift build
```

#### Issue: Merge Conflicts in Generated Code

**Symptoms:**

```
<<<<<<< HEAD
internal struct User { ... }
=======
internal struct User { ... }
>>>>>>> feature-branch
```

**Solution:**

```bash
# 1. Accept either version (doesn't matter which)
git checkout --theirs Sources/MistKit/Generated/

# 2. Merge the OpenAPI specs carefully
git merge-tool openapi.yaml

# 3. Regenerate from merged spec
./Scripts/generate-openapi.sh

# 4. Stage the correctly generated code
git add Sources/MistKit/Generated/
```

**Never manually resolve conflicts in generated files!**

#### Issue: CI Fails with "Generated Code Out of Date"

**Symptoms:**

```
❌ Generated code is out of date!
Run: ./Scripts/generate-openapi.sh
```

**Solution:**

```bash
# Regenerate locally
./Scripts/generate-openapi.sh

# Verify differences
git status

# Commit updated generated code
git add Sources/MistKit/Generated/
git commit -m "chore: update generated code to match OpenAPI spec"
git push
```

#### Issue: Generator Version Mismatch

**Symptoms:**

```
Error: swift-openapi-generator version mismatch
Expected: 1.10.0
Found: 1.9.0
```

**Solution:**

```bash
# Clear Mint cache
rm -rf .mint/

# Reinstall correct version
mint bootstrap -m Mintfile

# Verify version
mint run swift-openapi-generator --version
```

## Best Practices Summary

### DO ✅

- ✅ **Commit generated code** to version control
- ✅ **Regenerate after every OpenAPI spec change**
- ✅ **Review OpenAPI spec changes carefully** in pull requests
- ✅ **Run tests after regeneration** to catch breaking changes
- ✅ **Document breaking changes** in CHANGELOG
- ✅ **Use CI/CD to verify** generated code is up-to-date
- ✅ **Keep generator version** in sync across team (via Mintfile)
- ✅ **Clean build after regeneration** to avoid cached issues

### DON'T ❌

- ❌ **Never manually edit generated files** (changes will be overwritten)
- ❌ **Don't ignore generated code** in .gitignore
- ❌ **Don't merge conflicts** in generated files manually
- ❌ **Don't forget to regenerate** after OpenAPI changes
- ❌ **Don't commit only spec without generated code**
- ❌ **Don't skip testing** after regeneration
- ❌ **Don't use different generator versions** on different machines

## Real-World Example: Adding a New Endpoint

Let's walk through a complete example of adding the `uploadAssets` endpoint:

### 1. Update OpenAPI Spec

```yaml
# openapi.yaml
paths:
  /database/{version}/{container}/{environment}/{database}/assets/upload:
    post:
      summary: Upload Assets
      description: Upload binary assets to CloudKit
      operationId: uploadAssets
      parameters:
        - $ref: '#/components/parameters/version'
        - $ref: '#/components/parameters/container'
        - $ref: '#/components/parameters/environment'
        - $ref: '#/components/parameters/database'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AssetUploadRequest'
      responses:
        '200':
          description: Upload successful
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AssetUploadResponse'
```

### 2. Regenerate

```bash
./Scripts/generate-openapi.sh
```

### 3. Verify Generated Code

```swift
// Sources/MistKit/Generated/Types.swift (auto-generated)
internal enum Operations {
    // ... existing operations

    internal enum uploadAssets {
        internal static let id: Swift.String = "uploadAssets"

        internal struct Input: Sendable, Hashable {
            internal struct Path: Sendable, Hashable {
                internal var version: String
                internal var container: String
                internal var environment: environment
                internal var database: database
            }
            internal var path: Path
            internal var body: Body
        }

        internal enum Output: Sendable, Hashable {
            case ok(Ok)
            // ... error cases
        }
    }
}
```

### 4. Add Wrapper Method

```swift
// Sources/MistKit/MistKitClient.swift
extension MistKitClient {
    /// Upload an asset to CloudKit
    ///
    /// - Parameters:
    ///   - data: Asset data to upload
    ///   - recordName: Associated record name
    /// - Returns: Upload response with asset URL
    /// - Throws: CloudKitError if upload fails
    internal func uploadAsset(
        _ data: Data,
        forRecord recordName: String
    ) async throws -> AssetUploadResponse {
        let request = AssetUploadRequest(
            assetData: data,
            recordName: recordName
        )

        let response = try await client.uploadAssets(
            path: .init(
                version: "1",
                container: configuration.container,
                environment: configuration.environment,
                database: configuration.database
            ),
            body: .json(request)
        )

        switch response {
        case .ok(let okResponse):
            return try okResponse.body.json

        case .badRequest(let error):
            throw try CloudKitError(from: error.body.json)

        // ... handle other error cases
        }
    }
}
```

### 5. Add Tests

```swift
// Tests/MistKitTests/AssetUploadTests.swift
import Testing
@testable import MistKit

struct AssetUploadTests {
    @Test func uploadAssetSuccess() async throws {
        let mockTransport = MockTransport(
            returning: .ok(AssetUploadResponse(assetURL: "https://..."))
        )

        let client = try MistKitClient(
            configuration: testConfiguration,
            transport: mockTransport
        )

        let assetData = Data("test asset".utf8)
        let response = try await client.uploadAsset(
            assetData,
            forRecord: "testRecord"
        )

        #expect(response.assetURL != nil)
    }
}
```

### 6. Commit

```bash
git add openapi.yaml Sources/MistKit/Generated/ \
        Sources/MistKit/MistKitClient.swift \
        Tests/MistKitTests/AssetUploadTests.swift

git commit -m "feat(assets): add uploadAssets endpoint

- Added /assets/upload endpoint to OpenAPI spec
- Regenerated client code
- Added MistKitClient.uploadAsset() wrapper method
- Added comprehensive tests

Closes #123

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## See Also

- <doc:OpenAPICodeGeneration>
- <doc:GeneratedCodeAnalysis>
- [Git Best Practices](https://git-scm.com/book/en/v2)
- [Semantic Versioning](https://semver.org/)
- [swift-openapi-generator Releases](https://github.com/apple/swift-openapi-generator/releases)
