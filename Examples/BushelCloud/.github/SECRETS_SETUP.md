# GitHub Secrets Setup Checklist

This file lists exactly what secrets you need to configure for the scheduled CloudKit sync workflow.

## Prerequisites

Before adding secrets, you need a CloudKit Server-to-Server key:

1. Visit https://icloud.developer.apple.com/dashboard/
2. Select container: `iCloud.com.brightdigit.Bushel`
3. Navigate to: **API Access → Server-to-Server Keys**
4. Click **+** to create a new key
5. Download the `.pem` file (you can only download once!)
6. Copy the Key ID (32-character hex string)

## Required Secrets

You need to add **2 secrets** to your GitHub repository:

### 1. CLOUDKIT_KEY_ID

**Where to add:**
- Repository → Settings → Secrets and variables → Actions → New repository secret

**Secret configuration:**
- **Name:** `CLOUDKIT_KEY_ID`
- **Value:** Your 32-character key ID from CloudKit Dashboard
- **Example:** `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

### 2. CLOUDKIT_PRIVATE_KEY

**Where to add:**
- Repository → Settings → Secrets and variables → Actions → New repository secret

**Secret configuration:**
- **Name:** `CLOUDKIT_PRIVATE_KEY`
- **Value:** Full contents of your `.pem` file

**Getting the PEM content:**

Option A - Using terminal:
```bash
cat ~/Downloads/AuthKey_XXXXXXXXXX.pem | pbcopy
```

Option B - Using text editor:
1. Open the `.pem` file in a text editor
2. Copy **everything** including the header and footer lines:
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
[multiple lines of base64 encoded data]
...
-----END PRIVATE KEY-----
```

**Important:** Make sure to include the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines!

## Verification Checklist

After adding secrets, verify:

- [ ] Secret `CLOUDKIT_KEY_ID` exists in repository secrets
- [ ] Secret `CLOUDKIT_PRIVATE_KEY` exists in repository secrets
- [ ] PEM content includes header and footer lines
- [ ] No extra whitespace or line breaks in key ID
- [ ] Original `.pem` file stored securely (not in git!)

## Testing the Setup

1. Go to: **Actions → Scheduled CloudKit Sync**
2. Click **Run workflow**
3. Select branch: `main` (or current branch)
4. Click **Run workflow**
5. Monitor the run - it should complete successfully

If you see authentication errors, double-check:
- Key ID matches exactly (no typos)
- PEM content is complete (including headers)
- No extra spaces or formatting issues

## Important Notes

- **One key for both environments:** The same key works for development AND production CloudKit environments
- **Environment selection:** The environment (dev/prod) is controlled by `CLOUDKIT_ENVIRONMENT` variable in the workflow file, not by the key
- **Security:** Never commit the `.pem` file to git
- **Rotation:** Rotate keys every 90 days for security

## Quick Reference

| Secret Name | Where to Get It | Format |
|-------------|-----------------|--------|
| `CLOUDKIT_KEY_ID` | CloudKit Dashboard → API Access → Server-to-Server Keys | 32-character hex (e.g., `a1b2c3...`) |
| `CLOUDKIT_PRIVATE_KEY` | Downloaded `.pem` file | Multi-line PEM format with headers |

## Next Steps

After secrets are configured:
- Workflow will run automatically every 12 hours
- You can trigger manually anytime via Actions tab
- Check workflow logs to verify successful syncs
- Monitor CloudKit Dashboard to see synced data

## Need Help?

See the full setup guide: [CLOUDKIT_SYNC_SETUP.md](CLOUDKIT_SYNC_SETUP.md)
