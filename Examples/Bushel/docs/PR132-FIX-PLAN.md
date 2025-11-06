# PR #132 Code Review Fix Plan

**Date:** 2025-01-06
**PR:** https://github.com/brightdigit/MistKit/pull/132
**Review:** https://github.com/brightdigit/MistKit/pull/132#pullrequestreview-3428383976

## Executive Summary

This document provides a comprehensive plan to address code review feedback from PR #132, which adds the Bushel example application to MistKit. While the PR has been approved for merge as an educational example (rated 4/5 stars), several production-quality improvements are needed across type conversions, error handling, security, and code quality.

### Scope

- ✅ **In Scope**: Type conversions, error handling, security, refactoring, validation, batch operations, documentation, performance
- ❌ **Out of Scope**: Test coverage (separate effort), breaking API changes, new features

### Priority Summary

| Priority | Focus Areas | Timeline |
|----------|-------------|----------|
| **P0** | Type conversions, error handling, security | Week 1 |
| **P1** | Refactoring, validation | Week 2 |
| **P2** | Batch operations, documentation, performance | Week 3 |

---

## Issue 1: Type Conversion Inconsistencies

**Priority:** P0 (Critical)
**Effort:** Medium (3-5 days)
**Risk:** High (data corruption, runtime crashes)

### Problem Statement

The codebase has inconsistent boolean representation and unsafe type conversions that could lead to data loss or runtime errors.

### Specific Issues

#### 1.1 Boolean/Int64 Inconsistency

**Files:**
- `CloudKitFieldMapping.swift:86` - Has `.boolean()` method
- `RecordBuilder.swift:142` - Uses int64 representation for booleans

**Current Code (RecordBuilder.swift:70-75):**
```swift
// isSigned stored as int64 (1 = true, 0 = false)
if let isSigned = record.isSigned {
    builder.fields["isSigned"] = .int64(isSigned ? 1 : 0)
}
```

**Current Code (CloudKitFieldMapping.swift:34-36):**
```swift
public static func boolean(_ value: Bool) -> FieldValue {
    .int64(value ? 1 : 0)
}
```

**Issue:** CloudKitFieldMapping has a `.boolean()` helper that's never used. RecordBuilder manually implements the same logic inline.

**Solution:**
1. Standardize on using CloudKitFieldMapping.boolean() everywhere
2. Add reverse conversion: `extension FieldValue { var boolValue: Bool? { ... } }`
3. Document why int64 is used (CloudKit Web Services doesn't support native boolean)

**After:**
```swift
// RecordBuilder.swift
if let isSigned = record.isSigned {
    builder.fields["isSigned"] = .boolean(isSigned)
}

// CloudKitFieldMapping.swift - Add extraction
extension FieldValue {
    public var boolValue: Bool? {
        guard case .int64(let value) = self else { return nil }
        return value != 0
    }
}
```

#### 1.2 Unsafe Int/Int64 Conversions

**File:** `RecordBuilder.swift:85-90`

**Current Code:**
```swift
// Potential overflow on 32-bit systems
if let buildSize = record.buildSize {
    builder.fields["buildSize"] = .int64(Int64(buildSize))
}
```

**Issue:** Converting `Int` to `Int64` is safe, but converting back (if ever needed) could overflow on 32-bit systems.

**Solution:**
1. Use `Int64` throughout the model layer for sizes
2. Add safe conversion helper with overflow checking

**After:**
```swift
// Models/RestoreImageRecord.swift
public struct RestoreImageRecord: Sendable, Codable {
    public let buildSize: Int64?  // Changed from Int?
    // ... other fields
}

// CloudKitFieldMapping.swift - Add safe conversion
public static func safeInt(_ value: Int64) -> Int? {
    guard value <= Int.max, value >= Int.min else { return nil }
    return Int(value)
}
```

#### 1.3 Optional Field Handling

**Files:** `RecordBuilder.swift:60-120`

**Issue:** Inconsistent pattern for optional fields - some use `if let`, others use optional chaining

**Solution:**
1. Standardize on `if let` for all optional fields
2. Add documentation explaining when nil means "not set" vs "explicitly null"

### Acceptance Criteria

- [ ] All boolean fields use `CloudKitFieldMapping.boolean()`
- [ ] Add `FieldValue.boolValue` extension for extraction
- [ ] Model layer uses `Int64` for all numeric IDs and sizes
- [ ] Add safe conversion helpers with overflow checking
- [ ] Document boolean int64 representation in CloudKitFieldMapping
- [ ] Consistent optional field handling throughout RecordBuilder
- [ ] No unsafe type conversions remain

### Testing Considerations (Future)

- Unit test boolean round-trip conversion
- Test Int64 overflow scenarios
- Test optional field handling for nil vs missing

---

## Issue 2: Error Handling and Recovery

**Priority:** P0 (Critical)
**Effort:** Large (5-7 days)
**Risk:** Medium (poor debugging experience, cascading failures)

### Problem Statement

Error handling lacks granularity and recovery mechanisms, making debugging difficult and allowing transient failures to become permanent.

### Specific Issues

#### 2.1 Generic "Unknown" RecordType on Failure

**File:** `BushelCloudKitService.swift:144`

**Current Code:**
```swift
// In error handling
recordType = "Unknown"  // Loses context about what failed
```

**Issue:** When an operation fails, the recordType is set to "Unknown" which:
- Loses information about which record type caused the failure
- Makes debugging impossible
- Silently swallows the actual error

**Solution:**
1. Create detailed error types with operation context
2. Never use sentinel values like "Unknown"
3. Propagate errors with full context

**After:**
```swift
public enum BushelCloudKitError: LocalizedError {
    case batchOperationFailed(
        recordType: String,
        failedOperations: [(recordName: String, error: Error)],
        successfulCount: Int
    )

    public var errorDescription: String? {
        switch self {
        case .batchOperationFailed(let type, let failed, let succeeded):
            return """
            Batch operation for \(type) partially failed:
            - Successful: \(succeeded)
            - Failed: \(failed.count)
            Failed records: \(failed.map(\.recordName).joined(separator: ", "))
            """
        }
    }
}
```

#### 2.2 No Retry Logic for Transient Failures

**Files:**
- `BushelCloudKitService.swift:200-250` (batch operations)
- `DataSourcePipeline.swift:100-150` (fetcher calls)

**Current Behavior:** Single attempt, fail immediately

**Solution:**
Implement exponential backoff retry with configurable attempts

**After:**
```swift
// Configuration/FetchConfiguration.swift
public struct RetryConfiguration: Sendable, Codable {
    public let maxAttempts: Int
    public let initialDelay: Duration
    public let maxDelay: Duration
    public let multiplier: Double

    public static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: .seconds(1),
        maxDelay: .seconds(30),
        multiplier: 2.0
    )
}

// CloudKit/RetryPolicy.swift (new file)
public actor RetryPolicy {
    private let configuration: RetryConfiguration

    public func execute<T>(
        operation: String,
        attempt: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = configuration.initialDelay

        for attemptNumber in 1...configuration.maxAttempts {
            do {
                return try await attempt()
            } catch {
                lastError = error

                if attemptNumber == configuration.maxAttempts {
                    break
                }

                // Check if error is retryable
                guard isRetryable(error) else {
                    throw error
                }

                logger.warning("Attempt \(attemptNumber) failed for \(operation), retrying after \(delay)...")
                try await Task.sleep(for: delay)

                delay = min(
                    Duration.seconds(Int(delay.components.seconds) * Int(configuration.multiplier)),
                    configuration.maxDelay
                )
            }
        }

        throw lastError!
    }

    private func isRetryable(_ error: Error) -> Bool {
        // Network timeouts, 5xx errors, rate limits are retryable
        // 4xx client errors are not retryable
        // TODO: Implement based on MistKit error types
        true
    }
}
```

#### 2.3 HTTPHeaderHelpers Silent Failures

**File:** `DataSources/HTTPHeaderHelpers.swift`

**Issue:** Last-Modified parsing failures are ignored silently

**Solution:**
1. Add logging for parse failures
2. Return nil explicitly with warning
3. Add unit tests for date parsing edge cases

**After:**
```swift
extension DataSourceMetadata {
    static func from(headers: [String: String]) -> Self? {
        guard let lastModified = headers["Last-Modified"] else {
            return nil
        }

        guard let date = Self.parseHTTPDate(lastModified) else {
            logger.warning("Failed to parse Last-Modified header: \(lastModified)")
            return nil
        }

        return DataSourceMetadata(lastFetch: date, recordCount: 0)
    }
}
```

### Acceptance Criteria

- [ ] Remove all "Unknown" sentinel values
- [ ] Create comprehensive error types with operation context
- [ ] Implement RetryPolicy actor with exponential backoff
- [ ] Add retry configuration to FetchConfiguration
- [ ] Log all error cases with full context
- [ ] Add isRetryable logic based on error types
- [ ] HTTPHeaderHelpers logs parse failures
- [ ] Batch operations report per-record failures
- [ ] All network operations use retry policy

### Migration Guide

```swift
// Before
let records = try await service.sync(records)

// After
let result = try await service.sync(records)
switch result {
case .success(let count):
    logger.info("Successfully synced \(count) records")
case .partialSuccess(let succeeded, let failed):
    logger.warning("Partial sync: \(succeeded) succeeded, \(failed.count) failed")
    for failure in failed {
        logger.error("Failed to sync \(failure.recordName): \(failure.error)")
    }
case .failure(let error):
    logger.error("Sync failed: \(error)")
    throw error
}
```

---

## Issue 3: Security and Validation

**Priority:** P0 (Critical)
**Effort:** Small (1-2 days)
**Risk:** High (credential exposure)

### Problem Statement

Private key file handling lacks security validations that could expose credentials.

### Specific Issues

#### 3.1 Missing File Permission Validation

**File:** `BushelCloudKitService.swift:32-41`

**Current Code:**
```swift
private static func loadPrivateKey(from path: String) throws -> String {
    let keyPath = NSString(string: path).expandingTildeInPath
    let url = URL(fileURLWithPath: keyPath)

    guard FileManager.default.fileExists(atPath: keyPath) else {
        throw BushelCloudKitError.keyFileNotFound(path: path)
    }

    return try String(contentsOf: url, encoding: .utf8)
}
```

**Issue:** No permission checking - key file could be world-readable

**Solution:**
Add permission validation with warning/error

**After:**
```swift
private static func loadPrivateKey(from path: String) throws -> String {
    let keyPath = NSString(string: path).expandingTildeInPath
    let url = URL(fileURLWithPath: keyPath)

    guard FileManager.default.fileExists(atPath: keyPath) else {
        throw BushelCloudKitError.keyFileNotFound(path: path)
    }

    // Validate file permissions
    let attributes = try FileManager.default.attributesOfItem(atPath: keyPath)
    if let posixPermissions = attributes[.posixPermissions] as? NSNumber {
        let permissions = posixPermissions.uint16Value
        let ownerOnly = permissions & 0o077 == 0  // No group/other permissions

        if !ownerOnly {
            let permString = String(format: "%o", permissions)
            logger.warning("""
            ⚠️  SECURITY WARNING: Private key file has insecure permissions: \(permString)
            Recommended: Run 'chmod 600 \(keyPath)'
            """)

            #if DEBUG
            // Allow in debug mode with warning
            #else
            // Fail in production
            throw BushelCloudKitError.insecureKeyFilePermissions(
                path: path,
                permissions: permString
            )
            #endif
        }
    }

    return try String(contentsOf: url, encoding: .utf8)
}

// Add to BushelCloudKitError
case insecureKeyFilePermissions(path: String, permissions: String)

public var errorDescription: String? {
    switch self {
    case .insecureKeyFilePermissions(let path, let perms):
        return """
        Private key file has insecure permissions: \(perms)
        File: \(path)
        Fix: chmod 600 \(path)
        """
    // ... other cases
    }
}
```

#### 3.2 Logging Redaction Validation

**File:** `Supporting Files/Logger.swift`

**Current Issue:** Regex pattern for redacting sensitive data may be too broad or miss edge cases

**Solution:**
1. Audit current redaction patterns
2. Add tests for redaction effectiveness
3. Document what gets redacted and why

**Implementation:**
```swift
// Logger.swift - Enhanced redaction
public struct SensitiveDataRedactor {
    // Redact CloudKit tokens (typically 40+ hex characters)
    private static let tokenPattern = try! NSRegularExpression(
        pattern: "[a-fA-F0-9]{40,}",
        options: []
    )

    // Redact API keys in headers
    private static let headerPattern = try! NSRegularExpression(
        pattern: "(?i)(authorization|api-key|x-api-key):\\s*[^\\s]+",
        options: []
    )

    public static func redact(_ message: String) -> String {
        var redacted = message

        // Redact tokens
        redacted = tokenPattern.stringByReplacingMatches(
            in: redacted,
            range: NSRange(redacted.startIndex..., in: redacted),
            withTemplate: "[REDACTED-TOKEN]"
        )

        // Redact auth headers
        redacted = headerPattern.stringByReplacingMatches(
            in: redacted,
            range: NSRange(redacted.startIndex..., in: redacted),
            withTemplate: "$1: [REDACTED]"
        )

        return redacted
    }
}
```

### Acceptance Criteria

- [ ] Validate private key file permissions (600 or stricter)
- [ ] Warn in debug mode, error in production for insecure permissions
- [ ] Add BushelCloudKitError.insecureKeyFilePermissions case
- [ ] Audit and document logging redaction patterns
- [ ] Add SensitiveDataRedactor with comprehensive patterns
- [ ] Update README with security best practices section

### Documentation Additions

Add to README.md:

```markdown
## Security Best Practices

### Private Key Protection

Bushel requires a CloudKit Server-to-Server key for authentication. Protect this key:

1. **File Permissions**: Set restrictive permissions
   ```bash
   chmod 600 /path/to/AuthKey_KEYID.p8
   ```

2. **Storage Location**: Store outside version control
   ```bash
   # ✅ Good
   ~/Library/Mobile Documents/com~apple~CloudDocs/Keys/
   ~/.ssh/

   # ❌ Bad
   /path/to/project/keys/
   ```

3. **Environment Variables**: Use environment variables for CI/CD
   ```bash
   export CLOUDKIT_KEY_FILE=/secure/path/AuthKey.p8
   export CLOUDKIT_KEY_ID=ABCD1234
   ```

4. **Logging**: Bushel automatically redacts sensitive data in logs, but always review logs before sharing.
```

---

## Issue 4: Refactor Complex Methods

**Priority:** P1 (High)
**Effort:** Medium (3-4 days)
**Risk:** Low (internal refactoring)

### Problem Statement

Several methods have deep nesting and multiple responsibilities, making them hard to test and maintain.

### Specific Issues

#### 4.1 RecordBuilder Field Mapping Complexity

**File:** `RecordBuilder.swift:60-140`

**Current Structure:**
- Single method builds entire record
- Deep nesting (3-4 levels)
- Mixed concerns (validation, conversion, assignment)

**Refactoring Plan:**

**After:**
```swift
// RecordBuilder.swift - Extracted helpers
extension RecordBuilder {
    mutating func addRestoreImageFields(_ record: RestoreImageRecord) {
        addRequiredFields(record)
        addOptionalFields(record)
        addSignatureField(record)
    }

    private mutating func addRequiredFields(_ record: RestoreImageRecord) {
        fields["recordName"] = .string(record.recordName)
        fields["buildNumber"] = .string(record.buildNumber)
        fields["version"] = .string(record.version)
    }

    private mutating func addOptionalFields(_ record: RestoreImageRecord) {
        if let buildSize = record.buildSize {
            fields["buildSize"] = .int64(buildSize)
        }

        if let releaseDate = record.releaseDate {
            fields["releaseDate"] = .date(releaseDate)
        }

        // ... other optional fields
    }

    private mutating func addSignatureField(_ record: RestoreImageRecord) {
        guard let isSigned = record.isSigned else { return }
        fields["isSigned"] = .boolean(isSigned)
    }
}
```

#### 4.2 DataSourcePipeline isSigned Merge Logic

**File:** `DataSourcePipeline.swift:395-438`

**Current Code:** 44-line method with complex conditional logic

**Refactoring Plan:**

**After:**
```swift
// DataSourcePipeline.swift - Extract strategy
private struct SignatureMergeStrategy {
    /// MESU is authoritative for signature status
    private static let authoritativeSources: Set<String> = ["MESU"]

    static func merge(
        existing: Bool?,
        new: Bool,
        newSource: String,
        existingSource: String?,
        newTimestamp: Date,
        existingTimestamp: Date?
    ) -> Bool {
        // MESU is always trusted
        if authoritativeSources.contains(newSource) {
            return new
        }

        // If existing is from MESU, keep it
        if let existingSource, authoritativeSources.contains(existingSource) {
            return existing ?? false
        }

        // Use most recent
        guard let existingTimestamp, let existing else {
            return new
        }

        return newTimestamp > existingTimestamp ? new : existing
    }
}

// Usage
extension DataSourcePipeline {
    private func mergeRestoreImage(
        existing: RestoreImageRecord,
        new: RestoreImageRecord
    ) -> RestoreImageRecord {
        let mergedIsSigned = SignatureMergeStrategy.merge(
            existing: existing.isSigned,
            new: new.isSigned ?? false,
            newSource: new.dataSource,
            existingSource: existing.dataSource,
            newTimestamp: new.sourceUpdatedAt ?? .distantPast,
            existingTimestamp: existing.sourceUpdatedAt
        )

        // ... merge other fields
    }
}
```

#### 4.3 Duplicated Type Conversion Logic

**Files:**
- `CloudKitFieldMapping.swift` - Conversion utilities
- `RecordBuilder.swift` - Inline conversions
- `FieldValueExtensions.swift` - Extraction utilities

**Issue:** Same conversion logic repeated in multiple places

**Solution:**
Consolidate into single source of truth

**After:**
```swift
// CloudKitFieldMapping.swift - Complete conversion layer
public enum CloudKitFieldMapping {
    // MARK: - Swift to FieldValue
    public static func fieldValue(from bool: Bool) -> FieldValue {
        .int64(bool ? 1 : 0)
    }

    public static func fieldValue(from int: Int64) -> FieldValue {
        .int64(int)
    }

    public static func fieldValue(from double: Double) -> FieldValue {
        .double(double)
    }

    public static func fieldValue(from string: String) -> FieldValue {
        .string(string)
    }

    public static func fieldValue(from date: Date) -> FieldValue {
        .date(date)
    }

    // MARK: - FieldValue to Swift
    public static func bool(from fieldValue: FieldValue) -> Bool? {
        guard case .int64(let value) = fieldValue else { return nil }
        return value != 0
    }

    public static func int64(from fieldValue: FieldValue) -> Int64? {
        guard case .int64(let value) = fieldValue else { return nil }
        return value
    }

    // ... other extractors
}

// RecordBuilder.swift - Use mappings
if let isSigned = record.isSigned {
    fields["isSigned"] = CloudKitFieldMapping.fieldValue(from: isSigned)
}
```

### Acceptance Criteria

- [ ] RecordBuilder methods have max 3 levels of nesting
- [ ] Extract field addition into separate methods by category
- [ ] SignatureMergeStrategy extracted with clear documentation
- [ ] CloudKitFieldMapping is single source for all conversions
- [ ] Remove all inline conversion logic
- [ ] Add documentation for complex algorithms
- [ ] Each method has single responsibility

---

## Issue 5: Field and Reference Validation

**Priority:** P1 (High)
**Effort:** Medium (3-4 days)
**Risk:** Medium (runtime CloudKit errors)

### Problem Statement

Missing validation allows invalid data to reach CloudKit, causing sync failures that could be caught earlier.

### Specific Issues

#### 5.1 Reference Field Validation

**File:** `RecordBuilder.swift:95-100` (XcodeVersion records)

**Current Code:**
```swift
// References swiftVersion without checking if it exists
if let swiftVersionRef = record.defaultSwiftVersion {
    builder.fields["defaultSwiftVersion"] = .reference(swiftVersionRef)
}
```

**Issue:** If referenced Swift version doesn't exist in CloudKit, sync will fail

**Solution:**
Add reference validation layer

**After:**
```swift
// CloudKit/ReferenceValidator.swift (new file)
public actor ReferenceValidator {
    private var existingRecords: Set<String> = []

    func addExistingRecord(_ recordName: String) {
        existingRecords.insert(recordName)
    }

    func validate(reference: String, type: String) throws {
        guard existingRecords.contains(reference) else {
            throw ValidationError.invalidReference(
                recordName: reference,
                recordType: type
            )
        }
    }
}

// SyncEngine.swift - Use validator
private let referenceValidator = ReferenceValidator()

func syncAll() async throws {
    // First, sync SwiftVersions and track their names
    let swiftRecords = try await syncSwiftVersions()
    for record in swiftRecords {
        await referenceValidator.addExistingRecord(record.recordName)
    }

    // Then sync XcodeVersions with validation
    try await syncXcodeVersions(withValidator: referenceValidator)
}

// RecordBuilder.swift - Validate references
mutating func addXcodeFields(
    _ record: XcodeVersionRecord,
    validator: ReferenceValidator
) async throws {
    // ... other fields

    if let swiftRef = record.defaultSwiftVersion {
        try await validator.validate(reference: swiftRef, type: "SwiftVersion")
        fields["defaultSwiftVersion"] = .reference(swiftRef)
    }
}
```

#### 5.2 Record Name Validation

**Files:** All RecordBuilder usage

**Issue:** No validation that record names meet CloudKit requirements:
- Max 255 characters
- Valid characters only
- Not empty

**Solution:**
```swift
// CloudKit/RecordNameValidator.swift (new file)
public struct RecordNameValidator {
    private static let maxLength = 255
    private static let validPattern = try! NSRegularExpression(
        pattern: "^[a-zA-Z0-9._-]+$",
        options: []
    )

    public static func validate(_ name: String) throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyRecordName
        }

        guard name.count <= maxLength else {
            throw ValidationError.recordNameTooLong(
                name: name,
                length: name.count,
                maxLength: maxLength
            )
        }

        let range = NSRange(name.startIndex..., in: name)
        guard validPattern.firstMatch(in: name, range: range) != nil else {
            throw ValidationError.invalidRecordNameCharacters(name: name)
        }
    }
}

// RecordBuilder.swift - Validate on creation
public init(recordType: String, recordName: String) throws {
    try RecordNameValidator.validate(recordName)
    self.recordType = recordType
    self.fields = ["recordName": .string(recordName)]
}
```

#### 5.3 Required Field Validation

**File:** `RecordBuilder.swift`

**Solution:**
```swift
// Models/CloudKitSchema.swift (new file)
public protocol CloudKitRecord {
    static var requiredFields: Set<String> { get }
    static var recordType: String { get }

    func validate() throws
}

extension RestoreImageRecord: CloudKitRecord {
    public static let requiredFields: Set<String> = [
        "recordName", "buildNumber", "version"
    ]

    public static let recordType = "RestoreImage"

    public func validate() throws {
        guard !recordName.isEmpty else {
            throw ValidationError.missingRequiredField("recordName")
        }
        guard !buildNumber.isEmpty else {
            throw ValidationError.missingRequiredField("buildNumber")
        }
        guard !version.isEmpty else {
            throw ValidationError.missingRequiredField("version")
        }
    }
}

// RecordBuilder.swift - Validate before building
public func build<T: CloudKitRecord>(from record: T) throws -> RecordOperation {
    try record.validate()
    // ... build record
}
```

### Acceptance Criteria

- [ ] ReferenceValidator actor tracks existing records
- [ ] All reference fields validated before sync
- [ ] RecordNameValidator checks length and characters
- [ ] CloudKitRecord protocol defines required fields
- [ ] All models implement validate() method
- [ ] Validation errors provide clear messages
- [ ] SyncEngine validates in dependency order

---

## Issue 6: Batch Operation Improvements

**Priority:** P2 (Medium)
**Effort:** Medium (2-3 days)
**Risk:** Low (quality of life)

### Problem Statement

Batch operations lack flexibility and resilience for large-scale syncs.

### Implementation Plan

#### 6.1 Configurable Batch Size

**Files:**
- `Configuration/FetchConfiguration.swift`
- `BushelCloudKitService.swift`

**After:**
```swift
// FetchConfiguration.swift
public struct BatchConfiguration: Sendable, Codable {
    public let restoreImages: Int
    public let xcodeVersions: Int
    public let swiftVersions: Int

    public static let `default` = BatchConfiguration(
        restoreImages: 200,  // CloudKit limit
        xcodeVersions: 100,   // Smaller for testing
        swiftVersions: 50     // Fewest records
    )
}

public struct FetchConfiguration {
    public var batchSizes: BatchConfiguration
    // ... other config
}

// BushelCloudKitService.swift
func sync(
    _ records: [RestoreImageRecord],
    batchSize: Int = 200
) async throws -> SyncResult {
    let batches = records.chunked(into: batchSize)
    // ... process batches
}
```

#### 6.2 Progress Callbacks

**After:**
```swift
// CloudKit/SyncProgress.swift (new file)
public struct SyncProgress: Sendable {
    public let recordType: String
    public let totalRecords: Int
    public let processedRecords: Int
    public let successfulRecords: Int
    public let failedRecords: Int

    public var percentComplete: Double {
        Double(processedRecords) / Double(totalRecords)
    }
}

public protocol SyncProgressDelegate: Sendable {
    func didUpdate(progress: SyncProgress)
}

// BushelCloudKitService.swift
func sync(
    _ records: [RestoreImageRecord],
    progressDelegate: (any SyncProgressDelegate)?
) async throws -> SyncResult {
    // ... report progress after each batch
}

// Commands/SyncCommand.swift
struct ProgressReporter: SyncProgressDelegate {
    func didUpdate(progress: SyncProgress) {
        let percent = Int(progress.percentComplete * 100)
        print("[\(progress.recordType)] \(percent)% complete - \(progress.successfulRecords) synced, \(progress.failedRecords) failed")
    }
}
```

### Acceptance Criteria

- [ ] BatchConfiguration with per-record-type sizes
- [ ] SyncProgress struct with progress tracking
- [ ] Progress callbacks during batch operations
- [ ] Command-line progress reporting
- [ ] Documentation for tuning batch sizes

---

## Issue 7: Enhanced Documentation

**Priority:** P2 (Medium)
**Effort:** Small (2-3 days)
**Risk:** None

### Documentation Additions

#### 7.1 Code Documentation

**Files to Document:**
- `DataSourcePipeline.swift:395-438` - isSigned merge logic
- `RecordBuilder.swift` - Field mapping strategies
- `SyncEngine.swift` - Dependency ordering

**Template:**
```swift
/// Merges isSigned field from multiple data sources using priority rules.
///
/// Priority Rules:
/// 1. MESU (Apple's authoritative source) is always trusted
/// 2. If existing value is from MESU, keep it regardless of new source
/// 3. Otherwise, use most recent source based on `sourceUpdatedAt`
/// 4. If timestamps are equal or missing, default to `false` (conservative)
///
/// - Parameters:
///   - existing: Current isSigned value and metadata
///   - new: New isSigned value and metadata
/// - Returns: Merged isSigned value following priority rules
private func mergeIsSignedField(
    existing: (value: Bool?, source: String?, timestamp: Date?),
    new: (value: Bool, source: String, timestamp: Date)
) -> Bool {
    // Implementation...
}
```

#### 7.2 Architectural Documentation

**New File:** `Examples/Bushel/docs/ARCHITECTURE.md`

**Contents:**
- Component diagram
- Data flow from fetchers to CloudKit
- Merge strategy explanation
- Error handling architecture
- Configuration hierarchy

#### 7.3 Decision Log

**New File:** `Examples/Bushel/docs/DECISIONS.md`

**Contents:**
- Why boolean as int64?
- Why MESU is authoritative?
- Why 200-operation batches?
- Why these specific data sources?

### Acceptance Criteria

- [ ] All complex methods have doc comments
- [ ] ARCHITECTURE.md with diagrams
- [ ] DECISIONS.md with rationale
- [ ] Updated README with troubleshooting section
- [ ] Enhanced IMPLEMENTATION_NOTES.md

---

## Issue 8: Performance Optimization

**Priority:** P2 (Medium)
**Effort:** Small (1-2 days)
**Risk:** Low

### Optimizations

#### 8.1 Configurable Throttling

**After:**
```swift
// Configuration/FetchConfiguration.swift
public struct ThrottleConfiguration: Sendable, Codable {
    public let appleDB: Duration
    public let mesu: Duration
    public let ipsw: Duration

    public static let `default` = ThrottleConfiguration(
        appleDB: .hours(6),
        mesu: .hours(1),
        ipsw: .hours(12)
    )
}
```

#### 8.2 Metadata Persistence

**After:**
```swift
// Models/DataSourceMetadata.swift
public actor MetadataStore {
    private let fileURL: URL

    func save(_ metadata: [String: DataSourceMetadata]) async throws {
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: fileURL)
    }

    func load() async throws -> [String: DataSourceMetadata] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([String: DataSourceMetadata].self, from: data)
    }
}
```

### Acceptance Criteria

- [ ] Configurable throttling per source
- [ ] Metadata persists between runs
- [ ] Command-line flags for performance tuning
- [ ] Documentation for optimization

---

## Implementation Timeline

### Week 1: Critical Issues (P0)
- Days 1-2: Type conversions (Issue 1)
- Days 3-5: Error handling (Issue 2)
- Day 5: Security (Issue 3)

### Week 2: High Priority (P1)
- Days 1-2: Refactoring (Issue 4)
- Days 3-4: Validation (Issue 5)

### Week 3: Polish (P2)
- Days 1-2: Batch operations (Issue 6)
- Days 3-4: Documentation (Issue 7)
- Day 5: Performance (Issue 8)

## Testing Strategy (Future)

When test coverage is added:

1. **Unit Tests**
   - Type conversions (boolean, Int64, optionals)
   - Record name validation
   - Reference validation
   - Signature merge logic

2. **Integration Tests**
   - End-to-end sync with mock CloudKit
   - Error recovery flows
   - Batch operation handling

3. **Security Tests**
   - File permission validation
   - Logging redaction effectiveness

## Success Metrics

- ✅ Zero "Unknown" recordType errors
- ✅ All type conversions validated
- ✅ File permissions checked on key load
- ✅ Code complexity reduced (max nesting: 3)
- ✅ All references validated before sync
- ✅ Comprehensive error context in logs

## References

- **PR Review:** https://github.com/brightdigit/MistKit/pull/132#pullrequestreview-3428383976
- **CloudKit Docs:** `.claude/docs/webservices.md`
- **Swift Best Practices:** [Apple Swift Documentation](https://swift.org/documentation/)
- **Error Handling:** [Swift Error Handling Guide](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)

---

**Document Version:** 1.0
**Last Updated:** 2025-01-06
**Maintained By:** MistKit Team
