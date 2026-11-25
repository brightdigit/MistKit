//
//  ZoneInfo+Atomic.swift
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

extension ZoneInfo {
  /// Whether commits to this zone are all-or-nothing.
  ///
  /// A zone whose response left ``atomic`` out counts as not atomic, the safe
  /// reading: commits then report per-record results.
  public var isAtomic: Bool { atomic ?? false }

  /// A zone with only an identity and its ``atomic`` flag.
  ///
  /// - Parameters:
  ///   - id: The zone's name and owner.
  ///   - isAtomic: Whether commits to it are all-or-nothing.
  public init(id: ZoneID, isAtomic: Bool) {
    self.init(
      zoneName: id.zoneName,
      ownerRecordName: id.ownerName,
      capabilities: [],
      atomic: isAtomic
    )
  }
}
