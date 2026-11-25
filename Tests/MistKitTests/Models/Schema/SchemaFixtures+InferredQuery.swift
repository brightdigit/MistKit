//
//  SchemaFixtures+InferredQuery.swift
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

internal import Foundation

extension SchemaFixtures {
  /// PROVISIONAL, hand-written: a `records/query` response for two players
  /// with every field type, including empty `STRING_LIST`s
  /// (`Fixtures/Provisional/schema/inferred-query-player.json`).
  internal static let inferredQueryPlayer = """
    {
      "records": [
        {
          "recordName": "player-ana",
          "recordType": "Player",
          "recordChangeTag": "kq1x0f2a",
          "zoneID": {
            "zoneName": "_defaultZone"
          },
          "created": {
            "timestamp": 1793210000000,
            "userRecordName": "_user-redacted",
            "deviceID": "2"
          },
          "modified": {
            "timestamp": 1793300000000,
            "userRecordName": "_user-redacted",
            "deviceID": "2"
          },
          "fields": {
            "displayName": {
              "value": "Ana Lima",
              "type": "STRING"
            },
            "handle": {
              "value": "ana",
              "type": "STRING"
            },
            "rating": {
              "value": 1840,
              "type": "INT64"
            },
            "lastSeen": {
              "value": 1793300000000,
              "type": "TIMESTAMP"
            },
            "avatar": {
              "value": {
                "fileChecksum": "AbCdEf0123456789",
                "size": 48213,
                "downloadURL": "https://cvws.icloud-content.com/redacted/${f}"
              },
              "type": "ASSETID"
            },
            "friends": {
              "value": [
                {
                  "recordName": "player-ben",
                  "action": "NONE",
                  "zoneID": {
                    "zoneName": "_defaultZone"
                  }
                }
              ],
              "type": "REFERENCE_LIST"
            },
            "titles": {
              "value": [],
              "type": "STRING_LIST"
            }
          }
        },
        {
          "recordName": "player-ben",
          "recordType": "Player",
          "recordChangeTag": "kq1x0f2b",
          "zoneID": {
            "zoneName": "_defaultZone"
          },
          "created": {
            "timestamp": 1793210500000,
            "userRecordName": "_user-redacted",
            "deviceID": "2"
          },
          "modified": {
            "timestamp": 1793301000000,
            "userRecordName": "_user-redacted",
            "deviceID": "2"
          },
          "fields": {
            "displayName": {
              "value": "Ben Okafor",
              "type": "STRING"
            },
            "country": {
              "value": "NG",
              "type": "STRING"
            },
            "rating": {
              "value": 1720,
              "type": "INT64"
            },
            "winRate": {
              "value": 0.61,
              "type": "DOUBLE"
            },
            "home": {
              "value": {
                "latitude": 6.5244,
                "longitude": 3.3792,
                "horizontalAccuracy": 65.0
              },
              "type": "LOCATION"
            },
            "settings": {
              "value": "eyJ0aGVtZSI6ImRhcmsifQ==",
              "type": "BYTES"
            },
            "titles": {
              "value": [],
              "type": "STRING_LIST"
            }
          }
        }
      ]
    }
    """
}
