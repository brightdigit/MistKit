import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public struct CloudKitService {
    let containerIdentifier: String
    let apiToken: String
    let environment: String = "development"
    
    private let mistKitClient: MistKitClient
    private var client: Client {
        return mistKitClient.client
    }
    
   public init(containerIdentifier: String, apiToken: String, webAuthToken: String) throws {
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
   public func fetchCurrentUser() async throws -> UserInfo {
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
        case .badRequest(let badRequestResponse):
            if case .json(let errorResponse) = badRequestResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 400,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 400)
            }
        case .unauthorized(let unauthorizedResponse):
            // Try to extract error details from the response body
            if case .json(let errorResponse) = unauthorizedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 401,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 401)
            }
        case .forbidden(let forbiddenResponse):
            if case .json(let errorResponse) = forbiddenResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 403,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 403)
            }
        case .notFound(let notFoundResponse):
            if case .json(let errorResponse) = notFoundResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 404,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 404)
            }
        case .conflict(let conflictResponse):
            if case .json(let errorResponse) = conflictResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 409,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 409)
            }
        case .preconditionFailed(let preconditionFailedResponse):
            if case .json(let errorResponse) = preconditionFailedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 412,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 412)
            }
        case .contentTooLarge(let contentTooLargeResponse):
            if case .json(let errorResponse) = contentTooLargeResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 413,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 413)
            }
        case .tooManyRequests(let tooManyRequestsResponse):
            if case .json(let errorResponse) = tooManyRequestsResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 429,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 429)
            }
        case .misdirectedRequest(let misdirectedRequestResponse):
            if case .json(let errorResponse) = misdirectedRequestResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 421,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 421)
            }
        case .internalServerError(let internalServerErrorResponse):
            if case .json(let errorResponse) = internalServerErrorResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 500,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 500)
            }
        case .serviceUnavailable(let serviceUnavailableResponse):
            if case .json(let errorResponse) = serviceUnavailableResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 503,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 503)
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
                        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
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
  public func listZones() async throws -> [ZoneInfo] {
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
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 400)
            }
        case .unauthorized(let unauthorizedResponse):
            if case .json(let errorResponse) = unauthorizedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 401,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 401)
            }
        case .forbidden(let forbiddenResponse):
            if case .json(let errorResponse) = forbiddenResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 403,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 403)
            }
        case .notFound(let notFoundResponse):
            if case .json(let errorResponse) = notFoundResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 404,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 404)
            }
        case .conflict(let conflictResponse):
            if case .json(let errorResponse) = conflictResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 409,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 409)
            }
        case .preconditionFailed(let preconditionFailedResponse):
            if case .json(let errorResponse) = preconditionFailedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 412,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 412)
            }
        case .contentTooLarge(let contentTooLargeResponse):
            if case .json(let errorResponse) = contentTooLargeResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 413,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 413)
            }
        case .tooManyRequests(let tooManyRequestsResponse):
            if case .json(let errorResponse) = tooManyRequestsResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 429,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 429)
            }
        case .misdirectedRequest(let misdirectedRequestResponse):
            if case .json(let errorResponse) = misdirectedRequestResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 421,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 421)
            }
        case .internalServerError(let internalServerErrorResponse):
            if case .json(let errorResponse) = internalServerErrorResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 500,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 500)
            }
        case .serviceUnavailable(let serviceUnavailableResponse):
            if case .json(let errorResponse) = serviceUnavailableResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 503,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 503)
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
                        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
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
  public func queryRecords(recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
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
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 400)
            }
        case .unauthorized(let unauthorizedResponse):
            if case .json(let errorResponse) = unauthorizedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 401,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 401)
            }
        case .forbidden(let forbiddenResponse):
            if case .json(let errorResponse) = forbiddenResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 403,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 403)
            }
        case .notFound(let notFoundResponse):
            if case .json(let errorResponse) = notFoundResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 404,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 404)
            }
        case .conflict(let conflictResponse):
            if case .json(let errorResponse) = conflictResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 409,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 409)
            }
        case .preconditionFailed(let preconditionFailedResponse):
            if case .json(let errorResponse) = preconditionFailedResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 412,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 412)
            }
        case .contentTooLarge(let contentTooLargeResponse):
            if case .json(let errorResponse) = contentTooLargeResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 413,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 413)
            }
        case .tooManyRequests(let tooManyRequestsResponse):
            if case .json(let errorResponse) = tooManyRequestsResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 429,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 429)
            }
        case .misdirectedRequest(let misdirectedRequestResponse):
            if case .json(let errorResponse) = misdirectedRequestResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 421,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 421)
            }
        case .internalServerError(let internalServerErrorResponse):
            if case .json(let errorResponse) = internalServerErrorResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 500,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 500)
            }
        case .serviceUnavailable(let serviceUnavailableResponse):
            if case .json(let errorResponse) = serviceUnavailableResponse.body {
                throw CloudKitError.httpErrorWithDetails(
                    statusCode: 503,
                    serverErrorCode: errorResponse.serverErrorCode?.rawValue,
                    reason: errorResponse.reason
                )
            } else {
                throw CloudKitError.httpError(statusCode: 503)
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
                        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
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

