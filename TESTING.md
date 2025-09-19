# Testing MistKit Authentication

This guide explains how to test the MistKit authentication system with all three supported CloudKit Web Services authentication methods.

## 🚀 Quick Start Testing

### Prerequisites
- Xcode 15.0+ or Swift 5.9+
- macOS 14.0+ (for running the demo)
- Git (to clone the repository)

### 1. **Test API-Only Authentication** (Easiest to start)
```bash
# Clone and build
git clone <your-mistkit-repo>
cd MistKit
swift build

# Test API-only authentication
swift run --package-path . MistDemo --test-api-only
```

### 2. **Test AdaptiveTokenManager Transitions**
```bash
# Test the transition functionality
swift run --package-path . MistDemo --test-adaptive
```

### 3. **Comprehensive Test Suite**
```bash
# Test all authentication methods at once
swift run --package-path . MistDemo --test-all-auth
```

## 🔧 Setting Up Your Own CloudKit Container

To test with **real CloudKit data**, you'll need your own CloudKit container:

### Step 1: Create CloudKit Container
1. Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard)
2. Sign in with your Apple Developer account
3. Create a new container or use an existing one
4. Note your container identifier (e.g., `iCloud.com.yourteam.YourApp`)

### Step 2: Get API Token
1. In CloudKit Console → Your Container → API Access
2. Create a new API token with appropriate permissions:
   - **Read/Write** for testing record operations
   - **Public Database** for API-only testing
   - **Private Database** for web authentication testing
3. Copy the 64-character hex token

### Step 3: Test with Your Container
```bash
# Test with your container and API token
swift run --package-path . MistDemo \
  --container-identifier "iCloud.com.yourteam.YourApp" \
  --api-token "your_64_character_api_token_here" \
  --test-api-only
```

## 🌐 Testing Web Authentication

For **full web authentication testing**:

### Option 1: Use the Web Interface (Recommended)
```bash
# Start the authentication server
swift run --package-path . MistDemo \
  --container-identifier "your_container_id" \
  --api-token "your_api_token"

# This will:
# 1. Start a web server on http://localhost:8080
# 2. Open your browser automatically
# 3. Let you sign in with Apple ID
# 4. Run the demo with full user authentication
```

**What happens:**
- A local web server starts with CloudKit authentication interface
- Your browser opens to the authentication page
- You sign in with your Apple ID
- The server receives the web auth token
- The demo runs with full private database access

### Option 2: Use a Saved Web Auth Token
```bash
# If you have a web auth token from previous authentication
swift run --package-path . MistDemo \
  --skip-auth \
  --web-auth-token "your_web_auth_token_here" \
  --container-identifier "your_container_id" \
  --api-token "your_api_token"
```

### Option 3: Test Transitions with Web Token
```bash
# Test AdaptiveTokenManager with full transition capability
swift run --package-path . MistDemo \
  --test-adaptive \
  --web-auth-token "your_web_auth_token" \
  --api-token "your_api_token"
```

## 🧪 Running Unit Tests

```bash
# Run all 28 unit tests including TokenManager tests
swift test

# Run only TokenManager-specific tests
swift test --filter TokenManagerTests

# Run AdaptiveTokenManager integration tests
swift test --filter AdaptiveTokenManagerIntegrationTests
```

**Test Coverage:**
- `TokenManagerTests`: Protocol compliance, error handling, enum cases (10 tests)
- `AdaptiveTokenManagerIntegrationTests`: Transition functionality (3 tests)
- `MistKitTests`: Core functionality (15 tests)

## 📱 CLI Command Reference

### Available Commands
```bash
# Show all available options
swift run --package-path . MistDemo --help

# Testing commands
swift run --package-path . MistDemo --test-api-only      # Test API-only auth
swift run --package-path . MistDemo --test-adaptive     # Test AdaptiveTokenManager
swift run --package-path . MistDemo --test-all-auth     # Test all methods

# Web authentication
swift run --package-path . MistDemo                     # Start web auth server
swift run --package-path . MistDemo --skip-auth \       # Use saved token
  --web-auth-token "token"

# Custom configuration
swift run --package-path . MistDemo \
  --container-identifier "your_container" \
  --api-token "your_token" \
  --host "127.0.0.1" \
  --port 8080 \
  --test-all-auth
```

### Common Parameters
- `--container-identifier` / `-c`: CloudKit container ID
- `--api-token` / `-a`: CloudKit API token
- `--host`: Server host (default: 127.0.0.1)
- `--port` / `-p`: Server port (default: 8080)
- `--web-auth-token`: Web authentication token
- `--skip-auth`: Skip web authentication flow

## 🔍 Understanding the Output

### API-Only Test Output:
```
🔐 API-only Authentication Test
============================================================
Container: iCloud.com.brightdigit.MistDemo
Database: public (API-only limitation)
------------------------------------------------------------

📋 Testing API-only authentication...
✅ CloudKitService initialized with API-only authentication

📁 Listing zones in public database...
🌐 CloudKit Request: GET https://api.apple-cloudkit.com/database/...
   Query Parameters:
     ckAPIToken: 296c503003846ef692cb5b56c4a63cc1d27fb952eebe259d73e692759286dfa6
✅ Found 0 zone(s)

📋 Querying records from public database...
✅ Found 0 record(s) in public database
```

### AdaptiveTokenManager Test Output:
```
🔄 AdaptiveTokenManager Transition Test
============================================================
📋 Creating AdaptiveTokenManager with API token...
🔍 Testing initial API-only state...
✅ Initial state: API-only authentication (296c5030...)
✅ Has credentials: true
✅ Supports refresh: false
🔍 Testing credential validation...
✅ Credential validation: PASSED

🔄 Testing upgrade to web authentication...
✅ Upgraded to web auth (API: 296c5030..., Web: abc12345...)
✅ Validation after upgrade: PASSED
🔄 Testing downgrade to API-only...
✅ Downgraded to API-only (296c5030...)
✅ AdaptiveTokenManager transitions completed successfully!
```

### Full Test Suite Output:
```
🧪 MistKit Authentication Methods Test Suite
======================================================================
Container: iCloud.com.brightdigit.MistDemo
API Token: 296c503003846ef692cb5b56c4a63cc1d27fb952eebe259d73e692759286dfa6
======================================================================

🔐 Test 1: API-only Authentication (Public Database)
--------------------------------------------------
📋 Validating API token credentials...
✅ API Token validation: PASSED
📁 Listing public zones...
✅ Found 0 public zone(s)

🌐 Test 2: Web Authentication (Private Database)
--------------------------------------------------
📋 Validating web auth credentials...
✅ Web Auth validation: PASSED
👤 Fetching current user...
✅ User: _abc123def456ghi789
📁 Listing private zones...
✅ Found 2 private zone(s)

🔄 Test 3: AdaptiveTokenManager Transitions
--------------------------------------------------
✅ AdaptiveTokenManager transitions completed successfully!

======================================================================
✅ Authentication test suite completed!
======================================================================
```

## 🔧 Authentication Methods Explained

### 1. **API Token Authentication (APITokenManager)**
- **Use Case**: Public database access, server-to-server operations
- **Requires**: CloudKit API token only
- **Database Access**: Public database only
- **User Context**: No user-specific data
- **Best For**: Anonymous operations, public data queries

### 2. **Web Authentication (WebAuthTokenManager)**
- **Use Case**: User-specific operations, private database access
- **Requires**: API token + Web auth token (from user sign-in)
- **Database Access**: Private and shared databases
- **User Context**: Full user identity and permissions
- **Best For**: User-specific data, private records

### 3. **Server-to-Server Authentication (ServerToServerAuthManager)**
- **Use Case**: Enterprise applications, backend services
- **Requires**: ECDSA P-256 private key + Key ID
- **Database Access**: All databases with elevated permissions
- **User Context**: Service-level operations
- **Best For**: Backend services, batch operations

### 4. **Adaptive Authentication (AdaptiveTokenManager)**
- **Use Case**: Applications that need to switch between auth modes
- **Requires**: API token initially, can upgrade with web token
- **Database Access**: Starts with public, can access private after upgrade
- **User Context**: Transitions from anonymous to authenticated
- **Best For**: Apps with optional sign-in, progressive authentication

## 💡 Pro Tips

### Testing Best Practices
1. **Start with API-only** - No Apple ID required, works immediately
2. **Use the default container** initially to see how it works
3. **Enable verbose logging** to see all CloudKit requests/responses
4. **Check CloudKit Console** to verify your container setup
5. **Test transitions** to see the AdaptiveTokenManager switch between auth modes

### Common Issues & Solutions

#### "AUTHENTICATION_REQUIRED" Error
This is **expected behavior** for API-only authentication trying to access private databases:
```json
{
  "serverErrorCode": "AUTHENTICATION_REQUIRED",
  "reason": "request needs authorization"
}
```
**Solution**: Use web authentication for private database access.

#### Invalid API Token Format
```
❌ API token format is invalid
```
**Solution**: Ensure your API token is exactly 64 hexadecimal characters.

#### Container Not Found
```
❌ Container identifier not found
```
**Solution**: Verify your container ID in CloudKit Console.

#### Web Auth Token Expired
Web auth tokens expire after a certain period.
**Solution**: Re-authenticate through the web interface to get a fresh token.

### Development Workflow

1. **Development**: Use API-only for initial development and testing
2. **User Testing**: Implement web authentication for user-specific features
3. **Production**: Use appropriate authentication method based on use case
4. **Monitoring**: Use comprehensive test suite for CI/CD validation

## 🔗 Related Documentation

- [CloudKit Web Services Documentation](https://developer.apple.com/documentation/cloudkitjs)
- [CloudKit Console](https://icloud.developer.apple.com/dashboard)
- [MistKit Architecture](./README.md)
- [API Reference](./Sources/MistKit/Authentication/TokenManager.swift)

## 🆘 Getting Help

If you encounter issues:
1. Check the CloudKit Console for container and token configuration
2. Verify network connectivity to `api.apple-cloudkit.com`
3. Review the verbose logging output for request/response details
4. Ensure your Apple Developer account has CloudKit capabilities
5. Check that your container has the necessary database permissions

The demo includes comprehensive logging so you can see exactly how each authentication method works with the CloudKit Web Services API!