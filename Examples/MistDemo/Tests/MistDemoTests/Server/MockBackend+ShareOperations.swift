//
//  MockBackend+ShareOperations.swift
//  MistDemoTests
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#if canImport(Hummingbird)
  internal import MistKit

  @testable import MistDemoKit

  extension MockBackend {
    internal func webResolveShares(
      shortGUIDs: [String],
      fetchRootRecord: Bool?,
      fields: [String]?
    ) async throws -> [ShareRecordInfo] {
      lastResolveShares = ResolveOrAcceptSharesCall(
        shortGUIDs: shortGUIDs,
        fetchRootRecord: fetchRootRecord,
        fields: fields
      )
      try consumePendingError()
      return shortGUIDs.map { guid in
        ShareRecordInfo(
          shortGUID: ShortGUID(value: guid),
          rootRecordName: "stub-root-\(guid)",
          participantPermission: .readWrite,
          participantStatus: .accepted
        )
      }
    }

    internal func webAcceptShares(
      shortGUIDs: [String],
      fetchRootRecord: Bool?,
      fields: [String]?
    ) async throws -> [ShareRecordInfo] {
      lastAcceptShares = ResolveOrAcceptSharesCall(
        shortGUIDs: shortGUIDs,
        fetchRootRecord: fetchRootRecord,
        fields: fields
      )
      try consumePendingError()
      return shortGUIDs.map { guid in
        ShareRecordInfo(
          shortGUID: ShortGUID(value: guid),
          rootRecordName: "stub-root-\(guid)",
          participantPermission: .readWrite,
          participantStatus: .accepted
        )
      }
    }
  }
#endif
