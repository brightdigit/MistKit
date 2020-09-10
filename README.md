
<p align="center">
    <img alt="MistKit" title="MistKit" src="Assets/logo.svg" height="200">
</p>
<h1 align="center"> MistKit </h1>

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Twitter](https://img.shields.io/badge/twitter-@brightdigit-blue.svg?style=flat)](http://twitter.com/brightdigit)
![GitHub](https://img.shields.io/github/license/brightdigit/MistKit)
![GitHub issues](https://img.shields.io/github/issues/brightdigit/MistKit)

[![macOS](https://github.com/brightdigit/MistKit/workflows/macOS/badge.svg)](https://github.com/brightdigit/MistKit/actions?query=workflow%3AmacOS)
[![ubuntu](https://github.com/brightdigit/MistKit/workflows/ubuntu/badge.svg)](https://github.com/brightdigit/MistKit/actions?query=workflow%3Aubuntu)
[![Travis (.com)](https://img.shields.io/travis/com/brightdigit/MistKit?logo=travis)](https://travis-ci.com/brightdigit/MistKit)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/MistKit)](https://codecov.io/gh/brightdigit/MistKit)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/MistKit)](https://www.codefactor.io/repository/github/brightdigit/MistKit)
[![codebeat badge](https://codebeat.co/badges/c47b7e58-867c-410b-80c5-57e10140ba0f)](https://codebeat.co/projects/github-com-brightdigit-mistkit-main)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/brightdigit/MistKit)](https://codeclimate.com/github/brightdigit/MistKit)
[![Code Climate technical debt](https://img.shields.io/codeclimate/tech-debt/brightdigit/MistKit?label=debt)](https://codeclimate.com/github/brightdigit/MistKit)
[![Code Climate issues](https://img.shields.io/codeclimate/issues/brightdigit/MistKit)](https://codeclimate.com/github/brightdigit/MistKit)

[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

---

Access CloudKit outside of the CloudKit framework via Web Services. Why?

* Building a Command Line Application
* Required for Server-Side Integration (via Vapor)
* Access via AWS Lambda 

... and more

```
import MistKit

let token = "***"

let apiKey = "***"
let container = "iCloud.com.brightdigit.MistDemo"

let dbConnection = MKDatabaseConnection(
  container: container, 
  apiToken: apiKey, 
  environment: .development
)

let client = MKURLSessionClient(session: .shared)
let database = MKDatabase(
  connection: dbConnection,
  factory: MKURLBuilderFactory(),
  client: client,
  authenticationToken: token
)

var recordsResult: Result<[TodoListItem], Error>?
let getTodosQuery = FetchRecordQueryRequest(
  database: .private,
  query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self))
)

database.query(getTodosQuery) { result in
  dump(result)
}
```

# Features 

- [x] Composing Web Service Requests
- [ ] Modifying Records (records/modify)
- [x] Fetching Records Using a Query (records/query)
- [ ] Fetching Records by Record Name (records/lookup)
- [ ] Fetching Record Changes (records/changes)
- [ ] Fetching Record Information (records/resolve)
- [ ] Accepting Share Records (records/accept)
- [ ] Uploading Assets (assets/upload)
- [ ] Referencing Existing Assets (assets/rereference)
- [ ] Fetching Zones (zones/list)
- [ ] Fetching Zones by Identifier (zones/lookup)
- [ ] Modifying Zones (zones/modify)
- [ ] Fetching Database Changes (changes/database)
- [ ] Fetching Record Zone Changes (changes/zone)
- [ ] Fetching Zone Changes (zones/changes)
- [ ] Fetching Current User Identity (users/caller)
- [ ] Discovering User Identities (POST users/discover)
- [ ] Discovering All User Identities (GET users/discover)
- [x] Fetching Current User (users/current)
- [ ] Fetching Contacts (users/lookup/contacts)
- [ ] Fetching Users by Email (users/lookup/email)
- [ ] Fetching Users by Record Name (users/lookup/id)
- [ ] Fetching Subscriptions (subscriptions/list)
- [ ] Fetching Subscriptions by Identifier (subscriptions/lookup)
- [ ] Modifying Subscriptions (subscriptions/modify)
- [ ] Creating APNs Tokens (tokens/create)
- [ ] Registering Tokens (tokens/register)
- [ ] Types and Dictionaries
- [ ] Error Codes
- [ ] Data Size Limits

# Requirements 

[Documentation Here](/docs/README.md)
