import Foundation
import MistKit

/// Represents an RSS feed stored in CloudKit's public database
struct Feed {
    let recordName: String?  // nil for new records
    let recordChangeTag: String?  // CloudKit change tag for optimistic locking
    let feedURL: String
    let title: String
    let description: String?
    let totalAttempts: Int64
    let successfulAttempts: Int64
    let usageCount: Int64
    let lastAttempted: Date?
    let isActive: Bool

    // Web etiquette fields
    let lastModified: String?  // HTTP Last-Modified header for conditional requests
    let etag: String?  // ETag header for conditional requests
    let failureCount: Int64  // Consecutive failure count
    let lastFailureReason: String?  // Last error message
    let minUpdateInterval: TimeInterval?  // Minimum seconds between updates (from RSS <ttl> or <updatePeriod>)

    /// Convert to CloudKit record fields dictionary
    func toFieldsDict() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "feedURL": .string(feedURL),
            "title": .string(title),
            "totalAttempts": .int64(Int(totalAttempts)),
            "successfulAttempts": .int64(Int(successfulAttempts)),
            "usageCount": .int64(Int(usageCount)),
            "isActive": .int64(isActive ? 1 : 0),
            "failureCount": .int64(Int(failureCount))
        ]
        if let description = description {
            fields["description"] = .string(description)
        }
        if let lastAttempted = lastAttempted {
            fields["lastAttempted"] = .date(lastAttempted)
        }
        if let lastModified = lastModified {
            fields["lastModified"] = .string(lastModified)
        }
        if let etag = etag {
            fields["etag"] = .string(etag)
        }
        if let lastFailureReason = lastFailureReason {
            fields["lastFailureReason"] = .string(lastFailureReason)
        }
        if let minUpdateInterval = minUpdateInterval {
            fields["minUpdateInterval"] = .double(minUpdateInterval)
        }
        return fields
    }

    /// Create from CloudKit RecordInfo
    init(from record: RecordInfo) {
        self.recordName = record.recordName
        self.recordChangeTag = record.recordChangeTag

        // Extract string values
        if case .string(let value) = record.fields["feedURL"] {
            self.feedURL = value
        } else {
            self.feedURL = ""
        }

        if case .string(let value) = record.fields["title"] {
            self.title = value
        } else {
            self.title = ""
        }

        if case .string(let value) = record.fields["description"] {
            self.description = value
        } else {
            self.description = nil
        }

        // Extract Int64 values
        if case .int64(let value) = record.fields["totalAttempts"] {
            self.totalAttempts = Int64(value)
        } else {
            self.totalAttempts = 0
        }

        if case .int64(let value) = record.fields["successfulAttempts"] {
            self.successfulAttempts = Int64(value)
        } else {
            self.successfulAttempts = 0
        }

        if case .int64(let value) = record.fields["usageCount"] {
            self.usageCount = Int64(value)
        } else {
            self.usageCount = 0
        }

        // Extract boolean as Int64
        if case .int64(let value) = record.fields["isActive"] {
            self.isActive = value != 0
        } else {
            self.isActive = true  // Default to active
        }

        // Extract date value
        if case .date(let value) = record.fields["lastAttempted"] {
            self.lastAttempted = value
        } else {
            self.lastAttempted = nil
        }

        // Extract web etiquette fields
        if case .string(let value) = record.fields["lastModified"] {
            self.lastModified = value
        } else {
            self.lastModified = nil
        }

        if case .string(let value) = record.fields["etag"] {
            self.etag = value
        } else {
            self.etag = nil
        }

        if case .int64(let value) = record.fields["failureCount"] {
            self.failureCount = Int64(value)
        } else {
            self.failureCount = 0
        }

        if case .string(let value) = record.fields["lastFailureReason"] {
            self.lastFailureReason = value
        } else {
            self.lastFailureReason = nil
        }

        if case .double(let value) = record.fields["minUpdateInterval"] {
            self.minUpdateInterval = value
        } else {
            self.minUpdateInterval = nil
        }
    }

    /// Create new feed record
    init(
        recordName: String? = nil,
        recordChangeTag: String? = nil,
        feedURL: String,
        title: String,
        description: String? = nil,
        totalAttempts: Int64 = 0,
        successfulAttempts: Int64 = 0,
        usageCount: Int64 = 0,
        lastAttempted: Date? = nil,
        isActive: Bool = true,
        lastModified: String? = nil,
        etag: String? = nil,
        failureCount: Int64 = 0,
        lastFailureReason: String? = nil,
        minUpdateInterval: TimeInterval? = nil
    ) {
        self.recordName = recordName
        self.recordChangeTag = recordChangeTag
        self.feedURL = feedURL
        self.title = title
        self.description = description
        self.totalAttempts = totalAttempts
        self.successfulAttempts = successfulAttempts
        self.usageCount = usageCount
        self.lastAttempted = lastAttempted
        self.isActive = isActive
        self.lastModified = lastModified
        self.etag = etag
        self.failureCount = failureCount
        self.lastFailureReason = lastFailureReason
        self.minUpdateInterval = minUpdateInterval
    }
}
