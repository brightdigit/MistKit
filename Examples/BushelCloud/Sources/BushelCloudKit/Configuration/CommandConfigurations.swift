//
//  CommandConfigurations.swift
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

import Foundation

// MARK: - Sync Configuration

/// Sync command configuration
public struct SyncConfiguration: Sendable {
  public var dryRun: Bool
  public var restoreImagesOnly: Bool
  public var xcodeOnly: Bool
  public var swiftOnly: Bool
  public var noBetas: Bool
  public var noAppleWiki: Bool
  public var verbose: Bool
  public var force: Bool
  public var minInterval: Int?
  public var source: String?
  public var jsonOutputFile: String?

  public init(
    dryRun: Bool = false,
    restoreImagesOnly: Bool = false,
    xcodeOnly: Bool = false,
    swiftOnly: Bool = false,
    noBetas: Bool = false,
    noAppleWiki: Bool = false,
    verbose: Bool = false,
    force: Bool = false,
    minInterval: Int? = nil,
    source: String? = nil,
    jsonOutputFile: String? = nil
  ) {
    self.dryRun = dryRun
    self.restoreImagesOnly = restoreImagesOnly
    self.xcodeOnly = xcodeOnly
    self.swiftOnly = swiftOnly
    self.noBetas = noBetas
    self.noAppleWiki = noAppleWiki
    self.verbose = verbose
    self.force = force
    self.minInterval = minInterval
    self.source = source
    self.jsonOutputFile = jsonOutputFile
  }
}

// MARK: - Export Configuration

/// Export command configuration
public struct ExportConfiguration: Sendable {
  public var output: String?
  public var pretty: Bool
  public var signedOnly: Bool
  public var noBetas: Bool
  public var verbose: Bool

  public init(
    output: String? = nil,
    pretty: Bool = false,
    signedOnly: Bool = false,
    noBetas: Bool = false,
    verbose: Bool = false
  ) {
    self.output = output
    self.pretty = pretty
    self.signedOnly = signedOnly
    self.noBetas = noBetas
    self.verbose = verbose
  }
}

// MARK: - Status Configuration

/// Status command configuration
public struct StatusConfiguration: Sendable {
  public var errorsOnly: Bool
  public var detailed: Bool

  public init(
    errorsOnly: Bool = false,
    detailed: Bool = false
  ) {
    self.errorsOnly = errorsOnly
    self.detailed = detailed
  }
}

// MARK: - List Configuration

/// List command configuration
public struct ListConfiguration: Sendable {
  public var restoreImages: Bool
  public var xcodeVersions: Bool
  public var swiftVersions: Bool

  public init(
    restoreImages: Bool = false,
    xcodeVersions: Bool = false,
    swiftVersions: Bool = false
  ) {
    self.restoreImages = restoreImages
    self.xcodeVersions = xcodeVersions
    self.swiftVersions = swiftVersions
  }
}

// MARK: - Clear Configuration

/// Clear command configuration
public struct ClearConfiguration: Sendable {
  public var yes: Bool
  public var verbose: Bool

  public init(
    yes: Bool = false,
    verbose: Bool = false
  ) {
    self.yes = yes
    self.verbose = verbose
  }
}
