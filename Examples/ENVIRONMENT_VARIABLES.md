# Environment Variables Configuration

This document describes the environment variables used by MistKit for secure configuration management.

## Required Variables

### CLOUDKIT_API_TOKEN
- **Description**: CloudKit API Token for authentication
- **Format**: 64-character hexadecimal string
- **Source**: [Apple Developer Console](https://icloud.developer.apple.com/dashboard/)
- **Example**: `296c503003846ef692cb5b56c4a63cc1d27fb952eebe259d73e692759286dfa6`

## Optional Variables

### CLOUDKIT_WEB_AUTH_TOKEN
- **Description**: Web authentication token for user-specific operations
- **Format**: Base64-encoded string (obtained through web auth flow)
- **Example**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### CLOUDKIT_CONTAINER_IDENTIFIER
- **Description**: CloudKit container identifier
- **Default**: `iCloud.com.brightdigit.MistDemo`
- **Example**: `iCloud.com.yourcompany.yourapp`

### CLOUDKIT_ENVIRONMENT
- **Description**: CloudKit environment (development or production)
- **Default**: `development`
- **Values**: `development`, `production`

### CLOUDKIT_KEY_ID
- **Description**: Server-to-server authentication key ID
- **Format**: Alphanumeric string from Apple Developer Console
- **Example**: `ABC123DEF456`

### CLOUDKIT_PRIVATE_KEY
- **Description**: Server-to-server private key in PEM format
- **Format**: PEM-encoded private key
- **Example**: 
```
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg...
-----END PRIVATE KEY-----
```

### CLOUDKIT_PRIVATE_KEY_FILE
- **Description**: Path to private key file (alternative to CLOUDKIT_PRIVATE_KEY)
- **Format**: File system path
- **Example**: `/path/to/private_key.pem`

## Usage Examples

### Setting Environment Variables

#### macOS/Linux (Bash/Zsh)
```bash
export CLOUDKIT_API_TOKEN="your_api_token_here"
export CLOUDKIT_CONTAINER_IDENTIFIER="iCloud.com.yourcompany.yourapp"
export CLOUDKIT_ENVIRONMENT="development"
```

#### Windows (PowerShell)
```powershell
$env:CLOUDKIT_API_TOKEN="your_api_token_here"
$env:CLOUDKIT_CONTAINER_IDENTIFIER="iCloud.com.yourcompany.yourapp"
$env:CLOUDKIT_ENVIRONMENT="development"
```

#### Using .env file (with dotenv tools)
```bash
# Create .env file
echo "CLOUDKIT_API_TOKEN=your_api_token_here" > .env
echo "CLOUDKIT_CONTAINER_IDENTIFIER=iCloud.com.yourcompany.yourapp" >> .env
```

### Running MistDemo with Environment Variables

```bash
# Set environment variables and run
export CLOUDKIT_API_TOKEN="your_token"
swift run mistdemo

# Or run with inline environment variables
CLOUDKIT_API_TOKEN="your_token" swift run mistdemo
```

## Security Best Practices

1. **Never commit sensitive values to version control**
   - Add `.env` files to `.gitignore`
   - Use placeholder values in documentation

2. **Use different values for different environments**
   - Development: Use test/sandbox values
   - Production: Use production values
   - Staging: Use separate staging values

3. **Rotate credentials regularly**
   - Generate new API tokens periodically
   - Rotate server-to-server keys as needed

4. **Use secure storage for production**
   - Consider using key management services
   - Avoid hardcoding in application code

5. **Validate environment variables**
   - Check that required variables are set
   - Validate format of sensitive values
   - Use masked logging for debugging

## Troubleshooting

### Missing Required Variable
```
❌ Error: CloudKit API token is required
   Provide it via --api-token or set CLOUDKIT_API_TOKEN environment variable
```

**Solution**: Set the required environment variable or pass it as a command-line argument.

### Invalid Token Format
```
❌ Error: API token format is invalid (expected 64-character hex string)
```

**Solution**: Ensure the API token is exactly 64 hexadecimal characters.

### Environment Variable Not Found
```
❌ Error: Missing required environment variable 'CLOUDKIT_API_TOKEN': CloudKit API Token
```

**Solution**: Set the environment variable in your shell or use a .env file.
