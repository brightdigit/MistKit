import ArgumentParser

@main
internal struct BushelImagesCLI: AsyncParsableCommand {
    internal static let configuration = CommandConfiguration(
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
            StatusCommand.self,
            ListCommand.self,
            ExportCommand.self,
            ClearCommand.self
        ],
        defaultSubcommand: SyncCommand.self
    )
}
