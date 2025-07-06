# CloudKit Asset Field Decoding Error Fix Plan

## Error Description

The CloudKit demo fails when querying records with asset fields due to an unknown field type:

```
❌ Failed to query records: Client error - cause description: 'Unknown', underlying error: DecodingError: dataCorrupted - at CodingKeys(stringValue: "records", intValue: nil)/_CodingKey(stringValue: "Index 0", intValue: 0)/CodingKeys(stringValue: "fields", intValue: nil)/StringKey(stringValue: "image", intValue: nil)/CodingKeys(stringValue: "type", intValue: nil): Cannot initialize _typePayload from invalid String value ASSETID (underlying error: <nil>), operationID: queryRecords, operationInput: Input(path: MistKit.Operations.queryRecords.Input.Path(version: "1", container: "iCloud.com.brightdigit.MistDemo", environment: MistKit.Components.Parameters.environment.development, database: MistKit.Components.Parameters.database._private), headers: MistKit.Operations.queryRecords.Input.Headers(accept: [OpenAPIRuntime.AcceptHeaderContentType<MistKit.Operations.queryRecords.AcceptableContentType>(contentType: MistKit.Operations.queryRecords.AcceptableContentType.json, quality: OpenAPIRuntime.QualityValue(thousands: 1000))]), body: MistKit.Operations.queryRecords.Input.Body.json(MistKit.Operations.queryRecords.Input.Body.jsonPayload(zoneID: Optional(MistKit.Components.Schemas.ZoneID(zoneName: Optional("_defaultZone"), ownerName: nil)), resultsLimit: Optional(5), query: Optional(MistKit.Operations.queryRecords.Input.Body.jsonPayload.queryPayload(recordType: Optional("TodoItem"), filterBy: nil, sortBy: Optional([]))), desiredKeys: nil, continuationMarker: nil))), request: POST /database/1/iCloud.com.brightdigit.MistDemo/development/private/records/query [accept: application/json; content-length: 150; content-type: application/json; charset=utf-8], requestBody: OpenAPIRuntime.HTTPBody, baseURL: https://api.apple-cloudkit.com, response: 200 [access-control-expose-headers: X-Apple-Request-UUID,X-Apple-CloudKit-Web-Auth-Token,X-Responding-Instance,Via; connection: keep-alive; content-encoding: gzip; content-type: application/json; charset=UTF-8; date: Mon, 25 Aug 2025 23:31:42 GMT; server: AppleHttpServer/7347b443149f; strict-transport-security: max-age=31536000; includeSubDomains;; transfer-encoding: Identity; via: xrail:ms15p00ic-qujn16132102.me.com:8301:25R247:grp70,631194250daa17e24277dea86cf30319:3a01275c49ef1cdef312220332f795c5:uschi7; x-apple-cloudkit-version: 1.0; x-apple-cloudkit-web-auth-token: 106__54__AZxQzBfDVMYgWa7eWt+2o9hZzkLYfdcBHa+HKVFXSpktEb1U40Ux0gZgyAnm/oTCm3cYO+C9uoSx1gmkaMJEq99Fwxc9u27wJM4o58Bgiqp8jxee1wATjuiH2Y16R2sJuhy82a1xfUb81wFgMyHLPYe7U1OQxW4ax8hCCB4V8aV9HXWwJPsdb9IY3Mt9QZWIPEDZYXw6VL4DbSBoTbvfjWpQvC49uyruF3KCiHnNoNjIOIbksgeFsl9GtBRCmXLMOx6XkAJJSwaBC86nxqOXSiluKmii/M1+ExrAUSOwDhVzHhttHi5Hf2FI80dEIBCAgdGhnrWt8GO5uCiVxmsS5NaVS24QnPxgC2lwuRMtl6VJSGxj0/57DMyYvpKpGuQyzjTPbujI1Rav/tzT1MbPtjt88CgmZExPh9vcGnG8XWHtjJk=__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiVEdsemRFRndjR3c2TVRwQmNIQnNPakU2QVR6Y1ZySmJXRlpzb2JrY29IVTNkOUZUTWNnblRXWWVHczdqOElrNkJYa1crSWJWV3M4U2R6QXd3L011QXNIaitqbU5hbkR1QWNQMzZLREh5N0NNQWFzMjFMVjhPcTBkV1FtaE1FT1ZpUEJDdzRrbFBucm5reFJEREhsOVBIVWNBaUt4YVRNUUdBUHdTQTIreENTQ3NBRmg4TkpyWmhKODFDa1VDa1dqSWQ2UFRrR3NsQncxUmc9PSIsIlgtQVBQTEUtV0VCQVVUSC1QQ1MtU2hhcmluZyI6IlRHbHpkRUZ3Y0d3Nk1UcEJjSEJzT2pFNkFTSmE3OEVhbmpTTlRxLzkxb3JQc2ZVS21ydmREbGY3eU56dXFPdXFGOWZHeWJPM1ZSZXdUNkhvSDBtQmszYmtGZXJGSG9QYVRUT2N0bktPOFBNQm5ScGF0ZVlhZENGOE9KaExMaTFVQWc2cnNOdGVjekNTUGVLeHE3T0dzYmJXYXVWS0wrQTBXNGVDVEhtV29XZ0Z6WExvQzJNdmsrWEFuY2x1STBOVnVEZ1VUWkdnQ2tkSVNnPT0ifQ==; x-apple-edge-response-time: 201; x-apple-request-uuid: 2a45e9cc-eb6b-40ce-8a73-b08caa14c0cd; x-apple-user-partition: 106; x-responding-instance: ckdatabasews:404831555:prod-p106-ckdatabasews-50percent-8548457db5-gm9tv:8080:2530B184:1756f2a8aa03b72efff3caa88d4d489e5b0aef29], responseBody: OpenAPIRuntime.HTTPBody
```

## Problem Analysis

**Root Cause**: CloudKit is returning `ASSETID` as a field type, but our custom OpenAPI specification only recognizes `ASSET`. This causes decoding failures when querying records with asset fields.

**Key Issue**: Our OpenAPI specification is incomplete compared to Apple's actual CloudKit Web Services API - it's missing the `ASSETID` field type.

## Solution Plan

### 1. Update OpenAPI Specification

**File**: `openapi.yaml` (line 860)

**Current**:
```yaml
enum: [STRING, INT64, DOUBLE, BYTES, REFERENCE, ASSET, LOCATION, TIMESTAMP, LIST]
```

**Updated**:
```yaml
enum: [STRING, INT64, DOUBLE, BYTES, REFERENCE, ASSET, ASSETID, LOCATION, TIMESTAMP, LIST]
```

### 2. Regenerate Client Code

Run the OpenAPI code generation script:
```bash
./Scripts/generate-openapi.sh
```

This will update the generated Swift types in `Sources/MistKit/Generated/` to include `ASSETID` as a valid case in the `_typePayload` enum.

### 3. Test the Fix

- Run the CloudKit demo again
- Verify asset fields decode properly without errors
- Confirm record queries with asset fields (like the "image" field in TodoItem) work correctly

## Expected Outcome

The CloudKit demo should successfully query and decode records containing asset fields without throwing decoding errors. Records with asset/image fields will be properly parsed and displayed.

## Additional Notes

- This is a straightforward fix since we control the OpenAPI specification
- We may discover other missing field types as we test with more complex CloudKit data
- Consider adding comprehensive logging to identify any other unknown field types

## Files to Modify

1. `openapi.yaml` - Add `ASSETID` to FieldValue type enum
2. Run `./Scripts/generate-openapi.sh` to regenerate client code

---

*Created: 2025-08-26*  
*Status: Ready for implementation*