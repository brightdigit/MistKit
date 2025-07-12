//
//  RecordInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//




public struct RecordInfo: Encodable {
  public let recordName: String
  public let recordType: String
  public let fields: [String: String]
    
  internal init(from record: Components.Schemas.Record) {
        self.recordName = record.recordName ?? "Unknown"
        self.recordType = record.recordType ?? "Unknown"
        
        // Convert fields to simple string representation
        let simpleFields: [String: String] = [:]
        // Note: fields is a special structure in the generated code
        // For now, we'll leave it empty as the exact structure needs investigation
        self.fields = simpleFields
    }
}
