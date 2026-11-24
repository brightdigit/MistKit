internal import MistKit
internal import Testing

@Suite("CKDBHighlighter")
/// Tests `CKDBHighlighter` line tokens.
internal struct CKDBHighlighterTests {
  @Test("types, keywords and comments are told apart; names and spacing are kept")
  internal func tokens() {
    let tokens = CKDBHighlighter.tokens(
      in: "        rating           INT64 QUERYABLE SORTABLE,"
    )
    #expect(
      tokens.map(\.text).joined() == "        rating           INT64 QUERYABLE SORTABLE,"
    )
    #expect(tokens.first { $0.text == "rating" }?.kind == .plain)
    #expect(tokens.first { $0.text == "INT64" }?.kind == .type)
    #expect(tokens.first { $0.text == "QUERYABLE" }?.kind == .keyword)
  }

  @Test("lists, grants and quoted names")
  internal func grants() {
    let list = CKDBHighlighter.tokens(in: "players LIST<REFERENCE> QUERYABLE")
    #expect(list.first { $0.text == "LIST" }?.kind == .type)
    #expect(list.first { $0.text == "REFERENCE" }?.kind == .type)
    let grant = CKDBHighlighter.tokens(in: "GRANT READ, WRITE TO \"_creator\"")
    #expect(
      grant.filter { $0.kind == .keyword }.map(\.text) == [
        "GRANT", "READ", "WRITE", "TO",
      ]
    )
    #expect(grant.last?.text == "\"_creator\"")
    #expect(grant.last?.kind == .plain)
  }

  @Test("a comment line is all comment")
  internal func comment() {
    let tokens = CKDBHighlighter.tokens(in: "// Exported live at 7:28 PM")
    #expect(tokens.map(\.kind) == [.comment])
  }
}
