# CloudKit Schema Language Reference (sosumi.ai)

**Source:** https://sosumi.ai/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow
**Original:** https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow
**Downloaded:** 2025-11-11

---

# Integrating a Text-Based Schema into Your Workflow

> Define and update your schema with the CloudKit Schema Language.

## Overview

CloudKit's textual representation enables you to simultaneously manage your schema and the application source code that depends on it. The CloudKit command line tools download, verify, and install a schema to your container's sandbox environment, while the CloudKit dashboard promotes a schema to the production environment.

When publishing a schema, CloudKit attempts to apply changes to the existing schema, if one exists, to convert it to the form specifed in the new schema. If the modifications required would result in potential data loss with respect to the current production schema (like removing a record type or field name that exists already), then the schema isn't valid and CloudKit makes no changes.

For containers with an existing schema, use the CloudKit command line tools to download the container's schema. Manually constructing your existing schema by hand isn't recommended, as any mistakes may result in your existing sandbox data becoming inaccessible. A good practice is to integrate the schema into your source code repository.

### Learn the CloudKit Schema Language Grammar

The grammar for the CloudKit Schema Language contains all the elements to define your schema. Use the grammar to create roles, declare record types and their permissions, as well as specify data types and options for each field in the record.

```
create-schema:
    DEFINE SCHEMA
        [ { create-role | record-type } ";" ] ...

create-role:
    CREATE ROLE %role-name%

record-type:
    RECORD TYPE %type-name% (
        {
            [ %field-name% data-type [ field-options [..] ] ]
            |
            [ GRANT { READ | CREATE | WRITE } [, ... ] TO %role-name% ]
        } ["," ... ]
    )

field-options:
    | QUERYABLE
    | SORTABLE
    | SEARCHABLE

data-type:
   primitive-type | list-type

primitive-type:
   | ASSET
   | BYTES
   | DOUBLE
   | [ ENCRYPTED ] { BYTES | STRING | DOUBLE | INT64 | LOCATION | TIMESTAMP }
   | INT64
   | LOCATION
   | NUMBER [ PREFERRED AS { INT64 | DOUBLE } ]
   | REFERENCE
   | STRING
   | TIMESTAMP

list-type:
   | LIST "<" primitive-type ">"
```

Additional details and guidelines for creating roles, record types, type names, field names, data types and permissions are listed below.

`QUERYABLE` - Maintains an index to optimize equality lookups on the field.

`SORTABLE` - Maintains an index optimizing for range searches on the field.

`SEARCHABLE` - Maintains a text search index on the field.

Avoid using the `NUMBER` type, which is only for when a field is implicitly added to a schema by a record modification on a sandbox container. If such a field has been implicitly added to a type in your schema, the `PREFERRED AS` syntax allows you to explicitly indicate which type the `NUMBER` should be treated as (`INT64` or `DOUBLE`). Once you assign `NUMBER` as a `PREFERRED AS` type, future definitions must not change that type.

The grammar uses these conventions:

- Brackets indicate optional parts.
- Braces and vertical bars indicate that you must choose one alternative.
- An ellipsis indicates that the preceding element can be repeated.
- Names surrounded by percent signs indicate identifiers.

Identifiers must follow existing CloudKit naming conventions and restrictions. User-defined identifiers must follow these rules:

- The first character must be one of `a-z` or `A-Z`.
- Subsequent characters must be one of `a-z`, `A-Z`, `0-9`, or `_` (underscore).
- Use double quotes around identifiers to include keywords and reserved words in the syntax definition. For example, to create a type called *grant*, define it as "grant". The reserved words in the CloudKit Schema Language are: grant, preferred, queryable, sortable, and searchable.

Also, CloudKit reserves identifiers starting with a leading underscore as system-defined identifiers. For example, all record types have an implicitly defined `___recordID` field. Use double quotes when referring to such system fields as well.

The language allows comments in these forms:

```
// Single-line comment
-- Single-line comment
/*
Multi-line comment
*/
```

CloudKit doesn't preserve the comments in your schema when you upload them to CloudKit. Additionally, when you retreive the schema, the order of the elements may differ from the order when the schema was created or updated.

### Recognize Implicit Fields and Roles

All record types have the following implicitly defined fields:

- `"___createTime" TIMESTAMP`
- `"___createdBy" REFERENCE`
- `"___etag" STRING`
- `"___modTime" TIMESTAMP`
- `"___modifiedBy" REFERENCE`
- `"___recordID" REFERENCE`

These field names are always present within the record time so it's not necessary to explicitly provide them. If you wish to make any of these fields queryable, sortable, or searchable, then your type must explicitly specify the field and the attribute. You can't change the type of these system fields.

Though CloudKit won't remove the system field names, it doesn't maintain the field options if the field isn't mentioned in later schema updates. For example, if the following is in your schema:

```
RECORD TYPE ApplicationType  (
        "___createTime" TIMESTAMP QUERYABLE,
        name STRING,
        ...
)
```

Then CloudKit builds an index for efficient searches on the record creation time field. Later, if you modify the schema to no longer mention the creation time field:

```
RECORD TYPE ApplicationType  (
        name STRING,
        ...
)
```

Then the `__createTime` field remains on the record type (since it's a required system field), but CloudKit drops the index on the field, and the user query performance may degrade or fail as a result.

Additionally, all record types have these implicitly defined roles:

For types that you wish to use in a `PUBLIC` database, include the following grants:

```
GRANT WRITE TO "_creator"
GRANT CREATE TO "_icloud"
GRANT READ TO "_world"
```

### View an Example Schema

This sample schema defines a simple company department and employee information. It demonstrates extending the attributes of system fields and the double quotes necessary for referring to system identifiers.

```
DEFINE SCHEMA
    CREATE ROLE DeptManager;

    RECORD TYPE Department (
        "___createTime" TIMESTAMP QUERYABLE SORTABLE,
        "___recordID" REFERENCE QUERYABLE,
        name STRING,
        address STRING,
        phone LIST<STRING>,
        employees LIST<REFERENCE>,
        GRANT WRITE TO "_creator",
        GRANT CREATE TO "_icloud",
        GRANT READ TO "_world",
        GRANT WRITE, CREATE, READ TO DeptManager
    );

    RECORD TYPE Employee (
        "___createTime" TIMESTAMP QUERYABLE SORTABLE,
        "___recordID" REFERENCE QUERYABLE,
        name STRING,
        address STRING,
        hiredate TIMESTAMP,
        salary INT64,
        GRANT WRITE TO "_creator",
        GRANT CREATE TO "_icloud",
        GRANT READ TO "_world"
    );
```

## See Also

- [Designing and Creating a CloudKit Database](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)
- [Managing iCloud Containers with CloudKit Database App](https://developer.apple.com/documentation/cloudkit/managing-icloud-containers-with-cloudkit-database-app)
- [CKRecordZone](https://developer.apple.com/documentation/cloudkit/ckrecordzone)
- [CKRecord](https://developer.apple.com/documentation/cloudkit/ckrecord)
- [CKRecord.Reference](https://developer.apple.com/documentation/cloudkit/ckrecord/reference)
- [CKAsset](https://developer.apple.com/documentation/cloudkit/ckasset)

---

*Extracted by sosumi.ai - Making Apple docs AI-readable.*
*This is unofficial content. All documentation belongs to Apple Inc.*
