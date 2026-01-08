import Foundation

/// Represents a committer in GitHub API response
struct GitHubCommitter: Codable {
    let date: String // ISO 8601 format
}
