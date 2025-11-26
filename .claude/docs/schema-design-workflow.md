# CloudKit Schema Design Workflow with Task Master

**Purpose:** Integrate CloudKit schema design into Task Master workflows for structured, AI-assisted database development.

---

## Table of Contents

1. [Including Schema in PRD](#including-schema-in-prd)
2. [Task Decomposition Patterns](#task-decomposition-patterns)
3. [Schema Evolution Workflow](#schema-evolution-workflow)
4. [Task Templates](#task-templates)

---

## Including Schema in PRD

### PRD Structure for Schema-Driven Projects

When creating a PRD for a project that uses CloudKit, include a dedicated schema section:

```markdown
# Product Requirements Document: RSS Reader App (Celestra)

## Overview
Build an RSS feed reader application with CloudKit backend for sync across devices.

## Features
1. Subscribe to RSS feeds
2. View feed articles
3. Search articles by title
4. Categorize feeds
5. Sync across devices via CloudKit

## Data Model

### Record Types

**Feed**
- Purpose: Represents an RSS feed subscription
- Fields:
  - feedURL (STRING, unique, queryable) - The RSS feed URL
  - title (STRING, searchable) - Feed title
  - description (STRING) - Feed description
  - isActive (BOOLEAN) - Whether feed is active
  - usageCount (INT) - Number of times feed was accessed
  - lastAttempted (TIMESTAMP) - Last fetch attempt
- Permissions: Public read, authenticated create/write
- Indexes: feedURL (equality + sort), isActive (equality), usageCount (sort), lastAttempted (sort)

**Article**
- Purpose: Represents an article from an RSS feed
- Fields:
  - feed (REFERENCE to Feed) - Parent feed
  - title (STRING, searchable) - Article title
  - link (STRING) - Article URL
  - description (STRING) - Article description
  - author (STRING) - Article author
  - pubDate (TIMESTAMP) - Publication date
  - guid (STRING, unique) - RSS GUID
  - contentHash (STRING) - Hash for change detection
  - fetchedAt (TIMESTAMP) - When article was fetched
  - expiresAt (TIMESTAMP) - Cache expiration
- Permissions: Public read, authenticated create/write
- Indexes: feed (equality), pubDate (sort), guid (equality), contentHash (equality)
- Relationships: Article.feed → Feed.recordID

**Category** (Future)
- Purpose: Organize feeds into categories
- Fields: TBD
- Relationships: Feed.category → Category.recordID

## Implementation Notes
- Use CloudKit text-based schema (.ckdb file)
- Commit schema to version control
- Validate schema changes in development environment first
- Follow MistKit patterns for Swift models
```

### Key PRD Elements for Schema

1. **Record Types Section**: List all record types with purposes
2. **Field Specifications**: Field name, type, purpose, and indexing
3. **Relationship Diagram**: Document references between record types
4. **Permission Strategy**: Who can read/create/write each record type
5. **Query Patterns**: Expected queries that drive indexing decisions

### Example: Adding a Feature with Schema Changes

```markdown
## Feature: Feed Categorization

### Requirements
- Users can create categories
- Users can assign feeds to categories
- Users can filter feeds by category
- Categories have icons and colors

### Schema Changes

**New Record Type: Category**
- name (STRING, queryable, sortable) - Category name
- description (STRING) - Category description
- iconURL (STRING) - Icon image URL
- colorHex (STRING) - Display color
- sortOrder (INT, queryable, sortable) - Display order

**Modified Record Type: Feed**
- Add: category (REFERENCE to Category, queryable) - Assigned category

### Implementation Tasks
1. Design and validate Category record type
2. Add category field to Feed record type
3. Create Swift Category model
4. Update Swift Feed model with category reference
5. Implement category management UI
6. Implement feed filtering by category
7. Add category migration for existing feeds
```

---

## Task Decomposition Patterns

### Pattern 1: New Feature with Schema

When a feature requires new record types:

```
Task: Implement Feed Categorization
├── Subtask 1: Schema Design
│   ├── Define Category record type in schema.ckdb
│   ├── Add category field to Feed record type
│   ├── Validate schema syntax
│   └── Import to development environment
├── Subtask 2: Swift Model Generation
│   ├── Create Category struct conforming to Codable
│   ├── Add CloudKit conversion extensions (init, toCKRecord)
│   ├── Update Feed model with category reference
│   └── Add relationship helper methods
├── Subtask 3: Data Access Layer
│   ├── Implement CategoryRepository
│   ├── Add category queries to FeedRepository
│   ├── Add category filtering methods
│   └── Write unit tests
├── Subtask 4: UI Implementation
│   ├── Create category management screen
│   ├── Add category picker to feed edit screen
│   ├── Add category filter to feed list
│   └── Update feed list to show categories
└── Subtask 5: Migration & Testing
    ├── Create default categories for existing feeds
    ├── Test schema changes with real data
    ├── Test sync across devices
    └── Update documentation
```

### Pattern 2: Schema Evolution

When modifying an existing schema:

```
Task: Add Article Read Tracking
├── Subtask 1: Schema Analysis
│   ├── Review existing Article record type
│   ├── Determine field requirements (isRead, readAt)
│   ├── Decide on indexing strategy
│   └── Document schema changes
├── Subtask 2: Schema Modification
│   ├── Add isRead field (INT64, queryable)
│   ├── Add readAt field (TIMESTAMP, queryable, sortable)
│   ├── Validate schema changes
│   └── Test import to development
├── Subtask 3: Code Updates
│   ├── Update Article Swift model
│   ├── Add read/unread methods
│   ├── Update queries to filter by read status
│   └── Handle null values for existing articles
└── Subtask 4: Testing
    ├── Test with existing articles (null handling)
    ├── Test marking articles as read
    ├── Test filtering read/unread articles
    └── Verify sync behavior
```

### Pattern 3: Performance Optimization

When adding indexes to improve query performance:

```
Task: Optimize Article Queries
├── Subtask 1: Performance Analysis
│   ├── Identify slow queries
│   ├── Review CloudKit dashboard metrics
│   ├── Analyze current indexes
│   └── Determine missing indexes
├── Subtask 2: Schema Updates
│   ├── Add SORTABLE to author field
│   ├── Add QUERYABLE to contentHash field
│   ├── Validate schema changes
│   └── Import to development
├── Subtask 3: Query Optimization
│   ├── Update queries to use new indexes
│   ├── Add sort descriptors where beneficial
│   ├── Benchmark query performance
│   └── Document query patterns
└── Subtask 4: Monitoring
    ├── Deploy to production
    ├── Monitor CloudKit metrics
    ├── Verify performance improvements
    └── Update documentation
```

---

## Schema Evolution Workflow

### Workflow: Adding a New Field

Use this task pattern when adding a field to an existing record type:

```
Task ID: 5 - Add lastError Field to Feed
Status: pending
Dependencies: none

Description:
Add error tracking to Feed record type to display fetch failures to users.

Subtasks:
  5.1 - Update schema.ckdb with lastError field
    - Add "lastError" STRING field to Feed record type
    - No indexing needed (display only)
    - Validate syntax with cktool

  5.2 - Import schema to development
    - Set CLOUDKIT_ENVIRONMENT=development
    - Run cktool import-schema schema.ckdb
    - Verify in CloudKit Dashboard

  5.3 - Update Swift Feed model
    - Add var lastError: String? property
    - Update init(record:) to read field
    - Update toCKRecord() to write field
    - Handle nil for existing records

  5.4 - Update UI to display errors
    - Add error message label to feed list
    - Add error details to feed edit screen
    - Style error messages appropriately

  5.5 - Test with real data
    - Create test feed with error
    - Verify error displays correctly
    - Test with existing feeds (nil handling)
    - Verify sync across devices
```

### Workflow: Adding a New Record Type

Use this task pattern when introducing a new entity:

```
Task ID: 8 - Add Category Record Type
Status: pending
Dependencies: none

Description:
Implement feed categorization by adding Category record type and updating Feed.

Subtasks:
  8.1 - Design Category schema
    - Define fields: name, description, iconURL, colorHex, sortOrder
    - Determine indexing (name: queryable+sortable, sortOrder: queryable+sortable)
    - Define permissions (standard public pattern)
    - Add to schema.ckdb

  8.2 - Update Feed schema
    - Add "category" REFERENCE QUERYABLE field
    - Validate complete schema
    - Document relationship: Feed.category → Category.recordID

  8.3 - Import schema to development
    - Validate syntax
    - Import to development environment
    - Verify both record types in dashboard
    - Test creating sample records

  8.4 - Create Swift Category model
    - Define Category struct
    - Add Codable conformance
    - Implement CloudKit conversion (init, toCKRecord)
    - Add validation logic

  8.5 - Update Swift Feed model
    - Add var category: CKRecord.Reference? property
    - Update CloudKit conversion methods
    - Add helper to create category reference

  8.6 - Implement CategoryRepository
    - Create, read, update, delete operations
    - List all categories query
    - Sort by sortOrder
    - Unit tests

  8.7 - Update FeedRepository
    - Add category parameter to queries
    - Implement filterByCategory method
    - Update feed creation to include category

  8.8 - Implement UI
    - Category management screen (list, create, edit, delete)
    - Category picker in feed edit
    - Category filter in feed list
    - Category icons and colors

  8.9 - Migration and testing
    - Create default category
    - Migrate existing feeds to default category
    - Test all CRUD operations
    - Test sync across devices
    - Performance testing
```

### Workflow: Index Optimization

Use this task pattern when adding indexes to existing fields:

```
Task ID: 12 - Optimize Article Author Queries
Status: pending
Dependencies: none

Description:
Add SORTABLE index to author field to enable "sort by author" feature.

Subtasks:
  12.1 - Analyze current performance
    - Measure current query time for author sorting
    - Review CloudKit metrics for author queries
    - Document baseline performance

  12.2 - Update schema
    - Change "author" from QUERYABLE to QUERYABLE SORTABLE
    - Validate schema change
    - Import to development

  12.3 - Update queries
    - Add sort descriptor: NSSortDescriptor(key: "author", ascending: true)
    - Update ArticleRepository methods
    - Add "sort by author" option to UI

  12.4 - Test and benchmark
    - Create test data with varied authors
    - Measure new query performance
    - Compare to baseline
    - Document improvement
    - Verify no regressions

  12.5 - Deploy to production
    - Import schema to production
    - Monitor CloudKit metrics
    - Verify performance improvement
    - Update documentation
```

---

## Task Templates

### Template: New Record Type

```markdown
**Task: Add [RecordTypeName] Record Type**

**Description:**
Implement [RecordTypeName] to support [feature description].

**Schema Design:**
- Fields: [list fields with types and indexes]
- Permissions: [permission strategy]
- Relationships: [references to/from other types]

**Subtasks:**
1. Define schema in schema.ckdb
2. Validate and import to development
3. Create Swift model struct
4. Implement CloudKit conversion extensions
5. Create repository/data access layer
6. Add UI components
7. Write tests
8. Documentation

**Acceptance Criteria:**
- [ ] Schema imported to development successfully
- [ ] Swift model compiles and tests pass
- [ ] Can create, read, update, delete records
- [ ] Syncs correctly across devices
- [ ] UI displays data correctly
- [ ] Documentation updated
```

### Template: Add Field to Existing Type

```markdown
**Task: Add [fieldName] to [RecordTypeName]**

**Description:**
Add [fieldName] field to support [feature description].

**Field Specification:**
- Name: [fieldName]
- Type: [CloudKit type]
- Indexing: [QUERYABLE/SORTABLE/SEARCHABLE or none]
- Purpose: [why this field is needed]

**Subtasks:**
1. Add field to schema.ckdb
2. Validate and import to development
3. Update Swift model
4. Handle null values for existing records
5. Update UI if needed
6. Test with existing and new data

**Acceptance Criteria:**
- [ ] Schema imported successfully
- [ ] Swift model updated
- [ ] Existing records handle null gracefully
- [ ] New records populate field correctly
- [ ] Tests pass
```

### Template: Schema Validation

```markdown
**Task: Validate Schema Changes**

**Description:**
Ensure all schema modifications are valid before production deployment.

**Checklist:**
- [ ] Run `cktool validate-schema schema.ckdb`
- [ ] Import to development environment
- [ ] Create test records with new schema
- [ ] Query test records successfully
- [ ] Verify indexes in CloudKit Dashboard
- [ ] Test with existing data (migration)
- [ ] Verify permissions work correctly
- [ ] Check for data loss warnings
- [ ] Document any issues found
- [ ] Get approval for production import
```

### Template: Performance Optimization

```markdown
**Task: Optimize [QueryType] Performance**

**Description:**
Improve performance of [query description] by adding/modifying indexes.

**Analysis:**
- Current performance: [baseline metrics]
- Bottleneck: [identified issue]
- Proposed solution: [index changes]

**Schema Changes:**
- [Field]: Add/modify [index type]

**Subtasks:**
1. Benchmark current performance
2. Update schema with new indexes
3. Import to development
4. Update query code to use indexes
5. Benchmark new performance
6. Document improvement
7. Deploy to production
8. Monitor metrics

**Success Metrics:**
- Query time reduced by [target %]
- CloudKit operation count reduced
- User-perceived performance improvement
```

---

## Integration with Task Master Commands

### Workflow Commands

```bash
# 1. Parse PRD with schema requirements
task-master parse-prd .taskmaster/docs/prd.txt

# 2. Analyze complexity of schema tasks
task-master analyze-complexity --research

# 3. Expand schema design task into subtasks
task-master expand --id=5 --research

# 4. Get next schema task to work on
task-master next

# 5. Update subtask with implementation notes
task-master update-subtask --id=5.1 --prompt="Added lastError field, validated successfully"

# 6. Mark subtask complete
task-master set-status --id=5.1 --status=done

# 7. Research best practices
task-master research \
  --query="CloudKit schema indexing best practices for article queries" \
  --save-to=12.1
```

### Example Session

```bash
# Start working on schema tasks
$ task-master next
📋 Next Available Task: #8 - Add Category Record Type

# Show task details
$ task-master show 8
Task 8: Add Category Record Type
Status: pending
Description: Implement feed categorization...
Subtasks:
  8.1 - Design Category schema [pending]
  8.2 - Update Feed schema [pending]
  ...

# Expand subtask 8.1 if needed
$ task-master expand --id=8.1 --research

# Mark as in progress
$ task-master set-status --id=8.1 --status=in-progress

# Work on schema file...
# Edit Examples/Celestra/schema.ckdb

# Log progress
$ task-master update-subtask --id=8.1 --prompt="Defined Category record type with name (queryable sortable), description, iconURL, colorHex, and sortOrder (queryable sortable). Used standard public permissions."

# Complete subtask
$ task-master set-status --id=8.1 --status=done

# Move to next subtask
$ task-master set-status --id=8.2 --status=in-progress
```

---

## See Also

- **Schema Workflow Guide:** [Examples/Celestra/AI_SCHEMA_WORKFLOW.md](../../Examples/Celestra/AI_SCHEMA_WORKFLOW.md)
- **Quick Reference:** [Examples/SCHEMA_QUICK_REFERENCE.md](../../Examples/SCHEMA_QUICK_REFERENCE.md)
- **Claude Reference:** [.claude/docs/cloudkit-schema-reference.md](../../.claude/docs/cloudkit-schema-reference.md)
- **Task Master Guide:** [.taskmaster/CLAUDE.md](../CLAUDE.md)
