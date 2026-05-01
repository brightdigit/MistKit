//
//  RecordDetailView.swift
//  MistDemoApp
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

import SwiftUI

struct RecordDetailView: View {
    let record: RecordRow

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Record Name", value: record.recordName)
                LabeledContent("Record Type", value: record.recordType)
                if let modificationDate = record.modificationDate {
                    LabeledContent("Modified", value: modificationDate.formatted(date: .abbreviated, time: .standard))
                }
            }
            Section("Fields") {
                if record.fields.isEmpty {
                    Text("No fields").foregroundStyle(.secondary)
                } else {
                    ForEach(record.fields, id: \.key) { field in
                        LabeledContent(field.key, value: field.valueDescription)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(record.recordName)
    }
}
