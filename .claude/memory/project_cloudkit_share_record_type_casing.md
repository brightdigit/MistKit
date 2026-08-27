# cloudkit.share wire casing

Apple's archived CloudKit Web Services "Sharing Records" docs write the share record type as `cloudKit.share`. The live `records/modify` API only accepts / returns `cloudkit.share` (lowercase `k`).

Creating with `cloudKit.share` fails with `Cannot share - no such record exists to share` even when the root exists with `shortGUID` + `stableUrl`. Creating with `cloudkit.share` succeeds (share-only atomic modify after root create with `createShortGUID: true` + `forRecord.recordChangeTag`).

MistKit constant: `ShareInfo.recordType == "cloudkit.share"`.
