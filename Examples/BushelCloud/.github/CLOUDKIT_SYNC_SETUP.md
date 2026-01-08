# CloudKit Sync Workflow Setup

This document explains how to configure the scheduled CloudKit sync workflow.

## Prerequisites

1. Access to the CloudKit Dashboard: https://icloud.developer.apple.com/dashboard/
2. GitHub repository admin permissions (to add secrets)
3. Server-to-Server authentication key created in CloudKit

## Setup Steps

### 1. Create Server-to-Server Key (If Not Already Created)

1. Visit https://icloud.developer.apple.com/dashboard/
2. Select your container: `iCloud.com.brightdigit.Bushel`
3. Navigate to: **API Access → Server-to-Server Keys**
4. Click **+** to create a new key
5. Download the `.pem` file immediately (you can only download it once)
6. Save the file securely (e.g., `~/Downloads/AuthKey_XXXXXXXXXX.pem`)
7. Note the **Key ID** (32-character hex string)

### 2. Add GitHub Secrets

**Note**: A single S2S key works for both development and production environments. The environment is selected via the `CLOUDKIT_ENVIRONMENT` variable, not the key itself.

1. Go to your repository on GitHub
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Click **New repository secret**

#### Add CLOUDKIT_KEY_ID

- **Name:** `CLOUDKIT_KEY_ID`
- **Value:** Your 32-character key ID from step 1.7
- Click **Add secret**

#### Add CLOUDKIT_PRIVATE_KEY

- **Name:** `CLOUDKIT_PRIVATE_KEY`
- **Value:** Full contents of your `.pem` file

  To get the content:
  ```bash
  cat ~/Downloads/AuthKey_XXXXXXXXXX.pem | pbcopy
  ```

  Or open in a text editor and copy all lines including:
  ```
  -----BEGIN PRIVATE KEY-----
  [base64 encoded key data]
  -----END PRIVATE KEY-----
  ```

- Click **Add secret**

#### Optional: Separate Keys for Production (Advanced)

For enhanced security in production environments, you can optionally use separate keys:

**Benefits:**
- Compromised dev key doesn't affect production
- Different access controls per environment
- Independent key rotation schedules

**Setup:**
- Create a second S2S key in CloudKit Dashboard for production
- Add `CLOUDKIT_PROD_KEY_ID` and `CLOUDKIT_PROD_PRIVATE_KEY` secrets
- Update workflow to use prod secrets when `CLOUDKIT_ENVIRONMENT: production`

This is optional and recommended only for production deployments with real user data.

### 3. Verify Setup

#### Option 1: Manual Trigger (Recommended)

1. Go to: **Actions → Scheduled CloudKit Sync**
2. Click **Run workflow**
3. Select branch: `main`
4. Click **Run workflow**
5. Monitor the run for errors

#### Option 2: Wait for Scheduled Run

The workflow runs automatically every 12 hours at:
- 00:00 UTC (midnight)
- 12:00 UTC (noon)

### 4. Monitor Sync Status

- **Actions tab:** View workflow run history and logs
- **Email notifications:** GitHub sends emails on workflow failures (configure in Settings → Notifications)
- **Status badge (optional):** Add to README.md:
  ```markdown
  ![CloudKit Sync](https://github.com/brightdigit/BushelCloud-Schedule/actions/workflows/cloudkit-sync.yml/badge.svg)
  ```

## Troubleshooting

### Authentication Failed

**Error:** `AUTHENTICATION_FAILED` or credential errors

**Solution:**
- Verify `CLOUDKIT_KEY_ID` matches the key in CloudKit Dashboard
- Ensure `CLOUDKIT_PRIVATE_KEY` includes header/footer lines
- Check for extra whitespace or newlines in secret values
- Confirm the PEM format is correct (use `-----BEGIN PRIVATE KEY-----`, not `-----BEGIN EC PRIVATE KEY-----`)

### Container Not Found

**Error:** `Cannot find container`

**Solution:**
- Verify container ID: `iCloud.com.brightdigit.Bushel`
- Ensure your Apple Developer account has access to this container
- Check that the S2S key has permissions for this container

### Quota Exceeded

**Error:** `QUOTA_EXCEEDED`

**Solution:**
- This is expected if the workflow runs too frequently
- The workflow respects default fetch intervals to prevent this
- Do not use manual triggers more than once per hour

### Build Failures

**Error:** Swift build errors

**Solution:**
- Check if dependencies are accessible (MistKit, BushelKit)
- Verify Package.resolved is committed to repository
- Review workflow logs for specific compilation errors
- Try clearing the cache: Delete the cache key in Actions → Caches

### Network Timeout

**Error:** Timeout during data fetch or sync

**Solution:**
- External data sources may be temporarily unavailable
- The workflow will retry on the next scheduled run
- Check status of data sources: ipsw.me, xcodereleases.com, etc.

## Security Best Practices

1. **Never commit `.pem` files to version control**
2. **Rotate keys every 90 days**
3. **Audit key usage in CloudKit Dashboard regularly**
4. **Revoke compromised keys immediately**
5. **Consider separate keys for production** (optional, for enhanced security when handling real user data)

## Updating Secrets

### Rotating Keys (Recommended Every 90 Days)

1. Create a new S2S key in CloudKit Dashboard
2. Update GitHub secrets with new values:
   - Go to Settings → Secrets and variables → Actions
   - Click on `CLOUDKIT_KEY_ID` → Update secret
   - Click on `CLOUDKIT_PRIVATE_KEY` → Update secret
3. Test with a manual workflow run
4. Revoke the old key in CloudKit Dashboard (only after confirming new key works)

**Tip**: The same key works for both development and production, so you only need to update it once.

## Performance & Cost

### Resource Usage

- **Estimated runtime:**
  - First run (cache miss): 8-12 minutes
  - Subsequent runs (cache hit): 2-4 minutes
- **Frequency:** 2 runs per day = 60 runs per month
- **GitHub Actions usage:** ~120-240 Linux minutes per month
- **Cost:** Well within GitHub free tier (2,000 minutes/month)

### Build Caching

The workflow caches the Swift build directory (`.build`) to speed up subsequent runs:
- Cache key: Based on `Package.resolved` file hash
- Cache invalidation: Automatic when dependencies change
- Cache size: ~50-100 MB

To clear the cache:
1. Go to: **Actions → Caches**
2. Find caches starting with `Linux-swift-build-`
3. Click delete icon

## CloudKit Considerations

### Development vs Production

This workflow currently uses the **development** CloudKit environment:
- Changes don't affect production data
- Free API calls for public database
- Ideal for testing and demos
- Uses the same S2S key as production (environment is selected via `CLOUDKIT_ENVIRONMENT`)

**Switching to Production** (when ready):

Simply change the environment variable in `.github/workflows/cloudkit-sync.yml`:

```yaml
- name: Run CloudKit sync
  env:
    CLOUDKIT_KEY_ID: ${{ secrets.CLOUDKIT_KEY_ID }}
    CLOUDKIT_PRIVATE_KEY: ${{ secrets.CLOUDKIT_PRIVATE_KEY }}
    CLOUDKIT_ENVIRONMENT: production  # ← Change from 'development' to 'production'
    CLOUDKIT_CONTAINER_ID: iCloud.com.brightdigit.Bushel
```

**Important**: The same key works for both environments. The environment parameter tells CloudKit which database to use.

**Recommended Approach**: Create a separate workflow file (e.g., `cloudkit-sync-production.yml`) for production syncs with manual trigger only (`workflow_dispatch`). This prevents accidental production changes and allows you to test workflow modifications in development first.

### Data Sources

The sync fetches from these sources (with default fetch intervals):
- **ipsw.me** (12 hours) - macOS restore images
- **TheAppleWiki** (12 hours) - macOS restore images
- **Apple MESU** (1 hour) - macOS restore images signing status
- **Mr. Macintosh** (12 hours) - macOS restore images
- **xcodereleases.com** (12 hours) - Xcode versions
- **swiftversion.net** (12 hours) - Swift versions

The workflow respects these intervals to avoid overwhelming data sources.

## Advanced Configuration

### Changing Sync Frequency

Edit `.github/workflows/cloudkit-sync.yml`:

```yaml
schedule:
  - cron: '0 0 * * *'  # Once daily at midnight UTC
  - cron: '0 */6 * * *'  # Every 6 hours
  - cron: '0 0 * * 0'  # Weekly on Sundays
```

### Changing CloudKit Environment

The workflow uses the `CLOUDKIT_ENVIRONMENT` environment variable:

```yaml
env:
  CLOUDKIT_ENVIRONMENT: development  # or 'production'
```

Or override with environment variable:

```yaml
export CLOUDKIT_ENVIRONMENT=production
BIN_PATH=$(swift build -c release --show-bin-path)
"$BIN_PATH/bushel-cloud" sync --verbose
```

**Valid values**: `development`, `production` (case-insensitive)

### Sync Specific Record Types Only

Add flags to the sync command in the workflow:

```yaml
BIN_PATH=$(swift build -c release --show-bin-path)
"$BIN_PATH/bushel-cloud" sync \
  --verbose \
  --restore-images-only  # Or --xcode-only, --swift-only
```

### Force Fetch (Ignore Intervals)

Add `--force` flag to bypass fetch throttling:

```yaml
BIN_PATH=$(swift build -c release --show-bin-path)
"$BIN_PATH/bushel-cloud" sync \
  --verbose \
  --force  # Fetch fresh data regardless of intervals
```

**Warning:** This increases load on external data sources and may trigger rate limits.

## Questions or Issues?

- Review project documentation: [CLAUDE.md](../CLAUDE.md)
- Check S2S authentication details: [.claude/s2s-auth-details.md](../.claude/s2s-auth-details.md)
- File an issue: https://github.com/brightdigit/BushelCloud-Schedule/issues
