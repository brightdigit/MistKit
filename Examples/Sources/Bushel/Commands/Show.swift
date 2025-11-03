import ArgumentParser
import Foundation

// MARK: - Bushel.Show

extension Bushel {
  struct Show: AsyncParsableCommand {
    // MARK: Internal

    static let configuration = CommandConfiguration(
      abstract: "Show details for a specific version"
    )

    @Argument(help: "Version string to show (e.g., 1.2.3)")
    var version: String

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

      // Fetch the version
      guard let versionInfo = try await service.getVersion(version) else {
        print("Version \(version) not found.")
        throw ExitCode.failure
      }

      // Display detailed information
      print("Version: \(versionInfo.description)")
      print("Status: \(versionInfo.status.rawValue)")
      print("")

      // Version components
      print("Components:")
      print("  Major: \(versionInfo.major)")
      print("  Minor: \(versionInfo.minor)")
      print("  Patch: \(versionInfo.patch)")
      if let prerelease = versionInfo.prerelease {
        print("  Prerelease: \(prerelease)")
      }
      print("")

      // Release date
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .long
      dateFormatter.timeStyle = .short
      print("Released: \(dateFormatter.string(from: versionInfo.releaseDate))")
      print("")

      // Build information
      if let buildNumber = versionInfo.buildNumber {
        print("Build Number: \(buildNumber)")
      }
      if let commitHash = versionInfo.commitHash {
        print("Commit: \(commitHash)")
      }
      if versionInfo.buildNumber != nil || versionInfo.commitHash != nil {
        print("")
      }

      // Metadata
      if let metadata = versionInfo.metadata, !metadata.isEmpty {
        print("Metadata:")
        for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
          print("  \(key): \(value)")
        }
        print("")
      }

      // Release notes
      print("Release Notes:")
      print(versionInfo.releaseNotes)

      // Record ID
      if let recordID = versionInfo.recordID {
        print("")
        print("Record ID: \(recordID)")
      }
    }
  }
}
