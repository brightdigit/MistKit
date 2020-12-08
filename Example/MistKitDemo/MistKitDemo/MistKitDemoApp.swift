import SwiftUI

@main
public struct MistKitDemoApp: App {
  public var body: some Scene {
    WindowGroup {
      ContentView().environmentObject(MistObject())
    }
  }
}
