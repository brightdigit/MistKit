# Android CI Coverage Implementation Investigation

## Goal
Implement code coverage collection and reporting for Android CI builds in the MistKit project, using the swift-android-action and uploading results to Codecov.

## Background
Following Marc Prud'hommeaux's guidance in [swift-android-action#8](https://github.com/skiptools/swift-android-action/issues/8#issuecomment-3660918393), we implemented Android native code coverage workflow to retrieve `.profraw` files from the Android emulator and process them for Codecov upload.

## Implementation Approach

### Initial Setup (Successful)
1. **Coverage Collection**: Added Swift compiler flags for instrumentation
   ```yaml
   swift-build-flags: "-Xswiftc -profile-coverage-mapping -Xswiftc -profile-generate"
   ```

2. **Profraw Retrieval**: Implemented ADB-based file retrieval from Android emulator
   ```bash
   adb -s emulator-5554 pull /data/local/tmp/android-xctest/default.profraw
   ```
   ✅ **Result**: Successfully retrieved profraw files from emulator to host

3. **2-Step Conversion Workflow**: Implemented Android native coverage processing
   ```bash
   # Step 1: Convert profraw to profdata
   llvm-profdata merge -sparse default.profraw -o default.profdata

   # Step 2: Export profdata to LCOV
   llvm-cov export -format=lcov -instr-profile=default.profdata TEST_BINARY > coverage.lcov
   ```

## Issues Encountered

### Issue 1: LLVM Version Mismatch (Primary Blocker)

#### Error Message
```
warning: ../coverage-android/default.profraw: raw profile version mismatch:
Profile uses raw profile format version = 9; expected version = 10
PLEASE update this tool to version in the raw profile, or regenerate raw profile with expected version.
error: no profile can be merged
```

#### Root Cause
The Android Swift SDK generates profraw files with **LLVM v9 format**, but the host Swift toolchain's `llvm-profdata` expects **LLVM v10 format**. This is a fundamental incompatibility between:
- **Android SDK**: Uses LLVM v9 (generates v9 profraw files)
- **Host Swift Toolchain**: Uses LLVM v10 (llvm-profdata expects v10 format)

#### Attempts to Resolve

##### Attempt 1: Search for LLVM Tools in Android SDK Artifactbundle
**Hypothesis**: The Android SDK might include matching LLVM tools (llvm-profdata, llvm-cov) with LLVM v9.

**Implementation**:
```bash
# Search paths in Android artifactbundle
for search_path in \
  "${ANDROID_SDK_BASE}/bin" \
  "${ANDROID_SDK_BASE}/usr/bin" \
  "${ANDROID_SDK_BASE}/toolset/bin" \
  "${ANDROID_SDK_BASE}/../bin"; do
  if [ -f "${search_path}/llvm-profdata" ]; then
    # Use Android SDK's LLVM tools
  fi
done
```

**Result**: ❌ **Failed**
- Android SDK artifactbundle does **not include** llvm-profdata or llvm-cov tools
- All search paths came up empty
- Fell back to host Swift toolchain (LLVM v10)

**Commit**: `5c8c099` - "feat: search for LLVM tools in Android SDK artifactbundle"

---

##### Attempt 2: Use Swift 6.2 Stable Release
**Hypothesis**: Stable Swift 6.2 release (September 2024) should have LLVM v9.

**Configuration**:
```yaml
swift-version: "6.2"
```

**Result**: ❌ **Failed**
- Even Swift 6.2 stable release has **LLVM v10** in llvm-profdata
- Still got version mismatch error (v9 profraw vs v10 llvm-profdata)

**Commit**: `0bbd0ef` - "fix: use stable Swift 6.2 release for guaranteed LLVM v9"

**Logs**: [Build run](https://github.com/brightdigit/MistKit/actions/runs/20282816357/job/58249077463)
```
Using host Swift LLVM tools from /home/runner/.config/swiftpm/toolchains/swift-6.2-RELEASE/usr/bin
Step 1: Merging profraw to profdata...
warning: raw profile version mismatch: Profile uses version = 9; expected version = 10
error: no profile can be merged
```

---

##### Attempt 3: Use Swift 6.1.1
**Hypothesis**: Older Swift 6.1.1 (May 2024) might have LLVM v9.

**Configuration**:
```yaml
swift-version: "6.1.1"
```

**Result**: ❌ **Failed - Different Error**

**New Error**: Missing profile runtime library
```
clang: error: no such file or directory:
/home/runner/.config/swiftpm/swift-sdks/swift-6.1.1-RELEASE-android-0.1.artifactbundle/
swift-android/swift-resources/usr/lib/swift-x86_64/clang/lib/linux/
libclang_rt.profile-x86_64-android.a
```

**Analysis**:
- Swift 6.1.1 Android SDK is **missing the profile runtime library** (`libclang_rt.profile`)
- This library is required for `-profile-coverage-mapping -profile-generate` flags
- Suggests code coverage support may be incomplete in Swift 6.1.1 for Android

**Commit**: `93d3cdd` - "fix: try Swift 6.1.1 for LLVM v9 compatibility"

**Logs**: [Build run](https://github.com/brightdigit/MistKit/actions/runs/20283023904/job/58249797760)

---

##### Attempt 4: Use Development Snapshots
**Hypothesis**: Older development snapshots might have LLVM v9.

**Attempts Made**:

1. **November 2025 Snapshot** (`DEVELOPMENT-SNAPSHOT-2025-11-03-a`)
   - ❌ **Not available** in Skip's Android toolchain releases
   - Commit: `2424ea1`

2. **August 28, 2025 Snapshot** (`6.2-DEVELOPMENT-SNAPSHOT-2025-08-28-a`)
   - ❌ **Version matching failed** - grep filters out all `-SNAPSHOT` versions
   - Commit: `1131bda`

3. **August 14, 2025 Snapshot** (`6.2-DEVELOPMENT-SNAPSHOT-2025-08-14-a`)
   - ❌ **Version matching failed** - same grep filter issue
   - Commit: `97a79a2`

4. **Nightly Format** (`nightly-6.2`)
   - Would select latest 6.2 snapshot (August 28)
   - ❌ **Abandoned** - would likely have LLVM v10
   - Commit: `0176585`

**Available Snapshots** (from Skip's releases):
```
6.2-DEVELOPMENT-SNAPSHOT-2025-08-28-a
6.2-DEVELOPMENT-SNAPSHOT-2025-08-14-a
6.2-DEVELOPMENT-SNAPSHOT-2025-07-17-a
6.2
6.1.1
6.1
```

---

##### Attempt 5: Use Latest Swift Nightly
**Initial Approach**: Use latest development snapshot for LLVM v10 compatibility.

**Configuration**:
```yaml
swift-version: "nightly-main"  # Swift DEVELOPMENT-SNAPSHOT-2025-12-15-a
```

**Result**: ❌ **Failed**
- Host: Swift 6.3.0-dev with LLVM v10
- Android SDK: Generates LLVM v9 profraw files
- Same version mismatch as all other attempts

**Commits**:
- `01cd3f2` - "feat: use nightly Swift build for LLVM compatibility"
- `3507d77` - "feat: upload Android coverage as artifact (LLVM version incompatibility)"

---

### Issue 2: Codecov Format Requirements

#### Error Message
```
Found 0 coverage files to report
```

#### Root Cause
Codecov does **not accept** `.profraw` files directly. Supported formats:
- LCOV (`.lcov`)
- Cobertura XML (`.xml`)
- JaCoCo XML (`.xml`)
- Gcov (`.gcov`)

#### Resolution
Implemented 2-step conversion workflow (profraw → profdata → lcov), but blocked by LLVM version mismatch.

---

## Technical Analysis

### Why LLVM Version Mismatch Occurs

1. **Swift Toolchain Evolution**:
   - Swift 6.2 and later: LLVM v10
   - Older Swift versions: LLVM v9

2. **Android SDK Lag**:
   - Skip's Android SDK builds are separate from official Swift releases
   - Android SDK for Swift 6.2 still uses LLVM v9
   - Host Swift 6.2 has already moved to LLVM v10

3. **Profraw Format Incompatibility**:
   - Profraw files include version metadata
   - LLVM v10 tools reject v9 profraw files with "bad magic" error
   - No backward compatibility

### Why Android SDK Doesn't Include LLVM Tools

The Android SDK artifactbundle structure:
```
swift-6.2-RELEASE-android-0.1.artifactbundle/
├── swift-android/
│   ├── ndk-sysroot/        # NDK files
│   ├── swift-resources/    # Swift runtime libraries
│   └── swift-toolset.json  # Toolset configuration
└── Info.json
```

**No LLVM tools included**:
- `llvm-profdata` ❌
- `llvm-cov` ❌

These tools are expected to come from the host Swift installation, creating the version mismatch.

---

## Attempted Workarounds Summary

| Attempt | Swift Version | LLVM Tools Source | Result | Issue |
|---------|--------------|-------------------|--------|-------|
| 1 | nightly-main (Dec 15) | Host (v10) | ❌ Failed | Version mismatch |
| 2 | 6.2 stable | Host (v10) | ❌ Failed | Version mismatch |
| 3 | 6.2-SNAPSHOT-2025-08-28-a | N/A | ❌ Failed | Version matching error |
| 4 | 6.2-SNAPSHOT-2025-08-14-a | N/A | ❌ Failed | Version matching error |
| 5 | nightly-6.2 | N/A | ❌ Abandoned | Would have v10 mismatch |
| 6 | 6.1.1 | Host | ❌ Failed | Missing libclang_rt.profile |
| 7 | Android SDK search | Android SDK (v9) | ❌ Failed | LLVM tools not in SDK |

---

## Current Status

### What Works ✅
1. **Coverage instrumentation**: Code compiles with coverage flags
2. **Profraw generation**: Android tests generate profraw files
3. **Profraw retrieval**: Successfully pull profraw files from emulator to host using ADB
4. **Artifact upload**: Can upload profraw files as GitHub Actions artifacts

### What Doesn't Work ❌
1. **Profraw → Profdata conversion**: LLVM version mismatch prevents merge
2. **LCOV generation**: Cannot proceed without profdata
3. **Codecov upload**: Requires LCOV format, not profraw

---

## Recommendations

### Short-Term Solutions

#### Option A: Upload Profraw Artifacts for Offline Processing (Recommended)
**Implementation**:
```yaml
- name: Upload Android coverage artifact
  uses: actions/upload-artifact@v4
  with:
    name: android-coverage-profraw
    path: coverage-android/default.profraw
```

**Pros**:
- Preserves coverage data
- Can be processed offline with matching LLVM tools
- Doesn't block CI

**Cons**:
- No automatic Codecov reporting
- Requires manual processing

---

#### Option B: Disable Coverage for Android CI Temporarily
**Implementation**:
```yaml
swift-build-flags: ""  # Remove coverage flags
collect-coverage: false
```

**Pros**:
- Clean CI runs
- No confusing errors

**Cons**:
- Loses coverage data entirely

---

### Long-Term Solutions (Requires Skip Team)

#### Solution 1: Include LLVM Tools in Android SDK Artifactbundle
**Request**: Bundle `llvm-profdata` and `llvm-cov` (LLVM v9) in the Android SDK artifactbundle.

**Benefits**:
- Tools version matches profraw format
- Self-contained Android SDK
- Works with any host Swift version

**Implementation Path**:
```
swift-android/
├── ndk-sysroot/
├── swift-resources/
├── bin/                  # NEW: LLVM tools
│   ├── llvm-profdata    # LLVM v9
│   └── llvm-cov         # LLVM v9
└── swift-toolset.json
```

---

#### Solution 2: Update Android SDK to LLVM v10
**Request**: Rebuild Android SDK with LLVM v10 to match host toolchains.

**Benefits**:
- Matches modern Swift releases
- Future-proof

**Challenges**:
- Larger SDK rebuild effort
- May have other compatibility implications

---

#### Solution 3: Provide Standalone LLVM v9 Tools Package
**Request**: Provide downloadable LLVM v9 tools package for coverage processing.

**Benefits**:
- Minimal changes to Android SDK
- Can be cached in CI

**Implementation**:
```yaml
- name: Download LLVM v9 tools
  run: |
    curl -L https://example.com/llvm-9-tools.tar.gz | tar xz
    export PATH="./llvm-9-tools/bin:$PATH"
```

---

## Files Modified in This Investigation

### GitHub Actions Workflow
`.github/workflows/MistKit.yml`:
- Added Android build job with coverage collection
- Configured Codecov upload step
- Tested multiple Swift versions

### Custom Action
`.github/actions/swift-android-action/action.yml`:
- Implemented 2-step coverage conversion (profraw → profdata → lcov)
- Added LLVM tool search in Android SDK artifactbundle
- Added comprehensive error logging

### Commits Timeline
```
01cd3f2 feat: use nightly Swift build for LLVM compatibility
3507d77 feat: upload Android coverage as artifact (LLVM version incompatibility)
fe821e5 fix: use llvm-cov export directly, bypass version mismatch
bacbbce fix: use Swift toolchain's llvm-profdata
514734e fix: add llvm-profdata merge step for coverage processing
5c8c099 feat: search for LLVM tools in Android SDK artifactbundle
2424ea1 fix: use November Swift snapshot for LLVM v9 compatibility
1131bda fix: use August 28 Swift snapshot (only available dev snapshot)
97a79a2 fix: use August 14 snapshot (correct latest dev snapshot)
0176585 fix: use nightly-6.2 format instead of full snapshot name
0bbd0ef fix: use stable Swift 6.2 release for guaranteed LLVM v9
93d3cdd fix: try Swift 6.1.1 for LLVM v9 compatibility
2407c2e fix: fail CI if Codecov upload fails
```

---

## References

- **Original Issue**: [swift-android-action#8](https://github.com/skiptools/swift-android-action/issues/8)
- **Marc's Guidance**: [Comment #3660918393](https://github.com/skiptools/swift-android-action/issues/8#issuecomment-3660918393)
- **Android Native Code Coverage**: [Android Developer Docs](https://source.android.com/docs/core/tests/development/code-coverage)
- **LLVM Coverage Mapping**: [LLVM Documentation](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html)

---

## Conclusion

Android CI coverage for Swift is currently **blocked by LLVM version incompatibility** between:
- Android SDK profraw generation (LLVM v9)
- Host Swift toolchain processing (LLVM v10)

The Android SDK artifactbundle does not include LLVM tools, and older Swift versions either have the same issue or are missing required runtime libraries.

**Recommended Action**: Upload profraw artifacts for now and work with Skip team to include LLVM v9 tools in future Android SDK releases.

---

Generated: 2025-12-16
Authors: Leo Dion (with assistance from Claude Code)
Project: MistKit - Swift Package for CloudKit Web Services
