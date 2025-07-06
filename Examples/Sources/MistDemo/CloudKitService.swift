import Foundation
import MistKit
import OpenAPIRuntime
import OpenAPIURLSession

struct CloudKitService {
    let containerIdentifier: String
    let apiToken: String
    let environment: String = "development"
    
    private let client: Client
    
    init(containerIdentifier: String, apiToken: String) throws {
        self.containerIdentifier = containerIdentifier
        self.apiToken = apiToken
        
        // Initialize the OpenAPI client
        self.client = Client(
            serverURL: URL(string: "https://api.apple-cloudkit.com")!,
            transport: URLSessionTransport()
        )
    }
    
    /// Fetch current user information using a web auth token
    func fetchCurrentUser(webAuthToken: String) async throws -> UserInfo {
        // Create the request to get current user
        let response = try await client.users_current_get(
            path: .init(
                version: "1",
                container: containerIdentifier,
                environment: environment,
                database: "private"
            ),
            headers: .init(
                X_hyphen_Apple_hyphen_CloudKit_hyphen_API_hyphen_Token: apiToken,
                X_hyphen_Apple_hyphen_CloudKit_hyphen_Web_hyphen_Auth_hyphen_Token: webAuthToken
            )
        )
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let userData):
                return UserInfo(from: userData)
            }
        case .undocumented(let statusCode, _):
            throw CloudKitError.httpError(statusCode: statusCode)
        }
    }
    
    /// List zones in the user's private database
    func listZones(webAuthToken: String) async throws -> [ZoneInfo] {
        let response = try await client.zones_list_get(
            path: .init(
                version: "1",
                container: containerIdentifier,
                environment: environment,
                database: "private"
            ),
            headers: .init(
                X_hyphen_Apple_hyphen_CloudKit_hyphen_API_hyphen_Token: apiToken,
                X_hyphen_Apple_hyphen_CloudKit_hyphen_Web_hyphen_Auth_hyphen_Token: webAuthToken
            )
        )
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let zonesData):
                return zonesData.zones?.compactMap { ZoneInfo(from: $0) } ?? []
            }
        case .undocumented(let statusCode, _):
            throw CloudKitError.httpError(statusCode: statusCode)
        }
    }
    
    /// Query records from the default zone
    func queryRecords(webAuthToken: String, recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
        let requestBody = Components.Schemas.RecordsQueryRequest(
            query: .init(
                recordType: recordType,
                sortBy: [
                    .init(
                        fieldName: "modificationDate",
                        ascending: false
                    )
                ]
            ),
            resultsLimit: Int32(limit),
            zoneID: .init(
                zoneName: "_defaultZone"
            )
        )
        
        let response = try await client.records_query_post(
            path: .init(
                version: "1",
                container: containerIdentifier,
                environment: environment,
                database: "private"
            ),
            headers: .init(
                X_hyphen_Apple_hyphen_CloudKit_hyphen_API_hyphen_Token: apiToken,
                X_hyphen_Apple_hyphen_CloudKit_hyphen_Web_hyphen_Auth_hyphen_Token: webAuthToken
            ),
            body: .json(requestBody)
        )
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let recordsData):
                return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
            }
        case .undocumented(let statusCode, _):
            throw CloudKitError.httpError(statusCode: statusCode)
        }
    }
}

// Helper models
struct UserInfo {
    let userRecordName: String
    let firstName: String?
    let lastName: String?
    let emailAddress: String?
    
    init(from cloudKitUser: Components.Schemas.UserResponse) {
        self.userRecordName = cloudKitUser.userRecordName ?? "Unknown"
        self.firstName = cloudKitUser.firstName
        self.lastName = cloudKitUser.lastName
        self.emailAddress = cloudKitUser.emailAddress
    }
}

struct ZoneInfo: Encodable {
    let zoneName: String
    let ownerRecordName: String?
    let capabilities: [String]
    
    init(from zone: Components.Schemas.Zone) {
        self.zoneName = zone.zoneID?.zoneName ?? "Unknown"
        self.ownerRecordName = zone.zoneID?.ownerRecordName
        self.capabilities = zone.capabilities ?? []
    }
}

struct RecordInfo: Encodable {
    let recordName: String
    let recordType: String
    let fields: [String: String]
    let created: Date?
    let modified: Date?
    
    init(from record: Components.Schemas.Record) {
        self.recordName = record.recordName ?? "Unknown"
        self.recordType = record.recordType ?? "Unknown"
        
        // Convert fields to simple string representation
        var simpleFields: [String: String] = [:]
        if let fields = record.fields {
            for (key, field) in fields {
                if let value = field.value {
                    simpleFields[key] = "\(value)"
                }
            }
        }
        self.fields = simpleFields
        
        self.created = record.created?.recordTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
        self.modified = record.modified?.recordTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
    }
}

enum CloudKitError: LocalizedError {
    case httpError(statusCode: Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode):
            return "CloudKit API error: HTTP \(statusCode)"
        case .invalidResponse:
            return "Invalid response from CloudKit"
        }
    }
}