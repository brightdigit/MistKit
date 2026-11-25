# Building Queries

Build CloudKit queries from filters and sorts, from an editable `Codable` description, or from NSPredicate-format text; check them against a schema; and run them a page at a time or all at once.

## Overview

A `records/query` request is a record type, a list of filters combined with AND, and a list of sorts. MistKit gives you three ways to build one:

| Starting point | Type | Use it when |
| --- | --- | --- |
| Swift code | ``Query`` built from ``QueryFilter`` and ``QuerySort`` | The query is fixed at compile time |
| An editable value | ``QueryDescriptor`` | The query is built in a UI, saved, or sent over the wire as JSON |
| Text | ``QueryPredicate`` | People type the conditions, as in an NSPredicate format string |

All three end as a ``Query`` passed to ``CloudKitService``. A ``QueryDescriptor`` can also be checked against a ``CloudKitSchema`` before it's sent, so a filter on a field without an index fails on the client instead of as a `BAD_REQUEST`.

<doc:WorkingWithRecords> covers the basic query calls and querying custom and shared zones. This article covers the rest of the query surface.

## Filters and sorts

``QueryFilter`` has one factory per CloudKit comparator, each taking a field name and a ``FieldValue``. Values use the `Arity` form: `.string(.value("open"))` for one value, `.string(.list(["open", "full"]))` for a list.

```swift
let query = Query(
  recordType: "Match",
  filters: [
    .greaterThanOrEquals("startedAt", .date(.value(lastWeek))),
    .notEquals("status", .string(.value("cancelled")))
  ],
  sortBy: [.descending("startedAt")]
)
```

Sorts are ``QuerySort/ascending(_:)``, ``QuerySort/descending(_:)`` or ``QuerySort/sort(_:ascending:)``, most significant first.

### IN and NOT_IN

`in` and `notIn` take an array of single values. MistKit tags the list with its element type (`STRING_LIST`, `INT64_LIST`, …), which CloudKit requires:

```swift
.in("status", [.string(.value("open")), .string(.value("full"))])
.notIn("rating", [.int64(.value(0)), .int64(.value(1))])
```

### String and list-member filters

| Factory | CloudKit comparator | Field |
| --- | --- | --- |
| `beginsWith(_:_:)` / `notBeginsWith(_:_:)` | `BEGINS_WITH` / `NOT_BEGINS_WITH` | `STRING` |
| `containsAllTokens(_:_:)` / `containsAnyTokens(_:_:)` | `CONTAINS_ALL_TOKENS` / `CONTAINS_ANY_TOKENS` | `STRING` with a `SEARCHABLE` index |
| `listContains(_:_:)` / `notListContains(_:_:)` | `LIST_CONTAINS` / `NOT_LIST_CONTAINS` | Any list |
| `listMemberBeginsWith(_:_:)` / `notListMemberBeginsWith(_:_:)` | `LIST_MEMBER_BEGINS_WITH` / `NOT_LIST_MEMBER_BEGINS_WITH` | `LIST<STRING>` |

The string filters take a plain `String`; `listContains` takes a single ``FieldValue`` element:

```swift
.beginsWith("displayName", "Ka")
.containsAllTokens("notes", "rain delay")
.listContains("tags", .string(.value("ranked")))
.listMemberBeginsWith("tags", "rank")
```

### Location and record-name filters

``QueryFilter/near(_:_:distance:)`` matches records whose `LOCATION` field lies within `distance` **meters** of a ``Location``:

```swift
.near("venue", Location(latitude: 51.5, longitude: -0.12), distance: 25_000)
```

CloudKit matches record names on the `___recordID` system field with a `REFERENCE` value. ``QueryFilter/recordName(equals:)`` and ``QueryFilter/recordName(notEquals:)`` build that filter from a plain name:

```swift
.recordName(equals: "match-0042")
```

## Which comparators a field takes

``FilterComparator`` lists every CloudKit comparator by its wire name (`EQUALS`, `NEAR`, `LIST_MEMBER_BEGINS_WITH`, …). Each field type accepts only some of them, and ``SchemaFieldType/allowedComparators`` gives that list:

| Field type | Allowed comparators |
| --- | --- |
| `STRING` | The six equality and range comparators, `BEGINS_WITH`, `NOT_BEGINS_WITH`, `IN`, `NOT_IN`, `CONTAINS_ALL_TOKENS`, `CONTAINS_ANY_TOKENS` |
| `INT64`, `DOUBLE`, `TIMESTAMP`, `NUMBER` | The six equality and range comparators, `IN`, `NOT_IN` |
| `REFERENCE` | `EQUALS`, `NOT_EQUALS`, `IN`, `NOT_IN` |
| `LOCATION` | `NEAR` |
| Any list | `LIST_CONTAINS`, `NOT_LIST_CONTAINS`; `LIST<STRING>` adds the two list-member prefix comparators |
| `BYTES`, `ASSET`, any `ENCRYPTED` type | None |

``SchemaRecordType/allowedComparators(forField:)`` answers the same question by field name, counting implicit system fields such as `___recordID`.

Every filter needs a `QUERYABLE` index on its field, with two exceptions that ``FilterComparator`` reports:

- ``FilterComparator/requiresSortableIndex`` is `true` for `<`, `<=`, `>` and `>=`. CloudKit rejects a range comparison on a field that is `QUERYABLE` but not `SORTABLE`.
- ``FilterComparator/requiresSearchableIndex`` is `true` for the two token comparators, which need `SEARCHABLE` instead of `QUERYABLE`.

## Describing a query as data

``QueryDescriptor`` is an editable, `Codable`, `Hashable` description of a query: a record type, a zone, conditions combined with AND, sorts, desired keys and a page size. Every property is a `var`, so a form or table can edit it in place, and it round-trips through JSON for saving or sending.

| Property | Type | Default |
| --- | --- | --- |
| `recordType` | `String` | (required) |
| `zoneID` | ``ZoneID`` | ``ZoneID/defaultZone`` |
| `conditions` | `[QueryDescriptor.Condition]` | `[]` |
| `sorts` | `[QueryDescriptor.Sort]` | `[]` |
| `desiredKeys` | `[String]?` | `nil` (every field) |
| `limit` | `Int` | ``CloudKitService/maxRecordsPerRequest`` |

Each ``QueryDescriptor/Condition`` is a field name, a ``QueryDescriptor/Comparator`` and a ``FieldValue``. The comparator has one case per ``FilterComparator``; `NEAR` carries its radius as ``QueryDescriptor/Comparator/near(meters:)``. For `in` and `notIn` the value is a list: `.string(.list(["open", "full"]))`.

```swift
let descriptor = QueryDescriptor(
  recordType: "Match",
  conditions: [
    .init(fieldName: "startedAt", comparator: .greaterThanOrEquals, value: .date(.value(lastWeek))),
    .init(fieldName: "status", comparator: .in, value: .string(.list(["open", "full"]))),
    .init(
      fieldName: "venue",
      comparator: .near(meters: 25_000),
      value: .location(.value(Location(latitude: 51.5, longitude: -0.12)))
    )
  ],
  sorts: [.init(fieldName: "startedAt", ascending: false)],
  limit: 50
)
```

A condition's value is coded the way ``FieldValue`` codes itself: a CloudKit field dictionary with its type, `{"value": …, "type": "TIMESTAMP"}`.

To match record names, use ``QueryDescriptor/recordIDFieldName`` (`___recordID`) as the field name. A `STRING` value on that field is sent as a reference, as CloudKit requires. ``QueryFieldName/title(for:)`` gives the name to show a person (`recordName` instead of `___recordID`).

### Running a descriptor

``QueryDescriptor/query()`` turns the conditions into filters, in order, and the sorts into ``QuerySort`` values. The page size, desired keys and zone travel alongside it:

```swift
let result = try await service.queryRecords(
  try descriptor.query(),
  limit: descriptor.limit,
  desiredKeys: descriptor.desiredKeys,
  zoneID: descriptor.zoneID,
  database: .private
)
```

`query()` throws ``QueryDescriptorError`` when a condition's value doesn't fit its comparator:

- ``QueryDescriptorError/valueMismatch(fieldName:comparator:)``: for example `BEGINS_WITH` with a number, or `NEAR` with anything but a location.
- ``QueryDescriptorError/unsupportedValue(fieldName:)``: an asset, or a list outside `IN` and `NOT_IN`.

Both carry ``QueryDescriptorError/fieldName``, so a UI can point at the condition. ``QueryDescriptor/Condition/filter()`` converts a single condition the same way.

## Writing conditions as predicate text

``QueryPredicate/parse(_:recordType:)`` reads conditions from an NSPredicate-style format string, and ``QueryPredicate/format(_:)`` writes them back. Parsing the formatted text gives the same conditions.

```swift
let conditions = try QueryPredicate.parse("""
  startedAt >= CAST("2026-10-01T00:00:00Z", "NSDate")
  AND players CONTAINS REFERENCE("p-1")
  AND displayName BEGINSWITH "Ka"
  AND status IN {"open", "full"}
  AND distanceToLocation:fromLocation:(venue, LOCATION(51.5, -0.12)) < 25.0
  """)
let descriptor = QueryDescriptor(recordType: "Match", conditions: conditions)
```

The accepted syntax:

| Write | Meaning |
| --- | --- |
| `=` `==` `!=` `<>` `<` `<=` `=<` `>` `>=` `=>` | Equality and range comparators |
| `BEGINSWITH "Ka"` | `BEGINS_WITH` |
| `CONTAINS value` | `LIST_CONTAINS` |
| `IN {"open", 'full'}`, `IN {1, 2.5}` | `IN`; the list must hold one type |
| `distanceToLocation:fromLocation:(venue, LOCATION(51.5, -0.12)) < 25` | `NEAR`, with the distance in **kilometres** (`25` is 25,000 m); `<=` is also accepted |
| `"text"` or `'text'`, with `\"` escapes | `STRING` |
| `1500`, `-2.5` | `INT64`, `DOUBLE` |
| `CAST("2026-10-01T00:00:00Z", "NSDate")` | `TIMESTAMP`, from ISO 8601 |
| `REFERENCE("player-mei")` | `REFERENCE` |
| `LOCATION(51.5, -0.12)` | `LOCATION` |
| `BYTES("AQI=")` | `BYTES`, from base64 |
| `AND` or `&&` | Joins conditions |
| `#AND` | A field whose name is a reserved word |

Keywords ignore case, `/* … */` comments are skipped, and empty text or `TRUEPREDICATE` parses to no conditions. `OR`, `||`, `NOT` and `!` are rejected, because CloudKit queries only combine filters with AND. Format placeholders such as `%@` and `$value` are rejected too: the text must hold the values.

Pass a ``SchemaRecordType`` as `recordType` to use the field types: a whole number compared with a `DOUBLE` field is read as a double (`speed > 3` gives `.double(.value(3))`), and an empty `IN {}` takes the field's list type. Without one, `IN {}` is an error.

### Parse errors

``QueryPredicateParseError`` says what is wrong and where, so an editor can underline it. It carries a ``QueryPredicateParseError/Reason``, the offending `range` in `Character` offsets, and a 1-based `line` and `column`; ``QueryPredicateParseError/utf16Range(in:)`` converts the range for `NSRange`-based text views.

```swift
do {
  _ = try QueryPredicate.parse("rating = 3\nAND handle ~ 1")
} catch {
  // error.reason == .unexpectedCharacter("~")
  // error.line == 2, error.column == 12
  print(error.localizedDescription)  // "Predicate line 2, column 12: …"
}
```

Some reasons, from the tests:

| Text | Reason |
| --- | --- |
| `rating = 3 OR handle = 1` | `.unsupportedConnective("OR")` |
| `rating = %@` | `.placeholder("%@")` |
| `startedAt > CAST("yesterday", "NSDate")` | `.invalidDate("yesterday")` |
| `handle IN {"a", 1, 2}` | `.mixedList` |
| `rating = 3 handle` | `.expectedConnective` |
| `handle = LIST(1)` | `.unknownFunction("LIST")` |

### Formatting

``QueryPredicate/format(_:)`` writes one condition per line, joined with `AND`, in a canonical form: `rating==3 && handle <> 'x'` formats as `rating = 3` / `AND handle != "x"`. It throws ``QueryPredicateFormatError`` for what the syntax can't express:

- ``QueryPredicateFormatError/unrepresentableValue(fieldName:)``: assets, lists outside `IN`, empty `IN` lists and non-finite numbers.
- ``QueryPredicateFormatError/unrepresentableComparator(fieldName:comparator:)``: comparators with no NSPredicate spelling, such as `NOT_BEGINS_WITH`, the token comparators, `NOT_LIST_CONTAINS` and the list-member prefix comparators.

## Validating against a schema

``QueryDescriptor/validate(against:checksIndexes:)`` checks a descriptor against a ``CloudKitSchema`` before it is sent, using the same rules CloudKit applies: `QUERYABLE` for filters, `SEARCHABLE` for token filters, `SORTABLE` for sorts and range filters, the comparators each field type allows, and the value type each field takes. Fields are looked up with ``SchemaRecordType/queryField(named:)``, so implicit system fields such as `___recordID` and `___modTime` count.

```swift
let schema = try CloudKitSchema(contentsOf: schemaURL)
let validation = descriptor.validate(against: schema)
if !validation.isValid {
  for issue in validation.issues where issue.isBlocking {
    print(issue.target, issue.fieldName ?? "-", issue)
  }
}
```

The schema can come from a `.ckdb` file, from `CloudKitSchema(parsing:)`, or from the CloudKit Management API (`CloudKitManagementService`).

``QueryValidation`` holds the ``QueryValidationIssue`` values in query order: record type and limit, then conditions, sorts and desired keys. ``QueryValidation/isValid`` is `true` when no issue is blocking, and ``QueryValidation/issues(for:)`` returns the issues for one ``QueryValidationIssue/Target`` (`.query`, `.condition(i)`, `.sort(i)` or `.desiredKey(i)`).

| Issue | Blocks the query |
| --- | --- |
| `unknownRecordType`, `unknownField` | Yes |
| `notQueryable`, `notSearchable`, `notSortable` | Yes |
| `unsupportedComparator`, `valueMismatch` | Yes |
| `limitOutOfRange` (outside `1...200`) | Yes |
| `unknownDesiredKey` | No: the field comes back empty |
| `indexesUnknown` | No, but CloudKit may still reject the query |

A schema inferred from records has no index information. ``QueryDescriptor/validate(against:)`` takes an ``InferredSchema``, skips the index and field-list checks, and reports `indexesUnknown` once. Passing `checksIndexes: false` with a ``CloudKitSchema`` does the same.

## Running queries

Three ``CloudKitService`` methods run a ``Query``. Each takes an optional `zoneID`; `nil` leaves the `zoneID` key out of the request and CloudKit uses the database's default zone.

| Method | Returns | Pages |
| --- | --- | --- |
| ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)`` | One ``QueryResult`` | One, from `continuationMarker` |
| ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)`` | `[RecordInfo]` | All, up to `maxPages` (default `1_000`) |
| ``CloudKitService/queryRecordPages(_:limit:desiredKeys:continuationMarker:zoneID:database:)`` | `AsyncThrowingStream<QueryResult, any Error>` | All, one element per page |

`queryRecords` defaults to 100 records per page; pass `limit` up to 200. See <doc:WorkingWithRecords> for `queryRecords` and `queryAllRecords` examples, including custom and shared zones.

### Streaming pages

``CloudKitService/queryRecordPages(_:limit:desiredKeys:continuationMarker:zoneID:database:)`` yields each page as it arrives, for progress reporting or filling a table, instead of collecting everything first:

```swift
var count = 0
for try await page in service.queryRecordPages(
  try descriptor.query(),
  limit: descriptor.limit,
  desiredKeys: descriptor.desiredKeys,
  zoneID: descriptor.zoneID,
  database: .private
) {
  count += page.records.count
  print("\(count) records so far")
}
```

The stream finishes after the page whose continuation marker is `nil`. It also stops when the server answers with the continuation marker it was sent, since the next request would be identical: an empty page ends the stream before it is yielded, and a page with records is yielded once and then ends it. There is no `maxPages` ceiling; cancel the consuming task to stop earlier, which also cancels the request in flight.

An error ends the stream. Every error it throws is a ``CloudKitError``; the element type says `any Error` only because `AsyncThrowingStream` can't carry a typed failure. MistKit never retries: to resume, start a new stream at the last page's `continuationMarker`.

> Note: MistDemo's `query` command (`Examples/MistDemo/Sources/MistDemoKit/Commands/QueryCommand.swift`) builds a ``Query`` from `--filter field:operator:value` options and calls `queryRecords` with `--zone`, `--zone-owner`, `--limit`, `--fields` and `--zone-wide`. Run `swift run mistdemo query --help` in `Examples/MistDemo` for the options.

## Topics

### Building queries in code

- ``Query``
- ``QueryFilter``
- ``QuerySort``
- ``FilterComparator``

### Describing queries as data

- ``QueryDescriptor``
- ``QueryDescriptorError``
- ``QueryFieldName``

### Predicate text

- ``QueryPredicate``
- ``QueryPredicateParseError``
- ``QueryPredicateFormatError``

### Validation

- ``QueryValidation``
- ``QueryValidationIssue``

### Running queries

- ``CloudKitService/queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)``
- ``CloudKitService/queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)``
- ``CloudKitService/queryRecordPages(_:limit:desiredKeys:continuationMarker:zoneID:database:)``
- ``QueryResult``

## See Also

- <doc:WorkingWithRecords>
- <doc:FieldTypePolymorphism>
- <doc:CloudKitLimitsAndPerformance>
- <doc:HandlingErrors>
