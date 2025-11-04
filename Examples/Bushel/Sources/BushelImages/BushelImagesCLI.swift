import ArgumentParser

@main
struct BushelImagesCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bushel-images",
        abstract: "CloudKit version history tool for Bushel virtualization",
        discussion: """
        A command-line tool demonstrating MistKit's CloudKit Web Services capabilities.

        Manages macOS restore images, Xcode versions, and Swift compiler versions
        in CloudKit for use with Bushel's virtualization workflow.
        """,
        version: "1.0.0",
        subcommands: [
            SyncCommand.self,
            ExportCommand.self
        ],
        defaultSubcommand: SyncCommand.self
    )
}
