//
//  WebRequests+Tokens.swift
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

extension WebRequests {
  /// `POST /api/tokens` — mint a CloudKit-managed APNs token.
  ///
  /// `apnsEnvironment` defaults to `development`; an unrecognized value falls
  /// back to `development` rather than failing the demo request.
  internal struct CreateToken: Decodable {
    private enum CodingKeys: String, CodingKey {
      case apnsEnvironment
      case database
    }

    internal let environment: APNsEnvironment
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let raw =
        try container.decodeIfPresent(String.self, forKey: .apnsEnvironment)
        ?? "development"
      self.environment = APNsEnvironment(rawValue: raw) ?? .development
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/tokens/register` — register a device APNs token.
  internal struct RegisterToken: Decodable {
    private enum CodingKeys: String, CodingKey {
      case apnsToken
      case database
    }

    internal let apnsToken: String
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.apnsToken =
        try container.decodeIfPresent(String.self, forKey: .apnsToken) ?? ""
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }
}
