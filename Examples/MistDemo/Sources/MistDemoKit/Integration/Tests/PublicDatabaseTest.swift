//
//  PublicDatabaseTest.swift
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

internal struct PublicDatabaseTest: PhasedIntegrationTest {
  internal let name = "Public Database"
  internal let database: MistKit.Database
  internal let phases: [any IntegrationPhase]

  /// - Parameters:
  ///   - database: must be `.public`. Defaults to `.public`.
  ///   - includeUserContextPhases: when `true`, appends user-identity phases
  ///     (`FetchCallerPhase`, `DiscoverUserIdentitiesPhase`, `users/lookup/*`).
  ///     Those phases need web-auth credentials, which the resolver picks per
  ///     call from the service's `Credentials`. The runner sets this based on
  ///     whether web-auth credentials are configured.
  internal init(
    database: MistKit.Database = .public(.prefers(.serverToServer)),
    includeUserContextPhases: Bool = false
  ) {
    if case .public = database {
    } else {
      preconditionFailure("PublicDatabaseTest only supports the public database")
    }
    self.database = database

    var phases: [any IntegrationPhase] = [
      LookupZonePhase(),
      UploadAssetPhase(),
      CreateRecordsPhase(),
      RereferenceAssetPhase(),
      QueryRecordsPhase(),
      LookupRecordsPhase(),
      ModifyRecordsPhase(),
      FinalVerificationPhase(),
      CleanupPhase(),
    ]
    if includeUserContextPhases {
      phases.append(FetchCallerPhase())
      phases.append(DiscoverUserIdentitiesPhase())
      phases.append(LookupUsersByEmailPhase())
      phases.append(LookupUsersByRecordNamePhase())
    }
    self.phases = phases
  }
}
