# MistDemo Examples

This directory contains example scripts demonstrating how to use MistDemo's essential commands for CloudKit operations.

## Quick Start

1. **Set up authentication**:
   ```bash
   ./auth-flow.sh
   ```

2. **Create your first record**:
   ```bash
   ./create-record.sh
   ```

3. **Query records**:
   ```bash
   ./query-records.sh
   ```

## Example Scripts

### 🔐 auth-flow.sh
**Complete authentication workflow**

Demonstrates the full authentication process:
- Gets web authentication token via browser
- Verifies authentication with current-user command
- Saves configuration for future use
- Tests with a simple query

**Usage**:
```bash
export CLOUDKIT_API_TOKEN=your_api_token_here
./examples/auth-flow.sh
```

**What it does**:
1. Starts local authentication server
2. Opens browser for CloudKit login
3. Captures and validates web auth token
4. Saves credentials to `~/.mistdemo/config.json`
5. Tests authentication with a query

### 📝 create-record.sh
**Record creation examples**

Shows various ways to create CloudKit records:
- Inline field definitions
- Multiple field types (string, int64, double, timestamp)
- Custom record names
- JSON file input
- stdin input
- Different output formats

**Examples**:
```bash
# Simple note
swift run mistdemo create --field "title:string:My Note"

# Multiple fields
swift run mistdemo create --field "title:string:Task, priority:int64:5, progress:double:0.75"

# From JSON file
swift run mistdemo create --json-file fields.json

# From stdin
echo '{"title":"Quick Note"}' | swift run mistdemo create --stdin
```

### 🔍 query-records.sh
**Query and filtering examples**

Demonstrates CloudKit query capabilities:
- Basic queries
- Filtering with various operators
- Sorting (ascending/descending)
- Field selection
- Pagination
- Different output formats

**Examples**:
```bash
# Basic query
swift run mistdemo query --record-type Note --limit 10

# With filters
swift run mistdemo query --filter "title:contains:important" --filter "priority:gt:5"

# With sorting
swift run mistdemo query --sort "createdAt:desc" --limit 5

# Field selection
swift run mistdemo query --fields "title,createdAt,priority"
```

## Field Types

MistDemo supports four CloudKit field types:

| Type | Description | Example |
|------|-------------|---------|
| `string` | Text values | `title:string:My Note Title` |
| `int64` | Integer numbers | `priority:int64:5` |
| `double` | Decimal numbers | `rating:double:4.5` |
| `timestamp` | ISO 8601 dates | `deadline:timestamp:2026-12-31T23:59:59Z` |

## Filter Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `eq` | Equals | `status:eq:active` |
| `ne` | Not equals | `status:ne:deleted` |
| `lt` | Less than | `priority:lt:5` |
| `lte` | Less than or equal | `priority:lte:5` |
| `gt` | Greater than | `priority:gt:3` |
| `gte` | Greater than or equal | `priority:gte:3` |
| `in` | In list | `category:in:work,personal` |
| `contains` | Contains text | `title:contains:meeting` |
| `beginsWith` | Begins with text | `title:beginsWith:Project` |

## Output Formats

All commands support multiple output formats:

- `json` - JSON format (default, machine-readable)
- `table` - ASCII table format (human-readable)
- `csv` - CSV format (spreadsheet-compatible)
- `yaml` - YAML format (configuration-friendly)

## Configuration

### Environment Variables
```bash
export CLOUDKIT_API_TOKEN=your_api_token
export CLOUDKIT_WEB_AUTH_TOKEN=your_web_auth_token
```

### Configuration File
Location: `~/.mistdemo/config.json`

```json
{
    "api_token": "your_api_token",
    "web_auth_token": "your_web_auth_token",
    "container_id": "iCloud.com.brightdigit.MistDemo",
    "environment": "development"
}
```

### Command Line Options
```bash
swift run mistdemo <command> \
    --api-token your_api_token \
    --web-auth-token your_web_auth_token \
    --output-format json
```

## Prerequisites

1. **CloudKit API Token**: Get this from Apple Developer portal
2. **Apple ID**: Required for web authentication
3. **Swift 5.9+**: Required to build and run MistDemo

## Troubleshooting

### Authentication Issues
- Ensure your API token is valid and has CloudKit permissions
- Check that your Apple ID has access to the container
- Verify you're using the correct environment (development/production)

### Query Issues
- Start with simple queries and add filters gradually
- Check field names match your CloudKit schema
- Verify record types exist in your container

### Create Issues
- Validate field types match your schema requirements
- Ensure required fields are included
- Check zone permissions if using custom zones

## Next Steps

After running these examples:

1. **Explore the schema**: Check `schema.ckdb` to understand the data structure
2. **Build integrations**: Use JSON output format for programmatic access
3. **Automate workflows**: Create shell scripts combining multiple operations
4. **Scale up**: Consider pagination for large datasets

## Support

For more information:
- Check the main MistDemo documentation
- Review the Phase 2 implementation in `.claude/docs/mistdemo/phases/`
- Open issues on the GitHub repository for bugs or feature requests