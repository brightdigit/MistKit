# Support Swift Testing Framework Detection for WASM Builds

## Problem Description

When running WASM tests with `swift-build`, tests using the Swift Testing framework (`import Testing`) are not being discovered and executed, resulting in "0 tests" output:

```
Searching for Wasm test binaries...
Found test binaries:
.build/wasm32-unknown-wasip1/debug/MistKitPackageTests.xctest

Running tests with WasmKit: .build/wasm32-unknown-wasip1/debug/MistKitPackageTests.xctest
Test Suite 'All tests' started at 1970-01-01 00:03:45.952
Test Suite 'debug.xctest' started at 1970-01-01 00:03:46.013
Test Suite 'debug.xctest' passed at 1970-01-01 00:03:46.014
     Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
```

## Root Cause

The action currently runs WASM test binaries without specifying the testing library:

```bash
wasmkit run MistKitPackageTests.xctest
```

However, Swift Testing tests on WASM require an explicit flag:

```bash
wasmkit run MistKitPackageTests.xctest -- --testing-library swift-testing
```

When this flag is provided, tests execute correctly:

```
◇ Test run started.
↳ Testing Library Version: 6.2.3 (48a471ab313e858)
↳ Target Platform: wasm32-unknown-wasip
◇ Suite "Token Manager - Authentication Method" started.
✔ Test "AuthenticationMethod computed properties" passed after 0.016 seconds.
...
Test run with 487 tests passed after 28.891 seconds.
```

## Background: WASM Testing Requirements

Unlike native platforms where Swift Package Manager auto-detects the testing framework, WASM requires explicit specification:

- **Swift Testing tests** (`@Test`, `@Suite`): Require `--testing-library swift-testing`
- **XCTest tests** (`XCTestCase` subclasses): Run without flag or with `--testing-library xctest`
- **Mixed tests**: Currently problematic on WASM (would require multiple test runs)

Reference: [Swift Testing WASI Documentation](https://github.com/swiftlang/swift-testing/blob/main/Documentation/WASI.md)

## Proposed Solution

Add automatic testing framework detection with an optional override parameter.

### New Action Parameters

```yaml
inputs:
  wasm-testing-library:
    description: 'Testing framework for WASM tests (auto, swift-testing, xctest, both)'
    required: false
    default: 'auto'

  wasm-swift-test-flags:
    description: 'Additional flags to pass to WASM test runner'
    required: false
```

### Detection Algorithm

When `wasm-testing-library: 'auto'` (default):

1. **Scan test sources** for imports:
   ```bash
   # Check for Swift Testing
   grep -r "import Testing" Tests/ --include="*.swift" -q
   HAS_SWIFT_TESTING=$?

   # Check for XCTest
   grep -r "import XCTest" Tests/ --include="*.swift" -q
   HAS_XCTEST=$?
   ```

2. **Determine testing library**:
   - If only Swift Testing found → Use `--testing-library swift-testing`
   - If only XCTest found → Use `--testing-library xctest` (or no flag)
   - If both found → Use `both` mode (run twice)
   - If neither found → Use `--testing-library swift-testing` (Swift 6+ default)

3. **Execute tests accordingly**:
   ```bash
   case $TESTING_LIBRARY in
     swift-testing)
       wasmkit run $TEST_BINARY -- --testing-library swift-testing
       ;;
     xctest)
       wasmkit run $TEST_BINARY -- --testing-library xctest
       ;;
     both)
       echo "Running Swift Testing tests..."
       wasmkit run $TEST_BINARY -- --testing-library swift-testing
       echo "Running XCTest tests..."
       wasmkit run $TEST_BINARY -- --testing-library xctest
       ;;
   esac
   ```

### Manual Override Examples

For projects that know their testing framework:

```yaml
# Force Swift Testing
- uses: brightdigit/swift-build@1.5.0-beta.2
  with:
    type: wasm
    wasm-testing-library: swift-testing

# Force XCTest
- uses: brightdigit/swift-build@1.5.0-beta.2
  with:
    type: wasm
    wasm-testing-library: xctest

# Force both (run twice)
- uses: brightdigit/swift-build@1.5.0-beta.2
  with:
    type: wasm
    wasm-testing-library: both

# Pass additional test flags
- uses: brightdigit/swift-build@1.5.0-beta.2
  with:
    type: wasm
    wasm-swift-test-flags: --filter "TestSuiteName"
```

## Alternative Approach: Package Manifest Detection

Instead of scanning sources, parse `Package.swift` for test target dependencies:

```swift
.testTarget(
  name: "MyTests",
  dependencies: ["MyPackage", "Testing"]  // Swift Testing
)

.testTarget(
  name: "MyTests",
  dependencies: ["MyPackage", "XCTest"]   // XCTest
)
```

This approach is more reliable but requires parsing Swift code or running SPM commands.

## Benefits

1. **Backward compatible**: Default `auto` mode works for existing projects
2. **Zero configuration**: Automatically detects and uses correct framework
3. **Future-proof**: Supports mixed testing scenarios
4. **Performance**: Can skip tests with explicit `wasm-testing-library: none`
5. **Flexibility**: Manual override for edge cases

## Implementation Checklist

- [ ] Add new input parameters to `action.yml`
- [ ] Implement testing framework detection logic
- [ ] Update WASM test execution script to pass appropriate flags
- [ ] Add tests for auto-detection (Swift Testing, XCTest, mixed, none)
- [ ] Update README with new parameters and examples
- [ ] Add migration guide for existing users
- [ ] Consider adding warning when mixed tests detected

## Related Issues

- #72: Swap Wasmtime for WasmKit (completed)
- #30: Add WASM Support (foundation)
- #68: WASM code coverage is not supported (separate concern)

## Testing

This issue was discovered while testing [MistKit](https://github.com/brightdigit/MistKit) which uses Swift Testing exclusively. The tests work correctly when run manually with:

```bash
swift build --swift-sdk swift-6.2.3-RELEASE_wasm --build-tests \
  -Xcc -D_WASI_EMULATED_SIGNAL \
  -Xcc -D_WASI_EMULATED_MMAN \
  -Xlinker -lwasi-emulated-signal \
  -Xlinker -lwasi-emulated-mman

wasmkit run .build/wasm32-unknown-wasip1/debug/MistKitPackageTests.xctest -- --testing-library swift-testing
```

Result: All 487 tests pass successfully.

## Additional Context

- Swift Testing became the default testing framework in Swift 6.0
- Many modern projects are migrating from XCTest to Swift Testing
- WASM support is critical for cross-platform Swift development
- This issue affects any project using Swift Testing with WASM builds

## Questions for Maintainers

1. Is source scanning an acceptable approach, or would you prefer Package.swift parsing?
2. Should the default be `auto` or require explicit configuration?
3. For mixed tests, should we run both or fail with an error message?
4. Should we emit a GitHub Actions warning when mixed tests are detected?

---

**Environment:**
- swift-build: 1.5.0-beta.2
- Swift: 6.2.3
- WasmKit: 0.1.6
- Platform: Ubuntu (GitHub Actions)
