//
//  SubscriptionInfo+Codable.swift
//  MistKit
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

extension SubscriptionInfo: Codable {
  private enum CodingKeys: String, CodingKey {
    case subscriptionID
    case subscriptionType
    case query
    case zoneID
    case zoneWide
    case firesOn
    case firesOnce
    case notificationInfo
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.subscriptionID = try container.decode(String.self, forKey: .subscriptionID)
    self.notificationInfo =
      try container.decodeIfPresent(NotificationInfo.self, forKey: .notificationInfo)

    let type = try container.decode(SubscriptionType.self, forKey: .subscriptionType)
    switch type {
    case .query:
      self.kind = try Self.decodeQueryKind(from: container, codingPath: decoder.codingPath)
    case .zone:
      self.kind = try Self.decodeZoneOrDatabaseKind(from: container)
    }
  }

  private static func decodeQueryKind(
    from container: KeyedDecodingContainer<CodingKeys>,
    codingPath: [any CodingKey]
  ) throws -> Kind {
    let query = try container.decode(Query.self, forKey: .query)
    let firesOn =
      try container.decodeIfPresent(SubscriptionFireEvents.self, forKey: .firesOn) ?? []
    guard !firesOn.isEmpty else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: codingPath + [CodingKeys.firesOn],
          debugDescription:
            "Query subscription missing or empty firesOn — must declare "
            + "at least one of [create, update, delete]."
        )
      )
    }
    let firesOnce = try container.decodeIfPresent(Bool.self, forKey: .firesOnce)
    return .query(query, firesOn: firesOn, firesOnce: firesOnce)
  }

  // CloudKit collapses both "watch one zone" and "watch the whole
  // database" into `subscriptionType: zone`; `zoneWide: true` is the
  // database-subscription marker. Reading it as `.database` here
  // preserves the native CKSubscription trichotomy on the domain side.
  private static func decodeZoneOrDatabaseKind(
    from container: KeyedDecodingContainer<CodingKeys>
  ) throws -> Kind {
    let wide = try container.decodeIfPresent(Bool.self, forKey: .zoneWide) ?? false
    if wide {
      return .database
    }
    let zoneID = try container.decode(ZoneID.self, forKey: .zoneID)
    return .zone(zoneID)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(subscriptionID, forKey: .subscriptionID)
    try container.encode(subscriptionType, forKey: .subscriptionType)
    try container.encodeIfPresent(notificationInfo, forKey: .notificationInfo)
    switch kind {
    case .query(let query, let firesOn, let firesOnce):
      try container.encode(query, forKey: .query)
      try container.encode(firesOn, forKey: .firesOn)
      try container.encodeIfPresent(firesOnce, forKey: .firesOnce)
    case .zone(let zoneID):
      try container.encode(zoneID, forKey: .zoneID)
    case .database:
      try container.encode(true, forKey: .zoneWide)
    }
  }
}
