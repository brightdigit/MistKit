//
//  MistDemoKeys+Record.swift
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

internal import ConfigKeyKit
internal import MistKit

extension MistDemoKeys {
  /// Record identity and payload keys shared by the CRUD commands.
  internal enum Record {
    /// `--record-type` / `CLOUDKIT_RECORD_TYPE`.
    ///
    /// The former `record.type` and `record-type` spellings both encoded to this same
    /// flag and variable, so they were already aliases; they are unified here.
    internal static let recordType = ConfigKey<String>(
      "record-type",
      envPrefix: MistDemoKeys.envPrefix,
      default: MistDemoConstants.Defaults.recordType
    )

    /// `--record-type` without a default, for commands where it is optional.
    internal static let optionalRecordType = OptionalConfigKey<String>(
      "record-type", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--alternate-record-type` / `CLOUDKIT_ALTERNATE_RECORD_TYPE`.
    internal static let alternateRecordType = ConfigKey<String>(
      "alternate-record-type", envPrefix: MistDemoKeys.envPrefix, default: "Article"
    )

    /// `--record-name` / `CLOUDKIT_RECORD_NAME`.
    internal static let recordName = OptionalConfigKey<String>(
      "record-name", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--record-names` / `CLOUDKIT_RECORD_NAMES`, comma separated.
    internal static let recordNames = OptionalConfigKey<String>(
      "record.names", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--record-change-tag` / `CLOUDKIT_RECORD_CHANGE_TAG`.
    internal static let recordChangeTag = OptionalConfigKey<String>(
      "record.change.tag", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--fields` / `CLOUDKIT_FIELDS`.
    internal static let fields = OptionalConfigKey<String>(
      "fields", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--field` / `CLOUDKIT_FIELD`, repeated or comma separated.
    internal static let field = OptionalConfigKey<String>(
      "field", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--json-file` / `CLOUDKIT_JSON_FILE`.
    internal static let jsonFile = OptionalConfigKey<String>(
      "json.file", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--operations-file` / `CLOUDKIT_OPERATIONS_FILE`.
    internal static let operationsFile = OptionalConfigKey<String>(
      "operations.file", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--stdin` / `CLOUDKIT_STDIN`.
    internal static let stdin = ConfigKey<Bool>(
      "stdin", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--force` / `CLOUDKIT_FORCE`.
    internal static let force = ConfigKey<Bool>(
      "force", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--atomic` / `CLOUDKIT_ATOMIC`.
    internal static let atomic = ConfigKey<Bool>(
      "atomic", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--batch-size` / `CLOUDKIT_BATCH_SIZE`.
    internal static let batchSize = ConfigKey<Int>(
      "batch.size",
      envPrefix: MistDemoKeys.envPrefix,
      default: CloudKitService.maxRecordsPerRequest
    )

    /// `--numbers-as-strings` / `CLOUDKIT_NUMBERS_AS_STRINGS`.
    internal static let numbersAsStrings = OptionalConfigKey<Bool>(
      "numbers.as.strings", envPrefix: MistDemoKeys.envPrefix
    )
  }
}
