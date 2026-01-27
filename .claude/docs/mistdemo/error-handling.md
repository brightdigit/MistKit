# Error Handling

MistDemo provides consistent error reporting across all subcommands with detailed context and actionable suggestions.

## Error Output Format

Errors are always written to **stderr** in JSON format, regardless of the `--output` setting.

### Standard Error Structure

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "operation": "operation-name",
    "details": {
      "key": "value"
    },
    "suggestion": "How to fix the error"
  }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `code` | String | Machine-readable error code |
| `message` | String | Human-readable error description |
| `operation` | String | CloudKit operation that failed |
| `details` | Object | Additional context and debugging information |
| `suggestion` | String | Actionable suggestion for fixing the error |

## Error Codes

### Authentication Errors

**AUTHENTICATION_FAILED**
```json
{
  "error": {
    "code": "AUTHENTICATION_FAILED",
    "message": "Invalid or expired web authentication token",
    "operation": "query",
    "suggestion": "Run 'mistdemo auth-token' to obtain a new token"
  }
}
```

**MISSING_CREDENTIALS**
```json
{
  "error": {
    "code": "MISSING_CREDENTIALS",
    "message": "Required authentication credentials not provided",
    "details": {
      "required": ["container_id", "api_token"],
      "missing": ["api_token"]
    },
    "suggestion": "Set CLOUDKIT_API_TOKEN or use --api-token flag"
  }
}
```

**NOT_AUTHORIZED**
```json
{
  "error": {
    "code": "NOT_AUTHORIZED",
    "message": "User has not granted contacts permission",
    "operation": "lookup-contacts",
    "suggestion": "Request contacts permission from user"
  }
}
```

### Query Errors

**INVALID_QUERY**
```json
{
  "error": {
    "code": "INVALID_QUERY",
    "message": "Invalid filter expression",
    "operation": "query",
    "details": {
      "expression": "invalidField > 10",
      "reason": "Unknown field 'invalidField'",
      "validFields": ["title", "index", "createdAt", "modified"]
    },
    "suggestion": "Use one of: title, index, createdAt, modified"
  }
}
```

**INVALID_SORT_KEY**
```json
{
  "error": {
    "code": "INVALID_SORT_KEY",
    "message": "Sort field is not queryable",
    "operation": "query",
    "details": {
      "field": "image",
      "sortableFields": ["title", "index", "createdAt"]
    },
    "suggestion": "Try 'mistdemo query --help' for more information"
  }
}
```

### Record Errors

**RECORD_NOT_FOUND**
```json
{
  "error": {
    "code": "RECORD_NOT_FOUND",
    "message": "Record does not exist",
    "operation": "update",
    "details": {
      "recordName": "note_001",
      "recordType": "Note",
      "zoneName": "_defaultZone"
    },
    "suggestion": "Verify record name with 'mistdemo query'"
  }
}
```

**CONFLICT**
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "Record was modified by another client",
    "operation": "update",
    "details": {
      "recordName": "note_001",
      "expectedChangeTag": "abc123",
      "actualChangeTag": "def456"
    },
    "suggestion": "Fetch latest record and retry, or use --force"
  }
}
```

**VALIDATION_ERROR**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid field value",
    "operation": "create",
    "details": {
      "field": "index",
      "value": "not-a-number",
      "expectedType": "int64",
      "actualType": "string"
    },
    "suggestion": "Use format: --field \"index:int64:42\""
  }
}
```

### Zone Errors

**ZONE_NOT_FOUND**
```json
{
  "error": {
    "code": "ZONE_NOT_FOUND",
    "message": "Zone does not exist",
    "operation": "lookup-zones",
    "details": {
      "zoneName": "CustomZone1"
    },
    "suggestion": "Create zone with 'mistdemo modify-zones'"
  }
}
```

**ZONE_BUSY**
```json
{
  "error": {
    "code": "ZONE_BUSY",
    "message": "Zone is currently being modified",
    "operation": "modify-zones",
    "details": {
      "zoneName": "CustomZone1"
    },
    "suggestion": "Wait a moment and retry"
  }
}
```

### Configuration Errors

**INVALID_CONFIGURATION**
```json
{
  "error": {
    "code": "INVALID_CONFIGURATION",
    "message": "Configuration file is malformed",
    "details": {
      "file": "~/.mistdemo/config.json",
      "line": 10,
      "reason": "Unexpected token '}'"
    },
    "suggestion": "Check JSON syntax in configuration file"
  }
}
```

**MISSING_CONFIGURATION**
```json
{
  "error": {
    "code": "MISSING_CONFIGURATION",
    "message": "Configuration file not found",
    "details": {
      "searchedPaths": [
        "~/.mistdemo/config.json",
        "~/.mistdemo/config.yaml",
        "./.mistdemo.json"
      ]
    },
    "suggestion": "Create config file or use command-line options"
  }
}
```

### Network Errors

**NETWORK_ERROR**
```json
{
  "error": {
    "code": "NETWORK_ERROR",
    "message": "Network request failed",
    "operation": "query",
    "details": {
      "url": "https://api.apple-cloudkit.com/...",
      "reason": "Connection timeout"
    },
    "suggestion": "Check internet connection and retry"
  }
}
```

**SERVICE_UNAVAILABLE**
```json
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "CloudKit service is temporarily unavailable",
    "operation": "query",
    "details": {
      "statusCode": 503,
      "retryAfter": 30
    },
    "suggestion": "Retry after 30 seconds"
  }
}
```

### Rate Limiting

**THROTTLED**
```json
{
  "error": {
    "code": "THROTTLED",
    "message": "Request rate limit exceeded",
    "operation": "query",
    "details": {
      "retryAfter": 60,
      "limit": "100 requests per minute"
    },
    "suggestion": "Wait 60 seconds before retrying"
  }
}
```

## Exit Codes

MistDemo uses standard exit codes for script integration:

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Invalid usage (bad arguments) |
| `3` | Authentication error |
| `4` | Network error |
| `5` | Configuration error |
| `10` | Record not found |
| `11` | Validation error |
| `12` | Conflict error |

### Using Exit Codes

```bash
# Check for success
if mistdemo query > results.json; then
  echo "Success"
else
  echo "Failed with exit code: $?"
fi

# Handle specific errors
mistdemo update note_001 --field "title:string:New"
case $? in
  0)
    echo "Updated successfully"
    ;;
  3)
    echo "Authentication failed"
    mistdemo auth-token
    ;;
  10)
    echo "Record not found"
    ;;
  12)
    echo "Conflict - record was modified"
    ;;
  *)
    echo "Other error"
    ;;
esac
```

## Verbose Error Output

Use `--verbose` for detailed error information including:
- Full request/response details
- Stack traces (in debug builds)
- Timing information
- Intermediate steps

```bash
mistdemo query --verbose 2> detailed_error.json
```

**Verbose error output:**
```json
{
  "error": {
    "code": "INVALID_QUERY",
    "message": "Invalid filter expression",
    "operation": "query",
    "details": {
      "expression": "badField > 10",
      "validFields": ["title", "index", "createdAt", "modified"],
      "request": {
        "method": "POST",
        "url": "https://api.apple-cloudkit.com/.../records/query",
        "headers": {...},
        "body": {...}
      },
      "response": {
        "statusCode": 400,
        "headers": {...},
        "body": {...}
      },
      "duration": 0.234
    },
    "suggestion": "Use one of: title, index, createdAt, modified"
  }
}
```

## Error Handling in Scripts

### Basic Error Handling

```bash
#!/bin/bash
set -e  # Exit on error

# Capture stderr
if ! output=$(mistdemo query 2> error.json); then
  echo "Error occurred:"
  jq -r '.error.message' error.json
  exit 1
fi

echo "$output" | jq '.records'
```

### Retry Logic

```bash
#!/bin/bash

retry_query() {
  local retries=3
  local delay=5

  for i in $(seq 1 $retries); do
    if output=$(mistdemo query 2> error.json); then
      echo "$output"
      return 0
    fi

    # Check error code
    code=$(jq -r '.error.code' error.json)

    if [ "$code" = "THROTTLED" ]; then
      wait_time=$(jq -r '.error.details.retryAfter' error.json)
      echo "Rate limited, waiting ${wait_time}s..." >&2
      sleep "$wait_time"
    elif [ "$code" = "SERVICE_UNAVAILABLE" ]; then
      echo "Service unavailable, retry $i/$retries..." >&2
      sleep "$delay"
    else
      # Non-retryable error
      jq -r '.error.message' error.json >&2
      return 1
    fi
  done

  echo "Max retries exceeded" >&2
  return 1
}

retry_query
```

### Authentication Retry

```bash
#!/bin/bash

query_with_auth_retry() {
  if output=$(mistdemo query --database private 2> error.json); then
    echo "$output"
    return 0
  fi

  code=$(jq -r '.error.code' error.json)

  if [ "$code" = "AUTHENTICATION_FAILED" ]; then
    echo "Token expired, re-authenticating..." >&2
    export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a "$CLOUDKIT_API_TOKEN")

    # Retry
    mistdemo query --database private
  else
    jq -r '.error.message' error.json >&2
    return 1
  fi
}

query_with_auth_retry
```

## Common Error Scenarios

### Scenario 1: Invalid Credentials

**Error:**
```
Error: Invalid or expired web authentication token
```

**Solution:**
```bash
# Get new token
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a "$CLOUDKIT_API_TOKEN")

# Retry operation
mistdemo query --database private
```

### Scenario 2: Record Conflict

**Error:**
```
Error: Record was modified by another client
```

**Solution:**
```bash
# Option 1: Fetch latest and retry
mistdemo lookup note_001 > current.json
CHANGE_TAG=$(jq -r '.records[0].recordChangeTag' current.json)
mistdemo update note_001 --field "title:string:Updated" --change-tag "$CHANGE_TAG"

# Option 2: Force update
mistdemo update note_001 --field "title:string:Updated" --force
```

### Scenario 3: Rate Limiting

**Error:**
```
Error: Request rate limit exceeded
```

**Solution:**
```bash
# Wait and retry
sleep 60
mistdemo query

# Or implement exponential backoff
```

### Scenario 4: Invalid Query

**Error:**
```
Error: Unknown field 'invalidField' in filter
```

**Solution:**
```bash
# Check available fields
mistdemo query --help

# Use valid field
mistdemo query --filter "title CONTAINS 'test'"
```

## Best Practices

1. **Always check exit codes**
   ```bash
   if ! mistdemo query > output.json; then
     handle_error
   fi
   ```

2. **Capture and parse stderr**
   ```bash
   output=$(mistdemo query 2> error.json)
   ```

3. **Implement retry logic for transient errors**
   - `THROTTLED`
   - `SERVICE_UNAVAILABLE`
   - `NETWORK_ERROR`

4. **Don't retry non-transient errors**
   - `AUTHENTICATION_FAILED`
   - `INVALID_QUERY`
   - `VALIDATION_ERROR`

5. **Use verbose mode for debugging**
   ```bash
   mistdemo query --verbose --no-redaction 2> debug.json
   ```

6. **Log errors for troubleshooting**
   ```bash
   mistdemo query 2>&1 | tee -a mistdemo.log
   ```

## Related Documentation

- **[Overview](overview.md)** - Global options and debugging flags
- **[Authentication Operations](operations-auth.md)** - Handling auth errors
- **[Configuration](configuration.md)** - Fixing configuration errors
- **[Output Formats](output-formats.md)** - Understanding error output
