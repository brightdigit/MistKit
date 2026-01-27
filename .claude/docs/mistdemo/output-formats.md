# Output Formats

MistDemo supports four output formats: JSON, Table, CSV, and YAML. The output format can be specified using the `--output` or `-o` flag.

## Specifying Output Format

```bash
# JSON (default)
mistdemo query

# Explicit format
mistdemo query --output json
mistdemo query -o table
mistdemo query -o csv
mistdemo query -o yaml

# Pretty-printed
mistdemo query --output json --pretty
```

## JSON Format

Default format. Ideal for programmatic processing and piping to tools like `jq`.

### Features
- Machine-readable
- Preserves all data types
- Supports nested structures
- Integrates with JSON tools

### Options
- `--pretty` - Pretty-print with indentation

### Example Output

**Query results:**
```json
{
  "records": [
    {
      "recordName": "note_001",
      "recordType": "Note",
      "recordChangeTag": "abc123",
      "fields": {
        "title": {
          "value": "My First Note"
        },
        "index": {
          "value": 1
        },
        "createdAt": {
          "value": 1640995200000
        },
        "modified": {
          "value": 0
        }
      },
      "created": {
        "timestamp": 1640995200000,
        "userRecordName": "_abc123def456"
      },
      "modified": {
        "timestamp": 1640995200000,
        "userRecordName": "_abc123def456"
      }
    }
  ]
}
```

**Pretty-printed (`--pretty`):**
```json
{
  "records": [
    {
      "recordName": "note_001",
      "recordType": "Note",
      "fields": {
        "title": {
          "value": "My First Note"
        },
        "index": {
          "value": 1
        }
      }
    }
  ]
}
```

### Common Use Cases

**Extract specific fields with jq:**
```bash
mistdemo query -o json | jq -r '.records[].fields.title.value'
```

**Count results:**
```bash
mistdemo query -o json | jq '.records | length'
```

**Filter and transform:**
```bash
mistdemo query -o json | jq '[.records[] | {name: .recordName, title: .fields.title.value}]'
```

**Save for later processing:**
```bash
mistdemo query -o json --pretty > notes_backup.json
```

## Table Format

Human-readable tabular output. Best for terminal viewing and quick inspection.

### Features
- Easy to read
- Aligned columns
- UTF-8 box drawing characters
- Truncates long values

### Example Output

**Query results:**
```
┌───────────────┬──────────┬─────────────────────────┬───────┬──────────┐
│ Record Name   │ Type     │ Title                   │ Index │ Modified │
├───────────────┼──────────┼─────────────────────────┼───────┼──────────┤
│ note_001      │ Note     │ My First Note           │ 1     │ 0        │
│ note_002      │ Note     │ Another Important Note  │ 2     │ 0        │
│ note_003      │ Note     │ CloudKit Demo           │ 3     │ 1        │
└───────────────┴──────────┴─────────────────────────┴───────┴──────────┘
```

**User info:**
```
┌─────────────────────┬───────────────┐
│ Field               │ Value         │
├─────────────────────┼───────────────┤
│ User Record Name    │ _abc123def456 │
│ First Name          │ John          │
│ Last Name           │ Doe           │
│ Email               │ john@ex.com   │
│ Contacts Permission │ granted       │
└─────────────────────┴───────────────┘
```

**Zone list:**
```
┌──────────────┬───────────────────┬────────┬──────────────┐
│ Zone Name    │ Owner             │ Atomic │ Capabilities │
├──────────────┼───────────────────┼────────┼──────────────┤
│ CustomZone1  │ _abc123def456     │ true   │ FC,AT,SH     │
│ ProjectData  │ _abc123def456     │ true   │ FC,AT        │
└──────────────┴───────────────────┴────────┴──────────────┘

FC = Fetch Changes, AT = Atomic, SH = Sharing
```

### Column Selection

By default, table output shows the most relevant columns. Use `--fields` to customize:

```bash
# Show only specific fields
mistdemo query -o table --fields "title,index"

┌─────────────────────────┬───────┐
│ Title                   │ Index │
├─────────────────────────┼───────┤
│ My First Note           │ 1     │
│ Another Important Note  │ 2     │
└─────────────────────────┴───────┘
```

### Truncation

Long values are truncated to fit terminal width:

```
│ Very Long Title That Exceeds... │
```

## CSV Format

Comma-separated values. Best for spreadsheet import and data analysis.

### Features
- Standard CSV format (RFC 4180)
- Header row included
- Quoted fields when necessary
- Excel/Numbers compatible

### Example Output

**Query results:**
```csv
record_name,record_type,title,index,created_at,modified
note_001,Note,"My First Note",1,1640995200000,0
note_002,Note,"Another Important Note",2,1640995201000,0
note_003,Note,"CloudKit Demo",3,1640995202000,1
```

**With commas and quotes:**
```csv
record_name,record_type,title,index
note_001,Note,"Note with, comma",1
note_002,Note,"Note with ""quotes""",2
```

### Common Use Cases

**Import to spreadsheet:**
```bash
mistdemo query -o csv > notes.csv
# Open notes.csv in Excel/Numbers/Google Sheets
```

**Data analysis with csvkit:**
```bash
mistdemo query -o csv | csvstat
mistdemo query -o csv | csvgrep -c title -m "Important"
```

**Convert to other formats:**
```bash
# CSV to JSON
mistdemo query -o csv | csvjson > notes.json

# CSV to SQL
mistdemo query -o csv | csvsql --insert
```

## YAML Format

YAML format. Best for configuration-like output and human readability.

### Features
- Human-readable
- Preserves structure
- Comments supported (in output)
- Useful for documentation

### Example Output

**Query results:**
```yaml
records:
  - recordName: note_001
    recordType: Note
    recordChangeTag: abc123
    fields:
      title:
        value: My First Note
      index:
        value: 1
      createdAt:
        value: 1640995200000
      modified:
        value: 0
    created:
      timestamp: 1640995200000
      userRecordName: _abc123def456
    modified:
      timestamp: 1640995200000
      userRecordName: _abc123def456

  - recordName: note_002
    recordType: Note
    recordChangeTag: def456
    fields:
      title:
        value: Another Important Note
      index:
        value: 2
```

**User info:**
```yaml
userRecordName: _abc123def456
firstName: John
lastName: Doe
emailAddress: john@example.com
contactsPermission: granted
```

### Common Use Cases

**Generate documentation:**
```bash
mistdemo query -o yaml > examples/query_output.yaml
```

**Compare outputs:**
```bash
diff <(mistdemo query --filter "index=1" -o yaml) \
     <(mistdemo query --filter "index=2" -o yaml)
```

## Format Comparison

| Feature | JSON | Table | CSV | YAML |
|---------|------|-------|-----|------|
| **Human-readable** | ⚠️ Medium | ✅ High | ⚠️ Medium | ✅ High |
| **Machine-readable** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Preserves types** | ✅ Yes | ⚠️ Limited | ❌ No | ✅ Yes |
| **Nested data** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Compact** | ⚠️ Medium | ❌ No | ✅ Yes | ❌ No |
| **Spreadsheet import** | ⚠️ Possible | ❌ No | ✅ Yes | ⚠️ Possible |
| **Terminal viewing** | ⚠️ Medium | ✅ Best | ❌ No | ⚠️ Medium |
| **Scripting** | ✅ Best | ❌ No | ✅ Good | ✅ Good |

## Output Redirection

### Saving Output

```bash
# Save to file
mistdemo query -o json > results.json
mistdemo query -o csv > results.csv
mistdemo query -o yaml > results.yaml

# Append to file
mistdemo query -o json >> all_results.json

# Both stdout and file (tee)
mistdemo query -o table | tee results.txt
```

### Piping to Other Tools

**JSON:**
```bash
# jq for JSON processing
mistdemo query -o json | jq '.records[0]'

# Filter and format
mistdemo query -o json | jq -r '.records[] | "\(.recordName): \(.fields.title.value)"'
```

**CSV:**
```bash
# csvkit for CSV processing
mistdemo query -o csv | csvcut -c title,index

# grep for filtering
mistdemo query -o csv | grep "Important"
```

**YAML:**
```bash
# yq for YAML processing
mistdemo query -o yaml | yq '.records[0].fields.title.value'

# Convert YAML to JSON
mistdemo query -o yaml | yq -o json
```

**Table:**
```bash
# Paginate
mistdemo query -o table | less

# Search
mistdemo query -o table | grep "CloudKit"
```

## Error Output

Errors are always output to stderr in JSON format, regardless of `--output` setting:

```bash
# Stdout: empty
# Stderr: error JSON
mistdemo query --filter "invalid syntax" -o table
```

**Error format (stderr):**
```json
{
  "error": {
    "code": "INVALID_QUERY",
    "message": "Invalid filter expression",
    "details": {
      "expression": "invalid syntax",
      "reason": "Unexpected token 'syntax'"
    }
  }
}
```

This allows error handling in scripts:
```bash
if ! output=$(mistdemo query -o table 2> error.json); then
  echo "Error occurred:"
  cat error.json | jq -r '.error.message'
fi
```

## Configuration

### Default Output Format

Set default format via configuration:

**config.json:**
```json
{
  "output": "table",
  "pretty": true
}
```

**Environment variable:**
```bash
export MISTDEMO_OUTPUT=table
```

### Per-Command Override

```bash
# Default is table (from config)
# Override to JSON for this command
mistdemo query -o json
```

## Best Practices

### Choose Format by Use Case

- **Scripting/Automation**: Use JSON
- **Terminal viewing**: Use Table
- **Data export**: Use CSV
- **Documentation**: Use YAML
- **Debugging**: Use JSON with `--pretty`

### Consistent Formatting

```bash
# Set default in config.json for consistent experience
{
  "output": "table",
  "pretty": true
}
```

### Error Handling

Always check stderr for errors:
```bash
if ! mistdemo query -o json 2> errors.txt; then
  cat errors.txt | jq -r '.error.message'
  exit 1
fi
```

## Related Documentation

- **[Overview](overview.md)** - Global options
- **[Configuration](configuration.md)** - Setting default output format
- **[Error Handling](error-handling.md)** - Error output format
