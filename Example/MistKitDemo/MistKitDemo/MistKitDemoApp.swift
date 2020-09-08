import SwiftUI

@main
struct MistKitDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView().environmentObject(MistObject())
    }
  }
}
