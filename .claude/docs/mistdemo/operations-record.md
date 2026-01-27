# Record Operations

All record operations in MistDemo work with the `Note` record type defined in `schema.ckdb`.

## Note Record Type

| Field | Type | Queryable | Sortable | Searchable |
|-------|------|-----------|----------|------------|
| `title` | STRING | ✓ | ✓ | ✓ |
| `index` | INT64 | ✓ | ✓ | |
| `image` | ASSET | | | |
| `createdAt` | TIMESTAMP | ✓ | ✓ | |
| `modified` | INT64 | ✓ | | |

## query

Query Note records from CloudKit with filtering and sorting.

### Syntax
```bash
mistdemo query [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--zone` | Zone name | `_defaultZone` |
| `--filter` | Query filter expression (repeatable) | None |
| `--sort` | Sort field and direction (e.g., `"createdAt:desc"`) | None |
| `--limit` | Maximum records to return (1-200) | `20` |
| `--offset` | Pagination offset | `0` |
| `--fields` | Comma-separated list of fields to return | All fields |
| `--continuation-marker` | Pagination continuation marker | None |

### Filter Expressions

Supported operators:
- `=` - Equals
- `!=` - Not equals
- `>`, `>=`, `<`, `<=` - Comparisons
- `CONTAINS` - String contains (case-insensitive)
- `BEGINSWITH` - String starts with
- `IN` - Value in list

Supported fields: `title`, `index`, `createdAt`, `modified`

### Sort Directions
- `asc` - Ascending (default)
- `desc` - Descending

### Examples

**Query all records:**
```bash
mistdemo query
```

**Query with filters:**
```bash
mistdemo query \
  --filter "title CONTAINS 'test'" \
  --filter "index > 10" \
  --sort "createdAt:desc" \
  --limit 50
```

**Query specific fields:**
```bash
mistdemo query --fields "title,index,createdAt"
```

**Sort by index:**
```bash
mistdemo query --sort "index:asc"
```

**Paginated query:**
```bash
# First page
mistdemo query --limit 20 > page1.json

# Extract continuation marker and fetch next page
MARKER=$(jq -r '.continuationMarker' page1.json)
mistdemo query --limit 20 --continuation-marker "$MARKER"
```

## create

Create a new Note record in CloudKit.

### Syntax
```bash
mistdemo create [options]
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--zone` | | Zone name (default: `_defaultZone`) |
| `--record-name` | | Custom record name (auto-generated if omitted) |
| `--field` | `-f` | Field in format `"name:type:value"` (repeatable) |
| `--json-file` | | Path to JSON file containing record data |
| `--stdin` | | Read record data from stdin |

### Field Types

| Type | Used For | Example |
|------|----------|---------|
| `string` | `title` | `"title:string:My Note"` |
| `int64` | `index`, `modified` | `"index:int64:42"` |
| `timestamp` | `createdAt` | `"createdAt:timestamp:2024-01-01T00:00:00Z"` |
| `asset` | `image` | Asset reference (special handling) |

### Examples

**Simple record:**
```bash
mistdemo create \
  --field "title:string:My Note" \
  --field "index:int64:1" \
  --field "modified:int64:0"
```

**With custom record name:**
```bash
mistdemo create \
  --record-name "note_001" \
  --field "title:string:Getting Started with CloudKit" \
  --field "index:int64:42" \
  --field "createdAt:timestamp:2024-01-01T00:00:00Z" \
  --field "modified:int64:0"
```

**From JSON file:**
```bash
# testitem.json
{
  "recordType": "Note",
  "fields": {
    "title": {"value": "From File"},
    "index": {"value": 1},
    "modified": {"value": 0}
  }
}

mistdemo create --json-file testitem.json
```

**From stdin:**
```bash
echo '{"title": {"value": "From stdin"}, "index": {"value": 1}}' | \
  mistdemo create --stdin
```

## update

Update an existing Note record in CloudKit.

### Syntax
```bash
mistdemo update <record-name> [options]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `record-name` | Yes | Name of the record to update |

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--zone` | | Zone name (default: `_defaultZone`) |
| `--field` | `-f` | Field to update in format `"name:type:value"` |
| `--change-tag` | | Record change tag for optimistic locking |
| `--force` | | Force update, ignoring conflicts |
| `--json-file` | | Path to JSON file containing updates |
| `--stdin` | | Read updates from stdin |

### Optimistic Locking

CloudKit uses change tags for optimistic locking:
- Each record has a `recordChangeTag` that changes on every update
- Provide `--change-tag` to ensure you're updating the expected version
- Use `--force` to override (not recommended for concurrent updates)

### Examples

**Update single field:**
```bash
mistdemo update note_001 \
  --field "title:string:Updated Title"
```

**Update multiple fields with change tag:**
```bash
mistdemo update note_001 \
  --field "title:string:Updated Title" \
  --field "index:int64:100" \
  --field "modified:int64:1" \
  --change-tag "abc123"
```

**Force update from JSON:**
```bash
# updates.json
{
  "fields": {
    "title": {"value": "Force Updated"},
    "modified": {"value": 2}
  }
}

mistdemo update note_001 --json-file updates.json --force
```

## delete

Delete a Note record from CloudKit.

### Syntax
```bash
mistdemo delete <record-name> [options]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `record-name` | Yes | Name of the record to delete |

### Options

| Option | Description |
|--------|-------------|
| `--zone` | Zone name (default: `_defaultZone`) |
| `--change-tag` | Record change tag for optimistic locking |
| `--force` | Force delete, ignoring conflicts |

### Examples

**Delete a record:**
```bash
mistdemo delete note_001
```

**Delete with change tag:**
```bash
mistdemo delete note_old --change-tag "xyz789"
```

**Force delete:**
```bash
mistdemo delete temp_note --force
```

## lookup

Lookup specific Note records by their record names (batch fetch).

### Syntax
```bash
mistdemo lookup <record-names...> [options]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `record-names` | Yes | One or more record names to lookup |

### Options

| Option | Description |
|--------|-------------|
| `--zone` | Zone name (default: `_defaultZone`) |
| `--fields` | Comma-separated list of fields to return |

### Examples

**Lookup single record:**
```bash
mistdemo lookup note_001
```

**Lookup multiple records:**
```bash
mistdemo lookup note_001 note_002 note_003
```

**Lookup with specific fields:**
```bash
mistdemo lookup note_001 --fields "title,index,createdAt"
```

**Batch lookup from file:**
```bash
# record-names.txt contains one record name per line
cat record-names.txt | xargs mistdemo lookup
```

## modify

Perform batch operations (create, update, delete) in a single request.

### Syntax
```bash
mistdemo modify --operations-file <file> [options]
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--operations-file` | `-f` | Path to JSON file with operations |
| `--atomic` | | Make all operations atomic (all succeed or all fail) |
| `--stdin` | | Read operations from stdin |

### Operations File Format

```json
{
  "operations": [
    {
      "type": "create",
      "recordType": "Note",
      "fields": {
        "title": {"value": "New Note"},
        "index": {"value": 1},
        "modified": {"value": 0}
      }
    },
    {
      "type": "update",
      "recordType": "Note",
      "recordName": "note_001",
      "fields": {
        "title": {"value": "Updated Title"},
        "modified": {"value": 1}
      }
    },
    {
      "type": "delete",
      "recordType": "Note",
      "recordName": "note_old"
    }
  ]
}
```

### Operation Types

| Type | Required Fields | Description |
|------|----------------|-------------|
| `create` | `recordType`, `fields` | Create new record |
| `update` | `recordType`, `recordName`, `fields` | Update existing record |
| `delete` | `recordType`, `recordName` | Delete record |

### Examples

**Batch modify from file:**
```bash
mistdemo modify --operations-file batch.json
```

**Atomic batch operations:**
```bash
mistdemo modify --operations-file updates.json --atomic
```

**Pipe operations from another command:**
```bash
generate-operations | mistdemo modify --stdin
```

**Mixed operations:**
```bash
cat > mixed.json <<EOF
{
  "operations": [
    {
      "type": "create",
      "recordType": "Note",
      "fields": {
        "title": {"value": "Batch Created"},
        "index": {"value": 100}
      }
    },
    {
      "type": "update",
      "recordType": "Note",
      "recordName": "existing_note",
      "fields": {
        "title": {"value": "Batch Updated"}
      }
    },
    {
      "type": "delete",
      "recordType": "Note",
      "recordName": "old_note"
    }
  ]
}
EOF

mistdemo modify -f mixed.json --atomic
```

## Common Workflows

### Create and Query
```bash
# Create a note
mistdemo create \
  --field "title:string:Important Note" \
  --field "index:int64:1"

# Query to verify
mistdemo query --filter "title CONTAINS 'Important'"
```

### Update with Verification
```bash
# Lookup to get current state
mistdemo lookup note_001 > current.json

# Extract change tag
CHANGE_TAG=$(jq -r '.records[0].recordChangeTag' current.json)

# Update with optimistic locking
mistdemo update note_001 \
  --field "title:string:Updated" \
  --change-tag "$CHANGE_TAG"
```

### Bulk Delete
```bash
# Query records to delete
mistdemo query --filter "index < 10" > to_delete.json

# Extract record names and delete
jq -r '.records[].recordName' to_delete.json | \
  xargs -I {} mistdemo delete {}
```

## Related Documentation

- **[Overview](overview.md)** - Global options and schema reference
- **[Configuration](configuration.md)** - Configuration management
- **[Output Formats](output-formats.md)** - Output format specifications
- **[Error Handling](error-handling.md)** - Error reporting
