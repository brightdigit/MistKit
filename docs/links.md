# CloudKit as Your Backend: From iOS to Server-Side Swift — Links

Links from the iOSDevUK 2026 talk by Leo Dion ([@leogdion@c.im](https://c.im/@leogdion)).

## Leo Dion / BrightDigit

- [MistKit on GitHub](https://github.com/brightdigit/MistKit)
- [MistKit issues](https://github.com/brightdigit/MistKit/issues) — "What's Next?"
- [MistDemo](https://github.com/brightdigit/MistKit/tree/main/Examples/MistDemo) — CLI, macOS app and web demo used for integration testing
- [BushelCloud](https://github.com/brightdigit/MistKit/tree/main/Examples/BushelCloud) — the GitHub Actions sync shown in Deployment
  - [`cloudkit-sync-dev.yml`](https://github.com/brightdigit/MistKit/blob/main/Examples/BushelCloud/.github/workflows/cloudkit-sync-dev.yml) — scheduled workflow
  - [`cloudkit-sync` composite action](https://github.com/brightdigit/MistKit/blob/main/Examples/BushelCloud/.github/actions/cloudkit-sync/action.yml)
- [Bushel](https://getbushel.app) — Virtualization for App Developers
- [AtLeast](https://atleast.app) — Passive Timer for Apple Watch
- [Heartwitch](https://heartwitch.app) — Apple Watch heart-rate streaming; [App Store](https://apps.apple.com/us/app/heartwitch/id1480031203)
- [BrightDigit](https://brightdigit.com)
- [linktr.ee/leogdion](https://linktr.ee/leogdion)
- [iOSDevUK](https://www.iosdevuk.com)

## What is CloudKit

- [WWDC 2014 "Introducing CloudKit" (session 208)](https://nonstrict.eu/wwdcindex/wwdc2014/208/) — Apple no longer hosts the video; this mirror has the video, slides and transcript. Transcript only: [ASCIIwwdc](https://asciiwwdc.com/2014/sessions/208)
- [CloudKit framework documentation](https://developer.apple.com/documentation/cloudkit)
- [Enabling CloudKit in your app](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app) — Xcode capability setup
- [CloudKit Console](https://icloud.developer.apple.com/dashboard/)
- [Integrating a text-based schema into your workflow](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow)
- [cktool](https://developer.apple.com/icloud/ck-tool/) and [Automating CloudKit Development](https://developer.apple.com/icloud/cloudkit/automating/)

## CloudKit Web Services

- [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs)
- [CloudKit Web Services Reference](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html) — archived
  - [Composing Web Service Requests](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html)
  - [Accessing CloudKit Using an API Token](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW2)
  - [Accessing CloudKit Using a Server-to-Server Key](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW6)
  - [Document Revision History](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/RevisionHistory.html) — last updated 2016
  - [Uploading Assets](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/UploadAssets.html)
  - [Types and Dictionaries](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Types.html) — field types
  - [Error Codes](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ErrorCodes.html)
  - [Discovering User Identities (POST users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringUserIdentities%28usersdiscover%29.html)
  - [Discovering All User Identities (GET users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringAllUserIdentities.html) — the endpoint that returns HTTP 500
- Base URL: `https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}`
- [Apple Developer Support](https://developer.apple.com/support/) — contact URL in the OpenAPI document

## Authentication

- [CKFetchWebAuthTokenOperation](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation)
- [Sign in with Apple](https://developer.apple.com/documentation/signinwithapple) — mentioned as not existing when Heartwitch was built
- [swift-crypto](https://github.com/apple/swift-crypto) — `P256.Signing.PrivateKey` used in `RequestSignature`
- MistKit source shown in the talk:
  - [`AuthenticationMiddleware.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/AuthenticationMiddleware.swift)
  - [`APITokenAuthenticator.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/APITokenAuthenticator.swift)
  - [`WebAuthTokenAuthenticator.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/WebAuthTokenAuthenticator.swift)
  - [`ServerToServerAuthenticator.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/ServerToServerAuthenticator.swift)
  - [`RequestSignature.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Authentication/RequestSignature.swift)

## Swift OpenAPI Generator

- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
- [WWDC23 "Meet Swift OpenAPI Generator"](https://developer.apple.com/videos/play/wwdc2023/10171/)
- [Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator) and [tutorial: Working with Swift OpenAPI Generator](https://swiftpackageindex.com/apple/swift-openapi-generator/tutorials/swift-openapi-generator)
- [ClientMiddleware](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware) — the ["Implement a custom client middleware"](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware#Implement-a-custom-client-middleware) bearer-token example is a section on that page
- [Example projects](https://github.com/apple/swift-openapi-generator/tree/main/Examples) — including auth, logging and retrying middleware examples
- Package ecosystem:
  - [swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime)
  - [swift-openapi-urlsession](https://github.com/apple/swift-openapi-urlsession)
  - [swift-openapi-async-http-client](https://github.com/swift-server/swift-openapi-async-http-client)
  - [swift-okhttp](https://github.com/frameo-net/swift-okhttp)
  - [swift-openapi-vapor](https://github.com/vapor/swift-openapi-vapor)
  - [swift-openapi-hummingbird](https://github.com/hummingbird-project/swift-openapi-hummingbird)
  - [swift-openapi-lambda](https://github.com/awslabs/swift-openapi-lambda)
- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [MistKit `openapi.yaml`](https://github.com/brightdigit/MistKit/blob/main/openapi.yaml)

## Field Types and Error Handling

- [`FieldValue.swift`](https://github.com/brightdigit/MistKit/blob/main/Sources/MistKit/Models/FieldValues/FieldValue.swift)
- [MistKit issue #28: discoverAllUserIdentities returns HTTP 500](https://github.com/brightdigit/MistKit/issues/28)
  - Broken call, CloudKit Web Services: [Discovering All User Identities (GET users/discover)](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/DiscoveringAllUserIdentities.html)
  - Broken call, CloudKit JS: [`CloudKit.Container.discoverAllUserIdentities`](https://developer.apple.com/documentation/cloudkitjs/cloudkit.container/discoveralluseridentities)
- Apple Feedback FB22754466 — public copy on [Open Radar](https://openradar.appspot.com/FB22754466); filed via [Feedback Assistant](https://feedbackassistant.apple.com/)

## Deployment

- [GitHub Actions: scheduled workflows (`schedule` / cron)](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule)
- [GitHub Actions: using secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- [GitHub Actions: creating a composite action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action)
- [actions/checkout](https://github.com/actions/checkout)
- [dawidd6/action-download-artifact](https://github.com/dawidd6/action-download-artifact)
- [Swift Docker image](https://hub.docker.com/_/swift) — `swift:6.2-noble`

## Other tools mentioned

- [Hummingbird](https://hummingbird.codes) — server behind the MistDemo web interface
- [Vapor](https://vapor.codes) — Heartwitch backend
- [OBS Studio](https://obsproject.com) — Heartwitch streaming overlay
