# Authentication Operations

Authentication operations handle obtaining and validating CloudKit authentication credentials.

## Understanding CloudKit Authentication

### Authentication Methods

CloudKit Web Services supports two authentication methods:

#### 1. Web Authentication Token (User Authentication)
- **Use Case**: User-specific operations in private/shared databases
- **Flow**: OAuth-style browser-based authentication
- **Token Type**: Web auth token (user-scoped)
- **Duration**: Temporary (expires periodically)
- **Required For**: Private and shared database access

#### 2. Server-to-Server Key (Server Authentication)
- **Use Case**: Server-side applications, automation
- **Flow**: ECDSA key-based signing
- **Token Type**: None (signs requests directly)
- **Duration**: Permanent (until key is revoked)
- **Required For**: Server automation, background jobs

### Database Access Requirements

| Database | Public Operations | Authenticated Operations |
|----------|------------------|--------------------------|
| **Public** | API token only | API token only |
| **Private** | Not allowed | Web auth token or server key |
| **Shared** | Not allowed | Web auth token or server key |

## auth-token

Obtain a web authentication token by signing in with Apple ID. The token is output to stdout for easy capture.

### Syntax
```bash
mistdemo auth-token [options]
```

### Required

| Option | Short | Environment Variable | Description |
|--------|-------|---------------------|-------------|
| `--api-token` | `-a` | `CLOUDKIT_API_TOKEN` | CloudKit API token |

### Optional

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--port` | `-p` | Local server port | `8080` |
| `--host` | | Local server host | `127.0.0.1` |
| `--no-browser` | | Don't open browser automatically | Opens browser |

### How It Works

1. **Start Local Server**: Starts HTTP server on specified port
2. **Open Browser**: Opens CloudKit auth URL (unless `--no-browser`)
3. **User Signs In**: User authenticates with Apple ID
4. **Receive Callback**: CloudKit redirects to local server with token
5. **Output Token**: Token is written to stdout
6. **Shutdown**: Server shuts down automatically

### Examples

**Basic usage:**
```bash
mistdemo auth-token --api-token YOUR_API_TOKEN
```

**Save to environment variable:**
```bash
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token --api-token YOUR_API_TOKEN)
```

**Save to file:**
```bash
mistdemo auth-token --api-token YOUR_API_TOKEN > ~/.mistdemo/token.txt
```

**Custom port:**
```bash
mistdemo auth-token --api-token YOUR_API_TOKEN --port 3000
```

**Don't auto-open browser:**
```bash
mistdemo auth-token --api-token YOUR_API_TOKEN --no-browser
# Manually navigate to the URL shown in the output
```

**Use from environment:**
```bash
export CLOUDKIT_API_TOKEN="your-api-token"
mistdemo auth-token
```

### Output

**Success:**
```
Starting authentication server on http://127.0.0.1:8080
Opening browser for authentication...
Authentication successful!
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

The last line is the web auth token (example shown is not a real token).

**Browser not available:**
```
Starting authentication server on http://127.0.0.1:8080
Could not open browser automatically.
Please navigate to:
https://api.apple-cloudkit.com/database/1/iCloud.com.example.MyApp/development/public/web-auth?...

Waiting for authentication callback...
```

### Security Considerations

**Token Storage:**
- Tokens are sensitive credentials
- Store securely (environment variables, secure files)
- Never commit tokens to version control
- Use appropriate file permissions (0600)

**Token Lifetime:**
- Tokens expire periodically
- Re-authenticate when token expires
- Monitor for authentication errors

**Local Server:**
- Only binds to localhost by default
- Uses ephemeral port if default is unavailable
- Automatically shuts down after receiving token

### Common Workflows

**Setup script:**
```bash
#!/bin/bash
# setup-cloudkit.sh

# Check if token exists and is valid
if [ -f ~/.mistdemo/token.txt ]; then
  export CLOUDKIT_WEBAUTH_TOKEN=$(cat ~/.mistdemo/token.txt)
  if mistdemo validate > /dev/null 2>&1; then
    echo "Using existing token"
    exit 0
  fi
fi

# Get new token
echo "Obtaining new authentication token..."
mistdemo auth-token --api-token "$CLOUDKIT_API_TOKEN" > ~/.mistdemo/token.txt
chmod 600 ~/.mistdemo/token.txt
export CLOUDKIT_WEBAUTH_TOKEN=$(cat ~/.mistdemo/token.txt)
echo "Authentication complete"
```

**CI/CD automation:**
```bash
# For server-to-server authentication
export CLOUDKIT_KEY_ID="your-key-id"
export CLOUDKIT_PRIVATE_KEY_FILE="/path/to/private-key.pem"

# No web auth token needed
mistdemo query --database private
```

**Interactive session:**
```bash
# One-time setup per session
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a YOUR_API_TOKEN)

# Use for all subsequent commands
mistdemo query --database private
mistdemo create --database private --field "title:string:Test"
mistdemo current-user --database private
```

## validate

Validate current authentication credentials.

### Syntax
```bash
mistdemo validate [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--test-query` | Perform a test query to validate |

### Validation Checks

Without `--test-query`:
- Verifies required credentials are present
- Checks credential format
- Basic validation only

With `--test-query`:
- Performs actual CloudKit API call
- Verifies credentials work end-to-end
- Tests against current-user endpoint

### Examples

**Basic validation:**
```bash
mistdemo validate
```

**Validation with test query:**
```bash
mistdemo validate --test-query
```

**Check if authenticated:**
```bash
if mistdemo validate --test-query > /dev/null 2>&1; then
  echo "Authentication valid"
else
  echo "Authentication failed"
  exit 1
fi
```

### Response Format (JSON)

**Valid credentials:**
```json
{
  "valid": true,
  "method": "web-auth-token",
  "database": "private",
  "userRecordName": "_abc123def456"
}
```

**Invalid credentials:**
```json
{
  "valid": false,
  "error": {
    "code": "AUTHENTICATION_FAILED",
    "message": "Invalid or expired web authentication token"
  }
}
```

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Valid authentication |
| `1` | Invalid or missing credentials |
| `2` | Network or API error |

### Common Use Cases

**Pre-flight check:**
```bash
#!/bin/bash
# Run before executing batch operations

mistdemo validate --test-query || {
  echo "Error: Invalid authentication. Please re-authenticate."
  export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a "$CLOUDKIT_API_TOKEN")
}

# Proceed with operations
mistdemo query --database private
```

**Automated monitoring:**
```bash
#!/bin/bash
# Check authentication status periodically

while true; do
  if ! mistdemo validate --test-query > /dev/null 2>&1; then
    echo "$(date): Authentication expired, refreshing..."
    # Note: This requires manual re-auth for web auth tokens
    # Server-to-server keys don't expire
    notify-admin "CloudKit authentication needs renewal"
  fi
  sleep 3600  # Check every hour
done
```

## Authentication Workflows

### First-Time Setup

```bash
# 1. Set API token (from CloudKit Dashboard)
export CLOUDKIT_API_TOKEN="your-api-token-here"

# 2. Set container ID
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.MyApp"

# 3. Test public database access
mistdemo query --database public

# 4. Get web auth token for private access
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a "$CLOUDKIT_API_TOKEN")

# 5. Verify private access
mistdemo current-user --database private
```

### Development Environment

```bash
# .env file (never commit this)
CLOUDKIT_CONTAINER_ID=iCloud.com.example.MyApp
CLOUDKIT_API_TOKEN=your-api-token
CLOUDKIT_ENVIRONMENT=development
CLOUDKIT_DATABASE=private

# Load environment
source .env

# Get token for session
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a "$CLOUDKIT_API_TOKEN")
```

### Production Environment (Server-to-Server)

```bash
# Generate key pair (one time)
# See CloudKit documentation for key generation

# Set environment variables
export CLOUDKIT_CONTAINER_ID=iCloud.com.example.MyApp
export CLOUDKIT_API_TOKEN=your-api-token
export CLOUDKIT_ENVIRONMENT=production
export CLOUDKIT_KEY_ID=your-key-id
export CLOUDKIT_PRIVATE_KEY_FILE=/secure/path/to/key.pem

# No web auth needed
mistdemo query --database private
```

## Troubleshooting

### Token Expired
```bash
# Error: AUTHENTICATION_FAILED
# Solution: Get new token
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a "$CLOUDKIT_API_TOKEN")
```

### Port Already in Use
```bash
# Error: Address already in use
# Solution: Use different port
mistdemo auth-token --api-token YOUR_API_TOKEN --port 3000
```

### Browser Won't Open
```bash
# Use --no-browser and manually navigate
mistdemo auth-token --api-token YOUR_API_TOKEN --no-browser
# Copy the URL from output and open in browser
```

### Invalid API Token
```bash
# Error: Invalid API token
# Solution: Check CloudKit Dashboard for correct token
```

## Security Best Practices

### Token Storage
1. **Environment Variables**: Preferred for development
2. **Secure Files**: Use 0600 permissions
3. **Secrets Management**: Use vault systems in production
4. **Never Commit**: Add to .gitignore

### Token Rotation
1. Regenerate tokens periodically
2. Revoke old tokens
3. Update all environments

### Access Control
1. Use least-privilege principle
2. Separate dev/prod credentials
3. Audit access logs
4. Monitor for unusual activity

## Related Documentation

- **[Overview](overview.md)** - Global options and authentication overview
- **[User Operations](operations-user.md)** - Using authenticated operations
- **[Configuration](configuration.md)** - Managing credentials in config files
- **[Error Handling](error-handling.md)** - Authentication error codes
