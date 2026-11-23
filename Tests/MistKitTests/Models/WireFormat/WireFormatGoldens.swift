//
//  WireFormatGoldens.swift
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

/// JSON in the shapes of Mistico's Codecs golden files (`Fixtures/Golden/Codecs`).
///
/// `misticoRecords` is `records.json` verbatim: keys in CloudKit's order and
/// `"key": value` spacing, as another writer would produce.
internal enum WireFormatGoldens {
  internal static let misticoRecords = #"""
    [
      {
        "recordName": "specimen-1",
        "recordType": "Specimen",
        "recordChangeTag": "tag-1",
        "zoneID": {
          "zoneName": "_defaultZone"
        },
        "fields": {
          "count": {
            "value": 42,
            "type": "INT64"
          },
          "empty": {
            "value": [],
            "type": "STRING_LIST"
          },
          "friends": {
            "value": [
              {
                "recordName": "player-ben"
              },
              {
                "recordName": "player-chen",
                "zoneID": {
                  "zoneName": "Teams",
                  "ownerRecordName": "_owner1"
                }
              }
            ],
            "type": "REFERENCE_LIST"
          },
          "notes": {
            "value": "Line one\nLine two\t\"quoted\"",
            "type": "STRING"
          },
          "owner": {
            "value": {
              "recordName": "player-ana",
              "action": "DELETE_SELF"
            },
            "type": "REFERENCE"
          },
          "payload": {
            "value": "AP8QgA==",
            "type": "BYTES"
          },
          "photo": {
            "value": {
              "fileChecksum": "abc123",
              "size": 2048,
              "downloadURL": "https://cvws.icloud-content.com/B/abc/photo.jpg?o=1&e=2"
            },
            "type": "ASSET"
          },
          "ratio": {
            "value": 0.125,
            "type": "DOUBLE"
          },
          "seenAt": {
            "value": 1790000000500,
            "type": "TIMESTAMP"
          },
          "stops": {
            "value": [
              {
                "latitude": 1.5,
                "longitude": -2.25
              }
            ],
            "type": "LOCATION_LIST"
          },
          "tags": {
            "value": [
              "alpha",
              "β, gamma"
            ],
            "type": "STRING_LIST"
          },
          "title": {
            "value": "Émile & “Zoë”, 東京 🚀",
            "type": "STRING"
          },
          "venue": {
            "value": {
              "latitude": 53.3498,
              "longitude": -6.2603,
              "horizontalAccuracy": 5.0
            },
            "type": "LOCATION"
          }
        },
        "created": {
          "timestamp": 1789000000000,
          "userRecordName": "_creator"
        },
        "modified": {
          "timestamp": 1790000000000
        }
      },
      {
        "recordName": "specimen-2",
        "recordType": "Specimen",
        "recordChangeTag": "tag-2",
        "zoneID": {
          "zoneName": "_defaultZone"
        },
        "fields": {
          "count": {
            "value": -7,
            "type": "INT64"
          },
          "title": {
            "value": "Plain",
            "type": "STRING"
          }
        }
      }
    ]
    """#
}
