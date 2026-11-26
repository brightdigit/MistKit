//
//  WireFormatGoldens+Modify.swift
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

extension WireFormatGoldens {
  /// `modify-records-operations.json` verbatim: a create, an update that
  /// clears a field, and a delete in an owned zone with `atomic`.
  internal static let misticoModifyOperations = #"""
    {
      "operations": [
        {
          "operationType": "create",
          "record": {
            "recordName": "new-1",
            "recordType": "Specimen",
            "fields": {
              "title": {
                "value": "New",
                "type": "STRING"
              }
            }
          }
        },
        {
          "operationType": "update",
          "record": {
            "recordName": "specimen-1",
            "recordType": "Specimen",
            "recordChangeTag": "tag-1",
            "fields": {
              "notes": {
                "value": null
              },
              "title": {
                "value": "Renamed",
                "type": "STRING"
              }
            }
          }
        },
        {
          "operationType": "delete",
          "record": {
            "recordName": "specimen-2",
            "recordChangeTag": "tag-2"
          }
        }
      ],
      "zoneID": {
        "zoneName": "Teams",
        "ownerRecordName": "_owner1"
      },
      "atomic": true
    }
    """#

  /// ``WireFormatSamples/plain`` through `JSONEncoder.cloudKitReadable`.
  internal static let plainReadable = #"""
    {
      "fields" : {
        "count" : {
          "type" : "INT64",
          "value" : -7
        },
        "title" : {
          "type" : "STRING",
          "value" : "Plain"
        }
      },
      "recordChangeTag" : "tag-2",
      "recordName" : "specimen-2",
      "recordType" : "Specimen",
      "zoneID" : {
        "zoneName" : "_defaultZone"
      }
    }
    """#
}
