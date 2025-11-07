import Foundation
import MistKit

/// Represents an RSS feed stored in CloudKit's public database
struct PublicFeed {
    let recordName: String?  // nil for new records
    let feedURL: String
    let title: String
    let description: String?
    let totalAttempts: Int64
    let successfulAttempts: Int64
    let usageCount: Int64
    let lastAttempted: Date?
    let isActive: Bool

    /// Convert to CloudKit record fields dictionary
    func toFieldsDict() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "feedURL": .string(feedURL),
            "title": .string(title),
            "totalAttempts": .int64(Int(totalAttempts)),
            "successfulAttempts": .int64(Int(successfulAttempts)),
            "usageCount": .int64(Int(usageCount)),
            "isActive": .int64(isActive ? 1 : 0)
        ]
        if let description = description {
            fields["description"] = .string(description)
        }
        if let lastAttempted = lastAttempted {
            fields["lastAttempted"] = .date(lastAttempted)
        }
        return fields
    }

    /// Create from CloudKit RecordInfo
    init(from record: RecordInfo) {
        self.recordName = record.recordName

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
    }

    /// Create new feed record
    init(
        recordName: String? = nil,
        feedURL: String,
        title: String,
        description: String? = nil,
        totalAttempts: Int64 = 0,
        successfulAttempts: Int64 = 0,
        usageCount: Int64 = 0,
        lastAttempted: Date? = nil,
        isActive: Bool = true
    ) {
        self.recordName = recordName
        self.feedURL = feedURL
        self.title = title
        self.description = description
        self.totalAttempts = totalAttempts
        self.successfulAttempts = successfulAttempts
        self.usageCount = usageCount
        self.lastAttempted = lastAttempted
        self.isActive = isActive
    }
}
