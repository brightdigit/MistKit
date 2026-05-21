//
//  CloudKitStore+Users.swift
//  MistDemo
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

#if canImport(CloudKit)
  internal import CloudKit
  internal import Foundation
  internal import MistDemoKit

  /// Display-friendly snapshot of a CKUserIdentity.
  internal struct UserIdentityRow: Identifiable, Hashable, Sendable {
    internal let id: String
    internal let displayName: String?
    internal let recordName: String?
    internal let lookupHint: String?

    internal init(_ identity: CKUserIdentity, lookupHint: String? = nil) {
      let recordName = identity.userRecordID?.recordName
      self.id =
        recordName
        ?? identity.lookupInfo?.emailAddress
        ?? identity.lookupInfo?.phoneNumber
        ?? lookupHint
        ?? UUID().uuidString
      self.recordName = recordName
      self.displayName = Self.formatName(identity.nameComponents)
      self.lookupHint = lookupHint
    }

    private static func formatName(
      _ components: PersonNameComponents?
    ) -> String? {
      guard let components else {
        return nil
      }
      let formatter = PersonNameComponentsFormatter()
      let formatted = formatter.string(from: components)
      return formatted.isEmpty ? nil : formatted
    }
  }

  extension CloudKitStore {
    /// Look up a user identity by iCloud email address. Maps to
    /// `users/lookup/email` in the REST surface; uses CloudKit's
    /// `discoverUserIdentity(withEmailAddress:)`.
    ///
    /// `discoverUserIdentity(withEmailAddress:)` is deprecated as of macOS
    /// 14 / iOS 17 but still ships on the supported platforms — the
    /// CloudKit framework hasn't published an async replacement, so the
    /// completion-handler form is wrapped via `withCheckedThrowingContinuation`.
    internal func lookupUser(byEmail email: String) async throws -> UserIdentityRow? {
      let container = CKContainer(identifier: containerIdentifier)
      let identity: CKUserIdentity? = try await withCheckedThrowingContinuation {
        continuation in
        container.discoverUserIdentity(withEmailAddress: email) {
          identity, error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: identity)
          }
        }
      }
      return identity.map { UserIdentityRow($0, lookupHint: email) }
    }

    /// Look up a user identity by record name. Maps to `users/lookup/id`.
    internal func lookupUser(byRecordName recordName: String) async throws -> UserIdentityRow? {
      let container = CKContainer(identifier: containerIdentifier)
      let recordID = CKRecord.ID(recordName: recordName)
      let identity: CKUserIdentity? = try await withCheckedThrowingContinuation {
        continuation in
        container.discoverUserIdentity(withUserRecordID: recordID) {
          identity, error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: identity)
          }
        }
      }
      return identity.map { UserIdentityRow($0, lookupHint: recordName) }
    }

    /// Discover identities for a batch of email addresses, looping the
    /// per-call API since the framework doesn't expose a batch entry point.
    /// Maps to `users/discover` (POST) in the REST surface.
    internal func discoverUsers(byEmails emails: [String]) async throws -> [UserIdentityRow] {
      var rows: [UserIdentityRow] = []
      for email in emails {
        if let row = try await lookupUser(byEmail: email) {
          rows.append(row)
        }
      }
      return rows
    }
  }
#endif
