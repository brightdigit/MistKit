//
//  BrowserOpener.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

public import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Utility for opening URLs in the default browser
struct BrowserOpener {
    
    /// Open a URL in the default browser
    /// - Parameter url: The URL string to open
    static func openBrowser(url: String) {
        #if canImport(AppKit)
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        #elseif os(Linux)
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["xdg-open", url]
        try? process.run()
        #endif
    }
}
