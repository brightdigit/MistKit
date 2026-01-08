# GitHub Secrets Setup Guide

This document describes the GitHub secrets required for the automated RSS feed update workflow.

## Required Secrets

The workflow needs **2 repository secrets** to authenticate with CloudKit using Server-to-Server authentication. A third secret (`CLOUDKIT_CONTAINER_ID`) is optional since the default value is configured in the code.

### Where to Add Secrets

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each secret below

Direct link: https://github.com/brightdigit/CelestraCloud/settings/secrets/actions

---

## 1. CLOUDKIT_CONTAINER_ID (Optional)

**Name:** `CLOUDKIT_CONTAINER_ID`

**Status:** **Optional** - The default value `iCloud.com.brightdigit.Celestra` is configured in the code.

**Value (if overriding default):**
```
iCloud.com.brightdigit.Celestra
```

**Description:** The CloudKit container identifier for the Celestra app. This is the same for both development and production environments. Only set this secret if you need to use a different container.

---

## 2. CLOUDKIT_KEY_ID

**Name:** `CLOUDKIT_KEY_ID`

**Value:** Your CloudKit Server-to-Server key ID from Apple Developer Console

**Format:** Alphanumeric string (e.g., `ABC123XYZ456`)

**How to obtain:**
1. Go to [Apple Developer Console](https://developer.apple.com/account)
2. Navigate to: **Certificates, Identifiers & Profiles** → **Keys**
3. Find your CloudKit Server-to-Server key (or create one if needed)
4. Copy the **Key ID** value

**Creating a new key (if needed):**
1. Click the **+** button to create a new key
2. Enter a name (e.g., "CelestraCloud Server-to-Server")
3. Check **CloudKit**
4. Click **Continue** → **Register** → **Download**
5. **IMPORTANT:** Save the downloaded `.p8` file - you'll need to convert it to PEM format
6. Copy the **Key ID** shown on the confirmation page

---

## 3. CLOUDKIT_PRIVATE_KEY

**Name:** `CLOUDKIT_PRIVATE_KEY`

**Value:** The full contents of your PEM-formatted private key file

**Format:** Multi-line text starting with `-----BEGIN EC PRIVATE KEY-----` and ending with `-----END EC PRIVATE KEY-----`

**Example:**
```
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIB1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOP
qrstuvwxyz1234567890+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn
opqrstuvwxyz1234567890+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijk
...
-----END EC PRIVATE KEY-----
```

**How to obtain:**

### If you have the `.p8` file from Apple:

Convert it to PEM format:

```bash
# Convert .p8 to PEM format
openssl ec -in AuthKey_YOUR_KEY_ID.p8 -out cloudkit_key.pem

# View the PEM file contents
cat cloudkit_key.pem
```

Then copy the **entire output** (including BEGIN/END lines) and paste it as the secret value.

### If you already have the PEM file:

```bash
# Display the PEM file contents
cat /path/to/your/cloudkit_key.pem
```

Copy the entire output and paste it as the secret value.

### Important Notes:
- Include the `-----BEGIN EC PRIVATE KEY-----` and `-----END EC PRIVATE KEY-----` lines
- Include all line breaks and formatting exactly as shown
- Do not add any extra spaces or modify the format
- GitHub will encrypt this value automatically

---

## Environment Configuration

The workflow uses these secrets for **both** CloudKit environments:
- **Development**: Used for manual testing (default)
- **Production**: Used for scheduled runs

The same key works for both environments. The environment is selected at runtime via the workflow input or automatically for scheduled runs.

---

## Verification

After adding the required secrets (at minimum `CLOUDKIT_KEY_ID` and `CLOUDKIT_PRIVATE_KEY`), you can verify the setup by running the workflow manually:

```bash
# Trigger a test run using development environment
gh workflow run update-feeds.yml \
  --ref 19-scheduled-job \
  -f tier=high \
  -f environment=development \
  -f delay=2.0
```

Or through the GitHub UI:
1. Go to **Actions** tab
2. Select **Update RSS Feeds** workflow
3. Click **Run workflow**
4. Select:
   - Branch: `19-scheduled-job`
   - Tier: `high` (quick test)
   - Environment: `development` (safe testing)
   - Delay: `2.0` (default)
5. Click **Run workflow**

---

## Troubleshooting

### "Invalid credentials" or authentication errors
- Verify `CLOUDKIT_KEY_ID` matches the key in Apple Developer Console
- Ensure `CLOUDKIT_PRIVATE_KEY` includes the BEGIN/END lines
- Check for extra spaces or formatting issues in the PEM key

### "Container not found" errors
- Verify `CLOUDKIT_CONTAINER_ID` is spelled correctly
- Ensure the container exists in Apple Developer Console

### "Permission denied" errors
- Verify the Server-to-Server key has CloudKit permissions enabled
- Check that the key hasn't been revoked in Apple Developer Console

---

## Security Notes

- ✅ Secrets are encrypted by GitHub and only accessible to workflow runs
- ✅ The private key is created in `/tmp` during workflow execution and deleted after
- ✅ File permissions are set to `600` (owner read/write only)
- ✅ The key is never logged or exposed in workflow outputs
- ✅ Consider rotating keys periodically for security best practices

---

## Secret Rotation

If you need to rotate your CloudKit key:

1. **Generate new key** in Apple Developer Console
2. **Convert to PEM format** (if needed)
3. **Update GitHub secrets** with new values
4. **Test the workflow** to verify the new credentials work
5. **Revoke old key** in Apple Developer Console (optional, but recommended)

---

## Additional Resources

- [CloudKit Server-to-Server Authentication](https://developer.apple.com/documentation/cloudkit/ckservertoclientoperation)
- [GitHub Actions Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [MistKit CloudKit Integration](https://github.com/brightdigit/MistKit)
