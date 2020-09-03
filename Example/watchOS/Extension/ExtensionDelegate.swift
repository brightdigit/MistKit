import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
  func applicationDidFinishLaunching() {}

  func applicationDidBecomeActive() {}

  func applicationWillResignActive() {}

  @available(watchOSApplicationExtension 3.0, *)
  func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {
      if #available(watchOSApplicationExtension 5.0, *) {
        switch task {
        case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
          // Be sure to complete the relevant-shortcut task once you're done.
          relevantShortcutTask.setTaskCompletedWithSnapshot(false)
        case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
          // Be sure to complete the intent-did-run task once you're done.
          intentDidRunTask.setTaskCompletedWithSnapshot(false)
        default: break
        }
      }
      if #available(watchOSApplicationExtension 4.0, *) {
        switch task {
        case let backgroundTask as WKApplicationRefreshBackgroundTask:
          // Be sure to complete the background task once you’re done.
          backgroundTask.setTaskCompletedWithSnapshot(false)

        case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
          // Be sure to complete the connectivity task once you’re done.
          connectivityTask.setTaskCompletedWithSnapshot(false)
        case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
          // Be sure to complete the URL session task once you’re done.
          urlSessionTask.setTaskCompletedWithSnapshot(false)
        default: break
        }

        switch task {
        case let snapshotTask as WKSnapshotRefreshBackgroundTask:
          snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
        default:
          // make sure to complete unhandled task types
          task.setTaskCompletedWithSnapshot(false)
        }
      }
    }
  }
}

