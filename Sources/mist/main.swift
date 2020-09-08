import Foundation
import MistKit
//import MistKitAuth


let token = "29__54__AeRKh0by2d2DvN5Oz8PF4VAdx4UMoP1ZsmDwjCTRzmbgiyGp3xygO+MRZ9jjNuW/npq8rPnAjs/MHuGmTVfrbOy8Gzw00qK8CDiK9WbiX6wBoYEniyo75po5iC4fMq0sXoysth54wzokiQMsXDhqpotXUVJMlQVsuyImtZJOMLpgKLc+nr94e1VRBlrmuWdRtUN85Cch0RHij4xgorQkXOOQOmcujTsX88+61il9ugVahsVi19dKPhfE9B0lMZ7QByTk5IR3ZMEqeZVz7+nmitWJMn5/h82n8WIP2fx0FlXZ+gvwEt1AVRh314QG7VxAmCZipO0RrQx3mKxbUEX+QP2elNo4kY/F1rinLFbL04NXp+nKM0BDln8xN8D7SVrrwW1JiCqcJTAK2wh5gWpq3kbUV5Ti0nE8UzSX3X31tjoTtxk=__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0dMK090eHFMeXlKSVJDeTdJai94aHBIN3puRStDS0g3WkMyVDNQWkorOGRvS2UrT24xdU9zMk94NUU0SjduSXJocDdrQXprZHNrQU9LYUVveWJVK0NFIiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0dYam54OVZHMEZxNkFWUndzRnViZCtpZ3RzUmJiMUtXOEs4bEhpWXE1UnRiZVZtczNkeW1CRzNac2xaYnZRM1V4b3grRjNyYlNmUkl2dUhqb2kvenBKIn0="

let apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"
let container = "iCloud.com.brightdigit.MistDemo"

enum MKEnvironment : String {
  case production
  case development
}


enum MKAPIVersion : String {
    case v1 = "1"
}

let environment = MKEnvironment.development
let database = MKDatabaseType.private

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

extension MKDatabase {
  func query<RecordType : MKQueryRecord>(_ query: FetchRecordQueryRequest<MKQuery<RecordType>>, _ callback: @escaping ((Result<[RecordType], Error>) -> Void) ) {
    self.perform(request: query) { (result) in
      let newResult = result.flatMap { (response) -> Result<[RecordType], Error> in
        Result{
        try response.records.map(
          RecordType.init(record:)
        )
        }
      }
      callback(newResult)
    }
  }
}

//struct UserIdentity : Codable {
//  let lookupInfo : UserIdentityLookupInfo?
//  let userRecordName : UUID
//  let nameComponents : UserIdentityNameComponents?
//}



let dbConnection = MKDatabaseConnection(container: container, apiToken: apiKey, environment: .development)

let client = MKURLSessionClient(session: .shared)
let db = MKDatabase(connection: dbConnection, factory: MKURLBuilderFactory(), client: client, authenticationToken: token)
let getUser = GetCurrentUserIdentityRequest()
var userResult : Result<UserIdentityResponse, Error>?
var recordsResult : Result<[TodoListItem], Error>?
db.perform(request: getUser) { (result) in
  userResult = result
}
let getTodoitems = FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKAnyQuery(recordType: "TodoItem")))
db.query(FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self)))) { (result) in
  recordsResult = result
}
while true {
  RunLoop.main.run(until: .distantPast)
  if let todoitems = recordsResult, let result = userResult  {
    dump(result)
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
