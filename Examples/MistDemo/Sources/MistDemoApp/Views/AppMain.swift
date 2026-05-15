//
//  MistDemoAppMain.swift
//  MistDemo
//
//  Created by Leo Dion on 5/15/26.
//

#if canImport(SwiftUI)
public import SwiftUI
public protocol AppMain : App {
  
}

extension AppMain {
  public var body: some Scene {
    WindowGroup("MistDemo (Native CloudKit)") {
      RootView()
    }
    #if os(macOS)
    .defaultSize(width: 880, height: 600)
    #endif
  }
}
#endif
