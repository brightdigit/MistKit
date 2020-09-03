//
//  MistKitDemoApp.swift
//  MistKitDemo
//
//  Created by Leo Dion on 9/3/20.
//

import SwiftUI

@main
struct MistKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView().environmentObject(MistObject())
        }
    }
}
