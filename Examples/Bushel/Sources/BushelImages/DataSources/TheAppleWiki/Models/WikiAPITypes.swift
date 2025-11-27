import Foundation

// MARK: - TheAppleWiki API Response Types

/// Root response from TheAppleWiki parse API
struct ParseResponse: Codable, Sendable {
    let parse: ParseContent
}

/// Parse content container
struct ParseContent: Codable, Sendable {
    let title: String
    let text: TextContent
}

/// Text content with HTML
struct TextContent: Codable, Sendable {
    let content: String

    enum CodingKeys: String, CodingKey {
        case content = "*"
    }
}
