import Foundation
import MistKit
import OpenAPIRuntime

@main
struct MistDemo {
    static func main() async throws {
        let arguments = CommandLine.arguments
        
        // Check for required API token
        guard arguments.count >= 2 else {
            print("❌ Error: API token is required")
            print("Usage: MistDemo <api-token> [container]")
            print("Example: MistDemo your-api-token-here iCloud.com.brightdigit.MistDemo")
            return
        }
        
        let apiToken = arguments[1]
        let container = arguments.count >= 3 ? arguments[2] : "iCloud.com.brightdigit.MistDemo"
        
        print("🚀 MistKit Demo - CloudKit Web Services Example")
        print("Container: \(container)")
        print("API Token: \(String(apiToken.prefix(8)))...")
        
        // Configure MistKit client
        let configuration = MistKitConfiguration(
            container: container,
            environment: .development,
            database: .private,
            apiToken: apiToken
        )
        
        do {
            let client = try MistKitClient(configuration: configuration)
            
            // Example: Query records
            print("\n📋 Example: Query Records")
            do {
                let queryInput = Operations.post_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_records_sol_query.Input.Body.jsonPayload(
                    query: .init(
                        recordType: "ExampleRecord",
                        filterBy: [],
                        sortBy: []
                    )
                )
                
                let operation = Operations.post_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_records_sol_query.Input(
                    path: .init(
                        version: configuration.version,
                        container: configuration.container,
                        environment: configuration.environment == .development ? .development : .production,
                        database: configuration.database == .public ? ._public : (configuration.database == .private ? ._private : .shared)
                    ),
                    body: .json(queryInput)
                )
                
                let response = try await client.client.post_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_records_sol_query(operation)
                
                switch response {
                case .ok(let okResponse):
                    switch okResponse.body {
                    case .json(let queryResponse):
                        print("✅ Query successful - found \(queryResponse.records?.count ?? 0) records")
                        if let records = queryResponse.records {
                            for record in records {
                                print("  - Record: \(record.recordName ?? "unknown")")
                            }
                        }
                    }
                case .badRequest(let badRequest):
                    print("❌ Query failed: Bad request")
                case .unauthorized(let unauthorized):
                    print("❌ Query failed: Unauthorized")
                case .undocumented(let statusCode, _):
                    print("❌ Query failed with status: \(statusCode)")
                }
            } catch {
                print("❌ Query error: \(error)")
            }
            
            // Example: List zones
            print("\n🗂️ Example: List Zones")
            do {
                let zonesOperation = Operations.get_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_zones_sol_list.Input(
                    path: .init(
                        version: configuration.version,
                        container: configuration.container,
                        environment: configuration.environment == .development ? .development : .production,
                        database: configuration.database == .public ? ._public : (configuration.database == .private ? ._private : .shared)
                    )
                )
                
                let zonesResponse = try await client.client.get_sol_database_sol__lcub_version_rcub__sol__lcub_container_rcub__sol__lcub_environment_rcub__sol__lcub_database_rcub__sol_zones_sol_list(zonesOperation)
                
                switch zonesResponse {
                case .ok(let okResponse):
                    switch okResponse.body {
                    case .json(let listResponse):
                        print("✅ Zones retrieved - found \(listResponse.zones?.count ?? 0) zones")
                        if let zones = listResponse.zones {
                            for zone in zones {
                                print("  - Zone: \(zone.zoneID?.zoneName ?? "unknown")")
                            }
                        }
                    }
                case .badRequest(let badRequest):
                    print("❌ List zones failed: Bad request")
                case .unauthorized(let unauthorized):
                    print("❌ List zones failed: Unauthorized")
                case .undocumented(let statusCode, _):
                    print("❌ List zones failed with status: \(statusCode)")
                }
            } catch {
                print("❌ List zones error: \(error)")
            }
            
            print("\n✅ MistKit CloudKit operations completed!")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            throw error
        }
    }
}