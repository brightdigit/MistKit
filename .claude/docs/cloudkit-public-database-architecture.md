# CloudKit Public Database Architecture for Celestara RSS Reader

**Version**: 2.0
**Last Updated**: 2025-11-04
**Purpose**: Architecture overview and schema reference for CloudKit public database implementation using MistKit

**Architecture**: Shared article cache in public database for efficiency and offline support

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Public Database Schema](#public-database-schema)
4. [Data Flow Patterns](#data-flow-patterns)
5. [MistKit Integration](#mistkit-integration)
6. [Implementation Considerations](#implementation-considerations)
7. [API Reference](#api-reference)

---

## Overview

### Purpose of Public Database

The CloudKit **public database** serves as a centralized, read-mostly repository for:
- **Feed Discovery**: Community-curated RSS feed URLs for new users
- **Feed Metadata**: Analytics and quality metrics (subscriber counts, update reliability)
- **Curated Collections**: Editorial or algorithmic feed bundles
- **Category Taxonomy**: Standardized feed categorization
- **Shared Article Cache**: RSS article content pulled once and shared across all users (reduces RSS server load, enables offline reading)

### Data Storage Architecture

**Where does article content live?**

| Storage Layer | What's Stored | Purpose |
|---------------|---------------|---------|
| **Public CloudKit DB** | Article CONTENT (title, body, images, author, etc.) | Shared by ALL users - fetch once, read by many |
| **Core Data (Local)** | Cached copy of articles | Offline reading on THIS device |
| **Private CloudKit DB** | User ACTIONS only (read states, stars, preferences) | Sync user's personal actions across devices |

**Important**: Private CloudKit does NOT store article content. It only stores references to articles (e.g., "User read article with ID abc123 on Jan 1, 2025"). The actual article content is always fetched from Public CloudKit DB.

**Example Flow**:
1. Server fetches article from RSS → saves to Public CloudKit DB
2. User's iPhone fetches article from Public CloudKit DB → saves to local Core Data
3. User reads article → saves read state (article ID + timestamp) to Private CloudKit DB
4. User's iPad syncs → gets read state from Private CloudKit DB, gets article content from Public CloudKit DB

### Architecture Principles

1. **Clear Separation: Content vs. User Actions**
   - **Public DB**: Article CONTENT (shared by all users) - title, body, images, etc.
   - **Private DB**: User ACTIONS only (read states, stars, preferences) - NO article content
   - **Core Data**: Local offline cache of articles copied from Public DB

2. **Dual-Source Article Upload (Hybrid Architecture)**
   - **Primary**: CLI app (cron job on Lambda/VPS) fetches RSS and uploads to Public DB
   - **Fallback**: Celestra iOS app uploads articles if missing/stale
   - Benefits: Resilient (works even if server is down), community-contributed content
   - All users benefit from articles uploaded by any source

3. **Efficiency Through Sharing**
   - Pull RSS content **once** per article across all users (whether by server or app)
   - Store in public DB → all users read from CloudKit instead of hammering RSS servers
   - Reduces bandwidth costs for RSS publishers
   - Faster loading (CloudKit CDN vs slow RSS servers)

4. **Offline-First Architecture**
   - Public DB articles synced to local Core Data
   - User can read offline without network
   - Background sync keeps content fresh

5. **Privacy-First**
   - User subscriptions never stored in public DB
   - Read states and starred articles kept private
   - No cross-user tracking
   - Anonymous analytics only (aggregated counts)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        RSS Feed Sources                          │
│  (External RSS/Atom/JSON Feed servers on the internet)          │
└──────────────────┬─────────────────────────┬────────────────────┘
                   │                         │
      PRIMARY PATH │                         │ FALLBACK PATH
    (Server-side)  │                         │ (Celestra app)
                   │                         │
                   ▼                         ▼
┌────────────────────────────┐  ┌───────────────────────────────┐
│  CLI App (Swift/Node.js)   │  │  Celestra iOS App             │
│  • Cron job (every 15-30m) │  │  • If articles missing/stale  │
│  • Deployed on Lambda/VPS  │  │  • Fetches RSS directly       │
│  • Fetches all feeds       │  │  • Parses with SyndiKit       │
│  • Parses with SyndiKit    │  │                               │
└──────────────┬─────────────┘  └────────────┬──────────────────┘
               │                              │
               │  Both upload to Public DB    │
               └──────────────┬───────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Public CloudKit Database                        │
│                                                                  │
│  CKRecord: PublicFeed        → Feed metadata & URLs             │
│  CKRecord: PublicArticle     → Article content (SHARED)         │
│  CKRecord: FeedMetadata      → Analytics & health               │
│  CKRecord: FeedCollection    → Curated bundles                  │
│  CKRecord: FeedCategory      → Category taxonomy                │
│                                                                  │
│  ⚠️  Articles uploaded by EITHER server OR app                  │
│  All users benefit from shared cache                            │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ Query & Download Articles
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Core Data (Local Device)                     │
│                                                                  │
│  CDFeed              → User's subscribed feeds                  │
│  CDArticle           → Cached article content (offline)         │
│  CDUserPreferences   → App settings                             │
│                                                                  │
│  Syncs to Private CloudKit for read states & stars             │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ User actions (read, star)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Private CloudKit Database                      │
│                                                                  │
│  CKRecord: UserReadState    → Which articles user read          │
│  CKRecord: UserStarred      → Starred/bookmarked articles       │
│  CKRecord: UserSubscription → User's feed list                  │
│  CKRecord: UserPreferences  → Settings sync                     │
│                                                                  │
│  ⚠️  IMPORTANT: NO ARTICLE CONTENT STORED HERE                  │
│  Only stores references (article IDs) + user actions            │
│  Syncs across user's devices                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Data Flow Patterns                          │
│                                                                  │
│  1. Feed Discovery:     Public DB → Browse feeds → Subscribe    │
│  2. Article Ingestion:  RSS → Parse → Public DB (server-side)  │
│  3. Content Fetch:      Public DB → Core Data (offline cache)  │
│  4. User Actions:       Local → Private DB (read/star states)  │
│  5. Multi-Device Sync:  Private DB ↔ User's devices            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Public Database Schema

### Record Type: `PublicFeed`

**Purpose**: Represents a community-discoverable RSS feed

**Fields**:

| Field Name | Type | Indexed | Sortable | Description |
|------------|------|---------|----------|-------------|
| `recordName` | String | ✅ | ❌ | Unique identifier (UUID) |
| `feedURL` | String | ✅ | ❌ | RSS/Atom feed URL (unique constraint) |
| `title` | String | ✅ | ✅ | Feed display name |
| `subtitle` | String | ❌ | ❌ | Feed description/tagline |
| `siteURL` | String | ❌ | ❌ | Website homepage URL |
| `imageURL` | String | ❌ | ❌ | Feed logo/icon URL |
| `category` | Reference(FeedCategory) | ✅ | ❌ | Primary category reference |
| `language` | String | ✅ | ❌ | ISO 639-1 language code (e.g., "en", "es") |
| `isFeatured` | Int64 (Boolean) | ✅ | ❌ | Editorial featured flag (1 or 0) |
| `isVerified` | Int64 (Boolean) | ✅ | ❌ | Verified/trusted source (1 or 0) |
| `qualityScore` | Double | ❌ | ✅ | Computed quality metric (0.0-100.0) |
| `subscriberCount` | Int64 | ❌ | ✅ | Number of Celestara users subscribed |
| `addedAt` | DateTime | ❌ | ✅ | When feed was added to public DB |
| `lastVerified` | DateTime | ❌ | ✅ | Last time feed was verified active |
| `updateFrequency` | Int64 | ❌ | ✅ | Average hours between updates |
| `tags` | String List | ✅ | ❌ | Searchable tags (e.g., ["swift", "ios", "apple"]) |

**Indexes**:
- `feedURL` (unique)
- `category` + `isFeatured`
- `category` + `subscriberCount` (descending)
- `tags` + `language`

**Security**:
- Read: World readable
- Write: Admin role only (via CloudKit Dashboard permissions)

---

### Record Type: `FeedMetadata`

**Purpose**: Analytics and health metrics for feeds

**Fields**:

| Field Name | Type | Indexed | Sortable | Description |
|------------|------|---------|----------|-------------|
| `recordName` | String | ✅ | ❌ | Unique identifier (UUID) |
| `feedReference` | Reference(PublicFeed) | ✅ | ❌ | Parent feed record |
| `subscriberCount` | Int64 | ❌ | ✅ | Total subscribers |
| `averageRating` | Double | ❌ | ✅ | Average user rating (0.0-5.0) |
| `ratingCount` | Int64 | ❌ | ❌ | Number of ratings |
| `lastFetchSuccess` | DateTime | ❌ | ✅ | Last successful fetch timestamp |
| `lastFetchFailure` | DateTime | ❌ | ❌ | Last failed fetch timestamp |
| `uptimePercentage` | Double | ❌ | ✅ | 30-day uptime (0.0-100.0) |
| `averageArticlesPerWeek` | Double | ❌ | ❌ | Publishing frequency |
| `healthStatus` | String | ✅ | ❌ | "healthy", "degraded", "down" |
| `lastHealthCheck` | DateTime | ❌ | ✅ | Last health verification |

**Indexes**:
- `feedReference` (unique)
- `healthStatus`
- `uptimePercentage` (descending)

**Security**:
- Read: World readable
- Write: Server-side process only

---

### Record Type: `FeedCategory`

**Purpose**: Hierarchical category taxonomy

**Fields**:

| Field Name | Type | Indexed | Sortable | Description |
|------------|------|---------|----------|-------------|
| `recordName` | String | ✅ | ❌ | Unique identifier (category slug) |
| `name` | String | ✅ | ✅ | Display name (e.g., "Technology") |
| `slug` | String | ✅ | ❌ | URL-safe identifier (e.g., "technology") |
| `icon` | String | ❌ | ❌ | SF Symbol name (e.g., "laptopcomputer") |
| `color` | String | ❌ | ❌ | Hex color code (e.g., "#007AFF") |
| `sortOrder` | Int64 | ❌ | ✅ | Display order priority |
| `parentCategory` | Reference(FeedCategory) | ✅ | ❌ | Parent category (for hierarchy) |
| `description` | String | ❌ | ❌ | Category description |

**Predefined Categories** (matches existing `FeedCategory` enum):
- General (slug: `general`, icon: `newspaper`)
- Technology (slug: `technology`, icon: `laptopcomputer`)
- Design (slug: `design`, icon: `paintbrush`)
- Business (slug: `business`, icon: `briefcase`)
- News (slug: `news`, icon: `globe`)
- Entertainment (slug: `entertainment`, icon: `tv`)
- Science (slug: `science`, icon: `flask`)
- Health (slug: `health`, icon: `heart`)

**Security**:
- Read: World readable
- Write: Admin role only

---

### Record Type: `FeedCollection`

**Purpose**: Curated bundles of feeds (e.g., "Best Tech Blogs", "Design Inspiration")

**Fields**:

| Field Name | Type | Indexed | Sortable | Description |
|------------|------|---------|----------|-------------|
| `recordName` | String | ✅ | ❌ | Unique identifier (UUID) |
| `title` | String | ✅ | ✅ | Collection display name |
| `description` | String | ❌ | ❌ | Collection description |
| `coverImageURL` | String | ❌ | ❌ | Cover art URL |
| `curatorName` | String | ❌ | ❌ | Collection creator/editor |
| `feeds` | Reference List(PublicFeed) | ❌ | ❌ | Ordered list of feed references |
| `isFeatured` | Int64 (Boolean) | ✅ | ❌ | Featured on discovery page |
| `subscriberCount` | Int64 | ❌ | ✅ | Users who imported this collection |
| `createdAt` | DateTime | ❌ | ✅ | Creation timestamp |
| `updatedAt` | DateTime | ❌ | ✅ | Last modification |
| `tags` | String List | ✅ | ❌ | Collection tags for search |

**Indexes**:
- `isFeatured`
- `subscriberCount` (descending)
- `createdAt` (descending)

**Security**:
- Read: World readable
- Write: Admin role only

---

### Record Type: `PublicArticle`

**Purpose**: Shared cache of RSS article content (pulled once, read by all users)

**Fields**:

| Field Name | Type | Indexed | Sortable | Description |
|------------|------|---------|----------|-------------|
| `recordName` | String | ✅ | ❌ | Unique identifier (content-based hash or GUID) |
| `feedReference` | Reference(PublicFeed) | ✅ | ❌ | Parent feed record |
| `guid` | String | ✅ | ❌ | Article GUID from RSS (unique per feed) |
| `title` | String | ✅ | ✅ | Article headline |
| `excerpt` | String | ❌ | ❌ | Summary/description (plain text) |
| `content` | String | ❌ | ❌ | Full article HTML content |
| `contentText` | String | ❌ | ❌ | Plain text version (for search) |
| `author` | String | ❌ | ❌ | Article author name |
| `url` | String | ✅ | ❌ | Original article URL |
| `imageURL` | String | ❌ | ❌ | Featured image URL |
| `publishedDate` | DateTime | ❌ | ✅ | Publication timestamp |
| `fetchedAt` | DateTime | ❌ | ✅ | When article was added to CloudKit |
| `expiresAt` | DateTime | ✅ | ✅ | Retention expiration (30-90 days) |
| `contentHash` | String | ✅ | ❌ | SHA-256 of content (deduplication) |
| `wordCount` | Int64 | ❌ | ❌ | Article word count |
| `estimatedReadingTime` | Int64 | ❌ | ❌ | Minutes to read (calculated) |
| `language` | String | ✅ | ❌ | ISO 639-1 language code |
| `tags` | String List | ✅ | ❌ | Article tags/categories |

**Indexes**:
- `feedReference` + `publishedDate` (descending) — fetch latest articles for feed
- `guid` + `feedReference` (unique) — deduplication check
- `contentHash` (unique) — cross-feed deduplication
- `expiresAt` — cleanup query for expired articles
- `url` — prevent duplicate URLs

**Security**:
- Read: World readable
- Write: Authenticated users (Celestra app can upload as fallback) + Server-side process

**Write Strategy**:
- **Primary**: Server-side background job (MistKit) fetches and uploads articles
- **Fallback**: Celestra iOS app uploads articles if missing/stale in Public DB
- All users benefit from articles uploaded by any source

**Retention Policy**:
- Articles auto-delete after **90 days** from `fetchedAt`
- Server-side cleanup job runs daily
- Users can manually "archive" articles to private DB for permanent storage

**Content Limits**:
- `content` field max: 1 MB (CloudKit string limit)
- Articles larger than 1 MB truncated with "Read More" link to original URL
- Images stored as URLs (not embedded), CDN/cache on device

**De-duplication Strategy**:
1. **Per-feed deduplication**: Check `guid` + `feedReference`
2. **Cross-feed deduplication**: Check `contentHash` (same article from multiple feeds)
3. **URL-based check**: Some feeds publish same article with different GUIDs

---

## Data Flow Patterns

### Pattern 1: Feed Discovery

```
User Opens Discovery Tab
         │
         ▼
┌────────────────────────┐
│ Query Public DB        │
│                        │
│ 1. Fetch FeedCategory  │◄─── Cached locally for 24h
│    records             │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Query PublicFeed       │
│                        │
│ WHERE category =       │
│   selectedCategory     │
│ AND isFeatured = 1     │
│                        │
│ SORT BY subscriberCount│
│ LIMIT 50               │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Fetch FeedMetadata     │◄─── Join on feedReference
│ for quality scores     │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Display Feed List      │
│ with preview cards     │
└────────────────────────┘
```

**MistKit Query Example**:
```swift
let predicate = NSPredicate(
    format: "category == %@ AND isFeatured == 1",
    categoryReference
)
let query = CKQuery(recordType: "PublicFeed", predicate: predicate)
query.sortDescriptors = [
    NSSortDescriptor(key: "subscriberCount", ascending: false)
]
```

---

### Pattern 2: Feed Subscription Flow

```
User Taps "Subscribe" on Public Feed
         │
         ▼
┌────────────────────────┐
│ Extract feedURL from   │
│ PublicFeed record      │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Fetch Feed Content     │
│ via SyndiKit           │
│                        │
│ ParsedFeed = fetch(url)│
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Save to Local DB       │
│                        │
│ CDFeed.create(from:    │
│   parsedFeed)          │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Sync to Private DB     │
│                        │
│ NSPersistentCloudKit   │
│ Container handles sync │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Update Public Metadata │◄─── Async, server-side
│                        │     (increment subscriberCount)
│ Via CloudKit Function  │
└────────────────────────┘
```

**Key Point**: User's subscription is NEVER written to public DB. Only anonymous aggregate count incremented via server-side logic.

---

### Pattern 3: Article Ingestion (Server-Side via CLI App)

**WHO RUNS THIS**: Command-line app (cron job on AWS Lambda or VPS) - PRIMARY METHOD

```
Cron Job Triggers CLI App (every 15-30 min)
         │
         ▼
┌────────────────────────┐
│ Query PublicFeed       │
│ records to fetch       │
│                        │
│ WHERE lastFetchedAt <  │
│   now - updateFreq     │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ For Each Feed:         │
│                        │
│ SyndiKit Fetch         │
│ • Use ETag/If-Modified │
│ • Parse new articles   │
│ • Extract full content │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ De-duplication Check   │
│                        │
│ 1. Check contentHash   │
│ 2. Check guid+feed     │
│ 3. Check URL           │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Save to Public DB      │
│                        │
│ PublicArticle.create() │
│ • Set expiresAt = now  │
│   + 90 days            │
│ • Calculate readTime   │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Update FeedMetadata    │
│                        │
│ • lastFetchSuccess     │
│ • articleCount++       │
│ • healthStatus         │
└────────────────────────┘
```

**Key Points**:
- Server-side fetching prevents duplicate RSS requests across users
- Content stored once in public DB, accessed by all users
- Implementation: Simple command-line app (Swift or Node.js)
- Deployment: Cron job on AWS Lambda or VPS (every 15-30 min)
- Lambda benefits: Serverless, pay-per-execution, auto-scaling

---

### Pattern 3b: Article Ingestion (Client-Side Fallback via Celestra)

**WHO RUNS THIS**: Celestra iOS app (FALLBACK METHOD)

**When**: If articles are missing from Public DB or haven't been updated by server

```
User Opens Feed in Celestra App
         │
         ▼
┌────────────────────────┐
│ Query Public DB for    │
│ Recent Articles        │
│                        │
│ WHERE feedReference =  │
│   subscribed feed      │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Articles Found?        │
│                        │
│ • None found?          │
│ • Last article > 24h?  │
└────────┬───────────────┘
         │
         │ YES - Articles missing/stale
         ▼
┌────────────────────────┐
│ Celestra Fetches RSS   │
│ Directly               │
│                        │
│ SyndiKit.fetch(feedURL)│
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Check if Articles      │
│ Already Exist          │
│                        │
│ Query by guid+feed     │
└────────┬───────────────┘
         │
         │ New articles found
         ▼
┌────────────────────────┐
│ Upload to Public DB    │
│                        │
│ CKDatabase.save(       │
│   PublicArticle        │
│ )                      │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Save to Local Core     │
│ Data for Offline       │
└────────────────────────┘
```

**Key Points**:
- **Celestra acts as both consumer AND contributor** to public DB
- Fills gaps when server-side process hasn't run yet or is down
- Still performs deduplication check (don't upload duplicates)
- Benefits all users (articles uploaded by one user are available to everyone)
- **CloudKit Public DB Write Permissions**: Must allow authenticated users to write PublicArticle records (not just admin/server)

**Important for MistKit Demo**:
This client-side fallback pattern is specific to **Celestra's architecture** and won't affect the MistKit demonstration, which focuses on the server-side ingestion pattern (Pattern 3).

---

### Pattern 4: User Article Sync (Client-Side)

**WHO RUNS THIS**: User's device (iOS app)

```
User Opens Feed / Background Refresh
         │
         ▼
┌────────────────────────┐
│ Load User's Subscribed │
│ Feeds from Core Data   │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Query Public DB for    │
│ New Articles           │
│                        │
│ WHERE feedReference IN │
│   userSubscriptions    │
│ AND publishedDate >    │
│   lastSyncDate         │
│ SORT BY publishedDate  │
│ LIMIT 100              │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Download Articles      │
│ from Public DB         │
│                        │
│ Batch fetch            │
│ (50 records at a time) │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Save to Core Data      │
│                        │
│ CDArticle.bulkCreate() │
│ • Store locally        │
│ • Enable offline read  │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ User Reads Article     │
│                        │
│ Mark as read in local  │
│ Core Data              │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Sync Read State to     │
│ Private CloudKit       │
│                        │
│ UserReadState record   │
│ (multi-device sync)    │
└────────────────────────┘
```

**Key Points**:
- Users query public DB for articles from their subscribed feeds only
- Articles cached locally in Core Data for offline reading
- **Private CloudKit stores ONLY user actions**:
  - Which articles THIS user has read (article ID + read timestamp)
  - Which articles THIS user has starred (article ID + star flag)
  - NOT the article content itself (content is in Public DB)
- When you switch devices, your read/star states sync, but article content comes from Public DB

---

### Pattern 5: Collection Import

```
User Taps "Import Collection"
         │
         ▼
┌────────────────────────┐
│ Fetch FeedCollection   │
│ record by ID           │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Resolve Feed References│
│                        │
│ feeds.forEach { ref in │
│   fetch(PublicFeed)    │
│ }                      │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Show Confirmation UI   │
│                        │
│ "Import 15 feeds from  │
│  'Best Tech Blogs'?"   │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Subscribe to Each Feed │◄─── Reuses Pattern 2
│                        │     (individual subscriptions)
│ Parallel fetch with    │
│ progress indicator     │
└────────────────────────┘
```

---

## MistKit Integration

### MistKit Overview

[MistKit](https://github.com/aaronpearce/MistKit) is a Swift library that simplifies CloudKit operations with:
- Type-safe record encoding/decoding
- Async/await API
- Automatic batching
- Query builders
- Subscription management

### Record Type Definitions

#### PublicFeed Record

```swift
import MistKit

struct PublicFeed: CloudKitRecordable {
    static let recordType = "PublicFeed"

    var recordID: CKRecord.ID?

    // Core fields
    let feedURL: URL
    let title: String
    let subtitle: String?
    let siteURL: URL?
    let imageURL: URL?

    // References
    let category: CKRecord.Reference  // → FeedCategory

    // Metadata
    let language: String  // ISO 639-1 code
    let isFeatured: Bool
    let isVerified: Bool
    let qualityScore: Double
    let subscriberCount: Int
    let addedAt: Date
    let lastVerified: Date
    let updateFrequency: Int  // Hours
    let tags: [String]

    // CloudKit encoding
    func encode(to record: inout CKRecord) throws {
        record["feedURL"] = feedURL.absoluteString as CKRecordValue
        record["title"] = title as CKRecordValue
        record["subtitle"] = subtitle as CKRecordValue?
        record["siteURL"] = siteURL?.absoluteString as CKRecordValue?
        record["imageURL"] = imageURL?.absoluteString as CKRecordValue?
        record["category"] = category
        record["language"] = language as CKRecordValue
        record["isFeatured"] = (isFeatured ? 1 : 0) as CKRecordValue
        record["isVerified"] = (isVerified ? 1 : 0) as CKRecordValue
        record["qualityScore"] = qualityScore as CKRecordValue
        record["subscriberCount"] = subscriberCount as CKRecordValue
        record["addedAt"] = addedAt as CKRecordValue
        record["lastVerified"] = lastVerified as CKRecordValue
        record["updateFrequency"] = updateFrequency as CKRecordValue
        record["tags"] = tags as CKRecordValue
    }

    // CloudKit decoding
    init(from record: CKRecord) throws {
        self.recordID = record.recordID

        guard let urlString = record["feedURL"] as? String,
              let url = URL(string: urlString),
              let title = record["title"] as? String else {
            throw MistKitError.invalidRecord
        }

        self.feedURL = url
        self.title = title
        self.subtitle = record["subtitle"] as? String

        if let siteURLString = record["siteURL"] as? String {
            self.siteURL = URL(string: siteURLString)
        } else {
            self.siteURL = nil
        }

        if let imageURLString = record["imageURL"] as? String {
            self.imageURL = URL(string: imageURLString)
        } else {
            self.imageURL = nil
        }

        guard let categoryRef = record["category"] as? CKRecord.Reference else {
            throw MistKitError.invalidRecord
        }
        self.category = categoryRef

        self.language = record["language"] as? String ?? "en"
        self.isFeatured = (record["isFeatured"] as? Int ?? 0) == 1
        self.isVerified = (record["isVerified"] as? Int ?? 0) == 1
        self.qualityScore = record["qualityScore"] as? Double ?? 0.0
        self.subscriberCount = record["subscriberCount"] as? Int ?? 0
        self.addedAt = record["addedAt"] as? Date ?? Date()
        self.lastVerified = record["lastVerified"] as? Date ?? Date()
        self.updateFrequency = record["updateFrequency"] as? Int ?? 24
        self.tags = record["tags"] as? [String] ?? []
    }
}
```

#### FeedCategory Record

```swift
struct FeedCategory: CloudKitRecordable {
    static let recordType = "FeedCategory"

    var recordID: CKRecord.ID?

    let name: String
    let slug: String
    let icon: String  // SF Symbol name
    let color: String  // Hex code
    let sortOrder: Int
    let parentCategory: CKRecord.Reference?
    let description: String?

    func encode(to record: inout CKRecord) throws {
        record["name"] = name as CKRecordValue
        record["slug"] = slug as CKRecordValue
        record["icon"] = icon as CKRecordValue
        record["color"] = color as CKRecordValue
        record["sortOrder"] = sortOrder as CKRecordValue
        record["parentCategory"] = parentCategory
        record["description"] = description as CKRecordValue?
    }

    init(from record: CKRecord) throws {
        self.recordID = record.recordID

        guard let name = record["name"] as? String,
              let slug = record["slug"] as? String else {
            throw MistKitError.invalidRecord
        }

        self.name = name
        self.slug = slug
        self.icon = record["icon"] as? String ?? "newspaper"
        self.color = record["color"] as? String ?? "#007AFF"
        self.sortOrder = record["sortOrder"] as? Int ?? 0
        self.parentCategory = record["parentCategory"] as? CKRecord.Reference
        self.description = record["description"] as? String
    }
}
```

#### FeedMetadata Record

```swift
struct FeedMetadata: CloudKitRecordable {
    static let recordType = "FeedMetadata"

    var recordID: CKRecord.ID?

    let feedReference: CKRecord.Reference  // → PublicFeed
    let subscriberCount: Int
    let averageRating: Double
    let ratingCount: Int
    let lastFetchSuccess: Date?
    let lastFetchFailure: Date?
    let uptimePercentage: Double
    let averageArticlesPerWeek: Double
    let healthStatus: String  // "healthy", "degraded", "down"
    let lastHealthCheck: Date

    func encode(to record: inout CKRecord) throws {
        record["feedReference"] = feedReference
        record["subscriberCount"] = subscriberCount as CKRecordValue
        record["averageRating"] = averageRating as CKRecordValue
        record["ratingCount"] = ratingCount as CKRecordValue
        record["lastFetchSuccess"] = lastFetchSuccess as CKRecordValue?
        record["lastFetchFailure"] = lastFetchFailure as CKRecordValue?
        record["uptimePercentage"] = uptimePercentage as CKRecordValue
        record["averageArticlesPerWeek"] = averageArticlesPerWeek as CKRecordValue
        record["healthStatus"] = healthStatus as CKRecordValue
        record["lastHealthCheck"] = lastHealthCheck as CKRecordValue
    }

    init(from record: CKRecord) throws {
        self.recordID = record.recordID

        guard let feedRef = record["feedReference"] as? CKRecord.Reference else {
            throw MistKitError.invalidRecord
        }

        self.feedReference = feedRef
        self.subscriberCount = record["subscriberCount"] as? Int ?? 0
        self.averageRating = record["averageRating"] as? Double ?? 0.0
        self.ratingCount = record["ratingCount"] as? Int ?? 0
        self.lastFetchSuccess = record["lastFetchSuccess"] as? Date
        self.lastFetchFailure = record["lastFetchFailure"] as? Date
        self.uptimePercentage = record["uptimePercentage"] as? Double ?? 100.0
        self.averageArticlesPerWeek = record["averageArticlesPerWeek"] as? Double ?? 0.0
        self.healthStatus = record["healthStatus"] as? String ?? "healthy"
        self.lastHealthCheck = record["lastHealthCheck"] as? Date ?? Date()
    }
}
```

#### FeedCollection Record

```swift
struct FeedCollection: CloudKitRecordable {
    static let recordType = "FeedCollection"

    var recordID: CKRecord.ID?

    let title: String
    let description: String?
    let coverImageURL: URL?
    let curatorName: String?
    let feeds: [CKRecord.Reference]  // → PublicFeed list
    let isFeatured: Bool
    let subscriberCount: Int
    let createdAt: Date
    let updatedAt: Date
    let tags: [String]

    func encode(to record: inout CKRecord) throws {
        record["title"] = title as CKRecordValue
        record["description"] = description as CKRecordValue?
        record["coverImageURL"] = coverImageURL?.absoluteString as CKRecordValue?
        record["curatorName"] = curatorName as CKRecordValue?
        record["feeds"] = feeds as CKRecordValue
        record["isFeatured"] = (isFeatured ? 1 : 0) as CKRecordValue
        record["subscriberCount"] = subscriberCount as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["tags"] = tags as CKRecordValue
    }

    init(from record: CKRecord) throws {
        self.recordID = record.recordID

        guard let title = record["title"] as? String else {
            throw MistKitError.invalidRecord
        }

        self.title = title
        self.description = record["description"] as? String

        if let imageURLString = record["coverImageURL"] as? String {
            self.coverImageURL = URL(string: imageURLString)
        } else {
            self.coverImageURL = nil
        }

        self.curatorName = record["curatorName"] as? String
        self.feeds = record["feeds"] as? [CKRecord.Reference] ?? []
        self.isFeatured = (record["isFeatured"] as? Int ?? 0) == 1
        self.subscriberCount = record["subscriberCount"] as? Int ?? 0
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.updatedAt = record["updatedAt"] as? Date ?? Date()
        self.tags = record["tags"] as? [String] ?? []
    }
}
```

#### PublicArticle Record

```swift
import MistKit
import CryptoKit

struct PublicArticle: CloudKitRecordable {
    static let recordType = "PublicArticle"

    var recordID: CKRecord.ID?

    // Core fields
    let feedReference: CKRecord.Reference  // → PublicFeed
    let guid: String
    let title: String
    let excerpt: String?
    let content: String?  // HTML
    let contentText: String?  // Plain text for search
    let author: String?
    let url: URL
    let imageURL: URL?

    // Metadata
    let publishedDate: Date
    let fetchedAt: Date
    let expiresAt: Date
    let contentHash: String  // SHA-256
    let wordCount: Int
    let estimatedReadingTime: Int
    let language: String  // ISO 639-1
    let tags: [String]

    // CloudKit encoding
    func encode(to record: inout CKRecord) throws {
        record["feedReference"] = feedReference
        record["guid"] = guid as CKRecordValue
        record["title"] = title as CKRecordValue
        record["excerpt"] = excerpt as CKRecordValue?
        record["content"] = content as CKRecordValue?
        record["contentText"] = contentText as CKRecordValue?
        record["author"] = author as CKRecordValue?
        record["url"] = url.absoluteString as CKRecordValue
        record["imageURL"] = imageURL?.absoluteString as CKRecordValue?
        record["publishedDate"] = publishedDate as CKRecordValue
        record["fetchedAt"] = fetchedAt as CKRecordValue
        record["expiresAt"] = expiresAt as CKRecordValue
        record["contentHash"] = contentHash as CKRecordValue
        record["wordCount"] = wordCount as CKRecordValue
        record["estimatedReadingTime"] = estimatedReadingTime as CKRecordValue
        record["language"] = language as CKRecordValue
        record["tags"] = tags as CKRecordValue
    }

    // CloudKit decoding
    init(from record: CKRecord) throws {
        self.recordID = record.recordID

        guard let feedRef = record["feedReference"] as? CKRecord.Reference,
              let guid = record["guid"] as? String,
              let title = record["title"] as? String,
              let urlString = record["url"] as? String,
              let url = URL(string: urlString),
              let publishedDate = record["publishedDate"] as? Date,
              let fetchedAt = record["fetchedAt"] as? Date,
              let expiresAt = record["expiresAt"] as? Date,
              let contentHash = record["contentHash"] as? String else {
            throw MistKitError.invalidRecord
        }

        self.feedReference = feedRef
        self.guid = guid
        self.title = title
        self.excerpt = record["excerpt"] as? String
        self.content = record["content"] as? String
        self.contentText = record["contentText"] as? String
        self.author = record["author"] as? String
        self.url = url

        if let imageURLString = record["imageURL"] as? String {
            self.imageURL = URL(string: imageURLString)
        } else {
            self.imageURL = nil
        }

        self.publishedDate = publishedDate
        self.fetchedAt = fetchedAt
        self.expiresAt = expiresAt
        self.contentHash = contentHash
        self.wordCount = record["wordCount"] as? Int ?? 0
        self.estimatedReadingTime = record["estimatedReadingTime"] as? Int ?? 1
        self.language = record["language"] as? String ?? "en"
        self.tags = record["tags"] as? [String] ?? []
    }

    // Helper: Calculate content hash
    static func calculateContentHash(_ content: String) -> String {
        let data = Data(content.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Helper: Estimate reading time (based on 200 words/min)
    static func estimateReadingTime(wordCount: Int) -> Int {
        max(1, wordCount / 200)
    }

    // Helper: Extract plain text from HTML
    static func extractPlainText(from html: String) -> String {
        // Basic HTML stripping (in production, use proper parser)
        html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

---

### Service Layer: PublicFeedService

```swift
import MistKit
import CloudKit

@MainActor
final class PublicFeedService: ObservableObject {
    private let database: CKDatabase
    private let cache: PublicFeedCache

    init(container: CKContainer = .default()) {
        self.database = container.publicCloudDatabase
        self.cache = PublicFeedCache()
    }

    // MARK: - Fetch Operations

    /// Fetch featured feeds in a category
    func fetchFeaturedFeeds(
        category: CKRecord.Reference,
        limit: Int = 50
    ) async throws -> [PublicFeed] {
        // Check cache first
        if let cached = cache.featuredFeeds(for: category.recordID.recordName),
           !cache.isExpired(for: "featured_\(category.recordID.recordName)") {
            return cached
        }

        // Query CloudKit
        let predicate = NSPredicate(
            format: "category == %@ AND isFeatured == 1",
            category
        )
        let query = CKQuery(recordType: PublicFeed.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "subscriberCount", ascending: false)
        ]

        let results = try await database.records(
            matching: query,
            resultsLimit: limit
        )

        let feeds = try results.matchResults.compactMap { (recordID, result) -> PublicFeed? in
            switch result {
            case .success(let record):
                return try? PublicFeed(from: record)
            case .failure:
                return nil
            }
        }

        // Cache results
        cache.store(feeds, for: "featured_\(category.recordID.recordName)", ttl: 3600)

        return feeds
    }

    /// Search feeds by query string
    func searchFeeds(
        query: String,
        language: String = "en",
        limit: Int = 20
    ) async throws -> [PublicFeed] {
        // Search by title or tags
        let predicate = NSPredicate(
            format: "(title CONTAINS[cd] %@ OR ANY tags CONTAINS[cd] %@) AND language == %@",
            query, query, language
        )
        let ckQuery = CKQuery(recordType: PublicFeed.recordType, predicate: predicate)
        ckQuery.sortDescriptors = [
            NSSortDescriptor(key: "subscriberCount", ascending: false)
        ]

        let results = try await database.records(
            matching: ckQuery,
            resultsLimit: limit
        )

        return try results.matchResults.compactMap { (_, result) -> PublicFeed? in
            switch result {
            case .success(let record):
                return try? PublicFeed(from: record)
            case .failure:
                return nil
            }
        }
    }

    /// Fetch all categories
    func fetchCategories() async throws -> [FeedCategory] {
        // Check cache
        if let cached = cache.categories,
           !cache.isExpired(for: "categories") {
            return cached
        }

        let predicate = NSPredicate(value: true)  // Fetch all
        let query = CKQuery(recordType: FeedCategory.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true)
        ]

        let results = try await database.records(matching: query)

        let categories = try results.matchResults.compactMap { (_, result) -> FeedCategory? in
            switch result {
            case .success(let record):
                return try? FeedCategory(from: record)
            case .failure:
                return nil
            }
        }

        // Cache for 24 hours
        cache.storeCategories(categories, ttl: 86400)

        return categories
    }

    /// Fetch metadata for a feed
    func fetchMetadata(for feedID: CKRecord.ID) async throws -> FeedMetadata? {
        let reference = CKRecord.Reference(recordID: feedID, action: .none)
        let predicate = NSPredicate(format: "feedReference == %@", reference)
        let query = CKQuery(recordType: FeedMetadata.recordType, predicate: predicate)

        let results = try await database.records(matching: query, resultsLimit: 1)

        guard let first = results.matchResults.first else {
            return nil
        }

        switch first.value {
        case .success(let record):
            return try? FeedMetadata(from: record)
        case .failure:
            return nil
        }
    }

    /// Fetch featured collections
    func fetchFeaturedCollections(limit: Int = 10) async throws -> [FeedCollection] {
        let predicate = NSPredicate(format: "isFeatured == 1")
        let query = CKQuery(recordType: FeedCollection.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "subscriberCount", ascending: false)
        ]

        let results = try await database.records(
            matching: query,
            resultsLimit: limit
        )

        return try results.matchResults.compactMap { (_, result) -> FeedCollection? in
            switch result {
            case .success(let record):
                return try? FeedCollection(from: record)
            case .failure:
                return nil
            }
        }
    }

    /// Resolve feed references in a collection
    func resolveFeeds(in collection: FeedCollection) async throws -> [PublicFeed] {
        let recordIDs = collection.feeds.map { $0.recordID }

        // Batch fetch all referenced feeds
        let results = try await database.records(for: recordIDs)

        return try results.compactMap { (recordID, result) -> PublicFeed? in
            switch result {
            case .success(let record):
                return try? PublicFeed(from: record)
            case .failure:
                return nil
            }
        }
    }

    // MARK: - Article Operations

    /// Fetch recent articles for a feed
    func fetchArticles(
        for feedID: CKRecord.ID,
        limit: Int = 50,
        since: Date? = nil
    ) async throws -> [PublicArticle] {
        let reference = CKRecord.Reference(recordID: feedID, action: .none)

        let predicate: NSPredicate
        if let since = since {
            predicate = NSPredicate(
                format: "feedReference == %@ AND publishedDate > %@",
                reference, since as NSDate
            )
        } else {
            predicate = NSPredicate(
                format: "feedReference == %@",
                reference
            )
        }

        let query = CKQuery(recordType: PublicArticle.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "publishedDate", ascending: false)
        ]

        let results = try await database.records(
            matching: query,
            resultsLimit: limit
        )

        return try results.matchResults.compactMap { (_, result) -> PublicArticle? in
            switch result {
            case .success(let record):
                return try? PublicArticle(from: record)
            case .failure:
                return nil
            }
        }
    }

    /// Fetch articles for multiple feeds (user's subscriptions)
    func fetchArticles(
        for feedIDs: [CKRecord.ID],
        since: Date? = nil,
        limit: Int = 100
    ) async throws -> [PublicArticle] {
        let references = feedIDs.map { CKRecord.Reference(recordID: $0, action: .none) }

        let predicate: NSPredicate
        if let since = since {
            predicate = NSPredicate(
                format: "feedReference IN %@ AND publishedDate > %@",
                references, since as NSDate
            )
        } else {
            predicate = NSPredicate(
                format: "feedReference IN %@",
                references
            )
        }

        let query = CKQuery(recordType: PublicArticle.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "publishedDate", ascending: false)
        ]

        let results = try await database.records(
            matching: query,
            resultsLimit: limit
        )

        return try results.matchResults.compactMap { (_, result) -> PublicArticle? in
            switch result {
            case .success(let record):
                return try? PublicArticle(from: record)
            case .failure:
                return nil
            }
        }
    }

    /// Fetch a specific article by record ID
    func fetchArticle(byID recordID: CKRecord.ID) async throws -> PublicArticle? {
        let record = try await database.record(for: recordID)
        return try? PublicArticle(from: record)
    }

    /// Search articles by keyword
    func searchArticles(
        query: String,
        limit: Int = 20
    ) async throws -> [PublicArticle] {
        // Search in title and contentText
        let predicate = NSPredicate(
            format: "title CONTAINS[cd] %@ OR contentText CONTAINS[cd] %@",
            query, query
        )
        let ckQuery = CKQuery(recordType: PublicArticle.recordType, predicate: predicate)
        ckQuery.sortDescriptors = [
            NSSortDescriptor(key: "publishedDate", ascending: false)
        ]

        let results = try await database.records(
            matching: ckQuery,
            resultsLimit: limit
        )

        return try results.matchResults.compactMap { (_, result) -> PublicArticle? in
            switch result {
            case .success(let record):
                return try? PublicArticle(from: record)
            case .failure:
                return nil
            }
        }
    }
}
```

---

### Caching Layer

```swift
import Foundation
import CloudKit

/// Simple in-memory cache for public database queries
final class PublicFeedCache {
    private var storage: [String: CachedItem] = [:]
    private let queue = DispatchQueue(label: "com.celestra.publicfeedcache")

    struct CachedItem {
        let data: Any
        let expiresAt: Date
    }

    func store<T>(_ data: T, for key: String, ttl: TimeInterval) {
        queue.async {
            let expiresAt = Date().addingTimeInterval(ttl)
            self.storage[key] = CachedItem(data: data, expiresAt: expiresAt)
        }
    }

    func retrieve<T>(for key: String) -> T? {
        queue.sync {
            guard let item = storage[key],
                  item.expiresAt > Date() else {
                storage.removeValue(forKey: key)
                return nil
            }
            return item.data as? T
        }
    }

    func isExpired(for key: String) -> Bool {
        queue.sync {
            guard let item = storage[key] else { return true }
            return item.expiresAt <= Date()
        }
    }

    // Convenience accessors

    func featuredFeeds(for categoryID: String) -> [PublicFeed]? {
        retrieve(for: "featured_\(categoryID)")
    }

    var categories: [FeedCategory]? {
        retrieve(for: "categories")
    }

    func storeCategories(_ categories: [FeedCategory], ttl: TimeInterval) {
        store(categories, for: "categories", ttl: ttl)
    }

    func clear() {
        queue.async {
            self.storage.removeAll()
        }
    }
}
```

---

## Implementation Considerations

### 1. Rate Limiting & Quotas

**CloudKit Public Database Limits** (per user):
- **Requests**: 40 requests/second
- **Assets**: 200 MB/day download
- **Transfer**: 200 MB/day total

**Mitigation Strategies**:
- Aggressive caching (TTL: 1-24 hours for most queries)
- Batch operations where possible
- Conditional requests (use `CKFetchRecordZoneChangesOperation` with change tokens)
- Pagination for large result sets

### 2. Circuit Breaker Pattern

Implement circuit breaker for public DB operations to handle service degradation:

```swift
@MainActor
final class CircuitBreaker {
    enum State {
        case closed     // Normal operation
        case open       // Failures threshold exceeded, reject requests
        case halfOpen   // Testing if service recovered
    }

    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?

    private let failureThreshold = 5
    private let resetTimeout: TimeInterval = 60

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            if shouldAttemptReset() {
                state = .halfOpen
            } else {
                throw CircuitBreakerError.circuitOpen
            }

        case .halfOpen:
            break  // Allow one test request

        case .closed:
            break  // Normal operation
        }

        do {
            let result = try await operation()
            onSuccess()
            return result
        } catch {
            onFailure(error)
            throw error
        }
    }

    private func onSuccess() {
        failureCount = 0
        state = .closed
    }

    private func onFailure(_ error: Error) {
        failureCount += 1
        lastFailureTime = Date()

        if failureCount >= failureThreshold {
            state = .open
        }
    }

    private func shouldAttemptReset() -> Bool {
        guard let lastFailure = lastFailureTime else { return true }
        return Date().timeIntervalSince(lastFailure) >= resetTimeout
    }
}

enum CircuitBreakerError: Error {
    case circuitOpen
}
```

**Usage in PublicFeedService**:

```swift
private let circuitBreaker = CircuitBreaker()

func fetchFeaturedFeeds(...) async throws -> [PublicFeed] {
    try await circuitBreaker.execute {
        // CloudKit query logic here
    }
}
```

### 3. Privacy Considerations

**✅ DO**:
- Store feed URLs, metadata, and analytics in public DB
- Use anonymous aggregate metrics (subscriber counts)
- Cache aggressively to minimize requests

**❌ DON'T**:
- Store user subscription data in public DB
- Track individual user behavior
- Link user identities to feed subscriptions
- Store article read states publicly

### 4. Conflict Resolution

Public DB is primarily **read-only** for clients, so conflicts are minimal. For admin writes:

- Use `CKModifyRecordsOperation` with `.changedKeys` save policy
- Implement optimistic locking via `modificationDate` checks
- Server-side aggregation for subscriber counts (CloudKit Functions)

### 5. Offline Support

```swift
final class OfflinePublicFeedManager {
    private let service: PublicFeedService
    private let cache: PublicFeedCache

    func fetchFeaturedFeeds(
        category: CKRecord.Reference
    ) async -> Result<[PublicFeed], Error> {
        do {
            let feeds = try await service.fetchFeaturedFeeds(category: category)
            return .success(feeds)
        } catch {
            // Fallback to cache on network failure
            if let cached = cache.featuredFeeds(for: category.recordID.recordName) {
                return .success(cached)
            }
            return .failure(error)
        }
    }
}
```

### 6. Index Strategy

**Critical Indexes** (configure in CloudKit Dashboard):

**PublicFeed**:
- `QUERYABLE`: feedURL, category, isFeatured, language, tags
- `SORTABLE`: title, subscriberCount, qualityScore, addedAt

**FeedMetadata**:
- `QUERYABLE`: feedReference, healthStatus
- `SORTABLE`: uptimePercentage, averageRating

**FeedCategory**:
- `QUERYABLE`: slug, parentCategory
- `SORTABLE`: sortOrder, name

**FeedCollection**:
- `QUERYABLE`: isFeatured, tags
- `SORTABLE`: subscriberCount, createdAt

**PublicArticle**:
- `QUERYABLE`: feedReference, guid, url, contentHash, expiresAt, language, tags
- `SORTABLE`: publishedDate (descending), fetchedAt, expiresAt
- `COMPOUND`: feedReference + publishedDate (fetch feed articles), guid + feedReference (deduplication)

### 7. RSS Content Syndication

RSS/Atom feeds are provided by publishers for syndication purposes. Caching RSS content for improved app performance and offline reading is a common practice in RSS reader applications. Articles are attributed to their original sources and link back to the publisher's website.

---

### 8. CLI App Implementation (Server-Side Fetcher)

**Architecture Options**:

#### Option A: AWS Lambda (Recommended for simplicity)

**Pros**:
- Serverless (no server maintenance)
- Pay-per-execution (cost-effective for infrequent jobs)
- Auto-scaling (handles load automatically)
- Easy deployment with AWS SAM or Serverless Framework

**Implementation**:
```bash
# Project structure
rss-fetcher-cli/
├── Package.swift           # Swift dependencies (SyndiKit, CloudKit SDK)
├── Sources/
│   └── main.swift         # Fetch feeds → Upload to CloudKit
├── template.yaml          # AWS SAM template
└── scripts/
    └── deploy.sh          # Deployment script
```

**Deployment**:
1. Package Swift CLI as Lambda layer or zip
2. Create EventBridge rule (cron: `rate(15 minutes)`)
3. Lambda invokes CLI app every 15 minutes
4. CLI fetches all PublicFeed records → downloads RSS → uploads articles

**Costs** (estimate):
- Lambda: ~$0.01/month for 15-min intervals (2,880 invocations/month)
- CloudKit: Covered by iCloud storage (Public DB writes are free)

#### Option B: VPS/Server with Cron

**Pros**:
- Full control over execution environment
- No cold start delays (Lambda can have 1-2 sec delay)
- Easier debugging with logs

**Implementation**:
```bash
# Cron job on Linux server
*/15 * * * * /usr/local/bin/rss-fetcher >> /var/log/rss-fetcher.log 2>&1
```

**Costs** (estimate):
- VPS: $5-10/month (DigitalOcean, Linode)

**Recommendation**: Start with **AWS Lambda** for simplicity and cost-effectiveness. Can migrate to VPS later if needed.

---

### 9. Testing Strategy

**Unit Tests**:
- Mock CloudKit responses
- Test PublicFeed/PublicArticle model encoding/decoding
- Validate predicate construction
- Test deduplication logic (GUID, hash, URL)

**Integration Tests**:
- Use CloudKit Development environment
- Test query performance with realistic data volumes
- Verify cache expiration logic
- Test retention policy (article auto-deletion)

**Load Tests**:
- Simulate concurrent user queries
- Measure cache hit rates
- Monitor quota consumption
- Test with 100,000+ article records

---

## API Reference

### PublicFeedService Methods

#### Feed Operations

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `fetchFeaturedFeeds` | `category`, `limit` | `[PublicFeed]` | Fetch featured feeds in category |
| `searchFeeds` | `query`, `language`, `limit` | `[PublicFeed]` | Full-text search feeds |
| `fetchCategories` | - | `[FeedCategory]` | Fetch all categories |
| `fetchMetadata` | `feedID` | `FeedMetadata?` | Get metadata for feed |
| `fetchFeaturedCollections` | `limit` | `[FeedCollection]` | Fetch featured collections |
| `resolveFeeds` | `collection` | `[PublicFeed]` | Resolve references in collection |

#### Article Operations

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `fetchArticles(for:limit:since:)` | `feedID`, `limit`, `since` | `[PublicArticle]` | Fetch recent articles for a feed |
| `fetchArticles(for:since:limit:)` | `feedIDs`, `since`, `limit` | `[PublicArticle]` | Fetch articles for multiple feeds |
| `fetchArticle(byID:)` | `recordID` | `PublicArticle?` | Fetch a specific article |
| `searchArticles` | `query`, `limit` | `[PublicArticle]` | Search articles by keyword |

### Query Examples

#### Find Top Tech Feeds

```swift
let techCategory = CKRecord.Reference(
    recordID: CKRecord.ID(recordName: "technology"),
    action: .none
)

let feeds = try await service.fetchFeaturedFeeds(
    category: techCategory,
    limit: 20
)
```

#### Search by Tag

```swift
let query = "swift"
let results = try await service.searchFeeds(
    query: query,
    language: "en",
    limit: 10
)
```

#### Get Feed Health Status

```swift
let feedID = CKRecord.ID(recordName: "feed-uuid-123")
if let metadata = try await service.fetchMetadata(for: feedID) {
    print("Health: \(metadata.healthStatus)")
    print("Uptime: \(metadata.uptimePercentage)%")
}
```

#### Import Collection

```swift
let collections = try await service.fetchFeaturedCollections(limit: 5)

if let first = collections.first {
    let feeds = try await service.resolveFeeds(in: first)

    // Subscribe to each feed
    for feed in feeds {
        let parsedFeed = try await syndiKitParser.fetch(feed.feedURL)
        try await feedRepository.create(from: parsedFeed)
    }
}
```

#### Fetch Recent Articles for a Feed

```swift
let feedID = CKRecord.ID(recordName: "feed-uuid-123")

// Fetch latest 50 articles
let articles = try await service.fetchArticles(
    for: feedID,
    limit: 50
)

// Fetch articles since last sync
let lastSync = Date().addingTimeInterval(-24 * 60 * 60)  // 24h ago
let newArticles = try await service.fetchArticles(
    for: feedID,
    since: lastSync,
    limit: 100
)
```

#### Sync Articles for User's Subscriptions

```swift
// User has subscribed to multiple feeds
let userFeedIDs = userSubscriptions.map { $0.feedRecordID }

// Fetch latest articles from all subscribed feeds
let lastSync = UserDefaults.standard.object(forKey: "lastArticleSync") as? Date
    ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)  // Default: 7 days ago

let articles = try await service.fetchArticles(
    for: userFeedIDs,
    since: lastSync,
    limit: 200
)

// Save to Core Data for offline reading
for article in articles {
    try await articleRepository.saveFromPublicDB(article)
}

// Update last sync timestamp
UserDefaults.standard.set(Date(), forKey: "lastArticleSync")
```

#### Search Articles by Keyword

```swift
let query = "Swift 6 concurrency"
let results = try await service.searchArticles(
    query: query,
    limit: 20
)

// Display search results
for article in results {
    print("\(article.title) - \(article.publishedDate)")
    print(article.url)
}
```

---

## Migration Path

### Phase 1: Schema Setup (Development Environment)
1. Configure record types in CloudKit Dashboard:
   - `PublicFeed`
   - `FeedCategory`
   - `FeedMetadata`
   - `FeedCollection`
   - **`PublicArticle`** (NEW)
2. Create indexes as specified above (especially compound indexes for articles)
3. Set security roles:
   - World Readable (all record types)
   - Admin Write (`PublicFeed`, `FeedCategory`, `FeedCollection`)
   - **Authenticated Users + Server Write** (`PublicArticle`, `FeedMetadata`) ← Celestra app needs write permission for fallback uploads

### Phase 2: Seed Data
1. Import initial `FeedCategory` records (8 categories)
2. Curate 50-100 high-quality `PublicFeed` records
3. Generate `FeedMetadata` via server-side health checks
4. Create 3-5 editorial `FeedCollection` records
5. **Run initial RSS fetch to populate ~1,000 `PublicArticle` records**

### Phase 3: Server-Side Infrastructure (Optional but Recommended)
1. **Build CLI app** for RSS fetching:
   - Language: Swift (can share code with iOS app) or Node.js
   - Uses SyndiKit for parsing
   - Implements deduplication logic (contentHash, GUID, URL)
   - Uploads to Public CloudKit DB
2. **Deploy as cron job**:
   - **Option A**: AWS Lambda (serverless, pay-per-execution)
     - Use EventBridge (CloudWatch Events) for scheduling
     - Run every 15-30 minutes
   - **Option B**: VPS/Server with cron
     - Traditional cron job on Linux server
     - More control, but requires server maintenance
3. **Implement cleanup job**:
   - Delete expired articles (expiresAt < now) daily
   - Keep retention at 90 days max
4. Add proper attribution to original sources in uploaded articles

### Phase 4: App Integration (Client-Side)
1. Add MistKit dependency (`Package.swift`)
2. Implement `PublicFeedService` with caching
3. Build discovery UI (browse categories, search, collections)
4. **Implement article sync flow**:
   - Background fetch articles from public DB
   - Save to local Core Data for offline reading
   - Sync read states to private DB
5. Add article reading UI with offline support

### Phase 5: Monitoring & Optimization
1. CloudKit telemetry dashboard
2. Cache hit rate metrics
3. Query performance monitoring
4. Transfer bandwidth monitoring
5. Retention policy effectiveness (90-day cleanup)
6. Server-side fetch job health monitoring

---

## Conclusion

This architecture provides a **scalable, efficient, privacy-first approach** to RSS feed distribution using CloudKit's public database with shared article caching. Key design principles:

1. **Hybrid Article Ingestion**:
   - **Primary**: CLI app (cron job on AWS Lambda or VPS) fetches RSS and uploads to Public DB
   - **Fallback**: Celestra iOS app uploads articles if missing/stale (resilient, community-contributed)
2. **Shared Content Efficiency**: Articles pulled once from RSS (by server OR app), cached in public DB, accessed by all users
3. **Offline-First**: Public DB → Core Data sync enables full offline reading
4. **Privacy Protection**:
   - **Public DB** = article content (shared by everyone)
   - **Private DB** = user actions ONLY (read states, stars) - NO article content
   - **Core Data** = local offline cache
5. **Cost Optimization**: Reduces RSS server load, leverages CloudKit CDN
6. **RSS Syndication**: Standard practice for RSS readers with proper attribution
7. **MistKit Integration**: Type-safe Swift models with async/await (both server-side and client-side)

### Architecture Summary

```
                    PRIMARY                                 FALLBACK
RSS Feeds → CLI App (cron on Lambda/VPS)   OR   Celestra App (if missing/stale)
                    │                                    │
                    └──────────────┬─────────────────────┘
                                   ▼
                    Public CloudKit DB (article content - shared)
                                   ↓
                             User's Device
                                   ↓
                         Core Data (offline cache)
                                   ↓
                  Private CloudKit (user actions only: read states, stars)
```

**Key Points**:
- **Two upload paths**: CLI app cron job (primary) or Celestra app (fallback)
- **CLI app**: Simple command-line tool, runs every 15-30 min on Lambda or VPS
- **Private CloudKit stores ONLY user actions** (which articles read/starred), NOT article content
- **All users benefit** from articles uploaded by any source (CLI or other users)

**Benefits**:
- 📉 **Reduced Load**: RSS servers fetched once per article (not once per user)
- ⚡ **Fast Loading**: CloudKit CDN vs slow RSS servers
- 📴 **Offline Reading**: Full articles cached locally in Core Data
- 🔒 **Privacy**: User actions stay private, content is shared
- 💰 **Efficient**: Shared storage vs per-user duplication
- 🛡️ **Resilient**: Works even if server-side process is down (app fills gaps)

**Trade-offs**:
- 🔧 **Infrastructure**: Server-side process recommended (but app works without it via fallback)
- ⏱️ **Retention Policy**: Auto-delete after 90 days (can't archive everything)
- 🌐 **Dependency**: Users rely on public DB availability
- 📱 **Client Bandwidth**: Apps may fetch RSS directly if server hasn't updated feeds yet

---

**Document Status**: ✅ Ready for Implementation

**Critical Next Steps**:
1. Configure CloudKit schema in Dashboard (5 record types)
2. Configure write permissions: Allow authenticated users to write `PublicArticle` records
3. Add MistKit dependency to iOS app
4. Implement `PublicFeedService` with article sync
5. Implement client-side fallback: Celestra uploads articles if missing
6. Build article reading UI with offline support
7. Ensure proper attribution and links to original sources
8. **(Optional but recommended)** Build and deploy CLI app for RSS fetching:
   - Write simple Swift/Node.js CLI app
   - Deploy as cron job on AWS Lambda or VPS (every 15-30 min)
   - Improves efficiency and reduces client bandwidth usage

---

*For questions or clarifications, refer to:*
- *CloudKit documentation: https://developer.apple.com/icloud/cloudkit/*
- *MistKit GitHub: https://github.com/aaronpearce/MistKit*
- *RSS Best Practices: https://www.rssboard.org/rss-specification*
