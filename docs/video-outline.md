# MistKit

## What is CloudKit?

CloudKit is Apple's backend cloud database available to developers. 

> **[Author]** How much does it cost?
>
> **Answer:** No separate CloudKit fee beyond the Apple Developer Program (~$99/yr). Quotas (storage, transfer, requests) scale with active users; exceeding them typically returns `quotaExceeded` / throttles. Apple does not currently publish a clear public overage price list.

> **[Author]** What kind of database would it be called? It's not _relational_.
>
> **Answer:** NoSQL / document-oriented (schema-based record store). Records have typed fields; links use references, not SQL joins.

> **[Beginner]** Who pays for the storage — me or my users?

> **[Beginner]** What are the size limits on a single record?

## Introduction

## Some basics about CloudKit

### Records

> **[Beginner]** What is a record type / zone / subscription in plain terms?
Record Field Types
* String
* Double
* Integer
* Data
* Date
* CLLocation
* CKReference
* CKAsset
* List<>

> **[Beginner]** Do I have to define the schema up front, or does it create fields as I go?

Up-Front

### Databases

CloudKit supports 2 kinds of databases: a public and a private database. Private is exclusive to a single user but allows the ability to share records while Public is shared over the entire system. 
A great example is what I'll doing with my RSS app. The public database will contain the RSS content shared amongst all users while the private database will contain a user's particular reading status and subscriptions. The only requirement is the user is signed in on their device to access either database.

Besides the databases, theres environments. Environments allow you to test and develop against a development or production environment safely as well as deployment content back and forth.

> **[Beginner]** Do I really need a signed-in user for the *public* database?

Yes you need a signed user to write but not to read.

> **[Beginner]** When does data move between development and production?

There's a promotion functionality in the dashboard

> **[Beginner]** Is my container tied to one app, or can several apps share it?

Yes

### Authenticaion

There are 3 kinds of authentication (more like 2.5):

#### API Token

The most basic authentication is the API Token. You can retrieve this through the cloudkit dashboard. The API token doesn't really give you access to much however it's important for the next authentication method.

> **[Author]** What does API Token give you at all?
>
> **Answer:** Identifies your container to CloudKit Web Services. Alone (no user sign-in), it mainly allows unauthenticated **public** database access (e.g. world-readable reads). It does not open private/shared data; it is also the prerequisite for the web-auth login flow.

#### Web Token

With the API Token, you can add a login to your web page and retrieve the users web token. With the web token, you'll have access to the user's private database.

> **[Author]** Does the Web Token give you access to the public database?
>
> **Answer:** Yes. API token + web auth token can target public, private, and shared. Private/shared require web auth; public can use web auth or server-to-server.

> **[Author]** How long does a web auth token last, and how do I refresh it?
>
> **Answer:** Apple *does* document this, in the archived [Setting Up Web Services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html) — "Use and Duration of the Web Authentication Token." Two separate facts, and the second one is the surprising one:
>
> **Duration:** 30 minutes by default. If the user ticks **"Keep me signed in"** in the sign-in window, 2 weeks.
>
> **Rotation — the part nobody expects:** the token is **single-use**. Quoting directly:
>
> > "Each token is intended for a single round trip to the server. Whenever a token is sent to the server, a new token is provided in the response from the server. Once the response is received, the previous token is no longer valid. It must be discarded and the new, returned token used in the next request."
>
> So it isn't a session token that sits still for 30 minutes — it's a rolling credential that changes on *every single request*. The 30 minutes is the window in which the *chain* stays alive, not the lifetime of any one string.
>
> **What this means architecturally** — this is the good slide:
> - There's no refresh *endpoint*; refresh is a side effect of every call. You must read the new token out of each response and write it back to wherever you're storing it.
> - **Storage must be serialized.** Two concurrent requests sharing one stored token means one of them is using a token the other already burned. A web app with an async page load can hit this immediately. This is an actor-shaped problem, and it's why `AdaptiveTokenManager` is an `actor` with a `TokenStorage` seam rather than a struct.
> - Restarting your server mid-chain loses the token unless you persisted the latest one.
> - "Keep me signed in" changes the UX story: without it, a user who walks away for lunch comes back to a re-auth.
>
> **Honest caveat for the talk:** MistKit does not currently rotate this automatically. `WebAuthTokenManager` holds `webAuthToken` as an immutable `let`, and the rotated token in the response isn't modeled in `openapi.yaml` at all. `AdaptiveTokenManager` has the mutable slot and the storage hook, but it's upgraded by hand — nothing reads the new token off a response. That's a genuine gap worth naming on stage rather than glossing: today the practical workaround is "Keep me signed in" plus catching `AUTHENTICATION_REQUIRED` and re-running the sign-in flow:
>
> ```swift
> catch let error as CloudKitError where error.serverErrorCode == .authenticationRequired {
>     if let redirectURL = error.redirectURL { response.redirect(to: redirectURL) }
> }
> ```

##### CKFetchWebAuthTokenOperation

If you want to you can actually grab the user's web token using the CKFetchWebAuthTokenOperation.

> **[Beginner]** If my iOS app can already talk to CloudKit, why hand a token to a server at all?

> **[Beginner]** Does the token from `CKFetchWebAuthTokenOperation` rotate the same way?

#### Server to Server

> **[Author]** Why would I use server-to-server instead of web auth for the public database?
>
> **Answer:** Because server-to-server is the only method that doesn't need a human. Web auth authenticates *a user*; server-to-server authenticates *your server*. Three practical consequences:
>
> 1. **Writes.** Public-database writes need an authenticated identity. Server-to-server gives you one without anyone signing in.
> 2. **No expiry, no rotation.** An ECDSA key pair does not expire on its own. A web auth token expires in 30 minutes (2 weeks with "Keep me signed in") *and* is single-use, rotating on every request. A nightly cron job on a web auth token wouldn't just eventually stop — it would be dead by the second night, and you'd be storing a credential that changes under you on every call. Server-to-server has neither problem: the same key signs every request, forever.
> 3. **Attribution.** Records written with server-to-server belong to your service, not to whichever user happened to be signed in.
>
> Bushel is the concrete case: a GitHub Action runs on a stock `ubuntu-latest` runner, pulls restore-image data, and writes it to the public database. There is no user in that story to sign in. The key is a GitHub Actions secret injected as `CLOUDKIT_PRIVATE_KEY`, so it never touches disk.
>
> The mirror-image of this is why *shared* and *private* reject server-to-server outright — there's no such thing as "your server's private database."

> **[Beginner]** Whose key is it — do I get it from Apple?

> **[Beginner]** What actually gets signed on each request?

> **[Beginner]** How do I rotate a key without downtime?

#### Compare Capabilities

> **[Beginner]** Which method do I pick? Can I just use one for everything?

> **[Beginner]** Do all three databases support all the same operations?

## What is CloudKit Web Services?

> **[Beginner]** How does CloudKit Web Services differ from the CloudKit framework I’d use in an iOS app?

CloudKit Web Services is a REST API while the CloudKit framework is a built-in.

> **[Beginner]** Same data, or a different copy?

> **[Beginner]** How old is this API — is it deprecated?

> **[Beginner]** Is this the same thing as CloudKit JS?

## Why Server Side Cloud

> **[Beginner]** Can Linux / a Vapor server use the CloudKit framework, or only Web Services (MistKit)?

No it's only available on Apple devices.

> **[Beginner]** Why not just use Firebase / Supabase / my own Postgres?

> **[Beginner]** Isn't this locking me into Apple?

### Private Database

When I was writing Heartwitch, I wanted a user to have an easy way to login on the Apple Watch without having to type their username and password. Unfortunetly Sign in with Appple was not available and frankly I was intimidated by setting it up on the server. Why not use something already built in on the device with CloudKit.

This was great however I had a separate login mechanism for the website. I needed a way to link someone's Apple Watch to that login. I ended up adding to the website the ability to login into CloudKit.

1. Run Apple Watch app, adds Apple Watch record to CloudKit.
2. Login into Website.
3. Login into CloudKit from Website.
4. Pulls Apple Watch from CloudKit and adds it to Postgres.
5. User runs workout and passed Apple Watch id; Vapor knows how it is and heart rate shows up on web page.

> **[Author]** What happens to a user’s private database data if they delete the app or their iCloud account?
>
> **Answer:** Three different outcomes worth separating, because people conflate them:
>
> - **Delete the app** — the private data survives. It lives in the user's iCloud account, not in the app sandbox. Reinstall and it's there. (This is a *feature* people don't expect; it's also why "delete the app to reset" doesn't work as a support answer.)
> - **Sign out of iCloud / turn off iCloud Drive** — the data is intact on the server but the device can't reach it. Private database availability is literally gated on `ubiquityIdentityToken` being non-nil.
> - **Delete the iCloud account** — the data is gone, and you cannot recover it. You never had a copy.
>
> The consequence for Heart Witch's architecture is the interesting bit for the talk: **step 4 is the safety net.** Copying the watch ID into Postgres means the web side keeps working even though the CloudKit record is outside my control. If you're bridging CloudKit into your own backend, treat the CloudKit private database as an *input*, not as your system of record.

> **[Beginner]** Can I see or debug a user's private data in the dashboard?

> **[Beginner]** So does Heart Witch's website break 30 minutes after I sign in?

> **[Beginner]** How does sharing work — is that the third database?

### Public Database

My app Bushel is a macOS virtual machine app for developers. Part of using bushel is being able to install any available macOS version. What I need is the ability to pull the list of restore images (installer images) and know what is available, what is signed, and what versions of Xcode and Swift are available.

Bushel doesn't need a backend really but I need a place to store this information and easily and cheaply update it. This gave me the oppurtuniy to use a public database and able to update it easily in the cloud.

> **[Beginner]** How do I stop users from writing to the public database?

## Building MistKit

In 2020 I began the journey of building MistKit for heartwitch specifically. There were a few issues:

1. I had to hand write the client code for both URLSession and server-side AsyncHTTPClient (without async/await)
2. I had to hand write each api call based on the apple documentation.

### OpenAPI Generator

#### Introduce openapi.yaml

openapi formerlly swagger is a standard for yaml-based spec for describing a REST API. It allows client-side developers to know the variety of calls and many languages have the ability to easily write client-side code for the various calls.
Thankfully in 20**, the Swift OpenAPI Generator was released.

> **[Beginner]** Why generate a client instead of just writing `URLSession` calls?

Because when you are running on a non-Apple device or doing server-side calls, it's best to use a client that's SwiftNIO based. SwiftNIO is a dedicated networking stack written by many folks at Apple specically for server-side development.

### Using AI to create an openapi.yaml

> **[Beginner]** Can I trust an AI-generated spec?

No that's why I insist on not only unit tests but integration tests via a web dashboard.

> **[Beginner]** What did the AI get wrong?

1. Authenitcation
2. Field Types
3. Bad Documentation

## Authentication

### Using OpenAPI Middleware 

> **[Beginner]** What is middleware doing here, and why is auth a good fit for it?

The Swift OpenAPI suite contains a middleware layer that allows the you to either make sure changes to the request before the server receives it or before the client sends it.

> **[Beginner]** Can I plug in my own credential source — a secrets vault, or rotation?

Yes there's a pluggable API you can implement. 

> **[Author]** What is the protocol which the developer needs to implement?

#### API Token

#### Web Token

##### CKFetchWebAuthTokenOperation

#### Server to Server

## Field Types

> **[Beginner]** Are assets (images/files) stored differently from normal fields, and do they count against the same quotas?

> **[Beginner]** Why is a "type" needed at all — can't you tell from the JSON?

> **[Beginner]** How do you map a dynamically-typed field into Swift?

> **[Beginner]** What happens if the server sends something that doesn't fit?

## Error Handling

> **[Beginner]** What does a CloudKit error actually look like on the wire?

> **[Beginner]** Which errors should I retry, and which mean stop?

> **[Beginner]** If I save 200 records and one fails, do I lose all 200?

### NEW ERRORS

## Deployment

> **[Beginner]** Where do I actually run this — do I need a server?

> **[Beginner]** How do I keep the private key out of my repo?

> **[Beginner]** How do I test against CloudKit without wrecking my production data?

> **[Beginner]** Does this really run on Linux? What about Windows and Android?
