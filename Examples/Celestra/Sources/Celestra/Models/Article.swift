import Foundation
import MistKit
import CryptoKit

/// Represents an RSS article stored in CloudKit's public database
struct Article {
    let recordName: String?
    let feed: String  // Feed record name (stored as REFERENCE in CloudKit)
    let title: String
    let link: String
    let description: String?
    let content: String?
    let author: String?
    let pubDate: Date?
    let guid: String
    let fetchedAt: Date
    let expiresAt: Date

    /// Computed content hash for duplicate detection fallback
    var contentHash: String {
        let content = "\(title)|\(link)|\(guid)"
        let data = Data(content.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Convert to CloudKit record fields dictionary
    func toFieldsDict() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "feed": .reference(FieldValue.Reference(recordName: feed)),
            "title": .string(title),
            "link": .string(link),
            "guid": .string(guid),
            "contentHash": .string(contentHash),
            "fetchedAt": .date(fetchedAt),
            "expiresAt": .date(expiresAt)
        ]
        if let description = description {
            fields["description"] = .string(description)
        }
        if let content = content {
            fields["content"] = .string(content)
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

        // Extract feed reference
        if case .reference(let ref) = record.fields["feed"] {
            self.feed = ref.recordName
        } else {
            self.feed = ""
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

        if case .string(let value) = record.fields["content"] {
            self.content = value
        } else {
            self.content = nil
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
        feed: String,
        title: String,
        link: String,
        description: String? = nil,
        content: String? = nil,
        author: String? = nil,
        pubDate: Date? = nil,
        guid: String,
        ttlDays: Int = 30
    ) {
        self.recordName = recordName
        self.feed = feed
        self.title = title
        self.link = link
        self.description = description
        self.content = content
        self.author = author
        self.pubDate = pubDate
        self.guid = guid
        self.fetchedAt = Date()
        self.expiresAt = Date().addingTimeInterval(TimeInterval(ttlDays * 24 * 60 * 60))
    }

    /// Create a copy of this article with a specific recordName
    /// - Parameter recordName: The CloudKit record name to set
    /// - Returns: New Article instance with the recordName set
    func withRecordName(_ recordName: String) -> Article {
        Article(
            recordName: recordName,
            feed: self.feed,
            title: self.title,
            link: self.link,
            description: self.description,
            content: self.content,
            author: self.author,
            pubDate: self.pubDate,
            guid: self.guid,
            ttlDays: 30  // Use default TTL since we can't calculate from existing dates
        )
    }
}
