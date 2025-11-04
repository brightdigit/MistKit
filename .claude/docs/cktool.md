# Using cktool (Summary)

**Source**: https://developer.apple.com/icloud/ck-tool/
**Downloaded**: November 4, 2025
**Full Documentation**: See `cktool-full.md` for complete Apple documentation

## Overview

`cktool` is a command-line tool distributed with Xcode (starting with Xcode 13) that provides direct access to CloudKit Management APIs. It enables schema management, data operations, and automation tasks for CloudKit development.

## Before You Begin

- You'll need to be a current member of the Apple Developer Program or the Apple Developer Enterprise Program in order to use `cktool`.
- Understand the concepts of Authentication, as described in Automating CloudKit Development.
- Generate a CloudKit Management Token from the CloudKit Console by choosing the Settings section for your user account. Save this token, as it will not be visible again.

## Installing the Application

By default, `cktool` is distributed with Xcode starting with Xcode 13, which is available on the Mac App Store.

## General Usage

`cktool` is stateless and passes all operations to the CloudKit Management API in single operations. A full list of supported operations is available from the `help` command or the `man` pages:

```bash
xcrun cktool --help
```

Output:
```
OVERVIEW: CloudKit Command Line Tool

-h, --help				Show help information.

SUBCOMMANDS: ...
```

## Authenticating `cktool` to CloudKit

`cktool` supports both management and user tokens, and will store them securely in Mac Keychain. You can add a token using the `save-token` command, which will launch CloudKit Console for copying of the appropriate token after prompting for information from the user:

```bash
xcrun cktool save-token \
  --type [management | user]
```

## Schema Management Commands

Schema Management commands require the Management Token to be provided. Once provided, `cktool` can perform the following commands:

### Reset Development Schema

This allows you to revert the development database to the current production definition.

```bash
xcrun cktool reset-schema \
  --team-id [TEAM-ID] \
  --container-id [CONTAINER]
```

### Export Schema File

This allows you to save an existing CloudKit Database schema definition to a file, which can be kept alongside the related source code:

```bash
xcrun cktool export-schema \
  --team-id [TEAM-ID] \
  --container-id [CONTAINER] \
  --environment [development | production] \
  [--output-file schema.ckdb]
```

### Import Schema File

This applies a file-based schema definition against the development database for testing.

```bash
xcrun cktool import-schema \
  --team-id [TEAM-ID] \
  --container-id [CONTAINER] \
  --environment development \
  --file schema.ckdb
```

## Data Commands

When a user token is available, `cktool` can access public and private databases on behalf of the user. This can be used for fetching data and inserting new records prior to integration tests. Note that due to the short lifespan of the user token, frequent interactive authentication may be required.

### Query Records

Querying records can be performed with the `query-records` command. Note that queries without filters require the `___recordID` to have a `Queryable` index applied, as do fields specified in the optional `--filters` argument:

```bash
xcrun cktool query-records \
  --team-id [TEAMID] \
  --container-id [CONTAINER] \
  --zone-name [ZONE_NAME] \
  --database-type [public | private] \
  --environment [development | production] \
  --record-type [RECORD_TYPE] \
  [--filters [FILTER_1] [FILTER_2]]
```

Where `FILTER_1` is in the form `"[FIELD_NAME] [OPERATOR] [VALUE]"`, for example `"lastname == Appleseed"`.

### Create Records

Inserting data is accomplished with the `create-record` command:

```bash
xcrun cktool create-record \
  --team-id [TEAM_ID] \
  --container-id [CONTAINER] \
  --zone-name [ZONE_NAME] \
  --database-type [public | private] \
  --environment [development | production] \
  --record-type [RECORD_TYPE] \
  [--fields-json [FIELDS_JSON]]
```

Where `FIELDS_JSON` is a JSON representation of the fields to set in the record. For example:

```json
{
  "firstName": {
    "type": "stringType",
    "value": "Johnny"
  },
  "lastName": {
    "type": "stringType",
    "value": "Appleseed"
  }
}
```

## When to Consult This Documentation

- Setting up CloudKit schemas for development
- Exporting/importing schemas for version control
- Automating schema deployment in CI/CD pipelines
- Seeding test data for integration tests
- Resetting development environments
- Understanding CloudKit Management API capabilities

## Relation to MistKit

`cktool` operates at the management/development level, while MistKit operates at the runtime application level:

- **cktool**: Schema management, data seeding for tests, development workflows
- **MistKit**: Application runtime data operations, end-user interactions

Understanding `cktool` helps when:
- Setting up test environments for MistKit applications
- Creating reproducible CloudKit schemas
- Building CI/CD pipelines for MistKit-based projects
- Debugging schema-related issues during development

## Common Workflows

### Development Setup
1. Export production schema: `xcrun cktool export-schema --environment production`
2. Import to development: `xcrun cktool import-schema --environment development`
3. Seed test data: `xcrun cktool create-record` (multiple times)

### CI/CD Integration
1. Store `schema.ckdb` in version control
2. Import schema in CI: `xcrun cktool import-schema`
3. Run MistKit integration tests against seeded data

### Resetting Development Environment
1. Reset schema: `xcrun cktool reset-schema`
2. Re-import custom schema if needed
3. Re-seed test data

## Related Documentation

See also:
- `cktooljs.md` - JavaScript library for CloudKit management
- `webservices.md` - CloudKit Web Services REST API reference
- `cloudkitjs.md` - CloudKit JS SDK for web applications
