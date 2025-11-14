<!--
Downloaded via https://llm.codes by @steipete on November 4, 2025 at 03:40 PM
Source URL: https://developer.apple.com/documentation/cktooljs/
Total pages processed: 41
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/documentation/cktooljs/

Framework

# CKTool JS

Manage your CloudKit containers and databases from JavaScript.

CKTool JS 1.2.15+

## Overview

CKTool JS gives you access to features provided in the CloudKit Console API, facilitating CloudKit setup operations for local development and integration testing. It’s a JavaScript client library alternative to the macOS `cktool` command-line utility distributed with Xcode. To learn more about `cktool`, see Automating CloudKit Development.

With this library, you can:

- Apply a CloudKit schema file to Sandbox databases (for more information about CloudKit schema files, see Integrating a Text-Based Schema into Your Workflow).

- Populate databases with test data.

- Reset Sandbox databases to the production configuration.

- Write scripts for your integration tests to incorporate.

The library consists of three main modules:

- `CKToolDatabaseModule`: This package contains all the CloudKit related types and methods, operations to fetch teams and containers for the authorized user, and utility functions and types to communicate with the CloudKit servers. This package also contains operations to work with CloudKit records. You include `@apple/cktool.database` as a dependency in your `package.json` file to access this package.

- `CKToolNodeJsModule`: This package contains a `createConfiguration` function you use in projects intended to run in Node.js. You include `@apple/cktool.target.nodejs` as a dependency in your `package.json` file to access this package.

- `CKToolBrowserModule`: This package contains a `createConfiguration` function for use in browser-based projects. You include `@apple/cktool.target.browser` as a dependency in your `package.json` file to access this package.

## Topics

### Essentials

Integrating CloudKit access into your JavaScript automation scripts

Configure your JavaScript project to use CKTool JS.

### Promises API

`PromisesApi`

A class that exposes promise-based functions for interacting with the API.

`CancellablePromise`

A promise that has a function to cancel its operation.

`CKToolDatabaseModule`

The imported package that provides access to CloudKit containers and databases.

### Configuration

`Configuration`

An object you use to hold options for communicating with the API server.

`CKToolNodeJsModule`

The imported package that supports using the client library within a Node.js environment.

`CKToolBrowserModule`

The imported package that supports using the client library within a web browser.

### Global Structures and Enumerations

`Container`

Details about a CloudKit container.

`ContainersResponse`

An object that represents results of fetching multiple CloudKit containers.

`CKEnvironment`

An enumeration of container environments.

`ContainersSortByField`

An enumeration that indicates sorting options for retrieved containers.

`SortDirection`

An enumeration that indicates sorting direction when applying a custom sort.

### Errors

`ErrorBase`

The base class of any error emitted by functions in the client library.

### Classes

`Blob`

`File`

---

# https://developer.apple.com/documentation/cktooljs

Framework

# CKTool JS

Manage your CloudKit containers and databases from JavaScript.

CKTool JS 1.2.15+

## Overview

CKTool JS gives you access to features provided in the CloudKit Console API, facilitating CloudKit setup operations for local development and integration testing. It’s a JavaScript client library alternative to the macOS `cktool` command-line utility distributed with Xcode. To learn more about `cktool`, see Automating CloudKit Development.

With this library, you can:

- Apply a CloudKit schema file to Sandbox databases (for more information about CloudKit schema files, see Integrating a Text-Based Schema into Your Workflow).

- Populate databases with test data.

- Reset Sandbox databases to the production configuration.

- Write scripts for your integration tests to incorporate.

The library consists of three main modules:

- `CKToolDatabaseModule`: This package contains all the CloudKit related types and methods, operations to fetch teams and containers for the authorized user, and utility functions and types to communicate with the CloudKit servers. This package also contains operations to work with CloudKit records. You include `@apple/cktool.database` as a dependency in your `package.json` file to access this package.

- `CKToolNodeJsModule`: This package contains a `createConfiguration` function you use in projects intended to run in Node.js. You include `@apple/cktool.target.nodejs` as a dependency in your `package.json` file to access this package.

- `CKToolBrowserModule`: This package contains a `createConfiguration` function for use in browser-based projects. You include `@apple/cktool.target.browser` as a dependency in your `package.json` file to access this package.

## Topics

### Essentials

Integrating CloudKit access into your JavaScript automation scripts

Configure your JavaScript project to use CKTool JS.

### Promises API

`PromisesApi`

A class that exposes promise-based functions for interacting with the API.

`CancellablePromise`

A promise that has a function to cancel its operation.

`CKToolDatabaseModule`

The imported package that provides access to CloudKit containers and databases.

### Configuration

`Configuration`

An object you use to hold options for communicating with the API server.

`CKToolNodeJsModule`

The imported package that supports using the client library within a Node.js environment.

`CKToolBrowserModule`

The imported package that supports using the client library within a web browser.

### Global Structures and Enumerations

`Container`

Details about a CloudKit container.

`ContainersResponse`

An object that represents results of fetching multiple CloudKit containers.

`CKEnvironment`

An enumeration of container environments.

`ContainersSortByField`

An enumeration that indicates sorting options for retrieved containers.

`SortDirection`

An enumeration that indicates sorting direction when applying a custom sort.

### Errors

`ErrorBase`

The base class of any error emitted by functions in the client library.

### Classes

`Blob`

`File`

---

# https://developer.apple.com/documentation/cktooljs/cktooldatabasemodule



---

# https://developer.apple.com/documentation/cktooljs/cktoolnodejsmodule



---

# https://developer.apple.com/documentation/cktooljs/cktoolnodejsmodule/createconfiguration



---

# https://developer.apple.com/documentation/cktooljs/cktoolbrowsermodule



---

# https://developer.apple.com/documentation/cktooljs/cktoolbrowsermodule/createconfiguration



---

# https://developer.apple.com/documentation/cktooljs/integrating-cloudkit-access-into-your-javascript-automation-scripts



---

# https://developer.apple.com/documentation/cktooljs/promisesapi



---

# https://developer.apple.com/documentation/cktooljs/cancellablepromise



---

# https://developer.apple.com/documentation/cktooljs/configuration



---

# https://developer.apple.com/documentation/cktooljs/container



---

# https://developer.apple.com/documentation/cktooljs/containersresponse



---

# https://developer.apple.com/documentation/cktooljs/ckenvironment



---

# https://developer.apple.com/documentation/cktooljs/containerssortbyfield



---

# https://developer.apple.com/documentation/cktooljs/sortdirection



---

# https://developer.apple.com/documentation/cktooljs/errorbase



---

# https://developer.apple.com/documentation/cktooljs/database-length-validation-and-value-errors



---

# https://developer.apple.com/documentation/cktooljs/blob



---

# https://developer.apple.com/documentation/cktooljs/file



---

# https://developer.apple.com/documentation/cktooljs/cktooldatabasemodule):



---

# https://developer.apple.com/documentation/cktooljs/cktoolnodejsmodule):



---

# https://developer.apple.com/documentation/cktooljs/cktoolnodejsmodule/createconfiguration)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/cktooljs/cktoolbrowsermodule):



---

# https://developer.apple.com/documentation/cktooljs/cktoolbrowsermodule/createconfiguration)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/cktooljs/integrating-cloudkit-access-into-your-javascript-automation-scripts)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/cktooljs/promisesapi)



---

# https://developer.apple.com/documentation/cktooljs/cancellablepromise)



---

# https://developer.apple.com/documentation/cktooljs/cktooldatabasemodule)



---

# https://developer.apple.com/documentation/cktooljs/configuration)



---

# https://developer.apple.com/documentation/cktooljs/cktoolnodejsmodule)



---

# https://developer.apple.com/documentation/cktooljs/cktoolbrowsermodule)



---

# https://developer.apple.com/documentation/cktooljs/container)



---

# https://developer.apple.com/documentation/cktooljs/containersresponse)



---

# https://developer.apple.com/documentation/cktooljs/ckenvironment)



---

# https://developer.apple.com/documentation/cktooljs/containerssortbyfield)



---

# https://developer.apple.com/documentation/cktooljs/sortdirection)



---

# https://developer.apple.com/documentation/cktooljs/errorbase)



---

# https://developer.apple.com/documentation/cktooljs/database-length-validation-and-value-errors)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/cktooljs/blob)



---

# https://developer.apple.com/documentation/cktooljs/file)



---

