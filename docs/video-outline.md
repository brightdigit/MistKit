# MistKit

## What is CloudKit?

CloudKit is Apple's backend cloud database available to developers. 

> How much does it cost?

> What kind of database would it be called? It's not _relational_.

## Introduction

## Some basics about CloudKit

### Databases

CloudKit supports 2 kinds of databases: a public and a private database. Private is exclusive to a single user while Public is shared over the entire system.
A great example is what I'll doing with my RSS app. The public database will contain the RSS content shared amongst all users while the private database will contain a user's particular reading status and subscriptions.

### Authenticaion

There are 3 kinds of authentication (more like 2.5):

#### API Token

The most basic authentication is the API Token. You can retrieve this through the cloudkit dashboard. The API token doesn't really give you access to much however it's important for the next authentication method.

> What does API Token give you at all?

#### Web Token

With the API Token, you can add a login to your web page and retrieve the users web token. With the web token, you'll have access to the user's private database.

> Does the Web Token give you access to the public database?

##### CKFetchWebAuthTokenOperation

If you want to you can actually grab the user's web token using the CKFetchWebAuthTokenOperation.

#### Server to Server

#### Compare Capabilities

## What is CloudKit Web Services?

## Why Server Side Cloud

### Private Database

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

## Error Handling

### NEW ERRORS

## Deployment