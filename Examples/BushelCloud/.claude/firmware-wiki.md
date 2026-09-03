# Firmware

Source: TheAppleWiki - https://theapplewiki.com/wiki/Firmware
(Saved from PDF: Firmware - The Apple Wiki.pdf)

A **firmware** is an IPSW file or OTA update ZIP file that contains everything needed to install the core operating system of a device.

## Firmware Manifests

To check for iOS, iPod, Apple TV, and HomePod mini updates, iTunes, Finder, Apple Configurator, and Apple Devices contact the main manifest at:
- **https://s.mzstatic.com/version**

This manifest also contains carrier bundles.

There are separate manifests for:
- **macOS**: https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml
- **bridgeOS**: https://mesu.apple.com/assets/bridgeos/com_apple_bridgeOSIPSW/com_apple_bridgeOSIPSW.xml
- **visionOS**: https://mesu.apple.com/assets/visionos/com_apple_visionOSIPSW/com_apple_visionOSIPSW.xml

The first-generation Apple TV also uses a firmware manifest, found at:
- **https://mesu.apple.com/version.xml**

It uses separate files, rather than consolidating them into an IPSW archive.

## History

The original use of the version manifest was to notify the user of iPod firmware updates. The notification directs the user to the Apple Support website to download iPod Updater. With iTunes 7.0, iPod Updater functionality was merged into iTunes, using IPSW files to hold the firmware. iTunes 7.3 extends the manifest and IPSW file format to support the iPhone.

## Limitations

There is no public manifest of IPSWs for any Apple Watch, HomePod (other than HomePod mini), or Apple TV 4K and later. These devices exclusively use OTA updates, and can be recovered using recoveryOS. Some IPSW files have been discovered for these devices through various means, but lack of a user-accessible Lightning or USB-C port renders it difficult to make use of them.

## Firmware List (by device)

### Release Firmware

**Apple TV**
- 1.x · 2.x · 3.x · 4.x · 5.x · 6.x · 7.x · 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**Apple Vision**
- 1.x · 2.x · 26.x

**Apple Watch**
- 1.x · 2.x · 3.x · 4.x · 5.x · 6.x · 7.x · 8.x · 9.x · 10.x · 11.x · 26.x

**HomePod**
- 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**Mac**
- 1.x · 2.x · 3.x · 4.x · 6.x · 7.x · 8.x · 9.x · 10.0.x Cheetah · 10.1.x Puma · 10.2.x Jaguar · 10.3.x Panther · 10.4.x Tiger · 10.5.x Leopard · 10.6.x Snow Leopard · 10.7.x Lion · 10.8.x Mountain Lion · 10.9.x Mavericks · 10.10.x Yosemite · 10.11.x El Capitan · 10.12.x Sierra · 10.13.x High Sierra · 10.14.x Mojave · 10.15.x Catalina · 11.x Big Sur · 12.x Monterey · 13.x Ventura · 14.x Sonoma · 15.x Sequoia · 26.x Tahoe

**Mac Server**
- 1.x · 10.0.x Cheetah · 10.1.x Puma · 10.2.x Jaguar · 10.3.x Panther · 10.4.x Tiger · 10.5.x Leopard · 10.6.x Snow Leopard · 10.7.x Lion · macOS Server

**iBridge (T2 chip)**
- 1.x (embeddedOS) · 2.x · 3.x · 4.x · 5.x · 6.x · 7.x · 8.x · 9.x · 10.x

**iPad**
- 3.x · 4.x · 5.x · 6.x · 7.x · 8.x · 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**iPad Air**
- 7.x · 8.x · 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**iPad Pro**
- 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**iPad mini**
- 6.x · 7.x · 8.x · 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**iPhone**
- 1.x · 2.x · 3.x · 4.x · 5.x · 6.x · 7.x · 8.x · 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x · 16.x · 17.x · 18.x · 26.x

**iPod touch**
- 1.x · 2.x · 3.x · 4.x · 5.x · 6.x · 7.x · 8.x · 9.x · 10.x · 11.x · 12.x · 13.x · 14.x · 15.x

### Other Firmware Types

- Preinstalled Firmware
- iPod Firmware
- iPod Recovery Firmware
- Mac Security Updates
- Mac Server Security Updates

### Beta Firmware

### OTA Updates

### Rapid Security Responses

### Beta Rapid Security Responses

### RecoveryOSUpdates

### Firmware Keys

## External Links

### Manifests

**iOS, iPod, Apple TV, and HomePod mini**:
- https://s.mzstatic.com/version
- Old URL: https://itunes.apple.com/WebObjects/MZStore.woa/wa/com.apple.jingle.appserver.client.MZITunesClientCheck/version

**bridgeOS**:
- https://mesu.apple.com/assets/bridgeos/com_apple_bridgeOSIPSW/com_apple_bridgeOSIPSW.xml

**macOS**:
- https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml

**visionOS**:
- https://mesu.apple.com/assets/visionos/com_apple_visionOSIPSW/com_apple_visionOSIPSW.xml

## Key Insights for CloudKit Schema

1. **Multiple firmware types**: IPSW files (full OS), OTA updates (incremental)
2. **macOS versioning**: Uses both legacy (10.x) and modern (11+) numbering
3. **Latest version number**: 26.x appears across all platforms (likely future release)
4. **Apple Silicon coverage**: Big Sur 11.x onwards for Apple Silicon Macs
5. **Manifest structure**:
   - iOS/iPod/Apple TV/HomePod mini: Single manifest at s.mzstatic.com
   - macOS/bridgeOS/visionOS: Separate MESU XML files
6. **Beta firmware**: Listed separately from release firmware
7. **OTA vs IPSW**: Different update mechanisms, both tracked in manifests

## Relevance to MistKit Project

For Bushel's macOS virtualization use case:
- Focus on **macOS manifest only**: `mesu.apple.com/assets/macos/com_apple_macOSIPSW/`
- Version coverage: Big Sur 11.x through current (26.x)
- IPSW files specifically for restore/install, not OTA updates
- MESU provides only latest signed version
- Need community sources (ipsw.me, Mr. Macintosh) for historical data
- Beta firmware requires separate tracking (not in main MESU manifest)
