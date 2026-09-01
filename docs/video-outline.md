# MistKit

## What is CloudKit?

CloudKit is Apple's backend cloud database available to developers. 

> **[Author]** How much does it cost?
>
> **Answer:** No separate CloudKit fee beyond the Apple Developer Program (~$99/yr). Quotas (storage, transfer, requests) scale with active users; exceeding them typically returns `quotaExceeded` / throttles. Apple does not currently publish a clear public overage price list.

> **[Author]** What kind of database would it be called? It's not _relational_.
>
> **Answer:** NoSQL / document-oriented (schema-based record store). Records have typed fields; links use references, not SQL joins.

## Introduction

## Some basics about CloudKit

### Databases

CloudKit supports 2 kinds of databases: a public and a private database. Private is exclusive to a single user but allows the ability to share records while Public is shared over the entire system. 
A great example is what I'll doing with my RSS app. The public database will contain the RSS content shared amongst all users while the private database will contain a user's particular reading status and subscriptions. The only requirement is the user is signed in on their device to access either database.

Besides the databases, theres environments. Environments allow you to test and develop against a development or production environment safely as well as deployment content back and forth.

### Records

> **[Beginner]** What is a record type / zone / subscription in plain terms?

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

##### CKFetchWebAuthTokenOperation

If you want to you can actually grab the user's web token using the CKFetchWebAuthTokenOperation.

#### Server to Server

> **[Author]** Why would I use server-to-server instead of web auth for the public database?

#### Compare Capabilities

## What is CloudKit Web Services?

> **[Beginner]** How does CloudKit Web Services differ from the CloudKit framework I’d use in an iOS app?

CloudKit Web Services is a REST API while the CloudKit framework is a built-in.

## Why Server Side Cloud

> **[Beginner]** Can Linux / a Vapor server use the CloudKit framework, or only Web Services (MistKit)?

No it's only available on Apple devices.

### Private Database

When I was writing Heartwitch, I wanted a user to have an easy way to login on the Apple Watch without having to type their username and password. Unfortunetly Sign in with Appple was not available and frankly I was intimidated by setting it up on the server. Why not use something already built in on the device with CloudKit.

This was great however I had a separate login mechanism for the website. I needed a way to link someone's Apple Watch to that login. I ended up adding to the website the ability to login into CloudKit.

1. Run Apple Watch app, adds Apple Watch record to CloudKit.
2. Login into Website.
3. Login into CloudKit from Website.
4. Pulls Apple Watch from CloudKit and adds it to Postgres.
5. User runs workout and passed Apple Watch id; Vapor knows how it is and heart rate shows up on web page.

> **[Author]** What happens to a user’s private database data if they delete the app or their iCloud account?

### Public Database

My app Bushel is a macOS virtual machine app for developers. Part of using bushel is being able to install any available macOS version. What I need is the ability to pull the list of restore images (installer images) and know what is available, what is signed, and what versions of Xcode and Swift are available.

Bushel doesn't need a backend really but I need a place to store this information and easily and cheaply update it. This gave me the oppurtuniy to use a public database and able to update it easily in the cloud.

## Building MistKit

### OpenAPI Generator

#### Introduce openapi.yaml

### Using AI to create an openapi.yaml

## Authentication

### Using OpenAPI Middleware 

#### API Token

#### Web Token

##### CKFetchWebAuthTokenOperation

#### Server to Server

## Field Types

> **[Beginner]** Are assets (images/files) stored differently from normal fields, and do they count against the same quotas?

## Error Handling

### NEW ERRORS

## Deployment
