import Foundation
import MistKit

/// Represents an RSS article stored in CloudKit's public database
struct PublicArticle {
    let recordName: String?
    let feedRecordName: String
    let title: String
    let link: String
    let description: String?
    let author: String?
    let pubDate: Date?
    let guid: String
    let fetchedAt: Date
    let expiresAt: Date

    /// Convert to CloudKit record fields dictionary
    func toFieldsDict() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "feedRecordName": .string(feedRecordName),
            "title": .string(title),
            "link": .string(link),
            "guid": .string(guid),
            "fetchedAt": .date(fetchedAt),
            "expiresAt": .date(expiresAt)
        ]
        if let description = description {
            fields["description"] = .string(description)
        }
        if let author = author {
            fields["author"] = .string(author)
        }
        if let pubDate = pubDate {
            fields["pubDate"] = .date(pubDate)
        }
        return fields
    }

    /// Create from CloudKit RecordInfo
    init(from record: RecordInfo) {
        self.recordName = record.recordName

        // Extract required string values
        if case .string(let value) = record.fields["feedRecordName"] {
            self.feedRecordName = value
        } else {
            self.feedRecordName = ""
        }

        if case .string(let value) = record.fields["title"] {
            self.title = value
        } else {
            self.title = ""
        }

        if case .string(let value) = record.fields["link"] {
            self.link = value
        } else {
            self.link = ""
        }

        if case .string(let value) = record.fields["guid"] {
            self.guid = value
        } else {
            self.guid = ""
        }

        // Extract optional string values
        if case .string(let value) = record.fields["description"] {
            self.description = value
        } else {
            self.description = nil
        }

        if case .string(let value) = record.fields["author"] {
            self.author = value
        } else {
            self.author = nil
        }

        // Extract date values
        if case .date(let value) = record.fields["pubDate"] {
            self.pubDate = value
        } else {
            self.pubDate = nil
        }

        if case .date(let value) = record.fields["fetchedAt"] {
            self.fetchedAt = value
        } else {
            self.fetchedAt = Date()
        }

        if case .date(let value) = record.fields["expiresAt"] {
            self.expiresAt = value
        } else {
            self.expiresAt = Date()
        }
    }

    /// Create new article record
    init(
        recordName: String? = nil,
        feedRecordName: String,
        title: String,
        link: String,
        description: String? = nil,
        author: String? = nil,
        pubDate: Date? = nil,
        guid: String,
        ttlDays: Int = 30
    ) {
        self.recordName = recordName
        self.feedRecordName = feedRecordName
        self.title = title
        self.link = link
        self.description = description
        self.author = author
        self.pubDate = pubDate
        self.guid = guid
        self.fetchedAt = Date()
        self.expiresAt = Date().addingTimeInterval(TimeInterval(ttlDays * 24 * 60 * 60))
    }
}
