# Reverse-engineering CloudKit's asset `fileChecksum`

**Date:** 2026-09-04
**Container:** `iCloud.com.brightdigit.MistDemo` / `development` / public database (web-auth)
**Question:** How is the `fileChecksum` on a CloudKit `ASSET`/`ASSETID` field computed, and can a
client verify downloaded asset bytes against it?

**Bottom line:** `fileChecksum` is **deterministic and content-addressed**, but it is **not
client-derivable**. It is minted server-side by the CDN, returned in the `assets/upload` receipt, and
is an opaque token that Apple's own documentation labels only `[SIGNATURE]`. ~1,500 candidate
constructions over three byte-exact samples all failed. `Asset.matches(data:)` and
`Asset.download(using:)` as currently written (SHA-256 of plaintext, base64 or hex) **cannot ever
succeed** against a real CloudKit asset.

---

## 1. Samples

All PNGs produced by `PNGData.generate(withSizeInKB:)`
(`Examples/MistDemo/Sources/MistDemoKit/Integration/PNGData.swift`). The generator was reimplemented
in Python and **verified byte-exact**: generated lengths and SHA-1s match both the live upload sizes
and the bytes downloaded back from the CDN.

| `--asset-size` | bytes | sha1(plaintext) | sha256(plaintext)[:20] | observed `fileChecksum` | prefix | 20-byte body |
|---|---|---|---|---|---|---|
| 7 | 7320 | `f77d1cf229bcd696f01e655b4a7814320aa31509` | `9d3c…` | `AfQRAtjnqPAbe1u9gaUx81u01Uis` | `01` | `f41102d8e7a8f01b7b5bbd81a531f35bb4d548ac` |
| 50 | 51682 | `e5d44d02e25223f26a70dd7c6cb6e57603c628d3` | `8e6d2a5a81e0d603915bd5eb020c2905854f2178` | `AUStEc+gPyq1KTFbGO3RbXVpusut` | `01` | `44ad11cfa03f2ab529315b18edd16d7569bacbad` |
| 100 | 102933 | `59de06c35010dfd1cdc1d3798a4e88fc1c65f506` | `1d49ff05dba92c11b17579a5641b792ed7b49920` | `AZqG2xi2/dCW6cKE4VPySz6q2pRk` | `01` | `9a86db18b6fdd096e9c284e153f24b3eaada9464` |
| (shared-zone phase) | 51200 | — (not regenerated) | — | `AWbGPi+3CS5arEas6JNFb9tbw1zY` | `01` | `66c63e2fb7092e5aac46ace893456fdb5bc35cd8` |

Every checksum decodes to exactly **21 bytes = a constant `0x01` version prefix + a 20-byte body**.
Body one-bit counts are 81, 83, 81 out of 160 — statistically uniform, consistent with a
cryptographic digest rather than a structured identifier.

The same string appears URL-safe-encoded as the CDN path component:
`https://cvws.icloud-content.com/B/AfQRAtjnqPAbe1u9gaUx81u01Uis/${f}?…` — i.e. it doubles as the
content address.

## 2. Established facts

### 2.1 It is deterministic (content-addressed)

Uploading the **same bytes** in two independent `mistdemo test-public` runs, into two different
records, produced **identical** checksums:

| bytes | run 1 | run 2 | same? |
|---|---|---|---|
| 51200 | `AWbGPi+3CS5arEas6JNFb9tbw1zY` | `AWbGPi+3CS5arEas6JNFb9tbw1zY` | ✅ |
| 102933 | `AZqG2xi2/dCW6cKE4VPySz6q2pRk` | `AZqG2xi2/dCW6cKE4VPySz6q2pRk` | ✅ |

The 51682 sample also reproduced the value recorded in an earlier, separate session
(`AUStEc+gPyq1KTFbGO3RbXVpusut`). **No per-upload nonce or per-record key is involved** — the value
is a pure function of the content (plus, possibly, fixed container-scoped context).

### 2.2 The CDN stores and serves unmodified plaintext

Downloading the 7320-byte asset back from its `downloadURL` returned HTTP 200, exactly 7320 bytes,
**byte-identical** to the locally generated PNG. So the checksum is *not* a digest over an encrypted
or otherwise transformed server-side representation — the plaintext is what is stored. (No
`wrappingKey` was present in any upload response.)

### 2.3 It is minted server-side, not by the client

MistKit does not compute it. `CloudKitService+AssetUpload.swift:106` reads it straight out of the
CDN's `singleFileUpload` response:

```swift
return Asset(
  fileChecksum: uploadResponse.singleFile.fileChecksum,
  …
)
```

The client's only role is to pass the value through into the subsequent `records/modify`. Apple's
archived [Uploading Assets](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/UploadAssets.html)
documents the response purely as opaque pass-through data, giving `fileChecksum` the placeholder
`[SIGNATURE]` and specifying **no algorithm**. No primary Apple source in `.claude/docs/` documents
one either (`QUICK_REFERENCE.md:109` names the field but not its computation).

### 2.4 The upload receipt embeds a fragment of the checksum

The `receipt` is a binary (protobuf-like) blob. For the 51682 sample it contains the subsequence
`52 04 69bacbad` — a length-4 field whose value `69bacbad` is exactly the **last 4 bytes of the
checksum body** (`…7569bacbad`). This confirms the checksum body is a server-side artifact carried
inside the signed receipt, and reinforces that it is minted by Apple's infrastructure rather than
derived by either endpoint.

## 3. Hypotheses tested — all negative

Every construction below was evaluated against **all three byte-exact samples**; a hypothesis was
only ever going to be accepted on a ≥2-sample reproduction. **Total: ~1,500 probes, zero matches.**

| Family | Variants tried | Result |
|---|---|---|
| Plain digests | sha1, sha224, sha256, sha384, sha512, sha512_224/256, md5, sha3_224/256/384/512, blake2b, blake2s, ripemd160, sm3, md5-sha1, shake_128/256 — **every 20-byte sliding window** of each digest, not just the first | ❌ |
| blake2 with `digest_size=20` | blake2b-160, blake2s-160 | ❌ |
| Length framing | size as le64/be64/le32/be32/decimal-ASCII, prepended / appended / both, over sha1, sha256, sha512, md5, blake2b, sha3_256 | ❌ |
| Version-byte framing | `0x00`/`0x01`/`0x02`/`0x0100`/`0x0001` pre- and post-pended, over sha1/sha256 | ❌ |
| HMAC | 16 candidate keys (empty, zero-blocks, container id `iCloud.com.brightdigit.MistDemo`, `CloudKit`, `cloudkit`, `Apple`, `com.apple.cloudkit`, `com.apple.Dataclass.CloudKit`, `_defaultZone`, `development`, `public`, `singleFileUpload`, record type) × sha1/sha256/sha512/md5/blake2b, **and** with key/message swapped | ❌ |
| Data-derived keys | `hmac(k=sha256(data), m=len)`, `hmac(k=len, m=data)` | ❌ |
| Chunk trees | leaf ∈ {sha1, sha256, md5, blake2b}, root ∈ {sha1, sha256}, chunk sizes 512 B → 32 MiB (all powers of two) plus 51200/65535/102400; flat concatenation, truncated-leaf concatenation, index-framed leaves, and **binary Merkle trees** | ❌ |
| Representations | hashing the lowercase-hex, uppercase-hex, standard-base64, and url-safe-base64 encodings of the data | ❌ |
| Nested / iterated | `a(b(data))` and `a(b(data) ‖ data)` across sha1/sha256/md5/sha512/blake2b | ❌ |
| hash160 style | `ripemd160(sha256(d))`, `ripemd160(sha1(d))`, `sha1(sha256(d))`, `ripemd160(blake2b(d))`, etc. | ❌ |
| Protobuf-style wrappers | `H(tag ‖ inner_digest ‖ size)` with tags `01`, `00`, `0a14`, `1220`, size in both endiannesses | ❌ |
| PNG-internal | sha1/sha256 of the IDAT payload only, and of the inflated raw pixel data | ❌ |
| Encrypted-representation | ruled out empirically — CDN returns byte-identical plaintext (§2.2) | ❌ |

Also ruled out by construction: the 21-byte length excludes plain SHA-256 (32 B); the reproducibility
result (§2.1) excludes any per-upload nonce or random salt.

## 4. Verdict

**`fileChecksum` is not client-derivable from the asset bytes.**

The strongest evidence:

1. **Apple never documents an algorithm.** The archived Web Services Reference — the only primary
   source — treats the value as opaque pass-through and calls it `[SIGNATURE]`. A signature, not a
   digest, is the natural reading of a value the client is told only to echo back.
2. **The client never computes it.** It arrives from the CDN in the upload receipt; MistKit's sole
   involvement is forwarding it (§2.3).
3. **The receipt embeds part of it** (§2.4), placing its provenance inside Apple's server-side signed
   blob.
4. **~1,500 constructions over three byte-exact samples produced no match** (§3), including the
   entire space of common digests at every truncation offset.
5. The `0x01` prefix plus a 20-byte body most plausibly denotes a **versioned server-side signature
   or truncated keyed digest** whose key lives on Apple's infrastructure — unobtainable by a client
   by definition.

It remains conceivable that the body is some unkeyed digest under a framing not tried here, but the
combination of (1)–(4) makes a **server-held key** the far likelier explanation, and no amount of
client-side search can close that gap.

### Consequence for MistKit

`Asset.matches(data:)` (`Sources/MistKit/Models/FieldValues/Asset+Checksum.swift`) compares
`fileChecksum` against base64/hex of **SHA-256 of the plaintext**. Per the table above, that can
never match a real CloudKit asset. Because `Asset.download(using:)` treats a mismatch as fatal
(`CloudKitError.assetChecksumMismatch`) and refuses to return unverified bytes, **downloading any
genuine CloudKit asset currently always throws** — which is exactly the failing download-verify phase
in `mistdemo test-public`.

Options, in rough order of preference:

1. **Drop checksum verification as a precondition for returning bytes.** Return the downloaded data;
   the transport is already TLS-authenticated against Apple's CDN. Optionally expose `fileChecksum`
   as an opaque identity/caching token, which is what it demonstrably is.
2. **Verify size instead.** `size` from the asset dictionary is meaningful, client-checkable, and
   catches truncated downloads — the realistic failure mode.
3. **Keep `matches(data:)` but re-document it** as a local-integrity helper against a
   caller-supplied digest, not as CloudKit checksum validation.

Whichever is chosen, the current documentation comments asserting `fileChecksum` is "SHA-256 of the
plaintext" are factually wrong and should be corrected.

## 5. Reproducing

```bash
cd Examples/MistDemo
swiftly run +6.4.x-snapshot-2026-06-15 swift run mistdemo test-public \
    --record-count 1 --asset-size 50 --verbose
```

Grep the output for `"fileChecksum"` alongside the adjacent `"size"`. The Python reimplementation of
`PNGData.generate` used to reconstruct exact upload bytes (verified against CDN downloads) is
reproduced by porting `PNGData.swift`: solid-color RGB PNG, filter byte 0 per scanline, zlib
*stored* (uncompressed) DEFLATE blocks, square side = `round(sqrt(sizeKB * 1024 / 3))`.
