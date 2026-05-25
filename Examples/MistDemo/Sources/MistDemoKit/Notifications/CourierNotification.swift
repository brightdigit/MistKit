//
//  CourierNotification.swift
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

/// A CloudKit notification decoded from a web-courier frame.
///
/// Mirrors the documented `CloudKit.QueryNotification` (cloudkitjs.md), mapped
/// from the verified courier wire payload (#379):
///
/// ```jsonc
/// { "aps": { "alert": "…" },
///   "ck":  { "nid": "…", "cid": "…",
///            "qry": { "sid": "…", "rid": "…", "fo": 1, "zid": "…", "dbs": 1 } } }
/// ```
///
/// Only query-notification fields are mapped today (the demo creates query
/// subscriptions). Zone notifications would surface a sibling `ck` block; add
/// them here when needed.
internal struct CourierNotification: Sendable {
  /// The event that fired the subscription — the `ck.qry.fo` code.
  internal enum Reason: Int, Sendable {
    case recordCreated = 1
    case recordUpdated = 2
    case recordDeleted = 3
  }

  /// `ck.nid` — unique id for this notification.
  internal let notificationID: String?
  /// `ck.cid` — the container that generated the notification.
  internal let containerIdentifier: String?
  /// `ck.qry.sid` — the subscription that fired.
  internal let subscriptionID: String?
  /// `ck.qry.rid` — the record that changed.
  internal let recordName: String?
  /// `ck.qry.zid` — the zone the record lives in.
  internal let zoneID: String?
  /// `ck.qry.fo` — why the subscription fired.
  internal let reason: Reason?
  /// `ck.qry.dbs` — database-scope code (kept raw; interpretation unconfirmed).
  internal let databaseScope: Int?
  /// `aps.alert` — the alert text, when present.
  internal let alertBody: String?

  /// Decode a notification from a raw courier frame body.
  internal init(data: Data) throws {
    let wire = try JSONDecoder().decode(Wire.self, from: data)
    let cloudKit = wire.cloudKit
    let query = cloudKit?.qry
    self.notificationID = cloudKit?.nid
    self.containerIdentifier = cloudKit?.cid
    self.subscriptionID = query?.sid
    self.recordName = query?.rid
    self.zoneID = query?.zid
    self.reason = query?.firesOn.flatMap(Reason.init(rawValue:))
    self.databaseScope = query?.dbs
    self.alertBody = wire.aps?.alert?.body
  }
}

extension CourierNotification {
  /// The on-the-wire courier payload shape; mapped into the flat
  /// ``CourierNotification`` by ``init(data:)``.
  private struct Wire: Decodable {
    fileprivate struct APS: Decodable {
      fileprivate let alert: Alert?
    }

    /// APNs `alert` is either a bare string or an object with a `body` key.
    fileprivate enum Alert: Decodable {
      case text(String)
      case structured(body: String?)

      private enum CodingKeys: String, CodingKey {
        case body
      }

      fileprivate var body: String? {
        switch self {
        case .text(let value): return value
        case .structured(let body): return body
        }
      }

      fileprivate init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
          self = .text(value)
          return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = .structured(body: try container.decodeIfPresent(String.self, forKey: .body))
      }
    }

    fileprivate struct CloudKitPayload: Decodable {
      fileprivate struct Qry: Decodable {
        private enum CodingKeys: String, CodingKey {
          case sid
          case rid
          case zid
          case dbs
          case firesOn = "fo"
        }

        fileprivate let sid: String?
        fileprivate let rid: String?
        fileprivate let zid: String?
        fileprivate let firesOn: Int?
        fileprivate let dbs: Int?
      }

      fileprivate let nid: String?
      fileprivate let cid: String?
      fileprivate let qry: Qry?
    }

    private enum CodingKeys: String, CodingKey {
      case aps
      case cloudKit = "ck"
    }

    fileprivate let aps: APS?
    fileprivate let cloudKit: CloudKitPayload?
  }
}
