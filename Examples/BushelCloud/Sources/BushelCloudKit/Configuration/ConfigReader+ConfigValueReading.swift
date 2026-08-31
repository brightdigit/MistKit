//
//  ConfigReader+ConfigValueReading.swift
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

public import ConfigKeyKit
public import Configuration

/// Bridges swift-configuration's `ConfigReader` to ConfigKeyKit's
/// ``ConfigValueReading``, which supplies the CLI → ENV → default resolution
/// for every `ConfigKey` / `OptionalConfigKey` overload.
///
/// Before ConfigKeyKit 1.0.0-beta.2 each consumer hand-wrote those overloads;
/// they now live on the protocol extension in ConfigKeyKit's dependency-free
/// core, so this conformance is the only glue required.
extension ConfigReader: @retroactive ConfigValueReading {
  /// Wraps a resolved per-source key string in swift-configuration's own key type.
  public func makeConfigKey(_ string: String) -> Configuration.ConfigKey {
    .init(string)
  }
}
