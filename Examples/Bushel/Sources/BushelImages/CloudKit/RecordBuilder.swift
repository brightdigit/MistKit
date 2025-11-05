import Foundation
import MistKit

/// Builds CloudKit record operations from model types using public MistKit APIs
enum RecordBuilder {
    /// Build a record operation for RestoreImageRecord
    static func buildRestoreImageOperation(
        _ record: RestoreImageRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "buildNumber": .string(record.buildNumber),
            "releaseDate": .date(record.releaseDate),
            "downloadURL": .string(record.downloadURL),
            "fileSize": .int64(Int(record.fileSize)),
            "sha256Hash": .string(record.sha256Hash),
            "sha1Hash": .string(record.sha1Hash),
            "isSigned": .int64(record.isSigned ? 1 : 0),
            "isPrerelease": .int64(record.isPrerelease ? 1 : 0),
            "source": .string(record.source)
        ]

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
    static func buildXcodeVersionOperation(
        _ record: XcodeVersionRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "buildNumber": .string(record.buildNumber),
            "releaseDate": .date(record.releaseDate),
            "isPrerelease": .int64(record.isPrerelease ? 1 : 0)
        ]

        if let downloadURL = record.downloadURL {
            fields["downloadURL"] = .string(downloadURL)
        }

        if let fileSize = record.fileSize {
            fields["fileSize"] = .int64(Int(fileSize))
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
    static func buildSwiftVersionOperation(
        _ record: SwiftVersionRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "releaseDate": .date(record.releaseDate),
            "isPrerelease": .int64(record.isPrerelease ? 1 : 0)
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
}
