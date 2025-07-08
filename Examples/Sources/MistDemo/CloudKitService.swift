import Foundation
import MistKit
import OpenAPIRuntime
import OpenAPIURLSession

struct CloudKitService {
    let containerIdentifier: String
    let apiToken: String
    let environment: String = "development"
    
    private let mistKitClient: MistKitClient
    private var client: Client {
        return mistKitClient.client
    }
    
    init(containerIdentifier: String, apiToken: String, webAuthToken: String) throws {
        self.containerIdentifier = containerIdentifier
        self.apiToken = apiToken
        
        let config = MistKitConfiguration(
            container: containerIdentifier,
            environment: .development,
            database: .private,
            apiToken: apiToken,
            webAuthToken: webAuthToken
        )
        self.mistKitClient = try MistKitClient(configuration: config)
    }
    
    /// Fetch current user information
    func fetchCurrentUser() async throws -> UserInfo {
        // Create the request to get current user
        let response = try await client.getCurrentUser(
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
            case .json(let userData):
                return UserInfo(from: userData)
            }
        case .unauthorized(let unauthorizedResponse):
            // Try to extract error details from the response body
            if case .json(let errorResponse) = unauthorizedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 401,
                    serverErrorCode: errorResponse.serverErrorCode,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 401)
            }
        case .undocumented(let statusCode, let undocumentedResponse):
            // Try to decode the response body as an error response
            if let responseBody = undocumentedResponse.body {
                let errorData: Data
                do {
                    errorData = try await Data(collecting: responseBody, upTo: 1024 * 1024) // 1MB limit
                } catch {
                    throw CloudKitError.httpError(statusCode: statusCode)
                }
                
                do {
                    let errorResponse = try JSONDecoder().decode(Components.Schemas.ErrorResponse.self, from: errorData)
                    throw CloudKitError.httpErrorWithDetails(
                        statusCode: statusCode,
                        serverErrorCode: errorResponse.serverErrorCode,
                        reason: errorResponse.reason
                    )
                } catch {
                    // If we can't decode as ErrorResponse, try to get raw text
                    if let errorText = String(data: errorData, encoding: .utf8) {
                        throw CloudKitError.httpErrorWithRawResponse(statusCode: statusCode, rawResponse: errorText)
                    } else {
                        throw CloudKitError.httpError(statusCode: statusCode)
                    }
                }
            } else {
                throw CloudKitError.httpError(statusCode: statusCode)
            }
        }
    }
    
    /// List zones in the user's private database
    func listZones() async throws -> [ZoneInfo] {
        let response = try await client.listZones(
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
        case .badRequest(let badRequestResponse):
            if case .json(let errorResponse) = badRequestResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 400,
                    serverErrorCode: errorResponse.serverErrorCode,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 400)
            }
        case .unauthorized(let unauthorizedResponse):
            if case .json(let errorResponse) = unauthorizedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 401,
                    serverErrorCode: errorResponse.serverErrorCode,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 401)
            }
        case .undocumented(let statusCode, let undocumentedResponse):
            if let responseBody = undocumentedResponse.body {
                let errorData: Data
                do {
                    errorData = try await Data(collecting: responseBody, upTo: 1024 * 1024)
                } catch {
                    throw CloudKitError.httpError(statusCode: statusCode)
                }
                
                do {
                    let errorResponse = try JSONDecoder().decode(Components.Schemas.ErrorResponse.self, from: errorData)
                    throw CloudKitError.httpErrorWithDetails(
                        statusCode: statusCode,
                        serverErrorCode: errorResponse.serverErrorCode,
                        reason: errorResponse.reason
                    )
                } catch {
                    if let errorText = String(data: errorData, encoding: .utf8) {
                        throw CloudKitError.httpErrorWithRawResponse(statusCode: statusCode, rawResponse: errorText)
                    } else {
                        throw CloudKitError.httpError(statusCode: statusCode)
                    }
                }
            } else {
                throw CloudKitError.httpError(statusCode: statusCode)
            }
        }
    }
    
    /// Query records from the default zone
    func queryRecords(recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
        let response = try await client.queryRecords(
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
        case .badRequest(let badRequestResponse):
            if case .json(let errorResponse) = badRequestResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 400,
                    serverErrorCode: errorResponse.serverErrorCode,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 400)
            }
        case .unauthorized(let unauthorizedResponse):
            if case .json(let errorResponse) = unauthorizedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 401,
                    serverErrorCode: errorResponse.serverErrorCode,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 401)
            }
        case .undocumented(let statusCode, let undocumentedResponse):
            if let responseBody = undocumentedResponse.body {
                let errorData: Data
                do {
                    errorData = try await Data(collecting: responseBody, upTo: 1024 * 1024)
                } catch {
                    throw CloudKitError.httpError(statusCode: statusCode)
                }
                
                do {
                    let errorResponse = try JSONDecoder().decode(Components.Schemas.ErrorResponse.self, from: errorData)
                    throw CloudKitError.httpErrorWithDetails(
                        statusCode: statusCode,
                        serverErrorCode: errorResponse.serverErrorCode,
                        reason: errorResponse.reason
                    )
                } catch {
                    if let errorText = String(data: errorData, encoding: .utf8) {
                        throw CloudKitError.httpErrorWithRawResponse(statusCode: statusCode, rawResponse: errorText)
                    } else {
                        throw CloudKitError.httpError(statusCode: statusCode)
                    }
                }
            } else {
                throw CloudKitError.httpError(statusCode: statusCode)
            }
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
    case httpErrorWithDetails(statusCode: Int, serverErrorCode: String?, reason: String?)
    case httpErrorWithRawResponse(statusCode: Int, rawResponse: String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode):
            return "CloudKit API error: HTTP \(statusCode)"
        case .httpErrorWithDetails(let statusCode, let serverErrorCode, let reason):
            var message = "CloudKit API error: HTTP \(statusCode)"
            if let serverErrorCode = serverErrorCode {
                message += "\nServer Error Code: \(serverErrorCode)"
            }
            if let reason = reason {
                message += "\nReason: \(reason)"
            }
            return message
        case .httpErrorWithRawResponse(let statusCode, let rawResponse):
            return "CloudKit API error: HTTP \(statusCode)\nRaw Response: \(rawResponse)"
        case .invalidResponse:
            return "Invalid response from CloudKit"
        }
    }
}
