import Foundation

/// Response from GitHub API for commits
struct GitHubCommitsResponse: Codable {
    let sha: String
    let commit: GitHubCommit
}
