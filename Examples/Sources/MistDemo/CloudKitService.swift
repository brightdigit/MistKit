import Foundation
import MistKit
import OpenAPIRuntime
import OpenAPIURLSession

struct CloudKitService {
    let containerIdentifier: String
    let apiToken: String
    let environment: String = "development"
    
    private var mistKitClient: MistKitClient?
    private var client: Client {
        return mistKitClient!.client
    }
    
    init(containerIdentifier: String, apiToken: String) throws {
        self.containerIdentifier = containerIdentifier
        self.apiToken = apiToken
    }
    
    mutating func setWebAuthToken(_ token: String) throws {
        let config = MistKitConfiguration(
            container: containerIdentifier,
            environment: .development,
            database: .private,
            apiToken: apiToken,
            webAuthToken: token
        )
        self.mistKitClient = try MistKitClient(configuration: config)
    }
    
    /// Fetch current user information
    func fetchCurrentUser() async throws -> UserInfo {
        // Create the request to get current user
        let response = try await client.get_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol_public_sol_users_sol_current(
            .init(
                path: .init(
                    version: "1",
                    container: containerIdentifier,
                    environment: .development
                )
            )
        )
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let userData):
                return UserInfo(from: userData)
            }
        case .unauthorized:
            throw CloudKitError.httpError(statusCode: 401)
        case .undocumented(let statusCode, _):
            throw CloudKitError.httpError(statusCode: statusCode)
        }
    }
    
    /// List zones in the user's private database
    func listZones() async throws -> [ZoneInfo] {
        let response = try await client.get_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_zones_sol_list(
            .init(
                path: .init(
                    version: "1",
                    container: containerIdentifier,
                    environment: .development,
                    database: ._private
                )
            )
        )
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let zonesData):
                return zonesData.zones?.compactMap { zone in
                    guard let zoneID = zone.zoneID else { return nil }
                    return ZoneInfo(
                        zoneName: zoneID.zoneName ?? "Unknown",
                        ownerRecordName: zoneID.ownerName,
                        capabilities: []
                    )
                } ?? []
            }
        case .badRequest:
            throw CloudKitError.httpError(statusCode: 400)
        case .unauthorized:
            throw CloudKitError.httpError(statusCode: 401)
        case .undocumented(let statusCode, _):
            throw CloudKitError.httpError(statusCode: statusCode)
        }
    }
    
    /// Query records from the default zone
    func queryRecords(recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
        let response = try await client.post_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_records_sol_query(
            .init(
                path: .init(
                    version: "1",
                    container: containerIdentifier,
                    environment: .development,
                    database: ._private
                ),
                body: .json(.init(
                    zoneID: .init(zoneName: "_defaultZone"),
                    resultsLimit: limit,
                    query: .init(
                        recordType: recordType,
                        sortBy: [
                            .init(
                                fieldName: "modificationDate",
                                ascending: false
                            )
                        ]
                    )
                ))
            )
        )
        
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let recordsData):
                return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
            }
        case .badRequest:
            throw CloudKitError.httpError(statusCode: 400)
        case .unauthorized:
            throw CloudKitError.httpError(statusCode: 401)
        case .undocumented(let statusCode, _):
            throw CloudKitError.httpError(statusCode: statusCode)
        }
    }
}

// Helper models
struct UserInfo: Encodable {
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
    
    init(zoneName: String, ownerRecordName: String?, capabilities: [String]) {
        self.zoneName = zoneName
        self.ownerRecordName = ownerRecordName
        self.capabilities = capabilities
    }
}

struct RecordInfo: Encodable {
    let recordName: String
    let recordType: String
    let fields: [String: String]
    
    init(from record: Components.Schemas.Record) {
        self.recordName = record.recordName ?? "Unknown"
        self.recordType = record.recordType ?? "Unknown"
        
        // Convert fields to simple string representation
        let simpleFields: [String: String] = [:]
        // Note: fields is a special structure in the generated code
        // For now, we'll leave it empty as the exact structure needs investigation
        self.fields = simpleFields
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