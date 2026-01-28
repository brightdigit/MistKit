# Test Organization Guide for Swift Testing

## Overview

This guide documents a hierarchical test organization pattern for Swift Testing using empty enum containers with nested struct extensions. This approach provides:

- **Clear hierarchy**: Logical grouping of related tests
- **Scalability**: Easy to add new test categories without file bloat
- **Parallel execution**: Swift Testing can run suites concurrently
- **Discoverable structure**: File organization mirrors test hierarchy
- **Maintainability**: Isolated test categories in separate files

**When to use this pattern:**
- Production types with multiple test categories (validation, errors, concurrency, etc.)
- Test suites that will grow over time
- When you need to organize tests by feature or behavior
- For complex types requiring different test data per category

**When to use simple patterns:**
- Types with a small, focused set of tests (< 10 tests)
- Utility types with straightforward behavior
- Tests that don't require multiple categories

## Core Pattern Overview

Swift Testing supports hierarchical test organization through nested suites. This guide presents a pattern using empty enums as parent containers with struct extensions for categories, along with a critical naming convention.

### Pattern A: Parent Has "Tests" Suffix

```swift
// 1. Empty enum as parent container (has "Tests")
@Suite("Parent Suite Name")
internal enum ParentTests {}

// 2. Extension with nested suite struct (no "Tests")
extension ParentTests {
  @Suite("Category Description")
  internal struct Category {
    // 3. Test methods
    @Test("Test description")
    internal func testSomething() {
      #expect(condition)
    }
  }
}
```

**File structure:**
- `ParentTests.swift` - Defines the empty enum
- `ParentTests+Category.swift` - Extension with nested struct

### Pattern B: Child Has "Tests" Suffix

```swift
// 1. Empty enum as parent container (no "Tests")
@Suite("Parent Suite Name")
internal enum Parent {}

// 2. Extension with nested suite struct (has "Tests")
extension Parent {
  @Suite("Category Description")
  internal struct CategoryTests {
    // 3. Test methods
    @Test("Test description")
    internal func testSomething() {
      #expect(condition)
    }
  }
}
```

**File structure:**
- `Parent.swift` - Defines the empty enum
- `Parent+CategoryTests.swift` - Extension with nested struct

### Critical Convention: The "Tests" Suffix Rule

**Never use "Tests" in both the parent enum AND child struct names.**

This is the most important naming rule when using this organizational pattern. Choose one location for "Tests" and apply it consistently throughout your project.

## Naming Convention Rationale

### The "Tests" Suffix Rule Explained

**Rule**: Include "Tests" in EITHER the parent enum OR the child struct, NEVER both.

### Why This Matters

1. **Reduces Redundancy**:
   - ✅ `UserManagerTests+Validation` is cleaner
   - ❌ `UserManagerTests+ValidationTests` is redundant

2. **Clearer Intent**: The file extension and test directory location already indicate these are tests
   - File: `TypeNameTests+Category.swift` in `Tests/` directory → obviously tests
   - File: `TypeName+CategoryTests.swift` in `Tests/` directory → also obviously tests

3. **Shorter Names**: Reduces cognitive load when reading test output and file lists

4. **Consistency**: Pick one pattern for your project and maintain it

### Examples

✅ **Correct patterns:**
```
UserManagerTests + Validation      → UserManagerTests+Validation.swift
UserManager + ValidationTests      → UserManager+ValidationTests.swift
NetworkClientTests + Errors        → NetworkClientTests+Errors.swift
NetworkClient + ErrorTests         → NetworkClient+ErrorTests.swift
```

❌ **Avoid (redundant "Tests"):**
```
UserManagerTests + ValidationTests → TypeNameTests+CategoryTests.swift
NetworkClientTests + ErrorTests    → TypeNameTests+CategoryTests.swift
```

### Choosing a Pattern for Your Project

**Pattern A (Parent has "Tests")**
- Parent: `UserManagerTests`
- Children: `Basic`, `Validation`, `Errors`
- **Advantages**:
  - Matches test file naming convention
  - Clear that the entire hierarchy is for tests
  - Shorter child struct names

**Pattern B (Child has "Tests")**
- Parent: `UserManager`
- Children: `BasicTests`, `ValidationTests`, `ErrorTests`
- **Advantages**:
  - Parent enum name matches production type exactly
  - Easy to search for all test structs (filter by "Tests" suffix)
  - Clear separation between test enums and production types

**Recommendation**: Choose one pattern and apply it consistently across your entire test suite. Document your choice in your project's contribution guidelines.

## Step-by-Step Tutorial

### Creating a New Test Suite

This tutorial demonstrates **Pattern A** (parent with "Tests" suffix), but the steps apply equally to Pattern B.

#### Step 1: Choose Your Naming Convention

**Decision point**: Where should "Tests" appear?

For this tutorial, we'll use **Pattern A**:
- Parent enum: `TypeNameTests` (has "Tests")
- Child structs: `Category1`, `Category2` (no "Tests")

Alternatively, you could use **Pattern B**:
- Parent enum: `TypeName` (no "Tests")
- Child structs: `Category1Tests`, `Category2Tests` (have "Tests")

#### Step 2: Create the Parent Enum File

Create a file named after your production type with "Tests" suffix:

```swift
// File: TypeNameTests.swift
import Testing

/// Test suite for TypeName functionality.
@Suite("Type Name")
internal enum TypeNameTests {}
```

**Key points:**
- Empty enum (no properties or methods)
- `@Suite` attribute with descriptive name
- `internal` or `public` access level as appropriate
- Import `Testing` framework

#### Step 3: Create Extension Files for Each Test Category

Create separate files for each test category:

```swift
// File: TypeNameTests+Initialization.swift
import Testing

extension TypeNameTests {
  /// Tests for TypeName initialization scenarios.
  @Suite("Initialization Tests")
  internal struct Initialization {
    // Tests go here
  }
}
```

**Naming the extension file:**
- Format: `ParentEnumName+ChildStructName.swift`
- Example: `TypeNameTests+Initialization.swift`
- Child struct name has NO "Tests" suffix (parent already has it)

**Common test categories:**
- `Initialization` - Constructor and setup tests
- `Validation` - Input validation and constraints
- `Errors` - Error handling and edge cases
- `Concurrent` - Concurrency and thread safety
- `Integration` - Integration with other components
- `Performance` - Performance and benchmarking tests

#### Step 4: Add Test Data as Private Static Properties

```swift
extension TypeNameTests {
  @Suite("Initialization Tests")
  internal struct Initialization {
    // MARK: - Test Data Setup

    /// Valid configuration for testing.
    private static let validConfig = Configuration(
      timeout: 30,
      retryCount: 3
    )

    /// Invalid configuration for error testing.
    private static let invalidConfig = Configuration(
      timeout: -1,
      retryCount: 0
    )

    // MARK: - Tests

    @Test("Initialize with valid configuration")
    internal func initializeWithValidConfig() {
      let instance = TypeName(config: Self.validConfig)
      #expect(instance.config.timeout == 30)
    }
  }
}
```

**Best practices for test data:**
- Use `private static let` for immutable test data
- Group related data together
- Use descriptive names (`validConfig`, not `config1`)
- Document complex test data with comments
- Access via `Self.propertyName` in test methods

#### Step 5: Write Test Methods with @Test Attribute

```swift
extension TypeNameTests {
  @Suite("Initialization Tests")
  internal struct Initialization {
    // MARK: - Test Data Setup
    private static let validInput = "test-value"

    // MARK: - Basic Initialization

    @Test("Initialize with valid input")
    internal func initializeWithValidInput() {
      let instance = TypeName(input: Self.validInput)
      #expect(instance.input == Self.validInput)
      #expect(instance.isValid)
    }

    @Test("Initialize with default configuration")
    internal func initializeWithDefaults() {
      let instance = TypeName()
      #expect(instance.config != nil)
    }

    // MARK: - Error Cases

    @Test("Initialize with empty input throws error")
    internal func initializeWithEmptyInput() {
      #expect(throws: ValidationError.self) {
        _ = try TypeName(input: "")
      }
    }

    // MARK: - Async Initialization

    @Test("Initialize with async validation")
    internal func initializeWithAsyncValidation() async throws {
      let instance = TypeName(input: Self.validInput)
      let isValid = await instance.validate()
      #expect(isValid)
    }
  }
}
```

**Test method guidelines:**
- Use descriptive names matching the `@Test` description
- Use `#expect()` for assertions
- Use `async` for async operations
- Use `throws` when testing error conditions
- Group related tests with `// MARK:` sections

#### Step 6: Add Test Helpers if Needed

If you need helper methods for testing, create a separate file:

```swift
// File: TypeName+TestHelpers.swift

extension TypeName {
  /// Simplified async validation for testing.
  internal func testValidate() async -> Bool {
    do {
      try await validate()
      return true
    } catch {
      return false
    }
  }

  /// Create a test instance with default values.
  internal static func testInstance(input: String = "test-input") -> TypeName {
    TypeName(input: input)
  }
}
```

**When to create helpers:**
- Async wrapper methods for easier testing
- Simplified factory methods for test instances
- Validation helpers used across multiple test files
- Complex setup that's repeated in many tests

**Where to place them:**
- File: `TypeName+TestHelpers.swift` (production type name, not test enum)
- Extension on the production type, not the test enum
- Use `internal` access level (visible to tests)

### Common Pitfalls to Avoid

❌ **Using "Tests" in both parent and child:**
```swift
// DON'T DO THIS
internal enum TypeNameTests {}
extension TypeNameTests {
  struct CategoryTests { ... }  // ❌ Redundant "Tests"
}
```

❌ **Making test data mutable or non-static:**
```swift
// DON'T DO THIS
private var testValue = "..."  // ❌ Mutable, instance property

// DO THIS
private static let testValue = "..."  // ✅ Immutable, static
```

❌ **Using XCTest patterns:**
```swift
// DON'T DO THIS
XCTAssertEqual(a, b)  // ❌ XCTest API

// DO THIS
#expect(a == b)  // ✅ Swift Testing API
```

❌ **Mismatching file names and type names:**
```swift
// File: TypeNameTests+CategoryTests.swift  ❌ Name suggests both have "Tests"
extension TypeNameTests {
  struct Category { ... }  // Actual child doesn't have "Tests"
}

// File: TypeNameTests+Category.swift  ✅ Matches actual names
extension TypeNameTests {
  struct Category { ... }
}
```

## File Organization Conventions

### Naming Patterns

**CRITICAL RULE**: The "Tests" suffix should appear in EITHER the parent enum OR the nested struct, but NEVER in both.

### Option 1: Parent Has "Tests"

```swift
// File: TypeNameTests.swift
@Suite("Type Name")
internal enum TypeNameTests {}

// File: TypeNameTests+Category.swift
extension TypeNameTests {
  @Suite("Category Tests")
  internal struct Category { ... }
}
```

**File naming:**
- Parent: `TypeNameTests.swift`
- Extensions: `TypeNameTests+Category.swift`, `TypeNameTests+Validation.swift`
- Helpers: `TypeName+TestHelpers.swift` (note: production type name)

### Option 2: Parent Without "Tests"

```swift
// File: TypeName.swift
@Suite("Type Name")
internal enum TypeName {}

// File: TypeName+CategoryTests.swift
extension TypeName {
  @Suite("Category Tests")
  internal struct CategoryTests { ... }
}
```

**File naming:**
- Parent: `TypeName.swift` (matches production type exactly)
- Extensions: `TypeName+CategoryTests.swift`, `TypeName+ValidationTests.swift`
- Helpers: `TypeName+TestHelpers.swift`

### What to Avoid

❌ **Redundant "Tests" suffix:**
```swift
// DON'T DO THIS
internal enum TypeNameTests {}
extension TypeNameTests {
  struct CategoryTests { ... }  // "Tests" appears in both
}

// File would be: TypeNameTests+CategoryTests.swift  ❌ Redundant
```

### Directory Structure Examples

#### Example 1: Parent Has "Tests"

```
Tests/MyLibraryTests/
└── Feature/
    ├── TypeNameTests.swift                # Parent enum: TypeNameTests {}
    ├── TypeNameTests+Initialization.swift # Nested struct: Initialization
    ├── TypeNameTests+Validation.swift     # Nested struct: Validation
    ├── TypeNameTests+Errors.swift         # Nested struct: Errors
    ├── TypeNameTests+Concurrent.swift     # Nested struct: Concurrent
    └── TypeName+TestHelpers.swift         # Helpers on TypeName (production type)
```

#### Example 2: Parent Without "Tests"

```
Tests/MyLibraryTests/
└── Feature/
    ├── TypeName.swift                     # Parent enum: TypeName {}
    ├── TypeName+InitializationTests.swift # Nested struct: InitializationTests
    ├── TypeName+ValidationTests.swift     # Nested struct: ValidationTests
    ├── TypeName+ErrorTests.swift          # Nested struct: ErrorTests
    ├── TypeName+ConcurrentTests.swift     # Nested struct: ConcurrentTests
    └── TypeName+TestHelpers.swift         # Helpers on TypeName
```

#### Example 3: Simple Pattern (No Hierarchy)

```
Tests/MyLibraryTests/
└── Utils/
    └── FieldValueTests.swift              # Single struct: FieldValueTests
```

**When to use simple pattern:**
- Small, focused types with < 10 tests
- Utilities without complex behavior categories
- Tests that don't need multiple categories

## Test Data Management

### Pattern: Private Static Properties

Test data should be defined as private static properties within each suite struct:

```swift
@Suite("Validation Tests")
internal struct Validation {
  // MARK: - Test Data Setup

  /// Valid email address for testing.
  private static let validEmail = "user@example.com"

  /// Email address with invalid format.
  private static let invalidEmail = "not-an-email"

  /// Test user configuration.
  private static let testUserConfig = UserConfig(
    name: "Test User",
    email: validEmail,
    preferences: ["theme": "dark"]
  )

  // MARK: - Email Validation Tests

  @Test("Validate email with correct format")
  internal func validateCorrectFormat() {
    let result = EmailValidator.validate(Self.validEmail)
    #expect(result.isValid)
  }

  @Test("Reject email with invalid format")
  internal func rejectInvalidFormat() {
    let result = EmailValidator.validate(Self.invalidEmail)
    #expect(!result.isValid)
  }
}
```

### Best Practices for Test Data

**Do:**
- ✅ Use descriptive names that explain the data's purpose
- ✅ Group related data together under the same `// MARK:` section
- ✅ Use `private static let` for immutable data
- ✅ Document complex or non-obvious test data with comments
- ✅ Keep test data close to the tests that use it
- ✅ Access via `Self.propertyName` in test methods

**Don't:**
- ❌ Use vague names like `data1`, `config2`
- ❌ Make test data mutable (`var` instead of `let`)
- ❌ Use instance properties (non-static)
- ❌ Share mutable state between tests
- ❌ Define test data outside the suite struct

### Organizing Test Data

```swift
@Suite("Integration Tests")
internal struct Integration {
  // MARK: - Test Data Setup

  // MARK: User Data
  private static let adminUser = User(role: .admin)
  private static let regularUser = User(role: .user)
  private static let guestUser = User(role: .guest)

  // MARK: Configurations
  private static let defaultConfig = Configuration(...)
  private static let customConfig = Configuration(...)

  // MARK: Mock Data
  private static let mockResponse = HTTPResponse(...)
  private static let mockError = NetworkError.timeout

  // MARK: - Tests
  // ...
}
```

## Test Helpers Pattern

### When to Create Helpers

Create test helper methods when you need:

1. **Async wrapper methods** for easier testing
2. **Simplified interfaces** for test-specific operations
3. **Factory methods** to create test instances
4. **Validation helpers** used across multiple tests
5. **Setup/teardown helpers** for complex test scenarios

### Where to Place Helpers

**Always extend the production type, not the test enum:**

```swift
// File: TypeName+TestHelpers.swift
import Testing

extension TypeName {
  /// Simplified async validation for testing.
  internal func testValidate() async -> Bool {
    do {
      try await validate()
      return true
    } catch {
      return false
    }
  }

  /// Create a test instance with default values.
  internal static func testInstance(
    value: String = "test-value",
    config: Configuration = .default
  ) -> TypeName {
    TypeName(value: value, config: config)
  }
}
```

### Helper Method Examples

#### Async Wrapper Helpers

Simplify async operations for easier testing:

```swift
extension NetworkClient {
  /// Test helper: Fetch data and return success status.
  internal func testFetch() async -> Bool {
    do {
      _ = try await fetch()
      return true
    } catch {
      return false
    }
  }

  /// Test helper: Validate response with simple boolean result.
  internal func testValidate(_ response: Response) async -> Bool {
    do {
      try await validate(response)
      return true
    } catch {
      return false
    }
  }
}
```

#### Factory Helpers

Create test instances with sensible defaults:

```swift
extension Configuration {
  /// Create a test configuration with default values.
  internal static var testing: Configuration {
    Configuration(
      timeout: 30,
      retryCount: 3,
      cacheEnabled: true
    )
  }

  /// Create a minimal configuration for unit tests.
  internal static func minimal() -> Configuration {
    Configuration(
      timeout: 10,
      retryCount: 1,
      cacheEnabled: false
    )
  }
}
```

#### Validation Helpers

Common validation operations for tests:

```swift
extension DataStore {
  /// Test helper: Check if store contains an item.
  internal func testContains(id: String) async -> Bool {
    do {
      let item = try await retrieve(id: id)
      return item != nil
    } catch {
      return false
    }
  }

  /// Test helper: Get count of stored items.
  internal func testCount() async -> Int {
    (try? await allItems().count) ?? 0
  }
}
```

### Best Practices for Helpers

**Do:**
- ✅ Prefix helper methods with `test` to indicate test-only code
- ✅ Use `internal` access level (visible to test targets)
- ✅ Keep helpers simple and focused on testing needs
- ✅ Document the helper's purpose
- ✅ Place in separate `+TestHelpers.swift` file

**Don't:**
- ❌ Add helpers to production codebase (keep in test-only extensions)
- ❌ Make helpers public unless necessary
- ❌ Create helpers that duplicate production functionality
- ❌ Add complex business logic to helpers

## Code Organization Within Test Files

### MARK Sections for Logical Grouping

Use `// MARK:` comments to organize tests into logical sections:

```swift
extension TypeNameTests {
  @Suite("Comprehensive Tests")
  internal struct Comprehensive {
    // MARK: - Test Data Setup

    private static let validInput = "..."
    private static let testConfig = Configuration(...)

    // MARK: - Initialization Tests

    @Test("Initialize with valid parameters")
    internal func initializeWithValidParameters() { ... }

    @Test("Initialize with default configuration")
    internal func initializeWithDefaultConfiguration() { ... }

    // MARK: - Functional Tests

    @Test("Perform basic operation")
    internal func performBasicOperation() async throws { ... }

    @Test("Handle complex workflow")
    internal func handleComplexWorkflow() async throws { ... }

    // MARK: - Error Handling Tests

    @Test("Throws error for invalid input")
    internal func throwsErrorForInvalidInput() { ... }

    @Test("Recovers from failure")
    internal func recoversFromFailure() async { ... }

    // MARK: - Concurrent Tests

    @Test("Handles concurrent access safely")
    internal func handlesConcurrentAccessSafely() async { ... }

    @Test("Maintains consistency under load")
    internal func maintainsConsistencyUnderLoad() async { ... }

    // MARK: - Edge Cases

    @Test("Handles empty input")
    internal func handlesEmptyInput() { ... }

    @Test("Handles maximum values")
    internal func handlesMaximumValues() { ... }
  }
}
```

### Common MARK Sections

Use these standard sections to organize tests consistently:

1. **`// MARK: - Test Data Setup`**
   - Private static test data
   - Mock objects and fixtures
   - Test configurations

2. **`// MARK: - Initialization Tests`**
   - Constructor tests
   - Default value tests
   - Parameter validation

3. **`// MARK: - Functional Tests`** or **`// MARK: - Basic Tests`**
   - Core functionality
   - Happy path scenarios
   - Main use cases

4. **`// MARK: - Error Handling Tests`**
   - Invalid input tests
   - Error throwing tests
   - Recovery scenarios

5. **`// MARK: - Concurrent Tests`**
   - Thread safety tests
   - Race condition tests
   - Actor isolation tests

6. **`// MARK: - Edge Cases`**
   - Boundary values
   - Empty/nil inputs
   - Maximum/minimum values

7. **`// MARK: - Performance Tests`**
   - Speed benchmarks
   - Memory usage tests
   - Scalability tests

8. **`// MARK: - Integration Tests`**
   - Component interaction tests
   - System-level tests
   - End-to-end workflows

### Sub-sections Within Main Sections

For complex test categories, use sub-sections:

```swift
// MARK: - Functional Tests

// MARK: Basic Operations
@Test("Perform simple query")
internal func performSimpleQuery() { ... }

// MARK: Complex Operations
@Test("Perform multi-step workflow")
internal func performMultiStepWorkflow() { ... }

// MARK: Batch Operations
@Test("Process batch request")
internal func processBatchRequest() { ... }
```

### Ordering Guidelines

**Recommended order:**
1. Test Data Setup
2. Initialization Tests
3. Functional/Basic Tests
4. Error Handling Tests
5. Concurrent Tests
6. Edge Cases
7. Performance Tests
8. Integration Tests

**Rationale:**
- Setup first (test data)
- Basic functionality before advanced
- Error cases after happy paths
- Performance and integration toward the end

## Complete Examples

### Example 1: Simple Pattern (Single Level)

```swift
// File: FieldValueTests.swift
import Testing

/// Tests for FieldValue type conversions and operations.
@Suite("Field Value")
internal struct FieldValueTests {
  // MARK: - Test Data Setup

  private static let testString = "Hello, World"
  private static let testNumber = 42
  private static let testDate = Date()

  // MARK: - String Value Tests

  @Test("Create field value from string")
  internal func createFromString() {
    let value = FieldValue.string(Self.testString)
    #expect(value.stringValue == Self.testString)
  }

  @Test("Convert field value to string")
  internal func convertToString() {
    let value = FieldValue.string(Self.testString)
    let result = value.stringValue
    #expect(result == Self.testString)
  }

  // MARK: - Number Value Tests

  @Test("Create field value from integer")
  internal func createFromInteger() {
    let value = FieldValue.int(Self.testNumber)
    #expect(value.intValue == Self.testNumber)
  }

  // MARK: - Date Value Tests

  @Test("Create field value from date")
  internal func createFromDate() {
    let value = FieldValue.date(Self.testDate)
    #expect(value.dateValue == Self.testDate)
  }
}
```

**When to use:**
- Small types with focused functionality
- Utilities without complex behavior categories
- Types with < 10 tests total
- Self-contained functionality

### Example 2: Extension Pattern (Two Level) - Parent With "Tests"

```swift
// File: UserManagerTests.swift
import Testing

/// Test suite for UserManager functionality.
@Suite("User Manager")
internal enum UserManagerTests {}
```

```swift
// File: UserManagerTests+Basic.swift
import Testing

extension UserManagerTests {
  /// Basic UserManager functionality tests.
  @Suite("Basic Tests")
  internal struct Basic {
    // MARK: - Test Data Setup

    private static let testUserID = "user123"
    private static let testUsername = "testuser"

    private static let testConfig = UserConfig(
      autoSave: true,
      cacheEnabled: true
    )

    // MARK: - Initialization Tests

    @Test("Initialize with valid configuration")
    internal func initializeWithValidConfiguration() {
      let manager = UserManager(config: Self.testConfig)
      #expect(manager.config.autoSave)
      #expect(manager.config.cacheEnabled)
    }

    @Test("Initialize with default configuration")
    internal func initializeWithDefaultConfiguration() {
      let manager = UserManager()
      #expect(manager.config != nil)
    }

    // MARK: - User Fetching Tests

    @Test("Fetch user successfully")
    internal func fetchUserSuccessfully() async {
      let manager = UserManager(config: Self.testConfig)
      let user = await manager.fetchUser(id: Self.testUserID)
      #expect(user != nil)
    }
  }
}
```

```swift
// File: UserManagerTests+Validation.swift
import Testing

extension UserManagerTests {
  /// UserManager validation tests.
  @Suite("Validation Tests")
  internal struct Validation {
    // MARK: - Test Data Setup

    private static let validUserID = "user123"
    private static let emptyUserID = ""
    private static let tooLongUserID = String(repeating: "a", count: 1000)

    // MARK: - User ID Validation

    @Test("Validate user ID with correct format")
    internal func validateCorrectFormat() {
      let isValid = UserManager.validateUserID(Self.validUserID)
      #expect(isValid)
    }

    @Test("Reject empty user ID")
    internal func rejectEmptyUserID() {
      let isValid = UserManager.validateUserID(Self.emptyUserID)
      #expect(!isValid)
    }

    @Test("Reject user ID that is too long")
    internal func rejectTooLongUserID() {
      let isValid = UserManager.validateUserID(Self.tooLongUserID)
      #expect(!isValid)
    }
  }
}
```

```swift
// File: UserManager+TestHelpers.swift
import Testing

extension UserManager {
  /// Test helper: Fetch user with simple boolean result.
  internal func testFetchUser(id: String) async -> Bool {
    do {
      let user = try await fetchUser(id: id)
      return user != nil
    } catch {
      return false
    }
  }

  /// Create a test instance with default values.
  internal static func testInstance() -> UserManager {
    let config = UserConfig(autoSave: false, cacheEnabled: false)
    return UserManager(config: config)
  }
}
```

**When to use:**
- Production types with multiple test categories
- Tests that will grow over time
- When different categories need different test data
- Most common pattern for complex types

### Example 3: Extension Pattern - Child With "Tests"

**Alternative structure:**

```swift
// File: UserManager.swift
import Testing

@Suite("User Manager")
internal enum UserManager {}
```

```swift
// File: UserManager+BasicTests.swift
import Testing

extension UserManager {
  @Suite("Basic Tests")
  internal struct BasicTests {
    // Tests here
  }
}
```

```swift
// File: UserManager+ValidationTests.swift
import Testing

extension UserManager {
  @Suite("Validation Tests")
  internal struct ValidationTests {
    // Tests here
  }
}
```

**Note**: This pattern has "Tests" in the child struct instead of the parent enum. Both patterns are valid - choose one and use it consistently.

## Best Practices

### Do

✅ **Use empty enums as parent containers**
```swift
@Suite("Parent Suite")
internal enum ParentTests {}
```

✅ **Include "Tests" suffix in EITHER parent OR child, never both**
```swift
// Option 1: Parent has "Tests"
internal enum TypeNameTests {}
extension TypeNameTests {
  struct Category { ... }  // No "Tests"
}

// Option 2: Child has "Tests"
internal enum TypeName {}
extension TypeName {
  struct CategoryTests { ... }  // Has "Tests"
}
```

✅ **One category per extension file**
```swift
// File: TypeNameTests+Initialization.swift - Only Initialization suite
// File: TypeNameTests+Validation.swift - Only Validation suite
```

✅ **Private static test data in suite structs**
```swift
internal struct Category {
  private static let testData = "..."
}
```

✅ **Descriptive suite and test names**
```swift
@Suite("Input Validation and Format Checking")
@Test("Reject input with invalid format")
```

✅ **Async/await for all async operations**
```swift
@Test("Fetch data asynchronously")
internal func fetchDataAsync() async throws {
  let result = try await fetchData()
  #expect(result != nil)
}
```

✅ **#expect() for assertions**
```swift
#expect(value == expected)
#expect(throws: ErrorType.self) { code }
```

✅ **MARK sections for organization**
```swift
// MARK: - Test Data Setup
// MARK: - Initialization Tests
// MARK: - Error Handling Tests
```

✅ **Document suites and tests with comments**
```swift
/// Tests for error handling scenarios.
@Suite("Error Handling")
internal struct ErrorHandling { ... }
```

✅ **Match file names to actual type names**
```swift
// File: TypeNameTests+Category.swift
extension TypeNameTests {
  struct Category { ... }  // ✅ Matches file name
}
```

### Don't

❌ **Use "Tests" in both parent enum and child struct**
```swift
// DON'T DO THIS
internal enum TypeNameTests {}
extension TypeNameTests {
  struct CategoryTests { ... }  // ❌ Redundant "Tests"
}
```

❌ **Put multiple suite structs in one file**
```swift
// DON'T DO THIS - Split into separate files
extension TypeNameTests {
  struct Category1 { ... }
  struct Category2 { ... }  // ❌ Should be in separate file
}
```

❌ **Use classes for test suites**
```swift
// DON'T DO THIS
@Suite("Tests")
internal class MyTests { ... }  // ❌ Use struct

// DO THIS
@Suite("Tests")
internal struct MyTests { ... }  // ✅ Use struct
```

❌ **Share mutable state between tests**
```swift
// DON'T DO THIS
internal struct Tests {
  private var counter = 0  // ❌ Mutable state

  @Test func test1() { counter += 1 }
  @Test func test2() { counter += 1 }  // ❌ Tests depend on order
}
```

❌ **Create deeply nested hierarchies (max 2-3 levels)**
```swift
// DON'T DO THIS
internal enum Level1 {}
extension Level1 {
  enum Level2 {}
}
extension Level1.Level2 {
  enum Level3 {}  // ❌ Too deeply nested
}
```

❌ **Use XCTest patterns**
```swift
// DON'T DO THIS
XCTAssertEqual(a, b)  // ❌ XCTest API
XCTAssertTrue(condition)  // ❌ XCTest API

// DO THIS
#expect(a == b)  // ✅ Swift Testing API
#expect(condition)  // ✅ Swift Testing API
```

❌ **Mismatch file names and type names**
```swift
// File: TypeNameTests+CategoryTests.swift  ❌ Suggests both have "Tests"
extension TypeNameTests {
  struct Category { ... }  // Actual child name doesn't match file name
}

// File: TypeNameTests+Category.swift  ✅ Matches actual names
extension TypeNameTests {
  struct Category { ... }
}
```

## Swift Testing Features

### Suite Attributes

**Basic suite:**
```swift
@Suite("Description")
internal struct MyTests { ... }
```

**Conditional suite:**
```swift
@Suite("Linux-only tests", .enabled(if: os(Linux)))
internal struct LinuxTests { ... }
```

**Tagged suite:**
```swift
@Suite("Slow integration tests", .tags(.slow))
internal struct IntegrationTests { ... }
```

**Multiple attributes:**
```swift
@Suite(
  "Platform-specific performance tests",
  .enabled(if: !DEBUG),
  .tags(.performance)
)
internal struct PerformanceTests { ... }
```

### Test Attributes

**Basic test:**
```swift
@Test("Test description")
internal func testSomething() { ... }
```

**Conditional test:**
```swift
@Test("macOS-only test", .enabled(if: os(macOS)))
internal func testMacOSFeature() { ... }
```

**Tagged test:**
```swift
@Test("Slow network test", .tags(.slow, .network))
internal func testNetworkLatency() async { ... }
```

**Parameterized test:**
```swift
@Test("Validate multiple inputs", arguments: [
  "input1",
  "input2",
  "input3"
])
internal func validateInput(input: String) {
  #expect(Validator.isValid(input))
}
```

**Parameterized test with multiple arguments:**
```swift
@Test(
  "Test with combinations",
  arguments: ["a", "b", "c"],
  [1, 2, 3]
)
internal func testCombinations(string: String, number: Int) {
  #expect(!string.isEmpty)
  #expect(number > 0)
}
```

### Assertions

**Basic expectation:**
```swift
#expect(condition)
```

**Equality expectation:**
```swift
#expect(value == expected)
#expect(value != unexpected)
```

**Boolean expectation:**
```swift
#expect(result)
#expect(!failure)
```

**Optional expectation:**
```swift
let value = try #require(optionalValue)  // Unwrap or fail test
#expect(value != nil)
```

**Error throwing expectation:**
```swift
#expect(throws: ErrorType.self) {
  try throwingFunction()
}

#expect(throws: (any Error).self) {
  try anyErrorFunction()
}
```

**Error NOT throwing expectation:**
```swift
#expect(throws: Never.self) {
  try nonThrowingFunction()
}
```

**Collection expectations:**
```swift
#expect(collection.contains(item))
#expect(collection.isEmpty)
#expect(collection.count == expected)
```

**Custom messages:**
```swift
#expect(value == expected, "Value should equal expected")
```

### Issue Recording

**Record custom issue:**
```swift
if somethingWrong {
  Issue.record("Something went wrong: \(details)")
}
```

**Record issue with source location:**
```swift
Issue.record(
  "Unexpected state",
  sourceLocation: SourceLocation(
    fileID: #fileID,
    line: #line
  )
)
```

### Async Testing

**Basic async test:**
```swift
@Test("Async operation")
internal func testAsync() async {
  let result = await performAsync()
  #expect(result != nil)
}
```

**Async throwing test:**
```swift
@Test("Async throwing operation")
internal func testAsyncThrowing() async throws {
  let result = try await fetchData()
  #expect(result.count > 0)
}
```

**Concurrent async tests:**
```swift
@Test("Multiple async operations")
internal func testConcurrent() async {
  async let result1 = operation1()
  async let result2 = operation2()

  let (r1, r2) = await (result1, result2)
  #expect(r1 != nil && r2 != nil)
}
```

### Custom Tags

Define custom tags for filtering tests:

```swift
extension Tag {
  @Tag static var slow: Self
  @Tag static var network: Self
  @Tag static var integration: Self
  @Tag static var performance: Self
}

@Suite("Network Tests", .tags(.slow, .network))
internal struct NetworkTests { ... }
```

Run tests with specific tags:
```bash
swift test --filter tag:network
swift test --filter tag:slow --skip tag:integration
```

## Migration Guide

### Converting XCTest to Swift Testing

| XCTest | Swift Testing |
|--------|---------------|
| `class FooTests: XCTestCase` | `@Suite("Foo") struct FooTests` |
| `func testSomething()` | `@Test("Something") func something()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertNotEqual(a, b)` | `#expect(a != b)` |
| `XCTAssertTrue(condition)` | `#expect(condition)` |
| `XCTAssertFalse(condition)` | `#expect(!condition)` |
| `XCTAssertNil(value)` | `#expect(value == nil)` |
| `XCTAssertNotNil(value)` | `#expect(value != nil)` |
| `XCTAssertThrowsError` | `#expect(throws:)` |
| `XCTUnwrap(optional)` | `try #require(optional)` |
| `setUp()`/`tearDown()` | `init()`/`deinit` or test-level setup |
| `setUpWithError()`/`tearDownWithError()` | `init() throws`/`deinit` |
| `XCTFail("message")` | `Issue.record("message")` |
| `addTeardownBlock { }` | Use `defer` in test method |

### Migration Steps

1. **Change class to struct:**
```swift
// Before (XCTest)
class MyTests: XCTestCase { }

// After (Swift Testing)
@Suite("My Tests")
struct MyTests { }
```

2. **Add @Test attribute:**
```swift
// Before (XCTest)
func testFeature() { }

// After (Swift Testing)
@Test("Feature works correctly")
func testFeature() { }
```

3. **Replace assertions:**
```swift
// Before (XCTest)
XCTAssertEqual(value, expected)

// After (Swift Testing)
#expect(value == expected)
```

4. **Handle setup/teardown:**
```swift
// Before (XCTest)
override func setUp() {
  super.setUp()
  // setup code
}

// After (Swift Testing)
init() {
  // setup code
}
```

5. **Convert async tests:**
```swift
// Before (XCTest)
func testAsync() {
  let expectation = expectation(description: "...")
  Task {
    await doWork()
    expectation.fulfill()
  }
  waitForExpectations(timeout: 5)
}

// After (Swift Testing)
@Test("Async work")
func testAsync() async {
  await doWork()
}
```

6. **Replace test expectations with async/await:**
```swift
// Before (XCTest)
func testNetworkCall() {
  let exp = expectation(description: "Network call")
  networkManager.fetchData { result in
    XCTAssertNotNil(result)
    exp.fulfill()
  }
  wait(for: [exp], timeout: 5.0)
}

// After (Swift Testing)
@Test("Network call")
func testNetworkCall() async throws {
  let result = try await networkManager.fetchData()
  #expect(result != nil)
}
```

## Quick Reference Card

### Naming Convention

```
✅ Correct patterns:
TypeNameTests + Category          → TypeNameTests+Category.swift
TypeName + CategoryTests          → TypeName+CategoryTests.swift

❌ Avoid:
TypeNameTests + CategoryTests     → Redundant "Tests"
```

### File Structure Template (Pattern A: Parent Has "Tests")

```swift
// File: TypeNameTests.swift
import Testing

/// Test suite for TypeName functionality.
@Suite("Type Name")
internal enum TypeNameTests {}
```

```swift
// File: TypeNameTests+Category.swift
import Testing

extension TypeNameTests {
  /// Tests for TypeName category functionality.
  @Suite("Category Description")
  internal struct Category {
    // MARK: - Test Data Setup

    /// Test data description.
    private static let testData = ...

    // MARK: - Tests

    @Test("Test description")
    internal func testSomething() {
      let result = performOperation(Self.testData)
      #expect(result == expected)
    }
  }
}
```

```swift
// File: TypeName+TestHelpers.swift
import Testing

extension TypeName {
  /// Test helper description.
  internal func testHelper() async -> Bool {
    do {
      try await operation()
      return true
    } catch {
      return false
    }
  }
}
```

### Common MARK Sections

```swift
// MARK: - Test Data Setup
// MARK: - Initialization Tests
// MARK: - Functional Tests
// MARK: - Error Handling Tests
// MARK: - Concurrent Tests
// MARK: - Edge Cases
// MARK: - Performance Tests
// MARK: - Integration Tests
```

### Frequently Used Patterns

**Standalone (Simple):**
```swift
@Suite("Type Name")
internal struct TypeNameTests {
  @Test("Test description")
  internal func testSomething() { ... }
}
```

**Hierarchical (Two Level):**
```swift
// Parent
@Suite("Type Name")
internal enum TypeNameTests {}

// Child
extension TypeNameTests {
  @Suite("Category")
  internal struct Category { ... }
}
```

**Test Helpers:**
```swift
// File: TypeName+TestHelpers.swift
extension TypeName {
  internal func testHelper() { ... }
}
```

**Private Static Test Data:**
```swift
internal struct Category {
  private static let testData = ...

  @Test("Use test data")
  internal func testWithData() {
    let data = Self.testData
  }
}
```

### Swift Testing Cheat Sheet

**Assertions:**
```swift
#expect(condition)                    // Basic
#expect(value == expected)            // Equality
#expect(throws: Error.self) { code }  // Throws
let value = try #require(optional)    // Unwrap
```

**Suite Attributes:**
```swift
@Suite("Name")                        // Basic
@Suite("Name", .enabled(if: cond))    // Conditional
@Suite("Name", .tags(.slow))          // Tagged
```

**Test Attributes:**
```swift
@Test("Name")                         // Basic
@Test("Name", .enabled(if: cond))     // Conditional
@Test("Name", arguments: [...])       // Parameterized
```

**Async Testing:**
```swift
@Test("Async test")
internal func testAsync() async {
  let result = await operation()
  #expect(result != nil)
}
```

## Real-World Example: MistKit

This organizational pattern is used in the MistKit project for organizing CloudKit Web Services tests. Here's how MistKit applies these principles:

**Chosen convention**: Parent has "Tests" suffix (Pattern A)

**Example hierarchy:**
```
Tests/MistKitTests/
├── Authentication/
│   └── WebAuth/
│       ├── WebAuthTokenManagerTests.swift           # Parent enum
│       ├── WebAuthTokenManagerTests+Basic.swift     # Basic tests
│       ├── WebAuthTokenManagerTests+Validation.swift # Validation tests
│       └── WebAuthTokenManager+TestHelpers.swift    # Test helpers
├── Core/
│   └── FieldValue/
│       └── FieldValueTests.swift                    # Simple pattern
└── Storage/
    └── InMemory/
        └── InMemoryTokenStorage/
            ├── InMemoryTokenStorageTests.swift      # Parent enum
            └── InMemoryTokenStorageTests+Expiration.swift # Expiration tests
```

This demonstrates how the pattern scales from simple utilities (FieldValue) to complex managers (WebAuthTokenManager) in a real Swift package.

## Conclusion

This hierarchical test organization pattern provides:

- **Clear structure**: Logical grouping with enums and structs
- **Scalability**: Easy to add new test categories
- **Consistency**: Standardized naming and file organization
- **Discoverability**: Predictable location for tests
- **Maintainability**: Isolated test categories for focused changes

**Key takeaways:**
1. **Never use "Tests" in both parent and child** - Choose one location
2. **One category per extension file** - Keep files focused
3. **Private static test data** - Immutable data in suite structs
4. **Use MARK sections** - Organize tests within files
5. **Test helpers in separate files** - Extend production types

**Choose a pattern for your project:**
- Pattern A: Parent has "Tests" (e.g., `UserManagerTests+Validation`)
- Pattern B: Child has "Tests" (e.g., `UserManager+ValidationTests`)

Both patterns are equally valid. The important thing is to choose one and apply it consistently throughout your test suite. Document your choice in your project's contribution guidelines to ensure all contributors follow the same convention.
