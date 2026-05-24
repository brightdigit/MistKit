//
//  WebResponse.swift
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

internal import Foundation
internal import MistKit

/// Response payloads for the web command's CRUD endpoints.
internal enum WebResponse {
  /// Body returned by record-shaped routes (query / create / update).
  internal struct Records: Encodable {
    internal let records: [RecordInfo]
  }

  /// Body returned by `delete` (no record payload).
  internal struct Delete: Encodable {
    internal let recordName: String
    internal let deleted: Bool
  }

  /// Body returned by zone routes (`zones/modify`). `ZoneInfo` encodes to
  /// `{ zoneName, ownerRecordName, capabilities }`, which the browser's
  /// zone table reads directly.
  internal struct Zones: Encodable {
    internal let zones: [ZoneInfo]
  }

  /// Body returned by subscription routes (`list` / `lookup` / `modify`).
  /// `SubscriptionInfo` encodes to `{ subscriptionID, subscriptionType, query,
  /// zoneID, firesOn }`, matching the browser's subscription table and the
  /// CloudKit JS `{ subscriptions: [...] }` shape.
  internal struct Subscriptions: Encodable {
    internal let subscriptions: [SubscriptionInfo]
  }

  /// Body returned by `tokens/create`. Uses CloudKit's `webcAuthToken` wire
  /// name so the panel shows the canonical field.
  internal struct Token: Encodable {
    internal let apnsToken: String
    internal let webcAuthToken: String

    internal init(from result: APNsTokenResult) {
      self.apnsToken = result.apnsToken
      self.webcAuthToken = result.webAuthToken
    }
  }

  /// Body returned by `tokens/register` (no payload from CloudKit).
  internal struct TokenRegistration: Encodable {
    internal let registered: Bool
  }

  /// Body returned for any handled CloudKit/MistKit error so the UI can
  /// surface the message without parsing transport-level failures.
  internal struct Error: Encodable {
    internal let message: String
  }
}
