//
//  MistDemoConstants.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

/// Central constants for MistDemo application.
public enum MistDemoConstants {
  // MARK: - Configuration Keys

  /// Configuration key names used throughout the application.
  public enum ConfigKeys {
    /// API token configuration key.
    public static let apiToken = "api.token"
    /// Web auth token configuration key.
    public static let webAuthToken = "web.auth.token"
    /// Container ID configuration key.
    public static let containerID = "container.id"
    /// Environment configuration key.
    public static let environment = "environment"
    /// Database configuration key.
    public static let database = "database"
    /// Record type configuration key.
    public static let recordType = "record.type"
    /// Record name configuration key.
    public static let recordName = "record.name"
    /// Zone configuration key.
    public static let zone = "zone"
    /// Zone owner configuration key (ownerName for shared zones).
    public static let zoneOwner = "zone.owner"
    /// Limit configuration key.
    public static let limit = "limit"
    /// Fields configuration key.
    public static let fields = "fields"
    /// Output format configuration key.
    public static let outputFormat = "output.format"
    /// Sort configuration key.
    public static let sort = "sort"
    /// Filter configuration key.
    public static let filter = "filter"
    /// No-browser configuration key.
    public static let noBrowser = "no.browser"
    /// Host configuration key.
    public static let host = "host"
    /// Port configuration key.
    public static let port = "port"
    /// JSON file configuration key.
    public static let jsonFile = "json.file"
    /// Stdin configuration key.
    public static let stdin = "stdin"
    /// Record change tag configuration key.
    public static let recordChangeTag = "record.change.tag"
    /// Force configuration key.
    public static let force = "force"
    /// Record names configuration key.
    public static let recordNames = "record.names"
    /// Operations file configuration key.
    public static let operationsFile = "operations.file"
    /// Atomic configuration key.
    public static let atomic = "atomic"
    /// Batch size configuration key for the auto-chunking `*-all` commands.
    public static let batchSize = "batch.size"
    /// Zone-wide query configuration key (query across all zones).
    public static let zoneWide = "zone.wide"
    /// Numbers-as-strings configuration key (return numeric fields as strings).
    public static let numbersAsStrings = "numbers.as.strings"
    /// Desired record types configuration key (limits the change feed).
    public static let desiredRecordTypes = "record.types"
  }

  // MARK: - Field Names

  /// Standard CloudKit field names.
  public enum FieldNames {
    /// Record name field.
    public static let recordName = "recordName"
    /// Record type field.
    public static let recordType = "recordType"
    /// Record change tag field.
    public static let recordChangeTag = "recordChangeTag"
    /// User record name field.
    public static let userRecordName = "userRecordName"
    /// First name field.
    public static let firstName = "firstName"
    /// Last name field.
    public static let lastName = "lastName"
    /// Email address field.
    public static let emailAddress = "emailAddress"
    /// Created timestamp field.
    public static let created = "created"
    /// Modified timestamp field.
    public static let modified = "modified"
    /// Record ID field.
    public static let recordID = "recordID"
  }

  // MARK: - CloudKit Parameters

  /// CloudKit API parameter names.
  public enum CloudKitParams {
    /// Query parameter.
    public static let query = "query"
    /// Zone ID parameter.
    public static let zoneID = "zoneID"
    /// Results limit parameter.
    public static let resultsLimit = "resultsLimit"
    /// Desired keys parameter.
    public static let desiredKeys = "desiredKeys"
    /// Sort-by parameter.
    public static let sortBy = "sortBy"
    /// Filter-by parameter.
    public static let filterBy = "filterBy"
    /// Continuation marker parameter.
    public static let continuationMarker = "continuationMarker"
  }

  // MARK: - API Paths

  /// API endpoint paths.
  public enum APIPaths {
    /// API base path.
    public static let api = "api"
    /// Authenticate path.
    public static let authenticate = "authenticate"
  }

  // MARK: - Content Types

  /// HTTP content types.
  public enum ContentTypes {
    /// JSON content type.
    public static let json = "application/json"
    /// HTML content type.
    public static let html = "text/html"
    /// CSS content type.
    public static let css = "text/css"
    /// JavaScript content type.
    public static let javascript = "application/javascript"
  }

  // MARK: - Resource Files

  /// Resource file names.
  public enum Resources {
    /// Index HTML filename.
    public static let indexHTML = "index.html"
    /// Resources folder name.
    public static let resourcesFolder = "Resources"
    /// Sources folder name.
    public static let sourcesFolder = "Sources"
    /// MistDemo folder name.
    public static let mistDemoFolder = "MistDemo"
  }

  // MARK: - Command Names

  /// CLI command names.
  public enum Commands {
    /// Query command name.
    public static let query = "query"
    /// Create command name.
    public static let create = "create"
    /// Update command name.
    public static let update = "update"
    /// Current-user command name.
    public static let currentUser = "current-user"
    /// Auth-token command name.
    public static let authToken = "auth-token"
  }

  // MARK: - Environment Variables

  /// Environment variable names.
  public enum EnvironmentVars {
    /// CloudKit API token environment variable.
    public static let cloudKitAPIToken = "CLOUDKIT_API_TOKEN"
    /// CloudKit web auth token environment variable.
    public static let cloudKitWebAuthToken =
      "CLOUDKIT_WEB_AUTH_TOKEN"
    /// CloudKit container ID environment variable.
    public static let cloudKitContainerID =
      "CLOUDKIT_CONTAINER_ID"
    /// CloudKit environment environment variable.
    public static let cloudKitEnvironment =
      "CLOUDKIT_ENVIRONMENT"
    /// CloudKit database environment variable.
    public static let cloudKitDatabase = "CLOUDKIT_DATABASE"
  }
}
