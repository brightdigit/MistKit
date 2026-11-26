//
//  SchemaFixtures+RecordedQuery.swift
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
  /// Recorded: the first page of a `Player` query on Mistico's scratch
  /// container (`Fixtures/Recorded/query/first-page.json`), with its
  /// continuation marker shortened.
  internal static let recordedFirstPage = """
    {
      "records": [
        {
          "recordName": "fixture-player-1",
          "recordType": "Player",
          "fields": {
            "country": {
              "value": "GB",
              "type": "STRING"
            },
            "lastSeen": {
              "value": 1794950571000,
              "type": "TIMESTAMP"
            },
            "gamesPlayed": {
              "value": 12,
              "type": "INT64"
            },
            "displayName": {
              "value": "Fixture Player 1",
              "type": "STRING"
            },
            "rating": {
              "value": 1500,
              "type": "INT64"
            },
            "handle": {
              "value": "fixture1",
              "type": "STRING"
            }
          },
          "pluginFields": {},
          "recordChangeTag": "mwl7856s",
          "created": {
            "timestamp": 1794950571950,
            "userRecordName": "_fixtureUser1",
            "deviceID": "2"
          },
          "modified": {
            "timestamp": 1794950571950,
            "userRecordName": "_fixtureUser1",
            "deviceID": "2"
          },
          "deleted": false,
          "zoneID": {
            "zoneName": "_defaultZone",
            "ownerRecordName": "_fixtureUser1",
            "zoneType": "DEFAULT_ZONE"
          },
          "chainingKeyList": []
        },
        {
          "recordName": "fixture-player-2",
          "recordType": "Player",
          "fields": {
            "country": {
              "value": "GB",
              "type": "STRING"
            },
            "lastSeen": {
              "value": 1794950571000,
              "type": "TIMESTAMP"
            },
            "gamesPlayed": {
              "value": 12,
              "type": "INT64"
            },
            "displayName": {
              "value": "Fixture Player 2",
              "type": "STRING"
            },
            "rating": {
              "value": 1500,
              "type": "INT64"
            },
            "handle": {
              "value": "fixture2",
              "type": "STRING"
            }
          },
          "pluginFields": {},
          "recordChangeTag": "mwl7856t",
          "created": {
            "timestamp": 1794950571950,
            "userRecordName": "_fixtureUser1",
            "deviceID": "2"
          },
          "modified": {
            "timestamp": 1794950571950,
            "userRecordName": "_fixtureUser1",
            "deviceID": "2"
          },
          "deleted": false,
          "zoneID": {
            "zoneName": "_defaultZone",
            "ownerRecordName": "_fixtureUser1",
            "zoneType": "DEFAULT_ZONE"
          },
          "chainingKeyList": []
        },
        {
          "recordName": "fixture-player-3",
          "recordType": "Player",
          "fields": {
            "country": {
              "value": "GB",
              "type": "STRING"
            },
            "lastSeen": {
              "value": 1794950571000,
              "type": "TIMESTAMP"
            },
            "gamesPlayed": {
              "value": 12,
              "type": "INT64"
            },
            "displayName": {
              "value": "Fixture Player 3",
              "type": "STRING"
            },
            "rating": {
              "value": 1500,
              "type": "INT64"
            },
            "handle": {
              "value": "fixture3",
              "type": "STRING"
            }
          },
          "pluginFields": {},
          "recordChangeTag": "mwl7856u",
          "created": {
            "timestamp": 1794950571950,
            "userRecordName": "_fixtureUser1",
            "deviceID": "2"
          },
          "modified": {
            "timestamp": 1794950571950,
            "userRecordName": "_fixtureUser1",
            "deviceID": "2"
          },
          "deleted": false,
          "zoneID": {
            "zoneName": "_defaultZone",
            "ownerRecordName": "_fixtureUser1",
            "zoneType": "DEFAULT_ZONE"
          },
          "chainingKeyList": []
        }
      ],
      "continuationMarker": "Q29udGludWU="
    }
    """
}
