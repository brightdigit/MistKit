import Foundation
import MistKit

/// Builds CloudKit record operations from model types using public MistKit APIs
///
/// **Deprecated**: Use the `CloudKitRecord` protocol instead. Models now implement
/// `toCloudKitFields()` directly, and the generic `sync<T>()` method handles conversion.
@available(*, deprecated, message: "Use CloudKitRecord protocol and model.toCloudKitFields() instead")
enum RecordBuilder {
    /// Build a record operation for RestoreImageRecord
    @available(*, deprecated, message: "Use RestoreImageRecord.toCloudKitFields() via CloudKitRecord protocol")
    static func buildRestoreImageOperation(
        _ record: RestoreImageRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "buildNumber": .string(record.buildNumber),
            "releaseDate": .date(record.releaseDate),
            "downloadURL": .string(record.downloadURL),
            "fileSize": .int64(record.fileSize),
            "sha256Hash": .string(record.sha256Hash),
            "sha1Hash": .string(record.sha1Hash),
            "isPrerelease": .boolean(record.isPrerelease),
            "source": .string(record.source)
        ]

        // Only include isSigned if we have a known value
        if let isSigned = record.isSigned {
            fields["isSigned"] = .boolean(isSigned)
        }

        if let notes = record.notes {
            fields["notes"] = .string(notes)
        }

        return RecordOperation(
            operationType: .forceReplace,
            recordType: "RestoreImage",
            recordName: record.recordName,
            fields: fields
        )
    }

    /// Build a record operation for XcodeVersionRecord
    @available(*, deprecated, message: "Use XcodeVersionRecord.toCloudKitFields() via CloudKitRecord protocol")
    static func buildXcodeVersionOperation(
        _ record: XcodeVersionRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "buildNumber": .string(record.buildNumber),
            "releaseDate": .date(record.releaseDate),
            "isPrerelease": .boolean(record.isPrerelease)
        ]

        if let downloadURL = record.downloadURL {
            fields["downloadURL"] = .string(downloadURL)
        }

        if let fileSize = record.fileSize {
            fields["fileSize"] = .int64(fileSize)
        }

        if let minimumMacOS = record.minimumMacOS {
            fields["minimumMacOS"] = .reference(FieldValue.Reference(
                recordName: minimumMacOS,
                action: nil
            ))
        }

        if let includedSwiftVersion = record.includedSwiftVersion {
            fields["includedSwiftVersion"] = .reference(FieldValue.Reference(
                recordName: includedSwiftVersion,
                action: nil
            ))
        }

        if let sdkVersions = record.sdkVersions {
            fields["sdkVersions"] = .string(sdkVersions)
        }

        if let notes = record.notes {
            fields["notes"] = .string(notes)
        }

        return RecordOperation(
            operationType: .forceReplace,
            recordType: "XcodeVersion",
            recordName: record.recordName,
            fields: fields
        )
    }

    /// Build a record operation for SwiftVersionRecord
    @available(*, deprecated, message: "Use SwiftVersionRecord.toCloudKitFields() via CloudKitRecord protocol")
    static func buildSwiftVersionOperation(
        _ record: SwiftVersionRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "releaseDate": .date(record.releaseDate),
            "isPrerelease": .boolean(record.isPrerelease)
        ]

        if let downloadURL = record.downloadURL {
            fields["downloadURL"] = .string(downloadURL)
        }

        if let notes = record.notes {
            fields["notes"] = .string(notes)
        }

        return RecordOperation(
            operationType: .forceReplace,
            recordType: "SwiftVersion",
            recordName: record.recordName,
            fields: fields
        )
    }

    /// Build a record operation for DataSourceMetadata
    @available(*, deprecated, message: "Use DataSourceMetadata.toCloudKitFields() via CloudKitRecord protocol")
    static func buildDataSourceMetadataOperation(
        _ metadata: DataSourceMetadata
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "sourceName": .string(metadata.sourceName),
            "recordTypeName": .string(metadata.recordTypeName),
            "lastFetchedAt": .date(metadata.lastFetchedAt),
            "recordCount": .int64(metadata.recordCount),
            "fetchDurationSeconds": .double(metadata.fetchDurationSeconds)
        ]

        if let sourceUpdatedAt = metadata.sourceUpdatedAt {
            fields["sourceUpdatedAt"] = .date(sourceUpdatedAt)
        }

        if let lastError = metadata.lastError {
            fields["lastError"] = .string(lastError)
        }

        return RecordOperation(
            operationType: .forceReplace,
            recordType: "DataSourceMetadata",
            recordName: metadata.recordName,
            fields: fields
        )
    }
}
