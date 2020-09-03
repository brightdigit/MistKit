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
struct TodoItem : Identifiable {
  public let id : UUID
  public let text : String
  public let completedDate : Date?
  
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
      DispatchQueue.main.async {
        self.items = result
      }      
    }
  }
}

struct ContentView: View {
  @EnvironmentObject var data : MistObject
  
  var error : Error? {
    switch self.data.items {
    case .failure(let error): return error
    default: return nil
    }
  }
  var isBusy : Bool {
    self.data.items == nil
  }
  var items : [TodoItem] {
    self.data.items.flatMap{ try? $0.get() } ?? [TodoItem]()
  }
  var body: some View {
    ZStack{
      self.error.map{ Text($0.localizedDescription) }
      Text("Loading").opacity(self.isBusy ? 1.0 : 0.0)
      List( self.items ) { (item) in
        Text(item.text)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
