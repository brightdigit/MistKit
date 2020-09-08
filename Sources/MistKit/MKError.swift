import Foundation

public enum MKError : Error {
  case noDataFromStatus(Int)
  case invalidReponse(Any)
  case empty
  case invalidURL(URL)
  case invalidURLQuery(String)
  case invalidRecordName(String)
}
