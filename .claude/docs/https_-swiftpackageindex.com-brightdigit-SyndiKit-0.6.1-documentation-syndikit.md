<!--
Downloaded via https://llm.codes by @steipete on November 11, 2025 at 10:48 AM
Source URL: https://swiftpackageindex.com/brightdigit/SyndiKit/0.6.1/documentation/syndikit
Total pages processed: 1
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://swiftpackageindex.com/brightdigit/SyndiKit/0.6.1/documentation/syndikit

Framework

# SyndiKit

Swift Package for Decoding RSS Feeds.

## Overview

Built on top of XMLCoder, **SyndiKit** provides models and utilities for decoding RSS feeds of various formats and extensions.

### Features

- Import of RSS 2.0, Atom, and JSONFeed formats

- Extensions for various formats such as:

- iTunes-compatabile podcasts

- YouTube channels

- WordPress export data
- User-friendly errors

- Abstractions for format-agnostic parsing

### Requirements

**Apple Platforms**

- Xcode 13.3 or later

- Swift 5.5.2 or later

- iOS 15.4 / watchOS 8.5 / tvOS 15.4 / macOS 12.3 or later deployment targets

**Linux**

- Ubuntu 18.04 or later

### Installation

Swift Package Manager is Apple’s decentralized dependency manager to integrate libraries to your Swift projects. It is now fully integrated with Xcode 11.

To integrate **SyndiKit** into your project using SPM, specify it in your Package.swift file:

let package = Package(
...
dependencies: [\
.package(url: "https://github.com/brightdigit/SyndiKit", from: "0.3.0")\
],
targets: [\
.target(\
name: "YourTarget",\
dependencies: ["SyndiKit", ...]),\
...\
]
)

If this is for an Xcode project simply import the Github repository at:

### Decoding Your First Feed

You can get started decoding your feed by creating your first `SynDecoder`. Once you’ve created you decoder you can decode using `decode(_:)`:

let decoder = SynDecoder()
let empowerAppsData = Data(contentsOf: "empowerapps-show.xml")!
let empowerAppsRSSFeed = try decoder.decode(empowerAppsData)

### Working with Abstractions

Rather than working directly with the various formats, **SyndiKit** abstracts many of the common properties of the various formats. This enables developers to be agnostic regarding the specific format.

let decoder = SynDecoder()

// decoding a RSS 2.0 feed
let empowerAppsData = Data(contentsOf: "empowerapps-show.xml")!
let empowerAppsRSSFeed = try decoder.decode(empowerAppsData)
print(empowerAppsRSSFeed.title) // Prints "Empower Apps"

// decoding a Atom feed from YouTube
let kiloLocoData = Data(contentsOf: "kilo.youtube.xml")!
let kiloLocoAtomFeed = try decoder.decode(kiloLocoData)
print(kiloLocoAtomFeed.title) // Prints "Kilo Loco"

For a mapping of properties:

| Feedable | RSS 2.0 `channel` | Atom `AtomFeed` | JSONFeed `JSONFeed` |
| --- | --- | --- | --- |
| `title` | `title` | `title` | `title` |
| `siteURL` | `link` | `siteURL` | `title` |
| `summary` | `description` | `summary` | `homePageUrl` |
| `updated` | `lastBuildDate` | `pubDate` or `published` | `nil` |
| `authors` | `author` | `authors` | `author` |
| `copyright` | `copyright` | `nil` | `nil` |
| `image` | `url` | `links`.`first` | `nil` |
| `children` | `items` | `entries` | `items` |

### Specifying Formats

If you wish to access properties of specific formats, you can attempt to cast the objects to see if they match:

let empowerAppsRSSFeed = try decoder.decode(empowerAppsData)
if let rssFeed = empowerAppsRSSFeed as? RSSFeed {
print(rssFeed.channel.title) // Prints "Empower Apps"
}

let kiloLocoAtomFeed = try decoder.decode(kiloLocoData)
if let atomFeed = kiloLocoAtomFeed as? AtomFeed {
print(atomFeed.title) // Prints "Kilo Loco"
}

### Accessing Extensions

In addition to supporting RSS, Atom, and JSONFeed, **SyndiKit** also supports various RSS extensions for specific media including: YouTube, iTunes, and WordPress.

You can access these properties via their specific feed formats or via the `media` property on `Entryable`.

let empowerAppsRSSFeed = try decoder.decode(empowerAppsData)
switch empowerAppsRSSFeed.children.last?.media {
case .podcast(let podcast):
print(podcast.title) // print "WWDC 2018 - What Does It Mean For Businesses?"
default:
print("Not a Podcast! 🤷‍♂️")
}

let kiloLocoAtomFeed = try decoder.decode(kiloLocoData)
switch kiloLocoAtomFeed.children.last?.media {
case .video(.youtube(let youtube):
print(youtube.videoID) // print "SBJFl-3wqx8"
print(youtube.channelID) // print "UCv75sKQFFIenWHrprnrR9aA"
default:
print("Not a Youtube Video! 🤷‍♂️")
}

| `MediaContent` | Actual Property |
| --- | --- |
| `title` | `itunesTitle` |
| `episode` | `itunesEpisode` |
| `author` | `itunesAuthor` |
| `subtitle` | `itunesSubtitle` |
| `summary` | `itunesSummary` |
| `explicit` | `itunesExplicit` |
| `duration` | `itunesDuration` |
| `image` | `itunesImage` |
| `channelID` | `youtubeChannelID` |
| `videoID` | `youtubeVideoID` |

## Topics

### Decoding an RSS Feed

`class SynDecoder`

An object that decodes instances of Feedable from JSON or XML objects.

### Basic Feeds

The basic types used by **SyndiKit** for traversing the feed in abstract manner without needing the specific properties from the various feed formats.

`protocol Feedable`

Basic abstract Feed

`protocol Entryable`

Basic Feed type with abstract properties.

`struct Author`

a person, corporation, or similar entity.

`protocol EntryCategory`

Abstract category type.

`enum EntryID`

An identifier for an entry based on the RSS guid.

### Abstract Media Types

Abstract media types which can be pulled for the various `Entryable` objects.

`protocol PodcastEpisode`

A protocol representing a podcast episode.

`enum MediaContent`

A struct representing an Atom category. Represents different types of media content.

`enum Video`

A struct representing an Atom category. An enumeration representing different types of videos.

### XML Primitive Types

In many cases, types are encoded in non-matching types but are intended to strong-typed for various formats. These primitives are setup to make XML decoding easier while retaining their intended strong-type.

`struct CData`

#CDATA XML element.

`struct XMLStringInt`

XML Element which contains a `String` parsable into a `Integer`.

`struct ListString`

A struct representing a list of values that can be encoded/decoded as a comma-separated string. Useful for handling feed formats where multiple values are stored in a single string field.

### Syndication Updates

Properties from the RDF Site Summary Syndication Module concerning how often it is updated a feed is updated.

`struct SyndicationUpdate`

Properties concerning how often it is updated a feed is updated.

`enum SyndicationUpdatePeriod`

Describes the period over which the channel format is updated.

`typealias SyndicationUpdateFrequency`

Used to describe the frequency of updates in relation to the update period. A positive integer indicates how many times in that period the channel is updated.

### Atom Feed Format

Specific properties related to the Atom format.

`struct AtomFeed`

A struct representing an Atom category. An XML-based Web content and metadata syndication format.

`struct AtomEntry`

A struct representing an entry in an Atom feed.

`struct AtomCategory`

A struct representing an Atom category. A struct representing an Atom category.

`struct AtomMedia`

A struct representing an Atom category. Media structure which enables content publishers and bloggers to syndicate multimedia content such as TV and video clips, movies, images and audio.

`struct AtomMediaGroup`

A group of media elements in an Atom feed.

`struct Link`

A struct representing a link with a URL and optional relationship type. Used in various feed formats to represent hyperlinks with metadata.

### JSON Feed Format

Specific properties related to the JSON Feed format.

`struct JSONFeed`

A struct representing an Atom category. A struct representing a JSON feed.

`struct JSONItem`

A struct representing an Atom category. A struct representing an item in JSON format.

### OPML Feed Formate

`struct OPML`

A struct representing an OPML (Outline Processor Markup Language) document. OPML is an XML format for outlines that can be used to exchange subscription lists between feed readers. It consists of a version, head section with metadata, and body section with outline elements.

`enum OutlineType`

### RSS Feed Format

Specific properties related to the RSS Feed format.

`struct RSSFeed`

A struct representing an Atom category. RSS is a Web content syndication format.

`struct RSSChannel`

A struct representing an Atom category. A struct representing information about the channel (metadata) and its contents.

`struct RSSImage`

Represents a GIF, JPEG, or PNG image.

`struct RSSItem`

A struct representing an RSS item/entry. RSS items contain the individual pieces of content within an RSS feed, including title, link, description, publication date, and various media attachments.

`struct RSSItemCategory`

A struct representing an Atom category. A struct representing a category for an RSS item.

`struct Enclosure`

A struct representing an enclosure for a resource.

### Podcast Extensions

Specific properties related to .

`struct PodcastPerson`

A struct representing a person associated with a podcast.

`struct PodcastSeason`

A struct representing a season of a podcast.

`struct PodcastChapters`

A struct representing chapters of a podcast.

`struct PodcastLocation`

A struct representing the location of a podcast.

`struct PodcastSoundbite`

A struct representing a soundbite from a podcast.

`struct PodcastTranscript`

A struct representing a podcast transcript.

`struct PodcastFunding`

A struct representing funding information for a podcast.

`struct PodcastLocked`

A struct representing a locked podcast.

### WordPress Extensions

Specific extension properties provided by WordPress.

`enum WordPressElements`

A namespace for WordPress related elements.

`struct WordPressPost`

A struct representing a WordPress post.

`typealias WPTag`

A typealias for `WordPressElements.Tag`

`typealias WPCategory`

A typealias for `WordPressElements.Category`

`typealias WPPostMeta`

A typealias for `WordPressElements.PostMeta`.

`enum WordPressError`

An error type representing a missing field in a WordPress post.

### YouTube Extensions

Specific type abstracting the id properties a YouTube RSS Feed.

`protocol YouTubeID`

A struct representing an Atom category. A protocol abstracting the ID properties of a YouTube RSS Feed.

### iTunes Extensions

Specific extension properties provided by iTunes regarding mostly podcasts and their episodes.

`typealias iTunesImage`

A type alias for iTunes image links.

`struct iTunesOwner`

A struct representing an Atom category. A struct representing the owner of an iTunes account.

`typealias iTunesEpisode`

A struct representing an Atom category. A type alias for an iTunes episode.

`struct iTunesDuration`

A struct representing the duration of an iTunes track.

### Site Directories

Types related to the format used by the .

`protocol SiteDirectory`

A protocol for site directories.

`struct SiteCollectionDirectory`

A directory of site collections.

`protocol SiteDirectoryBuilder`

A protocol for building site directories.

`struct CategoryDescriptor`

A struct representing an Atom category. A descriptor for a category.

`struct CategoryLanguage`

A struct representing an Atom category. A struct representing a category in a specific language.

`struct Site`

A struct representing a website.

`struct SiteCategory`

A struct representing an Atom category. A struct representing a site category.

`struct SiteCollectionDirectoryBuilder`

A builder for creating a site collection directory.

`struct SiteLanguage`

A struct representing an Atom category. A struct representing a site language.

`struct SiteLanguageCategory`

A struct representing an Atom category. A struct representing a category of site languages.

`struct SiteLanguageContent`

A struct representing an Atom category. A struct representing the content of a site in a specific language.

`typealias SiteCategoryType`

A type alias representing a site category.

`typealias SiteCollection`

A collection of site language content.

`typealias SiteLanguageType`

A type representing the language of a website.

`typealias SiteStub`

A type alias for `SiteLanguageCategory.Site`.

- SyndiKit
- Overview
- Features
- Requirements
- Installation
- Decoding Your First Feed
- Working with Abstractions
- Specifying Formats
- Accessing Extensions
- License
- Topics

|
|

---

