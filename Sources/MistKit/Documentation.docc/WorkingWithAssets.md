# Working with Assets

Upload files to CloudKit's asset CDN, attach them to records, download them again and share one stored file between records.

## Overview

A CloudKit asset field doesn't hold the file's bytes. The bytes live on Apple's asset CDN (`cvws.icloud-content.com`), and the record holds an ``Asset`` descriptor that points at them. Writing an asset is therefore always two network trips before the record write:

1. Ask CloudKit for a one-time upload URL for a given record type and field (`assets/upload`).
2. Send the bytes to that URL on the CDN. The CDN answers with a receipt and checksum.

Only then do you create or update the record, putting the returned ``Asset`` in its asset field. MistKit exposes each step on its own and also chains the two uploads:

| Method | Does |
| --- | --- |
| ``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:zoneID:using:database:)`` | Both upload steps, returning an ``AssetUploadReceipt`` |
| ``CloudKitService/requestAssetUploadURL(recordType:fieldName:recordName:zoneID:database:)`` | Step 1 only, returning an ``AssetUploadToken`` |
| ``CloudKitService/uploadAssetData(_:to:using:)`` | Step 2 only, returning an ``Asset`` |

Reading goes the other way: a record fetched from CloudKit carries an ``Asset`` whose ``Asset/downloadURL`` points at the CDN, and ``Asset/download(using:)`` fetches the bytes.

The upload, attach, download and re-reference flows below are all exercised against a live container by MistDemo (`Examples/MistDemo`), both through its `upload-asset` command and the `test-public` / `test-private` integration phases.

## Uploading and attaching an asset

``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:zoneID:using:database:)`` runs both upload steps and returns an ``AssetUploadReceipt``. Its ``AssetUploadReceipt/asset`` is what goes into the record; ``AssetUploadReceipt/recordName`` and ``AssetUploadReceipt/fieldName`` echo what CloudKit associated the upload with. As with every other operation, `database:` has no default.

```swift
let imageData = try Data(contentsOf: imageURL)

let receipt = try await service.uploadAssets(
  data: imageData,
  recordType: "Photo",
  fieldName: "image",
  database: .private
)

let photo = try await service.createRecord(
  recordType: "Photo",
  fields: [
    "title": .string(.value("Sunset")),
    receipt.fieldName: .asset(.value(receipt.asset)),
  ],
  database: .private
)
```

An asset field takes the same ``FieldValue/Arity`` wrapper as every other kind, so a single asset is `.asset(.value(asset))` and an asset list is `.asset(.list([first, second]))`.

This is what MistDemo's `upload-asset` command does: it reads the file, uploads it, then creates a record that holds the asset, or updates an existing one when you pass `--record-name`.

```bash
cd Examples/MistDemo
swift run mistdemo upload-asset --file photo.jpg \
  --record-type Photo --field-name thumbnail
```

Two limits apply to every upload:

- **Upload URLs expire after 15 minutes.** Request the URL close to when you send the bytes; ``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:zoneID:using:database:)`` does this for you.
- **Each asset is capped at 15 MiB** (``CloudKitService/maxAssetUploadBytes``). MistKit doesn't check the size before sending. The CDN rejects an oversized upload with a bare HTTP 413 instead of a CloudKit JSON error, and MistKit turns that into ``CloudKitError/quotaExceeded(reason:hint:)`` carrying ``QuotaHint/assetExceedsSizeLimit(dataBytes:maxBytes:)``, so you can tell an oversized file apart from a full iCloud account.

### Updating an existing record

To put a new file on a record that already exists, pass that record's name when you upload, then update the record with the receipt's asset:

```swift
let receipt = try await service.uploadAssets(
  data: imageData,
  recordType: "Photo",
  fieldName: "image",
  recordName: photo.recordName,
  database: .private
)

let updated = try await service.updateRecord(
  recordType: "Photo",
  recordName: photo.recordName,
  fields: ["image": .asset(.value(receipt.asset))],
  recordChangeTag: photo.recordChangeTag,
  database: .private
)
```

### Assets in a custom zone

The upload URL is requested for a zone, and the record write that attaches the asset must target that same zone. Pass the same ``ZoneID`` to both calls:

```swift
let albumZone = ZoneID(zoneName: "Albums")

let receipt = try await service.uploadAssets(
  data: imageData,
  recordType: "Photo",
  fieldName: "image",
  zoneID: albumZone,
  database: .private
)

let photo = try await service.createRecord(
  recordType: "Photo",
  fields: ["image": .asset(.value(receipt.asset))],
  zoneID: albumZone,
  database: .private
)
```

Leave `zoneID` out of both to use the default zone. MistDemo's shared-zone round trip uploads with the shared zone's ``ZoneID`` (including its `ownerName`) against `.shared`, then updates the shared record with the same zone.

## Running the two steps yourself

Call the steps separately when you want to request the URL ahead of time or send the bytes some other way:

```swift
let token = try await service.requestAssetUploadURL(
  recordType: "Photo",
  fieldName: "image",
  database: .private
)

guard let uploadURL = token.url else {
  throw CloudKitError.invalidResponse
}

let asset = try await service.uploadAssetData(imageData, to: uploadURL)
```

``CloudKitService/uploadAssetData(_:to:using:)`` returns an ``Asset`` built from the CDN's JSON reply, which it decodes as an ``AssetUploadResponse``. The asset has ``Asset/receipt``, ``Asset/fileChecksum`` and ``Asset/size`` set and no ``Asset/downloadURL``, since CloudKit only issues a download URL once a record holds the asset.

## Keeping CDN uploads off the API transport

The CDN upload does **not** go through the `ClientTransport` the service uses for CloudKit API calls. By default it uses `URLSession.shared`, so the CDN gets its own connection pool.

> Warning: Never send asset bytes over the CloudKit API transport, and never write an ``AssetUploader`` that shares an HTTP/2 connection with `api.apple-cloudkit.com`. The API host and the CDN are different origins, and reusing one HTTP/2 connection for both makes the CDN answer 421 Misdirected Request.

One consequence is that a custom `transport:` passed to the service never sees asset bytes, so request logging installed there misses uploads. <doc:CloudKitLimitsAndPerformance#Asset-upload-transport> covers the connection-pool reasoning in full.

## Testing uploads with a custom uploader

Every upload method takes an optional ``AssetUploader``, a closure of type `(Data, URL) async throws -> (statusCode: Int?, data: Data)`. MistKit calls it in place of the default `URLSession` upload and decodes the returned data as the CDN's JSON reply. That makes it the seam for unit tests: return a canned reply and no network is touched.

```swift
let mockUploader: AssetUploader = { data, _ in
  let reply = """
    {"singleFile": {"fileChecksum": "AQID", "receipt": "test-receipt", "size": \(data.count)}}
    """
  return (statusCode: 200, data: Data(reply.utf8))
}

let asset = try await service.uploadAssetData(
  imageData,
  to: URL(string: "https://cvws.icloud-content.com/upload")!,
  using: mockUploader
)
```

A `nil` status code makes the upload throw ``CloudKitError/invalidResponse``, and any status outside `200...299` throws ``CloudKitError/httpError(statusCode:)``. Only replace the default uploader for tests or a specialised CDN setup. A production uploader has to keep the connection-pool separation described above.

## Downloading an asset

An ``Asset`` read back from CloudKit carries a ``Asset/downloadURL``. ``Asset/download(using:)`` fetches it with a plain GET and returns the bytes:

```swift
let results = try await service.lookupRecords(
  recordNames: [photo.recordName],
  database: .private
)

guard case .success(let record)? = results.first,
  case .asset(.value(let asset)) = record.fields["image"]
else {
  return
}

let bytes = try await asset.download()

if let declaredSize = asset.size, Int64(bytes.count) != declaredSize {
  // The download was truncated or otherwise incomplete.
}
```

The session defaults to `URLSession.shared`, which keeps downloads on the same CDN-side connection pool as uploads. Pass your own session to control caching or timeouts. It throws ``CloudKitError/missingAssetDownloadURL`` when the asset has no download URL, or one that isn't a valid absolute URL, and ``CloudKitError/httpError(statusCode:)`` for a non-success status.

### Downloaded bytes are not verified

``Asset/download(using:)`` returns the bytes **unverified**. Compare the byte count with ``Asset/size``, as above, if you want a guard against a truncated download. That is the only check available.

``Asset/fileChecksum`` looks as though it could be a digest of the content, but it can't be used to check one. CloudKit mints it on the server and MistKit reads it as-is from the CDN's upload reply. Apple documents it only as a signature, with no algorithm. Observed values decode to 21 bytes: a `0x01` version byte followed by a 20-byte digest that matches no hash of the plaintext anyone has found. It is stable for identical content and also appears in ``Asset/downloadURL``, so treat it as an identity or cache key for the stored file, not as something to recompute and compare.

``Asset/referenceChecksum`` and ``Asset/wrappingKey`` belong to encrypted assets. They have not appeared in live responses, and MistKit does nothing with them on download.

## Sharing one asset between records

To point a second record at a file that is already stored, without uploading it again, use `assets/rereference`. ``CloudKitService/rereferenceAsset(fromRecord:field:toRecord:field:zoneID:database:)`` does the whole job: it looks up the target record's type and change tag, fetches a reusable descriptor for the source field, and writes it onto the target:

```swift
let updated = try await service.rereferenceAsset(
  fromRecord: "photo-original",
  field: "image",
  toRecord: "photo-copy",
  database: .private
)
```

If you already have the target's record type and change tag, ``CloudKitService/rereferenceAsset(fromRecord:field:toRecord:recordType:recordChangeTag:field:zoneID:database:)`` skips the lookup. To get descriptors for several fields at once and write them yourself, ``CloudKitService/rereferenceAssets(_:zoneID:database:)`` returns one ``Asset`` per `(recordName, fieldName)` pair, in order. The request is validated as a whole, so one bad entry fails the call with a top-level ``CloudKitError/badRequest(reason:)`` and there are no per-item failures. CloudKit deletes the stored bytes only after every record that refers to them has let go.

## Platform availability

The asset APIs need macOS 12, iOS 15, tvOS 15, watchOS 8 or later. On WASI there is no `URLSession`:

- ``Asset/download(using:)`` is not compiled for WASI.
- The upload methods are available, but their default uploader throws ``CloudKitError/httpErrorWithRawResponse(statusCode:rawResponse:)`` with status 501. To upload from WASI, pass an ``AssetUploader`` built on whatever HTTP client the platform has, keeping it off the CloudKit API connection.

## Topics

### Uploading

- ``CloudKitService/uploadAssets(data:recordType:fieldName:recordName:zoneID:using:database:)``
- ``CloudKitService/requestAssetUploadURL(recordType:fieldName:recordName:zoneID:database:)``
- ``CloudKitService/uploadAssetData(_:to:using:)``
- ``CloudKitService/maxAssetUploadBytes``

### Upload types

- ``AssetUploadReceipt``
- ``AssetUploadToken``
- ``AssetUploadResponse``
- ``AssetUploader``

### Downloading and sharing

- ``Asset``
- ``Asset/download(using:)``
- ``CloudKitService/rereferenceAssets(_:zoneID:database:)``
- ``CloudKitService/rereferenceAsset(fromRecord:field:toRecord:field:zoneID:database:)``
- ``CloudKitService/rereferenceAsset(fromRecord:field:toRecord:recordType:recordChangeTag:field:zoneID:database:)``

### Errors

- ``CloudKitError/missingAssetDownloadURL``
- ``CloudKitError/quotaExceeded(reason:hint:)``
- ``QuotaHint``

## See Also

- <doc:WorkingWithRecords>
- <doc:CloudKitLimitsAndPerformance>
- <doc:HandlingErrors>
