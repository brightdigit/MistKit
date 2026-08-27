//
//  OperationInputPath.swift
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

internal import Foundation
internal import MistKitOpenAPI

/// Shared shape of every generated `Operations.*.Input.Path` type.
///
/// All CloudKit Web Services endpoints share the same path template
/// (`/database/{version}/{container}/{environment}/{database}/...`),
/// so each generated `Input.Path` exposes the same memberwise initializer.
/// Conforming each one to this protocol unlocks a single MistKit-flavored
/// convenience init that takes the domain `Environment` and `Database`
/// directly.
internal protocol OperationInputPath {
  init(
    version: Components.Parameters.version,
    container: Components.Parameters.container,
    environment: Components.Parameters.environment,
    database: Components.Parameters.database
  )
}

extension OperationInputPath {
  /// Initialize from MistKit configuration components.
  internal init(
    containerIdentifier: String,
    environment: Environment,
    database: Database
  ) {
    self.init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }
}

extension Operations.discoverUserIdentities.Input.Path: OperationInputPath {}

extension Operations.fetchRecordChanges.Input.Path: OperationInputPath {}

extension Operations.fetchZoneChanges.Input.Path: OperationInputPath {}

extension Operations.getCaller.Input.Path: OperationInputPath {}

extension Operations.listZones.Input.Path: OperationInputPath {}

extension Operations.lookupRecords.Input.Path: OperationInputPath {}

extension Operations.lookupUsersByEmail.Input.Path: OperationInputPath {}

extension Operations.lookupUsersByRecordName.Input.Path: OperationInputPath {}

extension Operations.lookupZones.Input.Path: OperationInputPath {}

extension Operations.modifyZones.Input.Path: OperationInputPath {}

extension Operations.queryRecords.Input.Path: OperationInputPath {}

extension Operations.uploadAssets.Input.Path: OperationInputPath {}

extension Operations.rereferenceAssets.Input.Path: OperationInputPath {}

extension Operations.listSubscriptions.Input.Path: OperationInputPath {}

extension Operations.lookupSubscriptions.Input.Path: OperationInputPath {}

extension Operations.modifySubscriptions.Input.Path: OperationInputPath {}

extension Operations.resolveShortGUIDs.Input.Path: OperationInputPath {}

extension Operations.acceptShares.Input.Path: OperationInputPath {}
