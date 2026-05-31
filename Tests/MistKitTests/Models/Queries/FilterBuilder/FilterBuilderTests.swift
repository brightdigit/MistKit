internal import Testing

@Suite("Filter Builder", .enabled(if: Platform.isCryptoAvailable))
internal enum FilterBuilderTests {}
