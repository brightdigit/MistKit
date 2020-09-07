import Foundation
import MistKit
import MistKitAuth

let token = "29__54__ASY54BFa%2Fuzc8N2wZ5dqQq%2FWTxLNfB2gKcqdkoYk8rlObgzRLA75yEUaMmRaD%2F8p%2BMmm5RI6CkHw9agx%2BeKgSU8z91AUnFeZZ9hWp5n8UzAqkCge3MoPnlDu%2F50FRZNQPs21RxkyteI2yg1cVyyemv8Wf1AUO16CpUxZtPr4oN6iiGFd1V1UYATugzYiZODdrGnHp3tB7iYTObM9tF0VKDpMs1ccymI1milAwsEU2BC8MPy%2FFRtZ%2FnMUTCRAZkIQARxgzToppmdYeislSe%2BuQRyJFIHxo%2BEeyhB%2FOdvbQYOOotucXv5aRGLtyPGiGLJ4qRtguQA47X2YlLnbdUyWklQFl6OvI0Jr5iSPJAZIM2TwnQ%2BzRemIr2QaMBoULWjsofwL%2BQTFGvhMmAhjVTVR%2Fx28AePfMO1l8xuczI6VONDmpC4%3D__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0VpWHNmM09aSFhLUjl5YXpEOFh1NXZkU1EzaCs5WmkwcGpBSnRVeUhjNHJ0aGwxdW9hMVFDMTFzMW4rWC9NRXNwUHBJaWpTNGp1NmpFM0t0UWtrM0VVIiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0hiODFSQXpVbnpkWXhBSEVrWlRhYmtrd1owOGhUNXVXK3NBTEJidlBEcS8yWlhLS3UrdmxtVTJ4VGp0Q1ZnVGd1dGMzZGZVUE1DZFJEMmtUNmtZb3BiIn0%3D"
let apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"
let container = "iCloud.com.brightdigit.MistDemo"

enum MKError : Error {
  case noDataFromStatus(Int)
}
enum MKEnvironment : String {
  case production
  case development
}

enum MKDatabaseType : String {
  case `private`
  case `public`
  case shared
}

enum MKAPIVersion : String {
    case v1 = "1"
}

let environment = MKEnvironment.development
let database = MKDatabaseType.private

protocol MKWebTokenProvider {
  
}
struct MKDatabaseConnection {
  let container : String
  let environment : MKEnvironment
  let version : MKAPIVersion
  
  public init ( container : String,
 environment : MKEnvironment,
 version : MKAPIVersion = .v1) {
    self.container = container
    self.environment = environment
    self.version = version
  }
}

protocol MKEncodable : Encodable {
  
}
protocol MKEncoder {
  func data<EncodableType : MKEncodable>(from object: EncodableType) throws -> Data
}
struct MKEmptyGet : MKEncodable {
  private init () {}
  public static let value = MKEmptyGet()
}
extension MKEncoder {
  func optionalData<EncodableType : MKEncodable>(from object: EncodableType) throws -> Data? {
    guard !(object is MKEmptyGet) else {
      return nil
    }
    
    return try self.data(from: object)
  }
}
protocol MKDecoder {
  func decode<DecoableType : MKDecodable>(_ type: DecoableType.Type, from data: Data) throws -> DecoableType
}
protocol MKDecodable : Decodable {
  
}

extension JSONDecoder : MKDecoder {
  
}

extension JSONEncoder : MKEncoder {
  func data<EncodableType : MKEncodable>(from object: EncodableType) throws -> Data {
    try self.encode(object)
  }
}

protocol MKRequest {
  var data : Data { get }
  var database : MKDatabaseType { get }
  var subpath : [String] { get }
  associatedtype Response : MKDecodable
  associatedtype Data : MKEncodable
}

extension MKRequest {
  var relativePath : [String] {
    ([self.database.rawValue] + subpath)
  }
}

protocol MKHttpResponse {
  var body : Data? { get }
  var status : Int { get }
}

protocol MKHttpRequest {
  func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void))
}

protocol MKHttpClient {
  associatedtype RequestType : MKHttpRequest
  func request (withURL url: URL, relativePath: [String], data: Data?) -> RequestType
}
struct MKDatabase<HttpClient : MKHttpClient> {
  let baseURL : URL
  let encoder : MKEncoder = JSONEncoder()
  let decoder : MKDecoder = JSONDecoder()
  let client : HttpClient
  func perform<RequestType : MKRequest, ResponseType>(request: RequestType, _ callback: @escaping ((Result<ResponseType, Error>) -> Void) ) where RequestType.Response == ResponseType {

    let data = try! self.encoder.optionalData(from: request.data)
    let httpRequest = client.request(withURL: self.baseURL, relativePath: request.relativePath, data: data)
    httpRequest.execute { (result) in
      let newResult = result.flatMap { (response) -> Result<Data, Error> in
        guard let data = response.body else {
          return .failure(MKError.noDataFromStatus(response.status))
        }
        return .success(data)
      }.flatMap { (data) in
        return Result{
          try self.decoder.decode(RequestType.Response.self, from: data)
        }
      }
      callback(newResult)
    }
  }
}

let channel = try startServer(htdocs: "", allowHalfClosure: true, bindTarget: .ip(host: "127.0.0.1", port: 7000))

let urlString = URL(string: "https://api.apple-cloudkit.com/database/1/\(container)/\(environment)/\(database)/users/current?ckAPIToken=\(apiKey)")!

print(urlString)
try channel.closeFuture.wait()
