//
//  ContentView.swift
//  MistKitDemo
//
//  Created by Leo Dion on 9/3/20.
//

import SwiftUI
import CloudKit

enum Errors : Error {
  case empty
}
struct TodoItem {
  let id : UUID
  let text : String
  let completedDate : Date?
  
  init(record: CKRecord) throws {
    guard let id = UUID(uuidString: record.recordID.recordName) else {
      throw NSError()
    }
    
    guard let text =  record["text"] as? String else {
      throw NSError()
    }
    
    self.id = id
    self.text = text
    self.completedDate = record["completedDate"] as? Date
  }
}

class MistObject: ObservableObject {
  @Published var items : Result<[TodoItem], Error>?
  init () {
    let container = CKContainer.default()
    let database = container.privateCloudDatabase
    database.perform(.init(recordType: "TodoItem", predicate: .init(value: true)), inZoneWith: nil) { (records, error) in
      let result : Result<[TodoItem], Error>
      if let error = error {
        result = .failure(error)
      } else if let records = records {
        result = .init{ try records.map(TodoItem.init) }
      } else {
        result = .failure(Errors.empty)
      }
      self.items = result
    }
  }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
