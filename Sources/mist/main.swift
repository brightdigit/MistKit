import Foundation
import MistKit
//import MistKitAuth


let token = "29__54__ASGcOFYJkVPHI6y8s83vtYVOR1typ4MSCUy0kZycATM4uthl1yAZJT7pQbcCdWGwaflTHuvieI8oG9ALTmWbk8AtC2o3Bd0XhaLZAdApXQKJwtysgq6DrVvsLhZEUTYPzSVDbmRwq9/dqTPnOtNV4SD9UJvYGgTyw/HXLeQJ22L/+qjB8qRCpJqXOvUHxeGxUjOslu3mQiLCsO3s/BVjQOE+9j0kh15xyHJNLXv0pa3Abyz3fn6F1oaZU3bfQ0q6HnG1VdBPp/k0Rcv8eUPO1W6BHkvMjSltC3tITBs2T1bdhZloKoOJhYe9B2/qgo2W/lO5ODt0QDU8AewbyGm27lvxJD0hJ066zX1NIAaNFm9vHLud0QpZStmcWuCAMayPBc7XNHWjpTO2qW0oEVAWMRuf+yuHJCRb0HXrwKq3AyrfrV4=__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0hCcTY4a2V5OVdVNTVXbVZUcjBzVjhPNWFVNk5FRXVXZDRnOFZ0MlYya09hclFSOHRFU1J0YzFTbi9PbHcrY3VYNk5KbUtNTE92SCtjZ3pXYW8zNG9CIiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0d2UWhPRU1vQklTdnNjR1NqQjVhZUhlSHNiNkh4am5WVFlRSHhYMFgrZGt1eW10dHdmaHFRTHpVa2dSbEZkUEJOMnB5b0FJS3lGclAxbTVvSTgyeDRGIn0="

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
    urlRequest.httpBody = data
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
    //[url.absoluteString
//    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
//      throw MKError.invalidURL(url)
//    }
//    components.queryItems = self.queryItems
//
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
var userResult : Result<UserIdentityResponse, Error>?
db.perform(request: getUser) { (result) in
  userResult = result
}

while true {
  RunLoop.main.run(until: .distantPast)
  if let result = userResult {
    dump(result)
    break
  }
}
//let channel = try startServer(htdocs: "", allowHalfClosure: true, bindTarget: .ip(host: "127.0.0.1", port: 7000))
//
//let urlString = URL(string: "https://api.apple-cloudkit.com/database/1/\(container)/\(environment)/\(database)/users/current?ckAPIToken=\(apiKey)")!
//
//print(urlString)
//try channel.closeFuture.wait()
