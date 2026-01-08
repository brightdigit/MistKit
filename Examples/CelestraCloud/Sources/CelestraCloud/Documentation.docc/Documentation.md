# ``Celestra``

CelestraCloud - A command-line RSS reader with CloudKit sync demonstrating MistKit integration.

## Overview

CelestraCloud is a production-ready command-line RSS reader that showcases MistKit's CloudKit Web Services integration capabilities. It manages RSS feeds in CloudKit's public database while implementing comprehensive web etiquette best practices including rate limiting, robots.txt compliance, and conditional HTTP requests.

### Key Features

- **RSS Feed Management** - Parse and store RSS feeds using SyndiKit
- **CloudKit Integration** - Demonstrate MistKit's query filtering and sorting APIs
- **Web Etiquette** - Respectful crawling with rate limiting and robots.txt compliance
- **Batch Operations** - Efficient article uploads with chunking and duplicate detection
- **Server-to-Server Auth** - CloudKit authentication for backend services

## Topics

### Commands

- ``AddFeedCommand``
- ``UpdateCommand``
- ``ClearCommand``

### Local Services

- ``RSSFetcherService``
- ``CelestraLogger``

### External Services (from CelestraKit)

CelestraCloud uses `RateLimiter` and `RobotsTxtService` from the CelestraKit package for web etiquette features.

### Models

- ``BatchOperationResult``

### Configuration

- ``CelestraConfig``
- ``CelestraError``

## Getting Started

### Prerequisites

1. **Apple Developer Account** with CloudKit access
2. **CloudKit Container** configured in Apple Developer Console
3. **Server-to-Server Key** generated for CloudKit access
4. **Swift 6.2+** and **macOS 26+**

### Installation

```bash
git clone https://github.com/brightdigit/CelestraCloud.git
cd CelestraCloud
make install
make build
```

### Configuration

Create a `.env` file with your CloudKit credentials:

```bash
CLOUDKIT_CONTAINER_ID=iCloud.com.brightdigit.Celestra
CLOUDKIT_KEY_ID=your-key-id-here
CLOUDKIT_PRIVATE_KEY_PATH=/path/to/eckey.pem
CLOUDKIT_ENVIRONMENT=development
```

### Usage

```bash
# Source environment variables
source .env

# Add a feed
swift run celestra-cloud add-feed https://example.com/feed.xml

# Update feeds with filters
swift run celestra-cloud update --min-popularity 10

# Clear all data
swift run celestra-cloud clear --confirm
```

## Architecture

CelestraCloud demonstrates several key MistKit patterns:

### Query Filtering

Uses MistKit's `QueryFilter` API for flexible CloudKit queries:

```swift
var filters: [QueryFilter] = []
filters.append(.lessThan("attemptedTimestamp", .date(cutoffDate)))
filters.append(.greaterThanOrEquals("subscriberCount", .int64(minPopularity)))
```

### Field Mapping

Direct field mapping pattern for CloudKit record conversion:

```swift
func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
        "title": .string(title),
        "isActive": .int64(isActive ? 1 : 0)
    ]
    return fields
}
```

### Batch Operations

Efficient article uploads with chunking:

```swift
let batches = articles.chunked(into: 10)
for batch in batches {
    let result = try await createArticles(batch)
    overallResult.append(result)
}
```

## Web Etiquette

CelestraCloud implements comprehensive web etiquette best practices including rate limiting (configurable delays, default 2s per domain), robots.txt compliance (respects robots.txt rules for all feeds), conditional requests (uses If-Modified-Since/ETag headers), failure tracking (exponential backoff for failed feeds), and TTL respect (honors feed update intervals).

## See Also

- [CelestraCloud Repository](https://github.com/brightdigit/CelestraCloud)
- [MistKit Documentation](https://github.com/brightdigit/MistKit)
- [SyndiKit Documentation](https://github.com/brightdigit/SyndiKit)
