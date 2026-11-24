internal import MistKit
internal import Testing

@Suite("Query field names")
/// Tests `QueryFieldName` and `QueryDescriptor.Comparator(_:nearMeters:)`.
internal struct QueryFieldNameTests {
  @Test("the record ID field shows as recordName; other fields as themselves")
  internal func title() {
    #expect(QueryFieldName.title(for: QueryDescriptor.recordIDFieldName) == "recordName")
    #expect(QueryFieldName.title(for: "rating") == "rating")
  }

  @Test("near takes the given distance; others map directly")
  internal func comparator() {
    #expect(QueryDescriptor.Comparator(.near, nearMeters: 50) == .near(meters: 50))
    #expect(QueryDescriptor.Comparator(.beginsWith, nearMeters: 50) == .beginsWith)
  }
}
