# Managing Schemas

Export a container's schema through the CloudKit Management API, and read, inspect and write CloudKit Schema Language text.

## Overview

CloudKit describes a container's record types, indexes and permissions in CloudKit Schema Language, the text format `cktool export-schema` writes to a `.ckdb` file. MistKit covers two parts of that workflow:

- ``CloudKitManagementService`` downloads a container's schema from the CloudKit Management API, the service behind `cktool`.
- ``CloudKitSchema`` parses schema text into record types, fields and grants, and writes it back out in the `cktool` layout.

The two are independent. You can parse a `.ckdb` file without a management token, and you can export the raw text without parsing it.

## The CloudKit Management API

Schema export isn't part of CloudKit Web Services. It's a separate service with its own host, authentication and error format:

| | CloudKit Web Services | CloudKit Management API |
| --- | --- | --- |
| Host | `api.apple-cloudkit.com` | `api.icloud.apple.com` (``CloudKitManagementService/baseURL``) |
| Client | ``CloudKitService`` | ``CloudKitManagementService`` |
| Credentials | API token, web-auth token or server-to-server key | Management token only |
| Errors | ``CloudKitError`` | ``CloudKitManagementError`` |

Because of those differences, the generated client comes from its own OpenAPI document, `management-openapi.yaml`, and lives in its own product, `MistKitManagementOpenAPI`, rather than in `MistKitOpenAPI`. You don't need to import it: ``CloudKitManagementService`` wraps the generated client the same way ``CloudKitService`` wraps `MistKitOpenAPI`, and no generated types appear in its public API.

### Getting a management token

Create a management token in [CloudKit Console](https://icloud.developer.apple.com/dashboard/), under your account's Settings. Console shows the token once, so copy it when you create it. Apple documents the token as scoped to a team and a user, with a default lifespan of one year, and revocable from the same Settings page. Apple doesn't document which team role the token needs.

You also need the team identifier of the team that owns the container, from the Membership page of the Apple Developer site.

Wrap the token in a ``ManagementToken``. It is sent only in the `X-Apple-CloudKit-Management-Token` request header. Its `description`, `debugDescription` and `Mirror` are all redacted, so printing or dumping it never reveals the value. The service installs no logging middleware, and errors from the generated client are translated rather than rethrown, because their descriptions include the request headers. The token doesn't reach a log through MistKit.

### Exporting a schema

Create a ``CloudKitManagementService`` for one team and container, then call ``CloudKitManagementService/exportSchema(environment:)`` to download and parse the schema:

```swift
import MistKit

let service = CloudKitManagementService(
  teamIdentifier: "ABCDE12345",
  containerIdentifier: "iCloud.com.example.MyApp",
  managementToken: ManagementToken(managementTokenString)
)

let exported = try await service.exportSchema(environment: .development)
for recordType in exported.schema.recordTypes {
  print(recordType.name, recordType.fields.map(\.name))
}
```

The result is an ``ExportedSchema``, which keeps the environment, the text exactly as CloudKit returned it and the parsed ``CloudKitSchema``. If you only want the text, for example to save it as a `.ckdb` file, call ``CloudKitManagementService/exportSchemaText(environment:)``, which skips parsing.

> Note: ``CloudKitManagementService/init(teamIdentifier:containerIdentifier:managementToken:)`` uses `URLSessionTransport` and isn't available on WASI.

### Handling Management API errors

Both export methods throw ``CloudKitManagementError``, except for transport failures, which propagate unchanged:

| Case | When it's thrown |
| --- | --- |
| ``CloudKitManagementError/requestFailed(_:)`` | The service answered with a JSON `RequestError`, decoded into a ``ManagementRequestFailure`` |
| ``CloudKitManagementError/httpError(statusCode:body:)`` | A non-success response whose body wasn't a `RequestError`; `body` is the UTF-8 text, when there is any |
| ``CloudKitManagementError/invalidResponse(reason:)`` | A success response MistKit couldn't use, such as a body that isn't UTF-8 or is larger than 32 MiB |
| ``CloudKitManagementError/invalidSchema(_:text:)`` | Only from `exportSchema(environment:)`: the text isn't valid CloudKit Schema Language; `text` keeps the export so you can still show or save it |

``ManagementRequestFailure`` carries the HTTP `statusCode` and the body's `code`, `message`, `reason`, `detailedMessage`, `requestUUID` and `retryAfterSeconds`. Against a live container, `message` is a kebab-case code:

| Status | `message` | Cause |
| --- | --- | --- |
| 401 | `invalid-or-expired-session` | The token is wrong, expired or revoked |
| 401 | `authentication-failed` | No token was sent |
| 403 | `authorization-failed` | The container is unknown, or the token's team can't access it |

An unknown container is a 403, not a 404, so don't treat 403 as a permissions problem only. Every observed failure carried a `requestUUID`; none carried `detailedMessage` or `retryAfterSeconds`.

```swift
do {
  let exported = try await service.exportSchema(environment: .production)
  // ...
} catch CloudKitManagementError.requestFailed(let failure) {
  print("\(failure.statusCode) \(failure.message): \(failure.reason)")
} catch CloudKitManagementError.invalidSchema(let parseError, let text) {
  print(parseError.localizedDescription)
  try text.write(to: backupURL, atomically: true, encoding: .utf8)
}
```

The error's `errorDescription` never includes the management token.

## CloudKit Schema Language

``CloudKitSchema`` models a whole schema: the roles declared with `CREATE ROLE` and the record types, both in source order. Each ``SchemaRecordType`` has its ``SchemaField`` declarations and ``SchemaGrant`` clauses.

### Parsing schema text

Parse text you already have with ``CloudKitSchema/init(parsing:)``, or read a file with ``CloudKitSchema/init(contentsOf:)``:

```swift
let schema = try CloudKitSchema(contentsOf: URL(fileURLWithPath: "schema.ckdb"))

if let note = schema.recordType(named: "Note"),
   let title = note.field(named: "title") {
  print(title.type.schemaText, title.isQueryable, title.isSortable, title.isSearchable)
}
```

`init(contentsOf:)` throws ``SchemaSourceError/unreadableFile(_:underlying:)`` or ``SchemaSourceError/notUTF8(_:)`` when the file can't be read as text. Both initializers throw ``SchemaParseError`` for invalid text, with the 1-based `line` and `column` of the first problem and a `message`.

The parser follows Apple's grammar and is strict in a few places:

- A bare name can't start with `_`, so system fields and roles such as `"___recordID"` and `"_creator"` must be quoted.
- The words `GRANT`, `PREFERRED`, `QUERYABLE`, `SORTABLE` and `SEARCHABLE` must be quoted when used as names.
- A role, record type or field defined twice is an error.
- `ENCRYPTED` in front of a type that can't be encrypted is an error.
- A trailing comma before `)` and a missing `;` after the last declaration are tolerated.
- Keywords are case-insensitive.

### Fields and types

A ``SchemaField`` has a `name`, a ``SchemaFieldType`` and its three index flags. ``SchemaField/isQueryable`` is required for query filters on the field, ``SchemaField/isSortable`` for sorts and range filters, and ``SchemaField/isSearchable`` for full-text search.

``SchemaFieldType`` describes the type as declared: a ``SchemaPrimitiveType``, whether it's `ENCRYPTED`, and whether it's a `LIST<…>`. ``SchemaPrimitiveType/canBeEncrypted`` is `true` for `BYTES`, `DOUBLE`, `INT64`, `LOCATION`, `STRING` and `TIMESTAMP`, and `false` for `ASSET`, `REFERENCE` and `NUMBER`.

``SchemaFieldType/resolved`` maps the declared type to ``FieldType``, the type the field's values carry. It drops `ENCRYPTED` and resolves `NUMBER` to `INT64` when it's `PREFERRED AS INT64`, and to `DOUBLE` otherwise. ``SchemaFieldType/allowedComparators`` lists the ``FilterComparator`` values CloudKit accepts in a filter on a field of that type; it's empty for encrypted, `BYTES` and `ASSET` fields.

### System fields

Every record type has CloudKit's system fields (`___createTime`, `___createdBy`, `___etag`, `___modTime`, `___modifiedBy` and `___recordID`), whether or not the schema lists them. A schema lists one only to give it an index, such as `"___recordID" REFERENCE QUERYABLE`. ``SchemaRecordType/fields`` holds only what the text declares. ``SchemaRecordType/fieldsIncludingImplicit`` adds the unlisted ones from ``SchemaField/implicitSystemFields``, unindexed and in the order CloudKit exports them.

### Grants and roles

``CloudKitSchema/roles`` lists custom roles from `CREATE ROLE`; the implicit roles `_creator`, `_icloud` and `_world` appear only if the schema declares them. A record type's ``SchemaRecordType/grants`` keep each `GRANT` clause as written. ``SchemaRecordType/mergedGrants`` combines them into one grant per role, and ``SchemaRecordType/permissions(for:)`` returns the ``SchemaPermission`` set for a single role.

### Writing schema text

``CloudKitSchema/schemaText`` writes the schema in the layout `cktool export-schema` uses: `DEFINE SCHEMA`, roles before record types, four-space indents, aligned field types, index options in the order `QUERYABLE` `SEARCHABLE` `SORTABLE`, and one grant per line. Parsing the result with ``CloudKitSchema/init(parsing:)`` gives back an equal schema. Comments aren't kept, which matches CloudKit. Names are quoted only when they must be, following ``CloudKitSchema/writtenIdentifier(_:)``.

The models are `Codable` with `var` properties, so you can edit a schema and write it back:

```swift
var schema = try CloudKitSchema(parsing: text)
schema.recordTypes[0].fields.append(
  SchemaField(name: "subtitle", type: SchemaFieldType(.string), isQueryable: true)
)
let updatedText = schema.schemaText
```

### Source lines

When a schema is parsed, each record type and field records the 1-based line its declaration starts on, in ``SchemaRecordType/sourceLine`` and ``SchemaField/sourceLine``. Use it to point at the declaration in an editor or in an error message. ``CloudKitSchema/annotatingSourceLines()`` returns a copy whose source lines refer to ``CloudKitSchema/schemaText`` instead, which is useful after you've built or edited a schema in code. Equality and hashing ignore source lines, so a parsed schema equals one built in code with the same declarations.

## Schema sources

The ``SchemaSource`` protocol abstracts where a schema comes from. Its `loadSchema()` returns a ``CloudKitSchema``, and its `schemaChanges()` stream yields when the schema should be loaded again; by default the stream finishes at once. MistKit provides three sources:

- ``ExportedSchemaSource`` exports one environment's schema through a ``CloudKitManagementService``.
- ``FileSchemaSource`` reads a `.ckdb` file. Pass a `fileChanges` stream to have it yield from `schemaChanges()` when the file's bytes change.
- ``InferredSchemaSource`` queries one page of records per record type through a ``CloudKitService`` and infers the fields from their values. Its `loadInferredSchema()` returns an ``InferredSchema``, whose ``SchemaNotice`` values report what it had to guess, such as a record type with no records or a field whose records disagree on its type. An inferred schema has no indexes or grants.

```swift
let sources: [any SchemaSource] = [
  ExportedSchemaSource(service: managementService, environment: .development),
  FileSchemaSource(url: URL(fileURLWithPath: "schema.ckdb")),
  InferredSchemaSource(service: cloudKitService, database: .private, recordTypes: ["Note"]),
]
for source in sources {
  let schema = try await source.loadSchema()
  print(schema.recordTypes.map(\.name))
}
```

## Example: MistDemo's export-schema command

MistDemo's `export-schema` command (`Examples/MistDemo/Sources/MistDemoKit/Commands/ExportSchemaCommand.swift`) uses only the management token: no API token or server-to-server key. It reads the token from `CLOUDKIT_MANAGEMENT_TOKEN` and the team from `DEVELOPMENT_TEAM`, then prints either the raw text or a summary of the parsed schema:

```swift
let service = CloudKitManagementService(
  teamIdentifier: teamID,
  containerIdentifier: config.base.containerIdentifier,
  managementToken: ManagementToken(token)
)
let environment = config.base.environment
do {
  if config.raw {
    print(try await service.exportSchemaText(environment: environment), terminator: "")
  } else {
    Self.printSummary(try await service.exportSchema(environment: environment))
  }
} catch let error as CloudKitManagementError {
  Self.printDetails(of: error)
  throw error
}
```

The summary walks the parsed schema's record types, fields and index flags:

```swift
for recordType in exported.schema.recordTypes {
  print("\nRECORD TYPE \(recordType.name)")
  for field in recordType.fields {
    let flags = [
      field.isQueryable ? "QUERYABLE" : nil,
      field.isSortable ? "SORTABLE" : nil,
      field.isSearchable ? "SEARCHABLE" : nil,
    ]
    .compactMap(\.self)
    print("  \(field.name) \(field.type.schemaText) \(flags.joined(separator: " "))")
  }
}
```

Run it from `Examples/MistDemo`:

```bash
swift run mistdemo export-schema --raw
swift run mistdemo export-schema --environment production
```

## Topics

### Management API

- ``CloudKitManagementService``
- ``ManagementToken``
- ``ExportedSchema``
- ``CloudKitManagementError``
- ``ManagementRequestFailure``

### Schema Language

- ``CloudKitSchema``
- ``SchemaRecordType``
- ``SchemaField``
- ``SchemaFieldType``
- ``SchemaPrimitiveType``
- ``FieldType``
- ``SchemaGrant``
- ``SchemaPermission``
- ``SchemaParseError``

### Schema Sources

- ``SchemaSource``
- ``ExportedSchemaSource``
- ``FileSchemaSource``
- ``InferredSchemaSource``
- ``InferredSchema``
- ``SchemaNotice``
- ``SchemaSourceError``

## See Also

- <doc:HandlingErrors>
- <doc:WorkingWithRecords>
- [Integrating a Text-Based Schema into Your Workflow](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow)
