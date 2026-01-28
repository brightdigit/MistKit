# Configuration Management

MistDemo supports flexible configuration through files, profiles, environment variables, and command-line arguments using Apple's Swift Configuration package.

## Configuration Sources

Configuration is resolved from multiple sources with the following priority (highest to lowest):

**Current Implementation:**
1. **Environment variables** - System environment (e.g., `CLOUDKIT_CONTAINER_ID`)
2. **Built-in defaults** - Hardcoded fallback values in `InMemoryProvider`

**Planned Additions:**
1. **Command-line arguments** - Explicit flags like `--database private` (requires CommandLineArgumentsProvider)
2. **Profile settings** - From `--profile` in configuration file
3. **Configuration file** - Default values in JSON/YAML file (requires FileProvider)

## Swift Configuration Package

MistDemo uses [swift-configuration](https://github.com/apple/swift-configuration) for hierarchical configuration management.

### Requirements

- **macOS 15.0+** required due to Swift Configuration dependency
- Swift 6.0 or later

### Package Configuration

```swift
.package(
    url: "https://github.com/apple/swift-configuration",
    from: "1.0.0"
)
```

### Current Implementation

| Provider | Status | Purpose |
|----------|--------|---------|  
| `EnvironmentVariablesProvider` | ✅ Implemented | Environment variables with automatic key transformation |
| `InMemoryProvider` | ✅ Implemented | Default values |
| `CommandLineArgumentsProvider` | ⏳ Planned | CLI argument parsing |
| `FileProvider + JSONSnapshot` | ⏳ Planned | JSON configuration files |
| `FileProvider + YAMLSnapshot` | ⏳ Planned | YAML configuration files |

## Configuration File Formats

### JSON Configuration

Default format, no additional trait needed.

**config.json:**
```json
{
  "container_id": "iCloud.com.example.MyApp",
  "api_token": "your-api-token",
  "environment": "development",
  "database": "private",
  "output": "table",
  "pretty": true,
  "profiles": {
    "production": {
      "environment": "production",
      "database": "public",
      "output": "json"
    },
    "testing": {
      "environment": "development",
      "container_id": "iCloud.com.example.MyApp.Testing",
      "database": "private"
    }
  }
}
```

### YAML Configuration

Requires `"YAML"` trait enabled.

**config.yaml:**
```yaml
container_id: iCloud.com.example.MyApp
api_token: your-api-token
environment: development
database: private
output: table
pretty: true

profiles:
  production:
    environment: production
    database: public
    output: json

  testing:
    environment: development
    container_id: iCloud.com.example.MyApp.Testing
    database: private
```

### Configuration Keys

**Note**: Swift Configuration automatically transforms keys:
- Dots (`.`) become underscores (`_`) for environment variables
- Example: `container.identifier` → `CONTAINER_IDENTIFIER` environment variable
- When CommandLineArgumentsProvider is added: dots become hyphens for CLI args (`container.identifier` → `--container-identifier`)

| Key | Type | Environment Variable (Auto-transformed) | Default | Description |
|-----|------|---------------------|---------|-------------|
| `container.identifier` | String | `CONTAINER_IDENTIFIER` | `iCloud.com.brightdigit.MistDemo` | Container identifier |
| `api.token` | String | `API_TOKEN` | Empty string | API token (secret) |
| `environment` | String | `ENVIRONMENT` | `development` | CloudKit environment |
| `database` | String | `DATABASE` | Varies by auth method | Database type |
| `web.auth.token` | String | `WEB_AUTH_TOKEN` | | Web auth token (secret) |
| `key.id` | String | `KEY_ID` | | Server-to-server key ID |
| `private.key` | String | `PRIVATE_KEY` | | Private key content (secret) |
| `private.key.file` | String | `PRIVATE_KEY_FILE` | | Path to private key |
| `host` | String | `HOST` | `127.0.0.1` | Server host for authentication |
| `port` | Int | `PORT` | `8080` | Server port |
| `output` | String | `MISTDEMO_OUTPUT` | `json` | Output format |
| `pretty` | Boolean | `MISTDEMO_PRETTY` | `false` | Pretty print output |
| `verbose` | Boolean | `MISTDEMO_VERBOSE` | `false` | Verbose logging |
| `no_redaction` | Boolean | `MISTDEMO_NO_REDACTION` | `false` | Disable log redaction |

## Using Configuration Files

### Specify Configuration File

```bash
# Via command-line
mistdemo query --config-file ~/.mistdemo/config.json

# Via environment variable
export MISTDEMO_CONFIG_FILE=~/.mistdemo/config.json
mistdemo query
```

### Default Locations

MistDemo searches for configuration files in this order:
1. Path specified by `--config-file`
2. `$MISTDEMO_CONFIG_FILE` environment variable
3. `~/.mistdemo/config.json`
4. `~/.mistdemo/config.yaml`
5. `./.mistdemo.json`
6. `./.mistdemo.yaml`

### File Format Detection

Format is determined by file extension:
- `.json` - Uses `JSONSnapshot`
- `.yaml` or `.yml` - Uses `YAMLSnapshot`

## Configuration Profiles

Profiles allow multiple named configurations in a single file.

### Defining Profiles

```json
{
  "container_id": "iCloud.com.example.MyApp",
  "api_token": "default-token",
  "environment": "development",

  "profiles": {
    "production": {
      "environment": "production",
      "database": "public",
      "api_token": "production-token"
    },
    "staging": {
      "environment": "production",
      "database": "public",
      "container_id": "iCloud.com.example.MyApp.Staging"
    },
    "local": {
      "environment": "development",
      "database": "private"
    }
  }
}
```

### Using Profiles

```bash
# Use production profile
mistdemo query --profile production

# Use staging profile
mistdemo create --profile staging --field "title:string:Test"

# Override profile settings
mistdemo query --profile production --database private
```

### Profile Merging

Profiles merge with base configuration:
1. Start with base configuration values
2. Apply profile-specific overrides
3. Apply command-line argument overrides

Example:
```json
{
  "container_id": "iCloud.com.example.MyApp",  // Base
  "environment": "development",                  // Base
  "database": "public",                          // Base

  "profiles": {
    "production": {
      "environment": "production"  // Overrides base
      // container_id and database inherited from base
    }
  }
}
```

## Environment Variables

All configuration keys can be set via environment variables.

### Variable Naming

| Configuration Key | Environment Variable |
|------------------|---------------------|
| `container_id` | `CLOUDKIT_CONTAINER_ID` |
| `api_token` | `CLOUDKIT_API_TOKEN` |
| `environment` | `CLOUDKIT_ENVIRONMENT` |
| `database` | `CLOUDKIT_DATABASE` |
| `web_auth_token` | `CLOUDKIT_WEBAUTH_TOKEN` |
| `key_id` | `CLOUDKIT_KEY_ID` |
| `private_key_file` | `CLOUDKIT_PRIVATE_KEY_FILE` |
| `output` | `MISTDEMO_OUTPUT` |
| `pretty` | `MISTDEMO_PRETTY` |
| `config_file` | `MISTDEMO_CONFIG_FILE` |
| `profile` | `MISTDEMO_PROFILE` |
| `verbose` | `MISTDEMO_VERBOSE` |
| `no_redaction` | `MISTDEMO_NO_REDACTION` |

### Environment Setup

**Development:**
```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.MyApp"
export CLOUDKIT_API_TOKEN="your-dev-token"
export CLOUDKIT_ENVIRONMENT="development"
export CLOUDKIT_DATABASE="private"
export MISTDEMO_OUTPUT="table"
export MISTDEMO_VERBOSE="true"
```

**Production:**
```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.MyApp"
export CLOUDKIT_API_TOKEN="your-prod-token"
export CLOUDKIT_ENVIRONMENT="production"
export CLOUDKIT_DATABASE="public"
export CLOUDKIT_KEY_ID="your-key-id"
export CLOUDKIT_PRIVATE_KEY_FILE="/secure/path/to/key.pem"
```

### .env Files

```bash
# .env.development
CLOUDKIT_CONTAINER_ID=iCloud.com.example.MyApp
CLOUDKIT_API_TOKEN=dev-token
CLOUDKIT_ENVIRONMENT=development
CLOUDKIT_DATABASE=private
MISTDEMO_OUTPUT=table

# Load environment
source .env.development

# Or use with tools like direnv, dotenv
```

## Configuration Priority Examples

### Example 1: Simple Override

**config.json:**
```json
{
  "database": "public",
  "output": "json"
}
```

**Command:**
```bash
mistdemo query --database private --output table
```

**Result:**
- `database`: `private` (CLI argument)
- `output`: `table` (CLI argument)

### Example 2: Profile with Override

**config.json:**
```json
{
  "database": "public",
  "environment": "development",

  "profiles": {
    "production": {
      "environment": "production",
      "database": "public"
    }
  }
}
```

**Command:**
```bash
mistdemo query --profile production --database private
```

**Result:**
- `environment`: `production` (from profile)
- `database`: `private` (CLI argument overrides profile)

### Example 3: Full Priority Chain

**config.json:**
```json
{
  "output": "json"
}
```

**Environment:**
```bash
export MISTDEMO_OUTPUT=table
```

**Profile (in config.json):**
```json
{
  "profiles": {
    "dev": {
      "output": "csv"
    }
  }
}
```

**Command:**
```bash
mistdemo query --profile dev --output yaml
```

**Resolution Order:**
1. CLI: `yaml` ✓ (highest priority, wins)
2. Profile: `csv`
3. Config file: `json`
4. Environment: `table`
5. Default: `json`

**Result:** `output` = `yaml`

## Secrets Management

### Secret Configuration Keys

Mark sensitive keys in configuration:
- `api_token`
- `web_auth_token`
- `private_key_file` content

### Best Practices

1. **Never commit secrets to version control**
   ```gitignore
   # .gitignore
   .env
   .env.*
   config.json
   *.token
   *.pem
   ```

2. **Use environment variables for secrets**
   ```bash
   # Good
   export CLOUDKIT_API_TOKEN=$(cat ~/.secrets/cloudkit_token)

   # Bad
   # Don't put secrets in config files in repositories
   ```

3. **Secure file permissions**
   ```bash
   chmod 600 ~/.mistdemo/config.json
   chmod 600 ~/.mistdemo/*.pem
   ```

4. **Use secrets management systems**
   - macOS Keychain
   - 1Password CLI
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault

### Example: Using Keychain

```bash
# Store token in keychain
security add-generic-password \
  -a "$USER" \
  -s "cloudkit-api-token" \
  -w "your-api-token"

# Retrieve and use
export CLOUDKIT_API_TOKEN=$(security find-generic-password \
  -a "$USER" \
  -s "cloudkit-api-token" \
  -w)

mistdemo query
```

## Command-Specific Configuration

Future enhancement: namespace configuration by subcommand.

### Planned Structure

```json
{
  "container_id": "iCloud.com.example.MyApp",

  "query": {
    "limit": 50,
    "zone": "_defaultZone",
    "output": "table"
  },

  "create": {
    "zone": "_defaultZone"
  }
}
```

See [ConfigKeyKit Strategy](configkeykit-strategy.md) for implementation details.

## Configuration Validation

### Validate Configuration

```bash
# Test configuration by querying current user
mistdemo current-user --config-file ~/.mistdemo/config.json

# Validate with specific profile
mistdemo validate --profile production --test-query
```

### Common Validation Errors

**Missing required fields:**
```
Error: Missing required configuration
  Required: container_id
  Required: api_token
```

**Invalid environment:**
```
Error: Invalid environment value
  Value: "prod"
  Expected: development | production
```

**File not found:**
```
Error: Configuration file not found
  Path: /path/to/config.json
```

## Related Documentation

- **[Overview](overview.md)** - Global options reference
- **[ConfigKeyKit Strategy](configkeykit-strategy.md)** - Implementation patterns
- **[Authentication Operations](operations-auth.md)** - Managing credentials
- **[Error Handling](error-handling.md)** - Configuration error codes
