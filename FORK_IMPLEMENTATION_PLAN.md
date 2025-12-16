# Implementation Plan: Fork swift-android-action for Coverage Support

## Approach

Fork `skiptools/swift-android-action` and add coverage file retrieval before emulator termination.

## Changes Required

### 1. Add Input Parameter

In `action.yml`, add a new input:

```yaml
inputs:
  collect-coverage:
    description: 'Collect code coverage data from tests'
    required: false
    default: 'false'
  coverage-output-dir:
    description: 'Directory to store retrieved coverage files'
    required: false
    default: '.build/coverage'
```

### 2. Modify Test Script Generation

Find the step "Prepare Android Emulator Test Script" (around line 300-400) and modify the script generation to add coverage retrieval:

**Before:**
```bash
echo "killall -INT crashpad_handler || true" >> run-android-tests.sh
```

**After:**
```bash
# Add coverage retrieval if enabled
if [ "${{ inputs.collect-coverage }}" == "true" ]; then
  echo "echo '==> Retrieving coverage data...'" >> run-android-tests.sh
  echo "mkdir -p ${{ inputs.coverage-output-dir }}" >> run-android-tests.sh
  echo "adb -s emulator-5554 shell find /data/local/tmp/android-xctest -name '*.profraw' 2>/dev/null | while read profraw; do" >> run-android-tests.sh
  echo "  echo \"Pulling \$profraw\"" >> run-android-tests.sh
  echo "  adb -s emulator-5554 pull \"\$profraw\" ${{ inputs.coverage-output-dir }}/ || true" >> run-android-tests.sh
  echo "done" >> run-android-tests.sh
  echo "echo '==> Coverage files retrieved to ${{ inputs.coverage-output-dir }}'" >> run-android-tests.sh
fi

echo "killall -INT crashpad_handler || true" >> run-android-tests.sh
```

## Usage in Workflow

```yaml
- name: Build and Test on Android with Coverage
  uses: brightdigit/swift-android-action@coverage-support  # your fork
  with:
    swift-version: "6.2"
    android-api-level: 34
    build-package: true
    build-tests: true
    run-tests: true
    swift-configuration: debug
    swift-build-flags: "-Xswiftc -profile-coverage-mapping -Xswiftc -profile-generate"
    collect-coverage: true
    coverage-output-dir: .build/coverage-android

- name: Process Coverage
  uses: sersoft-gmbh/swift-coverage-action@v4
  with:
    search-paths: .build/coverage-android
```

## Testing the Fork

1. Fork repository: `https://github.com/skiptools/swift-android-action`
2. Create branch: `git checkout -b feature/coverage-support`
3. Make the changes above
4. Update your workflow to use: `uses: brightdigit/swift-android-action@feature/coverage-support`
5. Push and test

## Timeline to Production

1. **Immediate** - Test in your fork
2. **Week 1** - Verify it works, refine implementation
3. **Week 2** - Submit PR to upstream skiptools/swift-android-action
4. **Long-term** - If accepted, use official action; if not, maintain fork

## Alternative: Environment Variable Approach

If forking is too complex, we could try setting `LLVM_PROFILE_FILE` to control output location:

```yaml
- uses: skiptools/swift-android-action@v2
  with:
    test-env: 'LLVM_PROFILE_FILE=/data/local/tmp/coverage-%p.profraw'
```

But this still requires the pull mechanism, so forking is still necessary.

## Recommendation

**Fork and modify** - It's the only way to reliably retrieve coverage data since:
- Emulator must be alive during `adb pull`
- GitHub Actions can't keep processes alive between steps
- The action controls the emulator lifecycle
- We need to inject retrieval before termination

**Estimated effort:** 2-3 hours to fork, modify, test, and deploy.
