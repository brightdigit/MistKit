//
//  BushelConfiguration.swift
//  BushelCloud
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

public import BushelFoundation
import Foundation
import MistKit

// MARK: - Configuration Error

/// Errors that can occur during configuration validation
public struct ConfigurationError: Error, Sendable {
  public let message: String
  public let key: String?

  public init(_ message: String, key: String? = nil) {
    self.message = message
    self.key = key
  }
}

// MARK: - Root Configuration

/// Root configuration containing all subsystem configurations
public struct BushelConfiguration: Sendable {
  public var cloudKit: CloudKitConfiguration?
  public var virtualBuddy: VirtualBuddyConfiguration?
  public var fetch: FetchConfiguration?
  public var sync: SyncConfiguration?
  public var export: ExportConfiguration?
  public var status: StatusConfiguration?
  public var list: ListConfiguration?
  public var clear: ClearConfiguration?

  public init(
    cloudKit: CloudKitConfiguration? = nil,
    virtualBuddy: VirtualBuddyConfiguration? = nil,
    fetch: FetchConfiguration? = nil,
    sync: SyncConfiguration? = nil,
    export: ExportConfiguration? = nil,
    status: StatusConfiguration? = nil,
    list: ListConfiguration? = nil,
    clear: ClearConfiguration? = nil
  ) {
    self.cloudKit = cloudKit
    self.virtualBuddy = virtualBuddy
    self.fetch = fetch
    self.sync = sync
    self.export = export
    self.status = status
    self.list = list
    self.clear = clear
  }

  /// Validate that all required fields are present
  public func validated() throws -> ValidatedBushelConfiguration {
    guard let cloudKit = cloudKit else {
      throw ConfigurationError("CloudKit configuration required", key: "cloudkit")
    }
    return ValidatedBushelConfiguration(
      cloudKit: try cloudKit.validated(),
      virtualBuddy: virtualBuddy,
      fetch: fetch,
      sync: sync,
      export: export,
      status: status,
      list: list,
      clear: clear
    )
  }
}

// MARK: - Validated Root Configuration

/// Validated configuration with non-optional required fields
public struct ValidatedBushelConfiguration: Sendable {
  public let cloudKit: ValidatedCloudKitConfiguration
  public let virtualBuddy: VirtualBuddyConfiguration?
  public let fetch: FetchConfiguration?
  public let sync: SyncConfiguration?
  public let export: ExportConfiguration?
  public let status: StatusConfiguration?
  public let list: ListConfiguration?
  public let clear: ClearConfiguration?

  public init(
    cloudKit: ValidatedCloudKitConfiguration,
    virtualBuddy: VirtualBuddyConfiguration?,
    fetch: FetchConfiguration?,
    sync: SyncConfiguration?,
    export: ExportConfiguration?,
    status: StatusConfiguration?,
    list: ListConfiguration?,
    clear: ClearConfiguration?
  ) {
    self.cloudKit = cloudKit
    self.virtualBuddy = virtualBuddy
    self.fetch = fetch
    self.sync = sync
    self.export = export
    self.status = status
    self.list = list
    self.clear = clear
  }
}
