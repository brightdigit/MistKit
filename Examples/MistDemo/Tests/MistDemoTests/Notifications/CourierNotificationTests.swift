//
//  CourierNotificationTests.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

// Raw-string JSON fixtures below intentionally use JSON-aligned indents that
// don't match Swift source-indent steps; the rule isn't useful inside raw
// payloads.
// swiftlint:disable indentation_width

/// Decoding regression tests pinned to the three real web-courier payload
/// shapes captured against a live container (#379). One record change matching
/// three subscriptions produced three frames sharing a `nid` but differing by
/// `sid` and `aps` shape: an alerting push, a bare `ck`-only frame, and a
/// silent `content-available` push.
@Suite("CourierNotification")
internal struct CourierNotificationTests {
  /// `aps.alert` carries a string body; all query fields present.
  @Test("Decodes an alerting push")
  internal func decodesAlertingPush() throws {
    let body = #"""
      {"aps":{"alert":"MistDemo push (token suffix: 429bd7)"},
       "ck":{"ce":2,"ckuserid":"_aca0fa","aux":{},
             "nid":"c17cf8c1-5567-4635-b650-9aba0cd9acdc",
             "qry":{"zid":"_defaultZone","dbs":1,"fo":1,"zoid":"_aca0fa",
                    "rid":"B61C8113-78DD-4ED1-9E62-4666F9888FE9",
                    "sid":"MistDemo.pushToken"},
             "cid":"iCloud.com.brightdigit.MistDemo"}}
      """#

    let notification = try CourierNotification(data: Data(body.utf8))

    #expect(notification.notificationID == "c17cf8c1-5567-4635-b650-9aba0cd9acdc")
    #expect(notification.containerIdentifier == "iCloud.com.brightdigit.MistDemo")
    #expect(notification.subscriptionID == "MistDemo.pushToken")
    #expect(notification.recordName == "B61C8113-78DD-4ED1-9E62-4666F9888FE9")
    #expect(notification.zoneID == "_defaultZone")
    #expect(notification.reason == .recordCreated)
    #expect(notification.databaseScope == 1)
    #expect(notification.alertBody == "MistDemo push (token suffix: 429bd7)")
  }

  /// No `aps` block at all — a sibling subscription's frame for the same change.
  @Test("Decodes a frame with no aps block")
  internal func decodesFrameWithoutAps() throws {
    let body = #"""
      {"ck":{"ce":2,"ckuserid":"_aca0fa",
             "nid":"c17cf8c1-5567-4635-b650-9aba0cd9acdc",
             "qry":{"zid":"_defaultZone","dbs":1,"fo":1,"zoid":"_aca0fa",
                    "rid":"B61C8113-78DD-4ED1-9E62-4666F9888FE9",
                    "sid":"7D5FBF2F-A449-4EDA-9287-F9B8EBFE0DD3"},
             "cid":"iCloud.com.brightdigit.MistDemo"}}
      """#

    let notification = try CourierNotification(data: Data(body.utf8))

    #expect(notification.subscriptionID == "7D5FBF2F-A449-4EDA-9287-F9B8EBFE0DD3")
    #expect(notification.recordName == "B61C8113-78DD-4ED1-9E62-4666F9888FE9")
    #expect(notification.reason == .recordCreated)
    #expect(notification.alertBody == nil)
  }

  /// Silent/background push: `aps` is `{"content-available":1}` with no
  /// `alert` key. The decoder must not choke on the missing alert.
  @Test("Decodes a silent content-available push")
  internal func decodesSilentPush() throws {
    let body = #"""
      {"aps":{"content-available":1},
       "ck":{"ce":2,"ckuserid":"_aca0fa","aux":{},
             "nid":"c17cf8c1-5567-4635-b650-9aba0cd9acdc",
             "qry":{"zid":"_defaultZone","dbs":1,"fo":1,"zoid":"_aca0fa",
                    "rid":"B61C8113-78DD-4ED1-9E62-4666F9888FE9",
                    "sid":"MistDemo.noteCreated"},
             "cid":"iCloud.com.brightdigit.MistDemo"}}
      """#

    let notification = try CourierNotification(data: Data(body.utf8))

    #expect(notification.subscriptionID == "MistDemo.noteCreated")
    #expect(notification.recordName == "B61C8113-78DD-4ED1-9E62-4666F9888FE9")
    #expect(notification.reason == .recordCreated)
    #expect(notification.alertBody == nil)
  }

  /// `fo` maps to the documented query-notification reasons.
  @Test(
    "Maps the fires-on reason code",
    arguments: [
      (1, CourierNotification.Reason.recordCreated),
      (2, .recordUpdated),
      (3, .recordDeleted),
    ]
  )
  internal func mapsReason(code: Int, expected: CourierNotification.Reason) throws {
    let body = #"{"ck":{"qry":{"fo":\#(code),"sid":"s","rid":"r"}}}"#
    let notification = try CourierNotification(data: Data(body.utf8))
    #expect(notification.reason == expected)
  }
}

// swiftlint:enable indentation_width
