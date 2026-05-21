//
//  PlatformAliases.swift
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

// The per-platform aliases live together (rather than one type per file)
// because each is a thin, `#if`-selected typealias. The file is deliberately
// not named after any one alias — in project-mode lint SwiftLint parses every
// `#if` branch, so a filename-matching typealias ladder would be misread as a
// `main_type` sitting amongst `supporting_type`s (`file_types_order`). Naming
// the file neutrally keeps every alias a plain supporting type; the resulting
// `file_name` mismatch is waived for this file in `.swiftlint.yml`.
#if canImport(SwiftUI)
  public import SwiftUI

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public import AppKit

    /// The platform application type (`NSApplication` on AppKit,
    /// `UIApplication` on UIKit, `WKApplication` on watchOS). Lets the
    /// push-notification delegate and registration call sites name one type
    /// instead of branching.
    public typealias PlatformApplication = NSApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias ApplicationDelegate = NSApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``ApplicationDelegate``. Lets `@main` declare the adaptor once
    /// rather than under parallel `#if` branches.
    public typealias PlatformApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
  #elseif canImport(WatchKit)
    public import WatchKit

    /// The platform application type. See the AppKit branch for full notes.
    public typealias PlatformApplication = WKApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias ApplicationDelegate = WKApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``ApplicationDelegate``.
    public typealias PlatformApplicationDelegateAdaptor = WKApplicationDelegateAdaptor
  #elseif canImport(UIKit)
    public import UIKit

    /// The platform application type. See the AppKit branch for full notes.
    public typealias PlatformApplication = UIApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias ApplicationDelegate = UIApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``ApplicationDelegate``.
    public typealias PlatformApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
  #endif
#endif
