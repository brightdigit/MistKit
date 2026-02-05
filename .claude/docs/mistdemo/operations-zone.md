# Zone Operations

Zone operations manage custom record zones in CloudKit databases. Zones provide isolation and enable features like atomic batch operations and zone-wide subscriptions.

## Understanding Zones

### Default Zone
- Name: `_defaultZone`
- Present in all databases
- Cannot be deleted or modified
- Used when no zone is specified

### Custom Zones
- User-created zones for organizing records
- Enable atomic batch operations
- Support zone subscriptions
- Can be deleted (along with all records)
- Only available in private and shared databases

### Zone Benefits

| Feature | Default Zone | Custom Zones |
|---------|--------------|--------------|
| Record storage | ✓ | ✓ |
| Queries | ✓ | ✓ |
| Atomic operations | | ✓ |
| Zone subscriptions | | ✓ |
| Deletion | | ✓ |
| Change tracking | | ✓ (enhanced) |

## list-zones

List all zones in the database.

### Syntax
```bash
mistdemo list-zones [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--include-default` | Include the default zone in results | `false` |

### Database Compatibility

| Database | Custom Zones |
|----------|--------------|
| Public | Not supported |
| Private | ✓ Supported |
| Shared | ✓ Supported |

### Examples

**List all custom zones:**
```bash
mistdemo list-zones --database private
```

**Include default zone:**
```bash
mistdemo list-zones --database private --include-default
```

**List zones with table output:**
```bash
mistdemo list-zones --database private -o table
```

### Response Format (JSON)

```json
{
  "zones": [
    {
      "zoneID": {
        "zoneName": "CustomZone1",
        "ownerRecordName": "_abc123def456"
      },
      "atomic": true,
      "capabilities": {
        "fetchChanges": true,
        "atomic": true,
        "sharing": false
      }
    },
    {
      "zoneID": {
        "zoneName": "SharedZone",
        "ownerRecordName": "_xyz789ghi012"
      },
      "atomic": true,
      "capabilities": {
        "fetchChanges": true,
        "atomic": true,
        "sharing": true
      }
    }
  ]
}
```

### Zone Properties

- `zoneName` - Unique zone identifier
- `ownerRecordName` - Zone owner's user record name
- `atomic` - Whether zone supports atomic operations
- `capabilities.fetchChanges` - Supports change tracking
- `capabilities.atomic` - Supports atomic batch operations
- `capabilities.sharing` - Supports CloudKit sharing

## lookup-zones

Lookup specific zones by name.

### Syntax
```bash
mistdemo lookup-zones <zone-names...> [options]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `zone-names` | Yes | One or more zone names to lookup |

### Examples

**Lookup single zone:**
```bash
mistdemo lookup-zones CustomZone1 --database private
```

**Lookup multiple zones:**
```bash
mistdemo lookup-zones CustomZone1 CustomZone2 SharedZone --database private
```

**Lookup from file:**
```bash
# zones.txt contains one zone name per line
cat zones.txt | xargs mistdemo lookup-zones --database private
```

### Response Format (JSON)

```json
{
  "zones": [
    {
      "zoneID": {
        "zoneName": "CustomZone1",
        "ownerRecordName": "_abc123def456"
      },
      "atomic": true,
      "capabilities": {
        "fetchChanges": true,
        "atomic": true,
        "sharing": false
      },
      "created": {
        "timestamp": 1640995200000
      },
      "modified": {
        "timestamp": 1640995200000
      }
    }
  ]
}
```

### Error Handling

**Zone not found:**
```json
{
  "zones": [
    {
      "zoneID": {
        "zoneName": "NonExistent"
      },
      "error": {
        "code": "ZONE_NOT_FOUND",
        "message": "Zone does not exist"
      }
    }
  ]
}
```

## modify-zones

Create, update, or delete zones.

### Syntax
```bash
mistdemo modify-zones --operations-file <file> [options]
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--operations-file` | `-f` | Path to JSON file with zone operations |
| `--stdin` | | Read operations from stdin |

### Operations File Format

```json
{
  "operations": [
    {
      "type": "create",
      "zoneName": "CustomZone1"
    },
    {
      "type": "create",
      "zoneName": "ProjectData",
      "atomic": true
    },
    {
      "type": "delete",
      "zoneName": "OldZone"
    }
  ]
}
```

### Operation Types

| Type | Required Fields | Optional Fields | Description |
|------|----------------|-----------------|-------------|
| `create` | `zoneName` | `atomic` | Create new zone |
| `delete` | `zoneName` | | Delete zone and all its records |

### Examples

**Create a new zone:**
```bash
cat > create_zone.json <<EOF
{
  "operations": [
    {
      "type": "create",
      "zoneName": "CustomZone1"
    }
  ]
}
EOF

mistdemo modify-zones --operations-file create_zone.json --database private
```

**Create multiple zones:**
```bash
cat > create_zones.json <<EOF
{
  "operations": [
    {
      "type": "create",
      "zoneName": "ProjectData"
    },
    {
      "type": "create",
      "zoneName": "UserPreferences"
    },
    {
      "type": "create",
      "zoneName": "Sync"
    }
  ]
}
EOF

mistdemo modify-zones -f create_zones.json --database private
```

**Delete a zone:**
```bash
cat > delete_zone.json <<EOF
{
  "operations": [
    {
      "type": "delete",
      "zoneName": "OldZone"
    }
  ]
}
EOF

mistdemo modify-zones -f delete_zone.json --database private
```

**Pipe operations:**
```bash
echo '{"operations":[{"type":"create","zoneName":"TempZone"}]}' | \
  mistdemo modify-zones --stdin --database private
```

### Response Format (JSON)

```json
{
  "results": [
    {
      "zoneName": "CustomZone1",
      "status": "success",
      "zoneID": {
        "zoneName": "CustomZone1",
        "ownerRecordName": "_abc123def456"
      }
    }
  ]
}
```

### Important Warnings

**⚠️ Deleting Zones:**
- Deletes the zone AND all records within it
- Cannot be undone
- Default zone cannot be deleted

**⚠️ Zone Naming:**
- Zone names must be unique per user
- Cannot start with underscore (reserved for system zones)
- Case-sensitive

## Common Workflows

### Create Zone and Add Records
```bash
# 1. Create a custom zone
cat > create_zone.json <<EOF
{
  "operations": [
    {
      "type": "create",
      "zoneName": "ProjectData"
    }
  ]
}
EOF

mistdemo modify-zones -f create_zone.json --database private

# 2. Add records to the zone
mistdemo create \
  --zone "ProjectData" \
  --database private \
  --field "title:string:Project Note" \
  --field "index:int64:1"

# 3. Query records in the zone
mistdemo query \
  --zone "ProjectData" \
  --database private
```

### List and Inspect Zones
```bash
# List all zones
mistdemo list-zones --database private -o json > zones.json

# Extract zone names
jq -r '.zones[].zoneID.zoneName' zones.json

# Lookup specific zones for details
jq -r '.zones[].zoneID.zoneName' zones.json | \
  xargs mistdemo lookup-zones --database private
```

### Backup and Delete Zone
```bash
# 1. Backup all records in the zone
mistdemo query --zone "OldZone" --database private > backup.json

# 2. Verify backup
jq '.records | length' backup.json

# 3. Delete the zone
cat > delete_zone.json <<EOF
{
  "operations": [
    {
      "type": "delete",
      "zoneName": "OldZone"
    }
  ]
}
EOF

mistdemo modify-zones -f delete_zone.json --database private
```

### Atomic Batch Operations
```bash
# Custom zones enable atomic operations
mistdemo modify \
  --operations-file batch.json \
  --atomic \
  --database private

# In batch.json, all operations must target the same custom zone
# All operations succeed or all fail together
```

## Zone Design Patterns

### Organization by Feature
```
CustomZone1: UserData
CustomZone2: Settings
CustomZone3: Cache
```

### Organization by Lifecycle
```
PermanentZone: Core data
TemporaryZone: Session data (can be deleted)
ArchiveZone: Historical data
```

### Organization by Sync
```
SyncZone: Records that sync across devices
LocalZone: Device-specific records
SharedZone: Shared with other users
```

## Limitations and Considerations

### Zone Limits
- Maximum zones per database: 1000 (check CloudKit documentation)
- Zone names are case-sensitive
- Cannot rename zones (delete and recreate)

### Performance
- Queries within a zone may be faster
- Zone-wide operations are efficient
- Change tracking is zone-scoped

### Best Practices
1. Use custom zones for features requiring atomic operations
2. Organize zones by data lifecycle or access pattern
3. Don't create too many zones (overhead)
4. Use meaningful, descriptive zone names
5. Document zone purposes in your schema

## Related Documentation

- **[Overview](overview.md)** - Global options and authentication
- **[Record Operations](operations-record.md)** - Working with records in zones
- **[Configuration](configuration.md)** - Managing database settings
- **[Error Handling](error-handling.md)** - Zone error codes
