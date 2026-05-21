//
//  View+DeleteSwipeAction.swift
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

#if canImport(SwiftUI)
  internal import SwiftUI

  extension View {
    /// Attaches a trailing destructive "Delete" swipe action.
    ///
    /// `swipeActions(...)` is unavailable on tvOS, so this is a no-op there;
    /// every list row that offers swipe-to-delete routes through this helper
    /// so the platform guard lives in exactly one place.
    @ViewBuilder
    internal func deleteSwipeAction(
      perform action: @escaping () -> Void
    ) -> some View {
      #if os(tvOS)
        self
      #else
        self.swipeActions {
          Button("Delete", role: .destructive, action: action)
        }
      #endif
    }
  }
#endif
