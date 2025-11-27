//
//  RecordTypeSet.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Protocol for types that provide iteration over CloudKit record types
///
/// Conforming types provide a `forEach` method for iterating through
/// a collection of CloudKit record types.
public protocol RecordTypeIterating {
  /// Iterate through all record types
  ///
  /// - Parameter action: Closure called for each record type
  /// - Throws: Rethrows any errors thrown by the action closure
  func forEach(_ action: (any CloudKitRecord.Type) async throws -> Void) async rethrows
}

/// Lightweight container for CloudKit record types using Swift variadic generics
///
/// This struct captures a parameter pack of `CloudKitRecord` types and provides
/// type-safe iteration over them without runtime reflection.
///
/// ## Example
///
/// ```swift
/// let recordTypes = RecordTypeSet(
///     RestoreImageRecord.self,
///     XcodeVersionRecord.self,
///     SwiftVersionRecord.self
/// )
///
/// recordTypes.forEach { recordType in
///     print(recordType.cloudKitRecordType)
/// }
/// ```
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
public struct RecordTypeSet<each RecordType: CloudKitRecord>: Sendable, RecordTypeIterating {
  /// Initialize with a parameter pack of CloudKit record types
  ///
  /// - Parameter types: Variadic parameter pack of CloudKit record types
  public init(_ types: repeat (each RecordType).Type) {}

  /// Iterate through all record types in the parameter pack
  ///
  /// This method uses Swift's `repeat each` pattern to iterate through
  /// the parameter pack at compile time, providing type-safe access to each type.
  ///
  /// - Parameter action: Closure called for each record type
  /// - Throws: Rethrows any errors thrown by the action closure
  public func forEach(_ action: (any CloudKitRecord.Type) async throws -> Void) async rethrows {
    try await (repeat action((each RecordType).self))
  }
}
