import ArgumentParser
import Foundation

// MARK: - Bushel.List

extension Bushel {
  struct List: AsyncParsableCommand {
    // MARK: Internal

    static let configuration = CommandConfiguration(
      abstract: "List all versions from CloudKit"
    )

    @Option(name: .long, help: "Filter by status (draft, released, deprecated)")
    var status: String?

    @Flag(name: .long, help: "Include prerelease versions")
    var includePrerelease = false

    @Option(name: .long, help: "Configuration file path")
    var config: String?

    func run() async throws {
      // Load configuration
      let configuration = if let configPath = config {
        try BushelConfiguration.fromFile(at: configPath)
      } else {
        try BushelConfiguration.fromEnvironment()
      }

      // Create service
      let service = try VersionService(configuration: configuration)

      // Parse status filter
      var statusFilter: Version.ReleaseStatus?
      if let statusString = status {
        guard let parsedStatus = Version.ReleaseStatus(rawValue: statusString) else {
          throw ValidationError("Invalid status: \(statusString). Must be one of: draft, released, deprecated")
        }
        statusFilter = parsedStatus
      }

      // Fetch versions
      let versions = try await service.listVersions(
        status: statusFilter,
        includePrerelease: includePrerelease,
        limit: 100
      )

      // Display results
      if versions.isEmpty {
        print("No versions found.")
        return
      }

      print("Found \(versions.count) version(s):\n")

      for version in versions {
        var line = "  \(version.description)"
        line += " [\(version.status.rawValue)]"

        if let buildNumber = version.buildNumber {
          line += " (build \(buildNumber))"
        }

        print(line)

        // Show release date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        print("    Released: \(dateFormatter.string(from: version.releaseDate))")

        // Show first line of release notes
        if let firstLine = version.releaseNotes.split(separator: "\n").first {
          let preview = String(firstLine.prefix(60))
          print("    \(preview)\(firstLine.count > 60 ? "..." : "")")
        }

        print("")
      }
    }
  }
}
