# MobileAsset Framework

Source: TheAppleWiki - https://theapplewiki.com/wiki/MobileAsset

> This page is a work in progress

Apple's operating systems have a framework called **MobileAsset**
used to download and update system data, independently of OS updates.

For example, the timezone database and the keyboard autocorrect language models
are updated silently in the background and don't need an OS update.
High-quality speech synthesizer voices for Siri and accessibility features
are downloaded on demand when a language is selected,
rather than being included with the OS,
since they are large and most people only need one or two languages.
OTA updates to iOS itself and firmware for Apple accessories are also mobile assets.

## Asset types

Assets are grouped using an *asset type* string in reverse-domain format,
starting with `com.apple.MobileAsset`,
such as `com.apple.MobileAsset.TimeZoneUpdate`.
There are currently more than a hundred asset types known.

There may be multiple *assets* for each asset type.
For example, the asset type for AirTag firmware
has a single asset with the latest version of the firmware,
but the asset type for Siri voices has hundreds of assets,
for the different voice languages, qualities, and compatible OS versions.

## Servers

There are two server systems from which asset metadata is retrieved.
"Mesu" uses static plist files in a simple CDN,
and the newer "Pallas" uses POST requests to a dynamic server.
Some assets are only in mesu, some are only in pallas,
some are actively updated in both,
and some are present in both but mesu doesn't get updated anymore
(still there only for compatibility with older operating systems).
Apple seems to be moving to Pallas for new asset types.

Both servers only provide the list of available assets
and their metadata, not the content.
The metadata includes a URL to the actual asset file,
which is hosted on `updates.cdn-apple.com`
(or `appldnld.apple.com` for some very old stuff).

### Mesu

The original asset server is `mesu.apple.com`.
It's a file server (probably Amazon S3 with a CDN) which serves XML plists,
containing the metadata for all the assets with a given asset type.
For example, every Siri voice for every language is listed in the same file,
and every iOS OTA update for every device is in the same file.

For iOS, these XML plists are downloaded from `mesu.apple.com/assets/{type}/{type}.xml`,
where `{type}` is the asset type, with dots replaced with underscores.
Other operating systems use `mesu.apple.com/assets/{os}/{type}/{type}.xml`,
where `{os}` is one of: `audio`, `watch`, `tv`, `macos`, `visionos`.
Some old visionOS assets are under "xros" instead.

Example:
`https://mesu.apple.com/assets/macos/com_apple_MobileAsset_TimeZoneUpdate/com_apple_MobileAsset_TimeZoneUpdate.xml`

They are simply static files;
no special user agent, request headers or query parameters are required,
and cache headers like ETag, Last-Modified and If-Modified-Since work as expected.

In the past, when iOS OTA updates used mesu,
there were also other directories like "iOS12DeveloperBeta"
in place of the {os} to serve OTAs of iOS betas.
This is not used anymore on newer iOS versions,
since OTA software updates (both beta and release) use Pallas exclusively.
The only known remaining exception is beta firmware for AirPods,
which are in `AirPods2022Seed/`.

The plist files in mesu have a dictionary containing these keys:
* `AssetType` (string): The dot-separated asset type string. Not always present.
* `Signature` (data): RSA signature of the asset metadata.
* `Certificate` (data): X.509 certificate used to verify the signature.
* `SigningKey` (string): Always "`AssetManifestSigning`".
* `FormatVersion` (integer): Always "1" (but not always present).
* `Assets` (array of dict): The list of assets. See below for details on the content of each dict.

There are three additional plists
in the mesu server that are not MobileAssets,
as their content is completely different:
* `macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml`
* `bridgeos/com_apple_bridgeOSIPSW/com_apple_bridgeOSIPSW.xml`
* `visionos/com_apple_visionOSIPSW/com_apple_visionOSIPSW.xml`

They contain URLs for .ipsw files for the latest version of
macOS (Apple Silicon), bridgeOS (T2 firmware) and visionOS.

### Pallas

The newer system is codenamed Pallas.
It runs in `gdmf.apple.com`
(the meaning of "gdmf" is unknown).
To get assets, you do a POST request sending JSON,
and get back a signed "JSON Web Token" (JWT) as response.

An example minimal request:
```json
{
    "ClientVersion": 2,
    "AssetAudience": "0c88076f-c292-4dad-95e7-304db9d29d34",
    "AssetType": "com.apple.MobileAsset.TimeZoneUpdate"
}
```

Unlike mesu, with pallas the OS can make more specific requests,
such as sending the OS version number
and only getting assets compatible with that version.
Or in the case of OS OTA updates,
getting updates only for the specific hardware device,
and deltas with the current version as prerequisite.

## Asset metadata

The XML plists from mesu and the JSON responses from pallas both have
an `"Assets"` key with an array of dictionaries.
Each dictionary in the array describes a downloadable asset file.
The content of these dictionaries can vary depending on asset type,
but it's the same schema for Mesu and Pallas.

Some asset types (currently) have no assets.
This is represented with a dummy entry in the array:
```json
"Assets": [
  {
    "__Empty": "Empty"
  }
]
```

Strangely, `com.apple.MobileAsset.DeviceCheck` in mesu
is missing the `Assets` key altogether.

Some dictionary keys are common to every asset
(even though they may not be always present),
and others are specific to certain asset types.
The common keys are:
* `__BaseURL` (string): The prefix of the URL that the asset file can be downloaded from. Always present.
* `__RelativePath` (string): The path to download the asset file from, relative to the BaseURL. Always present.
* `_DownloadSize` (integer): Size of the file to download, in bytes. Always present.
* `_UnarchivedSize` (integer): How much space this asset takes once the archive is extracted. Always present.
* `_Measurement` (data): SHA-1 hash of the asset file to download. Always present. This is a &lt;data&gt; element in mesu plists, and a base64 string in pallas JSON responses.
* `_MeasurementAlgorithm` (string): Hashing algorithm used in `_Measurement`. Always present, always set to "SHA-1". It's unknown if the code even supports other algorithms.
* `_CompressionAlgorithm` (string): Outer format of the asset file. Always "zip" in Mesu assets, can also be "aea", "AppleArchive", or "AppleEncryptedArchive" in some Pallas assets. Always present.
* `_IsZipStreamable` (bool): Exact meaning unknown; either `true` or missing. Seems to be `true` on every `zip`- and `aea`-format asset, except old ones hosted in the `appldnld` server.
* `_MasteredVersion` (string): Some version number. Present in every mesu asset, except some with asset type `SoftwareUpdate`, and some newer "auto assets" (`_IsMAAutoAsset==true`).
* `_CompatibilityVersion` (integer): A version number increased when the content of the asset changes in an incompatible way; newer versions of the OS start using assets with a newer content version while older OS versions keep using the old assets.
* `__CanUseLocalCacheServer` (bool): Presumably, whether this asset is eligible for Content Caching. It seems to be either true or missing.

The full URL to download an asset file is `__BaseURL + __RelativePath`.
The reason why it's split into two is that `__RelativePath`
can also be requested from a local caching server.

Most asset types have extra keys specific to their own purposes,
sometimes *a lot* of extra keys.

## Key Insights for CloudKit Schema

1. **MESU is NOT a historical database** - It only contains the current signed release
2. **Three special IPSW plists** that are NOT MobileAssets:
   - macOS: `mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml`
   - bridgeOS: `mesu.apple.com/assets/bridgeos/com_apple_bridgeOSIPSW/com_apple_bridgeOSIPSW.xml`
   - visionOS: `mesu.apple.com/assets/visionos/com_apple_visionOSIPSW/com_apple_visionOSIPSW.xml`
3. **MESU structure**: Simple static XML files, no authentication required
4. **Hash algorithm**: MESU only provides SHA-1, not SHA-256
5. **Download URLs**: All hosted on `updates.cdn-apple.com`
6. **Beta releases**: No longer in MESU for iOS (moved to Pallas), unknown for macOS

## Relevance to MistKit Project

For the Bushel CloudKit schema:
- Use MESU as a **freshness detector** for new releases only
- Don't rely on MESU for historical data (it doesn't have any)
- Primary source should be ipsw.me API (via IPSWDownloads package)
- MESU only provides SHA-1, need ipsw.me for SHA-256
- MESU won't have beta releases - need Mr. Macintosh for those
