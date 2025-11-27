import ArgumentParser
import Foundation
import MistKit

struct ClearCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Delete all feeds and articles from CloudKit",
        discussion: """
            Removes all Feed and Article records from the CloudKit public database. \
            Use with caution as this operation cannot be undone.
            """
    )

    @Flag(name: .long, help: "Skip confirmation prompt")
    var confirm: Bool = false

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    func run() async throws {
        // Require confirmation
        if !confirm {
            print("⚠️  This will DELETE ALL feeds and articles from CloudKit!")
            print("   Run with --confirm to proceed")
            print("")
            print("   Example: celestra clear --confirm")
            return
        }

        print("🗑️  Clearing all data from CloudKit...")

        let service = try CelestraConfig.createCloudKitService()

        // Delete articles first (to avoid orphans)
        print("📋 Deleting articles...")
        try await service.deleteAllArticles()
        print("✅ Articles deleted")

        // Delete feeds
        print("📋 Deleting feeds...")
        try await service.deleteAllFeeds()
        print("✅ Feeds deleted")

        print("\n✅ All data cleared!")
    }
}
