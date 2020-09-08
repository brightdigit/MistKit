import Foundation
import MistKit
//import MistKitAuth


let token = "29__54__ARHdpCmg06ZOVWu1BK9TnE0QIkAGdUiw7rxmJWLxb/LeZN05YtNcrtCH+KX77oHecH69twhPmGnePFniCp4og6QSqgp9aM+mL/3vP7PQp8Qy7IKdaoTns0TXZDHP+zXdCLX8ka/jD5UMTSmwbZjaDNzwgTBE8Re2X4MlmuL9SciBTzW0MLEaV5A551Z9/zI9VCjriDvRdUtj8lXBHQDgkqcypl24Pu/EC90vad3GAEk93oO9Zdk1VooWv5DWmsAVZBOX3n1wP5AIP2PID81CZmjEIiuzKoBnFf5z4eaIfLETXNBwBklR7IxxGy4Kuphz0M339Yfgvnvaln9DWBrh92v6/4ZrhXK0YhB6xMycJTfawVzHVlixK8+qcRJvAUTpQvNQEFSE8+cisf3CQ7MdcbB1h2TbzdvBkwoewi8O5UUfpJg=__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0VSRHE4MG1XRUJ6aVIxMk5CckZVaGhtZnV4UXZjNHAvUEtocEpHV0pIMlpaUHd2NExPN2k5QlZVclBnMFlUanlBQ0htbndkWE1yMnF4YTF1V1FMNVE0IiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0hHSUxuMDFjeU9vQXhjTXZ4L3BoTVpuc1JGTjlmbFgxTkNhK2hDQVFKVFFCQ1JBbVY1akNJbVRDT3FFbHR2MG5BSFd0OXhJRG14WUZObHRqZXBqcVFQIn0="

let apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"
let container = "iCloud.com.brightdigit.MistDemo"

enum MKError : Error {
  case noDataFromStatus(Int)
  case invalidReponse(Any)
  case empty
  case invalidURL(URL)
  case invalidURLQuery(String)
  case invalidRecordName(String)
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
  public static let baseURL = URL(string: "https://api.apple-cloudkit.com/database")!
  let container : String
  let environment : MKEnvironment
  let version : MKAPIVersion
  let apiToken : String
  
  public init ( container : String,
                apiToken : String,
 environment : MKEnvironment,
 version : MKAPIVersion = .v1) {
    self.container = container
    self.environment = environment
    self.version = version
    self.apiToken = apiToken
  }
}

extension MKDatabaseConnection {
  var url : URL {
    //return URL(string: "https://api.apple-cloudkit.com/database/1/\(container)/\(environment)")
    return Self.baseURL.appendingPathComponent(version.rawValue).appendingPathComponent(container).appendingPathComponent(environment.rawValue)
  }
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
struct MKURLResponse : MKHttpResponse {
  let body: Data?
  let response : HTTPURLResponse
  
  var status: Int {
    return response.statusCode
  }
}
protocol MKHttpRequest {
  func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void))
}

protocol MKHttpClient {
  associatedtype RequestType : MKHttpRequest
  func request (withURL url: URL, data: Data?) -> RequestType
}



struct FetchRecordQueryRequest : MKRequest {
  let data: FetchRecordQuery
  
  let database: MKDatabaseType
  
  let subpath = ["records","query"]

  
  
  typealias Response = FetchRecordQueryResponse
  
  typealias Data = FetchRecordQuery
  
  
}

struct MKURLRequest : MKHttpRequest {
  let urlRequest : URLRequest
  let urlSession: URLSession
  func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void)) {
    urlSession.dataTask(with: urlRequest) { (data, response, error) in
      let result : Result<MKHttpResponse, Error>
      if let error = error {
        result = .failure(error)
      } else if let response = response as? HTTPURLResponse {
        result = .success(MKURLResponse(body: data, response: response))
      } else if let response = response {
        result = .failure(MKError.invalidReponse(response))
      } else {
        result = .failure(MKError.empty)
      }
      callback(result)
    }.resume()
  }
  
  
}
struct MKURLSessionClient : MKHttpClient {
  let session : URLSession
  func request(withURL url: URL, data: Data?) -> MKURLRequest {
    var urlRequest = URLRequest(url: url)
    if let data = data {
      debugPrint(String(data: data, encoding: .utf8))
      urlRequest.httpBody = data
      urlRequest.httpMethod = "POST"
      urlRequest.allHTTPHeaderFields = [ "Content-Type": "application/json" ]

    }
    return MKURLRequest(urlRequest: urlRequest, urlSession: self.session)
  }
  
  typealias RequestType = MKURLRequest
  
  
}

struct MKURLBuilderFactory {
  func builder (forConnection connection: MKDatabaseConnection, withWebAuthToken webAuthenticationToken: String?) -> MKURLBuilder {
    return MKURLBuilder(tokenEncoder: CharacterMapEncoder(), connection: connection, webAuthenticationToken: webAuthenticationToken)
  }
}
struct MKURLBuilder {
  let tokenEncoder : CloudKitTokenEncoder?
  let connection : MKDatabaseConnection
  let webAuthenticationToken : String?
  
  func url(withPathComponents pathComponents: [String]) throws -> URL {
    var url = connection.url
    for path in pathComponents {
      url.appendPathComponent(path)
    }
    let query = self.queryItems.map {
      [$0.key, $0.value].joined(separator: "=")
    }.joined(separator: "&")
    guard let result = URL(string: [url.absoluteString, query].joined(separator: "?"))else {
      throw MKError.invalidURLQuery(query)
    }
    print(result)
    return result
  }
}

extension MKURLBuilder {
  var queryItems : [String : String] {
    var parameters = ["ckAPIToken" : self.connection.apiToken]
    if let webAuthenticationToken = self.webAuthenticationToken, let tokenEncoder = self.tokenEncoder {
      parameters["ckWebAuthToken"] = tokenEncoder.encode(webAuthenticationToken)
      parameters["ckSession"] = tokenEncoder.encode(webAuthenticationToken)
      
    }
    return parameters
  }
  
}



struct MKDatabase<HttpClient : MKHttpClient> {
  let urlBuilder : MKURLBuilder
  let encoder : MKEncoder = JSONEncoder()
  let decoder : MKDecoder = JSONDecoder()
  let client : HttpClient
  
  public init (connection: MKDatabaseConnection, factory: MKURLBuilderFactory, client: HttpClient, authenticationToken: String? = nil) {
    self.urlBuilder = MKURLBuilder(tokenEncoder: CharacterMapEncoder(), connection: connection, webAuthenticationToken: authenticationToken)
    self.client = client
  }
  func perform<RequestType : MKRequest, ResponseType>(request: RequestType, _ callback: @escaping ((Result<ResponseType, Error>) -> Void) ) where RequestType.Response == ResponseType {

    let url = try! self.urlBuilder.url(withPathComponents: request.relativePath)
    let data = try! self.encoder.optionalData(from: request.data)
    let httpRequest = client.request(withURL: url, data: data)
    dump(httpRequest)
    httpRequest.execute { (result) in
      let newResult = result.flatMap { (response) -> Result<Data, Error> in
        guard let data = response.body else {
          return .failure(MKError.noDataFromStatus(response.status))
        }
        debugPrint(String(data: data, encoding: .utf8))
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

struct UserIdentityLookupInfo : Codable {
  public let emailAddress : String
  public let phoneNumber : String
  public let userRecordName : String
}

struct UserIdentityNameComponents : Codable {
  public let namePrefix : String
  public let givenName : String
  public let familyName : String
  public let nickname : String
  public let nameSuffix : String
  public let middleName : String
  public let phoneticRepresentation : String
}

//struct UserIdentity : Codable {
//  let lookupInfo : UserIdentityLookupInfo?
//  let userRecordName : UUID
//  let nameComponents : UserIdentityNameComponents?
//}

struct RecordName : Decodable {
  public let uuid : UUID
  init(from decoder: Decoder) throws {
    let uuidString = try decoder.singleValueContainer().decode(String.self)
    guard let uuid = RecordNameParser.uuid(fromRecordName: uuidString) else {
      throw MKError.invalidRecordName(uuidString)
    }
    self.uuid = uuid
  }
  
}

struct UserIdentityResponse : MKDecodable {
  let lookupInfo : UserIdentityLookupInfo?
  let userRecordName : RecordName
  let nameComponents : UserIdentityNameComponents?
}
struct GetCurrentUserIdentityRequest : MKRequest {
  let data: MKEmptyGet = .value
  
  let database: MKDatabaseType = .public
  
  let subpath: [String] = ["users","caller"]
  
  typealias Response = UserIdentityResponse
  
  typealias Data = MKEmptyGet
  
  
}

let dbConnection = MKDatabaseConnection(container: container, apiToken: apiKey, environment: .development)

let client = MKURLSessionClient(session: .shared)
let db = MKDatabase(connection: dbConnection, factory: MKURLBuilderFactory(), client: client, authenticationToken: token)
let getUser = GetCurrentUserIdentityRequest()
//var userResult : Result<UserIdentityResponse, Error>?
var recordsResult : Result<FetchRecordQueryResponse, Error>?
//db.perform(request: getUser) { (result) in
//  userResult = result
//}
let getTodoitems = FetchRecordQueryRequest(data: FetchRecordQuery(query: .init(recordType: "TodoItem")), database: .private)
db.perform(request: getTodoitems) { (result) in
  recordsResult = result
}
while true {
  RunLoop.main.run(until: .distantPast)
  if let todoitems = recordsResult {
    //dump(result)
    dump(todoitems)
    break
  }
}
//let channel = try startServer(htdocs: "", allowHalfClosure: true, bindTarget: .ip(host: "127.0.0.1", port: 7000))
//
//let urlString = URL(string: "https://api.apple-cloudkit.com/database/1/\(container)/\(environment)/\(database)/users/current?ckAPIToken=\(apiKey)")!
//
//print(urlString)
//try channel.closeFuture.wait()
