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

CloudKit supports 2 kinds of databases: a public and a private database. Private is exclusive to a single user while Public is shared over the entire system.
A great example is what I'll doing with my RSS app. The public database will contain the RSS content shared amongst all users while the private database will contain a user's particular reading status and subscriptions.

> **[Beginner]** Is there a third database — shared — and when would I use it vs public?

> **[Beginner]** Do I need an iCloud-signed-in user on device to read the public database?

> **[Beginner]** What’s the difference between development and production environments, and how do I promote a schema?

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

> **[Beginner]** How long does a web auth token last, and how do I refresh it?

##### CKFetchWebAuthTokenOperation

If you want to you can actually grab the user's web token using the CKFetchWebAuthTokenOperation.

#### Server to Server

> **[Beginner]** Why would I use server-to-server instead of web auth for the public database?

#### Compare Capabilities

## What is CloudKit Web Services?

> **[Beginner]** How does CloudKit Web Services differ from the CloudKit framework I’d use in an iOS app?

## Why Server Side Cloud

> **[Beginner]** Can Linux / a Vapor server use the CloudKit framework, or only Web Services (MistKit)?

### Private Database

> **[Beginner]** What happens to a user’s private database data if they delete the app or their iCloud account?

### Public Database

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
