# Exporting CloudKit Data

Learn how to export CloudKit records to JSON format for analysis and backup.

## Overview

The `export` command downloads all records from CloudKit and saves them to a JSON file. This is useful for backup, data analysis, or migrating to other systems.

## Prerequisites

Before exporting, ensure you've completed <doc:CloudKitSetup> to configure your CloudKit credentials.

## Basic Export

Export all records to a JSON file:

```bash
bushel-cloud export --output data.json
```

This creates a JSON file containing all RestoreImage, XcodeVersion, SwiftVersion, and DataSourceMetadata records.

## Verbose Output

See detailed operation logs:

```bash
bushel-cloud export --output data.json --verbose
```

Verbose mode shows:
- Query operations for each record type
- Number of records fetched
- CloudKit API request/response details
- Field deserialization process

## JSON Structure

The exported JSON file has this structure:

```json
{
  "restoreImages": [
    {
      "recordName": "RestoreImage-23C71",
      "recordType": "RestoreImage",
      "fields": {
        "version": {"value": "14.0", "type": "STRING"},
        "buildNumber": {"value": "23C71", "type": "STRING"},
        "releaseDate": {"value": 1699920000000, "type": "TIMESTAMP"},
        "downloadURL": {"value": "https://...", "type": "STRING"},
        "fileSize": {"value": 13958643712, "type": "INT64"},
        "sha256Hash": {"value": "abc123...", "type": "STRING"},
        "isSigned": {"value": 1, "type": "INT64"},
        "isPrerelease": {"value": 0, "type": "INT64"}
      },
      "created": {...},
      "modified": {...}
    }
  ],
  "xcodeVersions": [...],
  "swiftVersions": [...],
  "dataSourceMetadata": [...]
}
```

## Field Types

CloudKit field types are preserved in the export:

| CloudKit Type | JSON Representation | Example |
|---------------|---------------------|---------|
| `STRING` | String value | `"macOS 14.0"` |
| `INT64` | Number value | `13958643712` |
| `TIMESTAMP` | Milliseconds since epoch | `1699920000000` |
| `REFERENCE` | Record name string | `"RestoreImage-23C71"` |

**Note**: Booleans are stored as INT64 (0 = false, 1 = true) in CloudKit.

## Date Handling

CloudKit dates are exported as **milliseconds since Unix epoch**:

```json
{
  "releaseDate": {"value": 1699920000000, "type": "TIMESTAMP"}
}
```

To convert in JavaScript:

```javascript
const date = new Date(1699920000000);
// Mon Nov 13 2023 19:46:40 GMT-0800
```

To convert in Python:

```python
from datetime import datetime
date = datetime.fromtimestamp(1699920000000 / 1000)
# 2023-11-13 19:46:40
```

## Reference Fields

CloudKit references are exported as record names:

```json
{
  "minimumMacOS": {
    "value": {
      "recordName": "RestoreImage-23C71",
      "action": "NONE"
    },
    "type": "REFERENCE"
  }
}
```

Use the `recordName` to look up related records in the exported data.

## Querying Exported Data

Use `jq` to query the exported JSON:

```bash
# Count restore images
jq '.restoreImages | length' data.json

# Find all Xcode 15 versions
jq '.xcodeVersions[] | select(.fields.version.value | startswith("15"))' data.json

# List all signed restore images
jq '.restoreImages[] | select(.fields.isSigned.value == 1) | .fields.version.value' data.json

# Get all Swift 5.9.x versions
jq '.swiftVersions[] | select(.fields.version.value | startswith("5.9"))' data.json
```

## Backup Strategy

Use export for regular CloudKit backups:

```bash
# Daily backup with timestamp
bushel-cloud export --output "backup-$(date +%Y%m%d).json"

# Keep last 7 days of backups
find . -name 'backup-*.json' -mtime +7 -delete
```

## Data Analysis

Import the JSON into your favorite tools:

**Python/Pandas**:
```python
import json
import pandas as pd

with open('data.json') as f:
    data = json.load(f)

# Convert to DataFrame
df = pd.DataFrame([
    {
        'version': r['fields']['version']['value'],
        'build': r['fields']['buildNumber']['value'],
        'size': r['fields']['fileSize']['value']
    }
    for r in data['restoreImages']
])
```

**JavaScript/Node.js**:
```javascript
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('data.json', 'utf8'));

// Filter prerelease versions
const prereleases = data.restoreImages.filter(
  r => r.fields.isPrerelease.value === 1
);
```

## Record Metadata

Each record includes CloudKit system fields:

```json
{
  "created": {
    "timestamp": 1699920000000,
    "userRecordName": "_server-to-server",
    "deviceID": "..."
  },
  "modified": {
    "timestamp": 1699920100000,
    "userRecordName": "_server-to-server",
    "deviceID": "..."
  }
}
```

Use these timestamps to track when records were created or last updated.

## Comparing Exports

Diff two exports to see changes:

```bash
# Export before sync
bushel-cloud export --output before.json

# Run sync
bushel-cloud sync

# Export after sync
bushel-cloud export --output after.json

# Compare (requires jq)
diff <(jq -S . before.json) <(jq -S . after.json)
```

## Performance

Export performance depends on record count:

- **< 100 records**: Near-instant
- **100-1000 records**: 1-5 seconds
- **1000+ records**: May take 10+ seconds

CloudKit queries are paginated automatically by MistKit.

## Example Workflow

```bash
# 1. Export current state
bushel-cloud export --output baseline.json --verbose

# 2. Check record counts
jq '{
  restoreImages: (.restoreImages | length),
  xcodeVersions: (.xcodeVersions | length),
  swiftVersions: (.swiftVersions | length)
}' baseline.json

# 3. Analyze data
jq '.restoreImages[] | select(.fields.isSigned.value == 0) | .fields.version.value' baseline.json

# 4. Save for comparison later
mv baseline.json exports/baseline-$(date +%Y%m%d).json
```

## Limitations

- **No Filtering**: Exports all records (cannot filter by date, version, etc.)
- **No Format Options**: Only JSON format supported
- **In-Memory Processing**: Large datasets may consume significant memory

These are intentional limitations for this demonstration tool.

## Next Steps

- <doc:SyncingData> - Upload data to CloudKit
- <doc:CloudKitIntegration> - Understand CloudKit field types
- <doc:DataFlow> - Learn about record relationships

## Key Classes

- ``ExportCommand`` - CLI command implementation
- ``BushelCloudKitService`` - CloudKit query operations
- ``CloudKitRecord`` - Protocol for record conversion
