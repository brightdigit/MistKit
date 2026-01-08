import Foundation

/// Represents a commit in GitHub API response
struct GitHubCommit: Codable {
    let committer: GitHubCommitter
    let message: String
}
