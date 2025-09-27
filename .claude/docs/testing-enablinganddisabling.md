<!--
Downloaded via https://llm.codes by @steipete on September 24, 2025 at 04:43 PM
Source URL: https://developer.apple.com/documentation/testing/enablinganddisabling
Total pages processed: 105
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/documentation/testing/enablinganddisabling

- Swift Testing
- Traits
- Enabling and disabling tests

Article

# Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

## Overview

Often, a test is only applicable in specific circumstances. For instance, you might want to write a test that only runs on devices with particular hardware capabilities, or performs locale-dependent operations. The testing library allows you to add traits to your tests that cause runners to automatically skip them if conditions like these are not met.

### Disable a test

If you need to disable a test unconditionally, use the `disabled(_:sourceLocation:)` function. Given the following test function:

@Test("Food truck sells burritos")
func sellsBurritos() async throws { ... }

Add the trait _after_ the test’s display name:

@Test("Food truck sells burritos", .disabled())
func sellsBurritos() async throws { ... }

The test will now always be skipped.

It’s also possible to add a comment to the trait to present in the output from the runner when it skips the test:

@Test("Food truck sells burritos", .disabled("We only sell Thai cuisine"))
func sellsBurritos() async throws { ... }

### Enable or disable a test conditionally

Sometimes, it makes sense to enable a test only when a certain condition is met. Consider the following test function:

@Test("Ice cream is cold")
func isCold() async throws { ... }

If it’s currently winter, then presumably ice cream won’t be available for sale and this test will fail. It therefore makes sense to only enable it if it’s currently summer. You can conditionally enable a test with `enabled(if:_:sourceLocation:)`:

@Test("Ice cream is cold", .enabled(if: Season.current == .summer))
func isCold() async throws { ... }

It’s also possible to conditionally _disable_ a test and to combine multiple conditions:

@Test(
"Ice cream is cold",
.enabled(if: Season.current == .summer),
.disabled("We ran out of sprinkles")
)
func isCold() async throws { ... }

If a test is disabled because of a problem for which there is a corresponding bug report, you can use one of these functions to show the relationship between the test and the bug report:

- `bug(_:_:)`

- `bug(_:id:_:)`

For example, the following test cannot run due to bug number `"12345"`:

@Test(
"Ice cream is cold",
.enabled(if: Season.current == .summer),
.disabled("We ran out of sprinkles"),
.bug(id: "12345")
)
func isCold() async throws { ... }

If a test has multiple conditions applied to it, they must _all_ pass for it to run. Otherwise, the test notes the first condition to fail as the reason the test is skipped.

### Handle complex conditions

If a condition is complex, consider factoring it out into a helper function to improve readability:

@Test(
"Can make sundaes",
.enabled(if: Season.current == .summer),
.enabled(if: allIngredientsAvailable(for: .sundae))
)
func makeSundae() async throws { ... }

## See Also

### Customizing runtime behaviors

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing

Framework

# Swift Testing

Create and run tests for your Swift packages and Xcode projects.

Swift 6.0+Xcode 16.0+

## Overview

With Swift Testing you leverage powerful and expressive capabilities of the Swift programming language to develop tests with more confidence and less code. The library integrates seamlessly with Swift Package Manager testing workflow, supports flexible test organization, customizable metadata, and scalable test execution.

- Define test functions almost anywhere with a single attribute.

- Group related tests into hierarchies using Swift’s type system.

- Integrate seamlessly with Swift concurrency.

- Parameterize test functions across wide ranges of inputs.

- Enable tests dynamically depending on runtime conditions.

- Parallelize tests in-process.

- Categorize tests using tags.

- Associate bugs directly with the tests that verify their fixes or reproduce their problems.

#### Related videos

![\\
\\
Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179)

![\\
\\
Go further with Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10195)

## Topics

### Essentials

Defining test functions

Define a test function to validate that code is working correctly.

Organizing test functions with suite types

Organize tests into test suites.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`macro Test(String?, any TestTrait...)`

Declare a test.

`struct Test`

A type representing a test or suite.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

### Test parameterization

Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

Declare a test parameterized over a collection of values.

Declare a test parameterized over two collections of values.

Declare a test parameterized over two zipped collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

`struct Case`

A single test case from a parameterized `Test`.

### Behavior validation

Check for expected values, outcomes, and asynchronous events in tests.

Mark issues as known when running tests.

### Test customization

Annotate test functions and suites, and customize their behavior.

### Data collection

Attach values to tests to help diagnose issues and gather feedback.

---

# https://developer.apple.com/documentation/testing/traits

Collection

- Swift Testing
- Traits

API Collection

# Traits

Annotate test functions and suites, and customize their behavior.

## Overview

Pass built-in traits to test functions or suite types to comment, categorize, classify, and modify the runtime behavior of test suites and test functions. Implement the `TestTrait`, and `SuiteTrait` protocols to create your own types that customize the behavior of your tests.

## Topics

### Customizing runtime behaviors

Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

Construct a time limit trait that causes a test to time out if it runs for too long.

### Running tests serially or in parallel

Running tests serially or in parallel

Control whether tests run serially or in parallel.

`static var serialized: ParallelizationTrait`

A trait that serializes the test to which it is applied.

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Associating bugs with tests

Associate bugs uncovered or verified by tests.

Interpreting bug identifiers

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

Constructs a bug to track with a test.

### Handling issues

Constructs an trait that transforms issues recorded by a test.

Constructs a trait that filters issues recorded by a test.

### Creating custom traits

`protocol Trait`

A protocol describing traits that can be added to a test function or to a test suite.

`protocol TestTrait`

A protocol describing a trait that you can add to a test function.

`protocol SuiteTrait`

A protocol describing a trait that you can add to a test suite.

`protocol TestScoping`

A protocol that tells the test runner to run custom code before or after it runs a test suite or test function.

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/trait/disabled(_:sourcelocation:)

#app-main)

- Swift Testing
- Trait
- disabled(\_:sourceLocation:)

Type Method

# disabled(\_:sourceLocation:)

Constructs a condition trait that disables a test unconditionally.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func disabled(
_ comment: Comment? = nil,
sourceLocation: SourceLocation = #_sourceLocation

Available when `Self` is `ConditionTrait`.

## Parameters

`comment`

An optional comment that describes this trait.

`sourceLocation`

The source location of the trait.

## Return Value

An instance of `ConditionTrait` that always disables the test to which it is added.

## Mentioned in

Enabling and disabling tests

Organizing test functions with suite types

## See Also

### Customizing runtime behaviors

Conditionally enable or disable individual tests before they run.

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test if its value is true.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing/trait/enabled(if:_:sourcelocation:)

#app-main)

- Swift Testing
- Trait
- enabled(if:\_:sourceLocation:)

Type Method

# enabled(if:\_:sourceLocation:)

Constructs a condition trait that disables a test if it returns `false`.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func enabled(

_ comment: Comment? = nil,
sourceLocation: SourceLocation = #_sourceLocation

Available when `Self` is `ConditionTrait`.

## Parameters

`condition`

A closure that contains the trait’s custom condition logic. If this closure returns `true`, the trait allows the test to run. Otherwise, the testing library skips the test.

`comment`

An optional comment that describes this trait.

`sourceLocation`

The source location of the trait.

## Return Value

An instance of `ConditionTrait` that evaluates the closure you provide.

## Mentioned in

Enabling and disabling tests

## See Also

### Customizing runtime behaviors

Conditionally enable or disable individual tests before they run.

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing/trait/bug(_:_:)

#app-main)

- Swift Testing
- Trait
- bug(\_:\_:)

Type Method

# bug(\_:\_:)

Constructs a bug to track with a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func bug(
_ url: String,
_ title: Comment? = nil

Available when `Self` is `Bug`.

## Parameters

`url`

A URL that refers to this bug in the associated bug-tracking system.

`title`

Optionally, the human-readable title of the bug.

## Return Value

An instance of `Bug` that represents the specified bug.

## Mentioned in

Associating bugs with tests

Interpreting bug identifiers

Enabling and disabling tests

## See Also

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Associate bugs uncovered or verified by tests.

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

---

# https://developer.apple.com/documentation/testing/trait/bug(_:id:_:)-10yf5

-10yf5#app-main)

- Swift Testing
- Trait
- bug(\_:id:\_:)

Type Method

# bug(\_:id:\_:)

Constructs a bug to track with a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func bug(
_ url: String? = nil,
id: String,
_ title: Comment? = nil

Available when `Self` is `Bug`.

## Parameters

`url`

A URL that refers to this bug in the associated bug-tracking system.

`id`

The unique identifier of this bug in its associated bug-tracking system.

`title`

Optionally, the human-readable title of the bug.

## Return Value

An instance of `Bug` that represents the specified bug.

## Mentioned in

Enabling and disabling tests

Interpreting bug identifiers

Associating bugs with tests

## See Also

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Associate bugs uncovered or verified by tests.

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

---

# https://developer.apple.com/documentation/testing/trait/bug(_:id:_:)-3vtpl

-3vtpl#app-main)

- Swift Testing
- Trait
- bug(\_:id:\_:)

Type Method

# bug(\_:id:\_:)

Constructs a bug to track with a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func bug(
_ url: String? = nil,
id: some Numeric,
_ title: Comment? = nil

Available when `Self` is `Bug`.

## Parameters

`url`

A URL that refers to this bug in the associated bug-tracking system.

`id`

The unique identifier of this bug in its associated bug-tracking system.

`title`

Optionally, the human-readable title of the bug.

## Return Value

An instance of `Bug` that represents the specified bug.

## Mentioned in

Interpreting bug identifiers

Associating bugs with tests

Enabling and disabling tests

## See Also

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Associate bugs uncovered or verified by tests.

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

---

# https://developer.apple.com/documentation/testing/limitingexecutiontime

- Swift Testing
- Traits
- Limiting the running time of tests

Article

# Limiting the running time of tests

Set limits on how long a test can run for until it fails.

## Overview

Some tests may naturally run slowly: they may require significant system resources to complete, may rely on downloaded data from a server, or may otherwise be dependent on external factors.

If a test may hang indefinitely or may consume too many system resources to complete effectively, consider setting a time limit for it so that it’s marked as failing if it runs for an excessive amount of time. Use the `timeLimit(_:)` trait as an upper bound:

@Test(.timeLimit(.minutes(60))
func serve100CustomersInOneHour() async {
for _ in 0 ..< 100 {
let customer = await Customer.next()
await customer.order()
...
}
}

If the above test function takes longer than an hour (60 x 60 seconds) to execute, the task in which it’s running is cancelled and the test fails with an issue of kind `Issue.Kind.timeLimitExceeded(timeLimitComponents:)`.

The testing library may adjust the specified time limit for performance reasons or to ensure tests have enough time to run. In particular, a granularity of (by default) one minute is applied to tests. The testing library can also be configured with a maximum time limit per test that overrides any applied time limit traits.

### Apply time limits to test suites

When you apply a time limit to a test suite, the testing library recursively applies it to all test functions and child test suites within that suite. The time limit applies to each test in the test suite and any child test suites, or each test case for parameterized tests.

For example, if a suite contains five tests and you apply a time limit trait with a duration of one minute, then each test in the suite may run for up to one minute.

### Apply time limits to parameterized tests

When you apply a time limit to a parameterized test function, the testing library applies it to each invocation _separately_ so that if only some cases cause failures due to timeouts, then the testing library doesn’t incorrectly mark successful cases as failing.

## See Also

### Customizing runtime behaviors

Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing/trait/enabled(_:sourcelocation:_:)

#app-main)

- Swift Testing
- Trait
- enabled(\_:sourceLocation:\_:)

Type Method

# enabled(\_:sourceLocation:\_:)

Constructs a condition trait that disables a test if it returns `false`.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func enabled(
_ comment: Comment? = nil,
sourceLocation: SourceLocation = #_sourceLocation,

Available when `Self` is `ConditionTrait`.

## Parameters

`comment`

An optional comment that describes this trait.

`sourceLocation`

The source location of the trait.

`condition`

A closure that contains the trait’s custom condition logic. If this closure returns `true`, the trait allows the test to run. Otherwise, the testing library skips the test.

## Return Value

An instance of `ConditionTrait` that evaluates the closure you provide.

## See Also

### Customizing runtime behaviors

Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing/trait/disabled(if:_:sourcelocation:)

#app-main)

- Swift Testing
- Trait
- disabled(if:\_:sourceLocation:)

Type Method

# disabled(if:\_:sourceLocation:)

Constructs a condition trait that disables a test if its value is true.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func disabled(

_ comment: Comment? = nil,
sourceLocation: SourceLocation = #_sourceLocation

Available when `Self` is `ConditionTrait`.

## Parameters

`condition`

A closure that contains the trait’s custom condition logic. If this closure returns `false`, the trait allows the test to run. Otherwise, the testing library skips the test.

`comment`

An optional comment that describes this trait.

`sourceLocation`

The source location of the trait.

## Return Value

An instance of `ConditionTrait` that evaluates the closure you provide.

## See Also

### Customizing runtime behaviors

Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing/trait/disabled(_:sourcelocation:_:)

#app-main)

- Swift Testing
- Trait
- disabled(\_:sourceLocation:\_:)

Type Method

# disabled(\_:sourceLocation:\_:)

Constructs a condition trait that disables a test if its value is true.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static func disabled(
_ comment: Comment? = nil,
sourceLocation: SourceLocation = #_sourceLocation,

Available when `Self` is `ConditionTrait`.

## Parameters

`comment`

An optional comment that describes this trait.

`sourceLocation`

The source location of the trait.

`condition`

A closure that contains the trait’s custom condition logic. If this closure returns `false`, the trait allows the test to run. Otherwise, the testing library skips the test.

## Return Value

An instance of `ConditionTrait` that evaluates the specified closure.

## See Also

### Customizing runtime behaviors

Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

Limiting the running time of tests

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Construct a time limit trait that causes a test to time out if it runs for too long.

---

# https://developer.apple.com/documentation/testing/trait/timelimit(_:)

#app-main)

- Swift Testing
- Trait
- timeLimit(\_:)

Type Method

# timeLimit(\_:)

Construct a time limit trait that causes a test to time out if it runs for too long.

visionOSSwift 6.0+Xcode 16.0+

Available when `Self` is `TimeLimitTrait`.

## Parameters

`timeLimit`

The maximum amount of time the test may run for.

## Return Value

An instance of `TimeLimitTrait`.

## Mentioned in

Limiting the running time of tests

## Discussion

Test timeouts do not support high-precision, arbitrarily short durations due to variability in testing environments. You express the duration in minutes, with a minimum duration of one minute.

When you associate this trait with a test, that test must complete within a time limit of, at most, `timeLimit`. If the test runs longer, the testing library records a `Issue.Kind.timeLimitExceeded(timeLimitComponents:)` issue, which it treats as a test failure.

The testing library can use a shorter time limit than that specified by `timeLimit` if you configure it to enforce a maximum per-test limit. When you configure a maximum per-test limit, the time limit of the test this trait is applied to is the shorter of `timeLimit` and the maximum per-test limit. For information on configuring maximum per-test limits, consult the documentation for the tool you use to run your tests.

If a test is parameterized, this time limit is applied to each of its test cases individually. If a test has more than one time limit associated with it, the testing library uses the shortest time limit.

If you apply this trait to a test suite, then it sets the time limit for each test in the suite, or each test case in parameterized tests in the suite. For example, if a suite contains five tests and you apply a time limit trait with a duration of one minute, then each test in the suite may run for up to one minute.

## See Also

### Customizing runtime behaviors

Enabling and disabling tests

Conditionally enable or disable individual tests before they run.

Set limits on how long a test can run for until it fails.

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

---

# https://developer.apple.com/documentation/testing/traits)



---

# https://developer.apple.com/documentation/testing/trait/disabled(_:sourcelocation:))



---

# https://developer.apple.com/documentation/testing/trait/enabled(if:_:sourcelocation:)):

):#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/testing/trait/bug(_:_:))



---

# https://developer.apple.com/documentation/testing/trait/bug(_:id:_:)-10yf5)



---

# https://developer.apple.com/documentation/testing/trait/bug(_:id:_:)-3vtpl)



---

# https://developer.apple.com/documentation/testing/limitingexecutiontime)



---

# https://developer.apple.com/documentation/testing/trait/enabled(if:_:sourcelocation:))

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/testing/trait/enabled(_:sourcelocation:_:))



---

# https://developer.apple.com/documentation/testing/trait/disabled(if:_:sourcelocation:))

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/testing/trait/disabled(_:sourcelocation:_:))

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/testing/trait/timelimit(_:))



---

# https://developer.apple.com/documentation/testing/

Framework

# Swift Testing

Create and run tests for your Swift packages and Xcode projects.

Swift 6.0+Xcode 16.0+

## Overview

With Swift Testing you leverage powerful and expressive capabilities of the Swift programming language to develop tests with more confidence and less code. The library integrates seamlessly with Swift Package Manager testing workflow, supports flexible test organization, customizable metadata, and scalable test execution.

- Define test functions almost anywhere with a single attribute.

- Group related tests into hierarchies using Swift’s type system.

- Integrate seamlessly with Swift concurrency.

- Parameterize test functions across wide ranges of inputs.

- Enable tests dynamically depending on runtime conditions.

- Parallelize tests in-process.

- Categorize tests using tags.

- Associate bugs directly with the tests that verify their fixes or reproduce their problems.

#### Related videos

![\\
\\
Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179)

![\\
\\
Go further with Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10195)

## Topics

### Essentials

Defining test functions

Define a test function to validate that code is working correctly.

Organizing test functions with suite types

Organize tests into test suites.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`macro Test(String?, any TestTrait...)`

Declare a test.

`struct Test`

A type representing a test or suite.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

### Test parameterization

Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

Declare a test parameterized over a collection of values.

Declare a test parameterized over two collections of values.

Declare a test parameterized over two zipped collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

`struct Case`

A single test case from a parameterized `Test`.

### Behavior validation

Check for expected values, outcomes, and asynchronous events in tests.

Mark issues as known when running tests.

### Test customization

Annotate test functions and suites, and customize their behavior.

### Data collection

Attach values to tests to help diagnose issues and gather feedback.

---

# https://developer.apple.com/documentation/testing/definingtests

- Swift Testing
- Defining test functions

Article

# Defining test functions

Define a test function to validate that code is working correctly.

## Overview

Defining a test function for a Swift package or project is straightforward.

### Import the testing library

To import the testing library, add the following to the Swift source file that contains the test:

import Testing

### Declare a test function

To declare a test function, write a Swift function declaration that doesn’t take any arguments, then prefix its name with the `@Test` attribute:

@Test func foodTruckExists() {
// Test logic goes here.
}

This test function can be present at file scope or within a type. A type containing test functions is automatically a _test suite_ and can be optionally annotated with the `@Suite` attribute. For more information about suites, see Organizing test functions with suite types.

Note that, while this function is a valid test function, it doesn’t actually perform any action or test any code. To check for expected values and outcomes in test functions, add expectations to the test function.

### Customize a test’s name

To customize a test function’s name as presented in an IDE or at the command line, supply a string literal as an argument to the `@Test` attribute:

@Test("Food truck exists") func foodTruckExists() { ... }

To further customize the appearance and behavior of a test function, use traits such as `tags(_:)`.

### Write concurrent or throwing tests

As with other Swift functions, test functions can be marked `async` and `throws` to annotate them as concurrent or throwing, respectively. If a test is only safe to run in the main actor’s execution context (that is, from the main thread of the process), it can be annotated `@MainActor`:

@Test @MainActor func foodTruckExists() async throws { ... }

### Limit the availability of a test

If a test function can only run on newer versions of an operating system or of the Swift language, use the `@available` attribute when declaring it. Use the `message` argument of the `@available` attribute to specify a message to log if a test is unable to run due to limited availability:

@available(macOS 11.0, *)
@available(swift, introduced: 8.0, message: "Requires Swift 8.0 features to run")
@Test func foodTruckExists() { ... }

## See Also

### Essentials

Organizing test functions with suite types

Organize tests into test suites.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`macro Test(String?, any TestTrait...)`

Declare a test.

`struct Test`

A type representing a test or suite.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

---

# https://developer.apple.com/documentation/testing/organizingtests

- Swift Testing
- Organizing test functions with suite types

Article

# Organizing test functions with suite types

Organize tests into test suites.

## Overview

When working with a large selection of test functions, it can be helpful to organize them into test suites.

A test function can be added to a test suite in one of two ways:

- By placing it in a Swift type.

- By placing it in a Swift type and annotating that type with the `@Suite` attribute.

The `@Suite` attribute isn’t required for the testing library to recognize that a type contains test functions, but adding it allows customization of a test suite’s appearance in the IDE and at the command line. If a trait such as `tags(_:)` or `disabled(_:sourceLocation:)` is applied to a test suite, it’s automatically inherited by the tests contained in the suite.

In addition to containing test functions and any other members that a Swift type might contain, test suite types can also contain additional test suites nested within them. To add a nested test suite type, simply declare an additional type within the scope of the outer test suite type.

By default, tests contained within a suite run in parallel with each other. For more information about test parallelization, see Running tests serially or in parallel.

### Customize a suite’s name

To customize a test suite’s name, supply a string literal as an argument to the `@Suite` attribute:

@Suite("Food truck tests") struct FoodTruckTests {
@Test func foodTruckExists() { ... }
}

To further customize the appearance and behavior of a test function, use traits such as `tags(_:)`.

## Test functions in test suite types

If a type contains a test function declared as an instance method (that is, without either the `static` or `class` keyword), the testing library calls that test function at runtime by initializing an instance of the type, then calling the test function on that instance. If a test suite type contains multiple test functions declared as instance methods, each one is called on a distinct instance of the type. Therefore, the following test suite and test function:

@Suite struct FoodTruckTests {
@Test func foodTruckExists() { ... }
}

Are equivalent to:

@Suite struct FoodTruckTests {
func foodTruckExists() { ... }

@Test static func staticFoodTruckExists() {
let instance = FoodTruckTests()
instance.foodTruckExists()
}
}

### Constraints on test suite types

When using a type as a test suite, it’s subject to some constraints that are not otherwise applied to Swift types.

#### An initializer may be required

If a type contains test functions declared as instance methods, it must be possible to initialize an instance of the type with a zero-argument initializer. The initializer may be any combination of:

- implicit or explicit

- synchronous or asynchronous

- throwing or non-throwing

- `private`, `fileprivate`, `internal`, `package`, or `public`

For example:

@Suite struct FoodTruckTests {
var batteryLevel = 100

@Test func foodTruckExists() { ... } // ✅ OK: The type has an implicit init().
}

@Suite struct CashRegisterTests {
private init(cashOnHand: Decimal = 0.0) async throws { ... }

@Test func calculateSalesTax() { ... } // ✅ OK: The type has a callable init().
}

struct MenuTests {
var foods: [Food]
var prices: [Food: Decimal]

@Test static func specialOfTheDay() { ... } // ✅ OK: The function is static.
@Test func orderAllFoods() { ... } // ❌ ERROR: The suite type requires init().
}

The compiler emits an error when presented with a test suite that doesn’t meet this requirement.

#### Test suite types must always be available

Although `@available` can be applied to a test function to limit its availability at runtime, a test suite type (and any types that contain it) must _not_ be annotated with the `@available` attribute:

@Suite struct FoodTruckTests { ... } // ✅ OK: The type is always available.

@available(macOS 11.0, *) // ❌ ERROR: The suite type must always be available.
@Suite struct CashRegisterTests { ... }

@available(macOS 11.0, *) struct MenuItemTests { // ❌ ERROR: The suite type's
// containing type must always
// be available too.
@Suite struct BurgerTests { ... }
}

## See Also

### Essentials

Defining test functions

Define a test function to validate that code is working correctly.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`macro Test(String?, any TestTrait...)`

Declare a test.

`struct Test`

A type representing a test or suite.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

---

# https://developer.apple.com/documentation/testing/migratingfromxctest

- Swift Testing
- Migrating a test from XCTest

Article

# Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

## Overview

The testing library provides much of the same functionality of XCTest, but uses its own syntax to declare test functions and types. Here, you’ll learn how to convert XCTest-based content to use the testing library instead.

### Import the testing library

XCTest and the testing library are available from different modules. Instead of importing the XCTest module, import the Testing module:

// Before
import XCTest

// After
import Testing

A single source file can contain tests written with XCTest as well as other tests written with the testing library. Import both XCTest and Testing if a source file contains mixed test content.

### Convert test classes

XCTest groups related sets of test methods in test classes: classes that inherit from the `XCTestCase` class provided by the XCTest framework. The testing library doesn’t require that test functions be instance members of types. Instead, they can be _free_ or _global_ functions, or can be `static` or `class` members of a type.

If you want to group your test functions together, you can do so by placing them in a Swift type. The testing library refers to such a type as a _suite_. These types do _not_ need to be classes, and they don’t inherit from `XCTestCase`.

To convert a subclass of `XCTestCase` to a suite, remove the `XCTestCase` conformance. It’s also generally recommended that a Swift structure or actor be used instead of a class because it allows the Swift compiler to better-enforce concurrency safety:

// Before
class FoodTruckTests: XCTestCase {
...
}

// After
struct FoodTruckTests {
...
}

For more information about suites and how to declare and customize them, see Organizing test functions with suite types.

### Convert setup and teardown functions

In XCTest, code can be scheduled to run before and after a test using the `setUp()` and `tearDown()` family of functions. When writing tests using the testing library, implement `init()` and/or `deinit` instead:

// Before
class FoodTruckTests: XCTestCase {
var batteryLevel: NSNumber!
override func setUp() async throws {
batteryLevel = 100
}
...
}

// After
struct FoodTruckTests {
var batteryLevel: NSNumber
init() async throws {
batteryLevel = 100
}
...
}

The use of `async` and `throws` is optional. If teardown is needed, declare your test suite as a class or as an actor rather than as a structure and implement `deinit`:

// Before
class FoodTruckTests: XCTestCase {
var batteryLevel: NSNumber!
override func setUp() async throws {
batteryLevel = 100
}
override func tearDown() {
batteryLevel = 0 // drain the battery
}
...
}

// After
final class FoodTruckTests {
var batteryLevel: NSNumber
init() async throws {
batteryLevel = 100
}
deinit {
batteryLevel = 0 // drain the battery
}
...
}

### Convert test methods

The testing library represents individual tests as functions, similar to how they are represented in XCTest. However, the syntax for declaring a test function is different. In XCTest, a test method must be a member of a test class and its name must start with `test`. The testing library doesn’t require a test function to have any particular name. Instead, it identifies a test function by the presence of the `@Test` attribute:

// Before
class FoodTruckTests: XCTestCase {
func testEngineWorks() { ... }
...
}

// After
struct FoodTruckTests {
@Test func engineWorks() { ... }
...
}

As with XCTest, the testing library allows test functions to be marked `async`, `throws`, or `async`- `throws`, and to be isolated to a global actor (for example, by using the `@MainActor` attribute.)

For more information about test functions and how to declare and customize them, see Defining test functions.

### Check for expected values and outcomes

XCTest uses a family of approximately 40 functions to assert test requirements. These functions are collectively referred to as `XCTAssert()`. The testing library has two replacements, `expect(_:_:sourceLocation:)` and `require(_:_:sourceLocation:)`. They both behave similarly to `XCTAssert()` except that `require(_:_:sourceLocation:)` throws an error if its condition isn’t met:

// Before
func testEngineWorks() throws {
let engine = FoodTruck.shared.engine
XCTAssertNotNil(engine.parts.first)
XCTAssertGreaterThan(engine.batteryLevel, 0)
try engine.start()
XCTAssertTrue(engine.isRunning)
}

// After
@Test func engineWorks() throws {
let engine = FoodTruck.shared.engine
try #require(engine.parts.first != nil)

try engine.start()
#expect(engine.isRunning)
}

### Check for optional values

XCTest also has a function, `XCTUnwrap()`, that tests if an optional value is `nil` and throws an error if it is. When using the testing library, you can use `require(_:_:sourceLocation:)` with optional expressions to unwrap them:

// Before
func testEngineWorks() throws {
let engine = FoodTruck.shared.engine
let part = try XCTUnwrap(engine.parts.first)
...
}

// After
@Test func engineWorks() throws {
let engine = FoodTruck.shared.engine
let part = try #require(engine.parts.first)
...
}

### Record issues

XCTest has a function, `XCTFail()`, that causes a test to fail immediately and unconditionally. This function is useful when the syntax of the language prevents the use of an `XCTAssert()` function. To record an unconditional issue using the testing library, use the `record(_:sourceLocation:)` function:

// Before
func testEngineWorks() {
let engine = FoodTruck.shared.engine
guard case .electric = engine else {
XCTFail("Engine is not electric")
return
}
...
}

// After
@Test func engineWorks() {
let engine = FoodTruck.shared.engine
guard case .electric = engine else {
Issue.record("Engine is not electric")
return
}
...
}

The following table includes a list of the various `XCTAssert()` functions and their equivalents in the testing library:

| XCTest | Swift Testing |
| --- | --- |
| `XCTAssert(x)`, `XCTAssertTrue(x)` | `#expect(x)` |
| `XCTAssertFalse(x)` | `#expect(!x)` |
| `XCTAssertNil(x)` | `#expect(x == nil)` |
| `XCTAssertNotNil(x)` | `#expect(x != nil)` |
| `XCTAssertEqual(x, y)` | `#expect(x == y)` |
| `XCTAssertNotEqual(x, y)` | `#expect(x != y)` |
| `XCTAssertIdentical(x, y)` | `#expect(x === y)` |
| `XCTAssertNotIdentical(x, y)` | `#expect(x !== y)` |

| `XCTAssertLessThanOrEqual(x, y)` | `#expect(x <= y)` |
| `XCTAssertLessThan(x, y)` | `#expect(x < y)` |
| `XCTAssertThrowsError(try f())` | `#expect(throws: (any Error).self) { try f() }` |
| `XCTAssertThrowsError(try f()) { error in … }` | `let error = #expect(throws: (any Error).self) { try f() }` |
| `XCTAssertNoThrow(try f())` | `#expect(throws: Never.self) { try f() }` |
| `try XCTUnwrap(x)` | `try #require(x)` |
| `XCTFail("…")` | `Issue.record("…")` |

The testing library doesn’t provide an equivalent of `XCTAssertEqual(_:_:accuracy:_:file:line:)`. To compare two numeric values within a specified accuracy, use `isApproximatelyEqual()` from swift-numerics.

### Continue or halt after test failures

An instance of an `XCTestCase` subclass can set its `continueAfterFailure` property to `false` to cause a test to stop running after a failure occurs. XCTest stops an affected test by throwing an Objective-C exception at the time the failure occurs.

The behavior of an exception thrown through a Swift stack frame is undefined. If an exception is thrown through an `async` Swift function, it typically causes the process to terminate abnormally, preventing other tests from running.

The testing library doesn’t use exceptions to stop test functions. Instead, use the `require(_:_:sourceLocation:)` macro, which throws a Swift error on failure:

// Before
func testTruck() async {
continueAfterFailure = false
XCTAssertTrue(FoodTruck.shared.isLicensed)
...
}

// After
@Test func truck() throws {
try #require(FoodTruck.shared.isLicensed)
...
}

When using either `continueAfterFailure` or `require(_:_:sourceLocation:)`, other tests will continue to run after the failed test method or test function.

### Validate asynchronous behaviors

XCTest has a class, `XCTestExpectation`, that represents some asynchronous condition. You create an instance of this class (or a subclass like `XCTKeyPathExpectation`) using an initializer or a convenience method on `XCTestCase`. When the condition represented by an expectation occurs, the developer _fulfills_ the expectation. Concurrently, the developer _waits for_ the expectation to be fulfilled using an instance of `XCTWaiter` or using a convenience method on `XCTestCase`.

Wherever possible, prefer to use Swift concurrency to validate asynchronous conditions. For example, if it’s necessary to determine the result of an asynchronous Swift function, it can be awaited with `await`. For a function that takes a completion handler but which doesn’t use `await`, a Swift continuation can be used to convert the call into an `async`-compatible one.

Some tests, especially those that test asynchronously-delivered events, cannot be readily converted to use Swift concurrency. The testing library offers functionality called _confirmations_ which can be used to implement these tests. Instances of `Confirmation` are created and used within the scope of the functions `confirmation(_:expectedCount:isolation:sourceLocation:_:)` and `confirmation(_:expectedCount:isolation:sourceLocation:_:)`.

Confirmations function similarly to the expectations API of XCTest, however, they don’t block or suspend the caller while waiting for a condition to be fulfilled. Instead, the requirement is expected to be _confirmed_ (the equivalent of _fulfilling_ an expectation) before `confirmation()` returns, and records an issue otherwise:

// Before
func testTruckEvents() async {
let soldFood = expectation(description: "…")
FoodTruck.shared.eventHandler = { event in
if case .soldFood = event {
soldFood.fulfill()
}
}
await Customer().buy(.soup)
await fulfillment(of: [soldFood])
...
}

// After
@Test func truckEvents() async {
await confirmation("…") { soldFood in
FoodTruck.shared.eventHandler = { event in
if case .soldFood = event {
soldFood()
}
}
await Customer().buy(.soup)
}
...
}

By default, `XCTestExpectation` expects to be fulfilled exactly once, and will record an issue in the current test if it is not fulfilled or if it is fulfilled more than once. `Confirmation` behaves the same way and expects to be confirmed exactly once by default. You can configure the number of times an expectation should be fulfilled by setting its `expectedFulfillmentCount` property, and you can pass a value for the `expectedCount` argument of `confirmation(_:expectedCount:isolation:sourceLocation:_:)` for the same purpose.

`XCTestExpectation` has a property, `assertForOverFulfill`, which when set to `false` allows an expectation to be fulfilled more times than expected without causing a test failure. When using a confirmation, you can pass a range to `confirmation(_:expectedCount:isolation:sourceLocation:_:)` as its expected count to indicate that it must be confirmed _at least_ some number of times:

// Before
func testRegularCustomerOrders() async {
let soldFood = expectation(description: "…")
soldFood.expectedFulfillmentCount = 10
soldFood.assertForOverFulfill = false
FoodTruck.shared.eventHandler = { event in
if case .soldFood = event {
soldFood.fulfill()
}
}
for customer in regularCustomers() {
await customer.buy(customer.regularOrder)
}
await fulfillment(of: [soldFood])
...
}

// After
@Test func regularCustomerOrders() async {
await confirmation(
"…",
expectedCount: 10...
) { soldFood in
FoodTruck.shared.eventHandler = { event in
if case .soldFood = event {
soldFood()
}
}
for customer in regularCustomers() {
await customer.buy(customer.regularOrder)
}
}
...
}

### Control whether a test runs

When using XCTest, the `XCTSkip` error type can be thrown to bypass the remainder of a test function. As well, the `XCTSkipIf()` and `XCTSkipUnless()` functions can be used to conditionalize the same action. The testing library allows developers to skip a test function or an entire test suite before it starts running using the `ConditionTrait` trait type. Annotate a test suite or test function with an instance of this trait type to control whether it runs:

// Before
class FoodTruckTests: XCTestCase {
func testArepasAreTasty() throws {
try XCTSkipIf(CashRegister.isEmpty)
try XCTSkipUnless(FoodTruck.sells(.arepas))
...
}
...
}

// After
@Suite(.disabled(if: CashRegister.isEmpty))
struct FoodTruckTests {
@Test(.enabled(if: FoodTruck.sells(.arepas)))
func arepasAreTasty() {
...
}
...
}

### Annotate known issues

A test may have a known issue that sometimes or always prevents it from passing. When written using XCTest, such tests can call `XCTExpectFailure(_:options:failingBlock:)` to tell XCTest and its infrastructure that the issue shouldn’t cause the test to fail. The testing library has an equivalent function with synchronous and asynchronous variants:

- `withKnownIssue(_:isIntermittent:sourceLocation:_:)`

- `withKnownIssue(_:isIntermittent:isolation:sourceLocation:_:)`

This function can be used to annotate a section of a test as having a known issue:

// Before
func testGrillWorks() async {
XCTExpectFailure("Grill is out of fuel") {
try FoodTruck.shared.grill.start()
}
...
}

// After
@Test func grillWorks() async {
withKnownIssue("Grill is out of fuel") {
try FoodTruck.shared.grill.start()
}
...
}

If a test may fail intermittently, the call to `XCTExpectFailure(_:options:failingBlock:)` can be marked _non-strict_. When using the testing library, specify that the known issue is _intermittent_ instead:

// Before
func testGrillWorks() async {
XCTExpectFailure(
"Grill may need fuel",
options: .nonStrict()
) {
try FoodTruck.shared.grill.start()
}
...
}

// After
@Test func grillWorks() async {
withKnownIssue(
"Grill may need fuel",
isIntermittent: true
) {
try FoodTruck.shared.grill.start()
}
...
}

Additional options can be specified when calling `XCTExpectFailure()`:

- `isEnabled` can be set to `false` to skip known-issue matching (for instance, if a particular issue only occurs under certain conditions)

- `issueMatcher` can be set to a closure to allow marking only certain issues as known and to allow other issues to be recorded as test failures

The testing library includes overloads of `withKnownIssue()` that take additional arguments with similar behavior:

- `withKnownIssue(_:isIntermittent:sourceLocation:_:when:matching:)`

- `withKnownIssue(_:isIntermittent:isolation:sourceLocation:_:when:matching:)`

To conditionally enable known-issue matching or to match only certain kinds of issues:

// Before
func testGrillWorks() async {
let options = XCTExpectedFailure.Options()
options.isEnabled = FoodTruck.shared.hasGrill
options.issueMatcher = { issue in
issue.type == thrownError
}
XCTExpectFailure(
"Grill is out of fuel",
options: options
) {
try FoodTruck.shared.grill.start()
}
...
}

// After
@Test func grillWorks() async {
withKnownIssue("Grill is out of fuel") {
try FoodTruck.shared.grill.start()
} when: {
FoodTruck.shared.hasGrill
} matching: { issue in
issue.error != nil
}
...
}

### Run tests sequentially

By default, the testing library runs all tests in a suite in parallel. The default behavior of XCTest is to run each test in a suite sequentially. If your tests use shared state such as global variables, you may see unexpected behavior including unreliable test outcomes when you run tests in parallel.

Annotate your test suite with `serialized` to run tests within that suite serially:

// Before
class RefrigeratorTests : XCTestCase {
func testLightComesOn() throws {
try FoodTruck.shared.refrigerator.openDoor()
XCTAssertEqual(FoodTruck.shared.refrigerator.lightState, .on)
}

func testLightGoesOut() throws {
try FoodTruck.shared.refrigerator.openDoor()
try FoodTruck.shared.refrigerator.closeDoor()
XCTAssertEqual(FoodTruck.shared.refrigerator.lightState, .off)
}
}

// After
@Suite(.serialized)
class RefrigeratorTests {
@Test func lightComesOn() throws {
try FoodTruck.shared.refrigerator.openDoor()
#expect(FoodTruck.shared.refrigerator.lightState == .on)

@Test func lightGoesOut() throws {
try FoodTruck.shared.refrigerator.openDoor()
try FoodTruck.shared.refrigerator.closeDoor()
#expect(FoodTruck.shared.refrigerator.lightState == .off)
}
}

For more information, see Running tests serially or in parallel.

### Attach values

In XCTest, you can create an instance of `XCTAttachment` representing arbitrary data, files, property lists, encodable objects, images, and other types of information that would be useful to have available if a test fails. Swift Testing has an `Attachment` type that serves much the same purpose.

To attach a value from a test to the output of a test run, that value must conform to the `Attachable` protocol. The testing library provides default conformances for various standard library and Foundation types.

If you want to attach a value of another type, and that type already conforms to `Encodable` or to `NSSecureCoding`, the testing library automatically provides a default implementation when you import Foundation:

// Before
import Foundation

class Tortilla: NSSecureCoding { /* ... */ }

func testTortillaIntegrity() async {
let tortilla = Tortilla(diameter: .large)
...
let attachment = XCTAttachment(
archivableObject: tortilla
)
self.add(attachment)
}

// After
import Foundation

struct Tortilla: Codable, Attachable { /* ... */ }

@Test func tortillaIntegrity() async {
let tortilla = Tortilla(diameter: .large)
...
Attachment.record(tortilla)
}

If you have a type that does not (or cannot) conform to `Encodable` or `NSSecureCoding`, or if you want fine-grained control over how it is serialized when attaching it to a test, you can provide your own implementation of `withUnsafeBytes(for:_:)`.

## See Also

### Related Documentation

Defining test functions

Define a test function to validate that code is working correctly.

Organizing test functions with suite types

Organize tests into test suites.

Check for expected values, outcomes, and asynchronous events in tests.

Mark issues as known when running tests.

### Essentials

`macro Test(String?, any TestTrait...)`

Declare a test.

`struct Test`

A type representing a test or suite.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

---

# https://developer.apple.com/documentation/testing/test(_:_:)

#app-main)

- Swift Testing
- Test(\_:\_:)

Macro

# Test(\_:\_:)

Declare a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

@attached(peer)
macro Test(
_ displayName: String? = nil,
_ traits: any TestTrait...
)

## Parameters

`displayName`

The customized display name of this test. If the value of this argument is `nil`, the display name of the test is derived from the associated function’s name.

`traits`

Zero or more traits to apply to this test.

## See Also

### Related Documentation

Defining test functions

Define a test function to validate that code is working correctly.

### Essentials

Organizing test functions with suite types

Organize tests into test suites.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`struct Test`

A type representing a test or suite.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

---

# https://developer.apple.com/documentation/testing/test

- Swift Testing
- Test

Structure

# Test

A type representing a test or suite.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct Test

## Overview

An instance of this type may represent:

- A type containing zero or more tests (i.e. a _test suite_);

- An individual test function (possibly contained within a type); or

- A test function parameterized over one or more sequences of inputs.

Two instances of this type are considered to be equal if the values of their `Test/id-swift.property` properties are equal.

## Topics

### Structures

`struct Case`

A single test case from a parameterized `Test`.

### Instance Properties

[`var associatedBugs: [Bug]`](https://developer.apple.com/documentation/testing/test/associatedbugs)

The set of bugs associated with this test.

[`var comments: [Comment]`](https://developer.apple.com/documentation/testing/test/comments)

The complete set of comments about this test from all of its traits.

`var displayName: String?`

The customized display name of this instance, if specified.

`var isParameterized: Bool`

Whether or not this test is parameterized.

`var isSuite: Bool`

Whether or not this instance is a test suite containing other tests.

`var name: String`

The name of this instance.

`var sourceLocation: SourceLocation`

The source location of this test.

The complete, unique set of tags associated with this test.

`var timeLimit: Duration?`

The maximum amount of time this test’s cases may run for.

[`var traits: [any Trait]`](https://developer.apple.com/documentation/testing/test/traits)

The set of traits added to this instance when it was initialized.

### Type Properties

`static var current: Test?`

The test that is running on the current task, if any.

## Relationships

### Conforms To

- `Copyable`
- `Equatable`
- `Hashable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Essentials

Defining test functions

Define a test function to validate that code is working correctly.

Organizing test functions with suite types

Organize tests into test suites.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`macro Test(String?, any TestTrait...)`

Declare a test.

`macro Suite(String?, any SuiteTrait...)`

Declare a test suite.

---

# https://developer.apple.com/documentation/testing/suite(_:_:)

#app-main)

- Swift Testing
- Suite(\_:\_:)

Macro

# Suite(\_:\_:)

Declare a test suite.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

@attached(member) @attached(peer)
macro Suite(
_ displayName: String? = nil,
_ traits: any SuiteTrait...
)

## Parameters

`displayName`

The customized display name of this test suite. If the value of this argument is `nil`, the display name of the test is derived from the associated type’s name.

`traits`

Zero or more traits to apply to this test suite.

## Overview

A test suite is a type that contains one or more test functions. Any escapable type (that is, any type that is not marked `~Escapable`) may be a test suite.

The use of the `@Suite` attribute is optional; types are recognized as test suites even if they do not have the `@Suite` attribute applied to them.

When adding test functions to a type extension, do not use the `@Suite` attribute. Only a type’s primary declaration may have the `@Suite` attribute applied to it.

## See Also

### Related Documentation

Organizing test functions with suite types

Organize tests into test suites.

### Essentials

Defining test functions

Define a test function to validate that code is working correctly.

Migrating a test from XCTest

Migrate an existing test method or test class written using XCTest.

`macro Test(String?, any TestTrait...)`

Declare a test.

`struct Test`

A type representing a test or suite.

---

# https://developer.apple.com/documentation/testing/parameterizedtesting

- Swift Testing
- Implementing parameterized tests

Article

# Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

## Overview

Some tests need to be run over many different inputs. For instance, a test might need to validate all cases of an enumeration. The testing library lets developers specify one or more collections to iterate over during testing, with the elements of those collections being forwarded to a test function. An invocation of a test function with a particular set of argument values is called a test _case_.

By default, the test cases of a test function run in parallel with each other. For more information about test parallelization, see Running tests serially or in parallel.

### Parameterize over an array of values

It is very common to want to run a test _n_ times over an array containing the values that should be tested. Consider the following test function:

enum Food {
case burger, iceCream, burrito, noodleBowl, kebab
}

@Test("All foods available")
func foodsAvailable() async throws {
for food: Food in [.burger, .iceCream, .burrito, .noodleBowl, .kebab] {
let foodTruck = FoodTruck(selling: food)
#expect(await foodTruck.cook(food))
}
}

If this test function fails for one of the values in the array, it may be unclear which value failed. Instead, the test function can be _parameterized over_ the various inputs:

@Test("All foods available", arguments: [Food.burger, .iceCream, .burrito, .noodleBowl, .kebab])
func foodAvailable(_ food: Food) async throws {
let foodTruck = FoodTruck(selling: food)
#expect(await foodTruck.cook(food))
}

When passing a collection to the `@Test` attribute for parameterization, the testing library passes each element in the collection, one at a time, to the test function as its first (and only) argument. Then, if the test fails for one or more inputs, the corresponding diagnostics can clearly indicate which inputs to examine.

### Parameterize over the cases of an enumeration

The previous example includes a hard-coded list of `Food` cases to test. If `Food` is an enumeration that conforms to `CaseIterable`, you can instead write:

enum Food: CaseIterable {
case burger, iceCream, burrito, noodleBowl, kebab
}

@Test("All foods available", arguments: Food.allCases)
func foodAvailable(_ food: Food) async throws {
let foodTruck = FoodTruck(selling: food)
#expect(await foodTruck.cook(food))

This way, if a new case is added to the `Food` enumeration, it’s automatically tested by this function.

### Parameterize over a range of integers

It is possible to parameterize a test function over a closed range of integers:

@Test("Can make large orders", arguments: 1 ... 100)
func makeLargeOrder(count: Int) async throws {
let foodTruck = FoodTruck(selling: .burger)
#expect(await foodTruck.cook(.burger, quantity: count))

### Pass the same arguments to multiple test functions

If you want to pass the same collection of arguments to two or more parameterized test functions, you can extract the arguments to a separate function or property and pass it to each `@Test` attribute. For example:

extension Food {
static var bestSelling: [Food] {
get async throws { /* ... */ }
}
}

@Test(arguments: try await Food.bestSelling)
func `Order entree`(food: Food) {
let foodTruck = FoodTruck()
#expect(foodTruck.order(food))

@Test(arguments: try await Food.bestSelling)
func `Package leftovers`(food: Food) throws {
let foodTruck = FoodTruck()
let container = try #require(foodTruck.container(fitting: food))
try container.add(food)
}

### Test with more than one collection

It’s possible to test more than one collection. Consider the following test function:

@Test("Can make large orders", arguments: Food.allCases, 1 ... 100)
func makeLargeOrder(of food: Food, count: Int) async throws {
let foodTruck = FoodTruck(selling: food)
#expect(await foodTruck.cook(food, quantity: count))

Elements from the first collection are passed as the first argument to the test function, elements from the second collection are passed as the second argument, and so forth.

Assuming there are five cases in the `Food` enumeration, this test function will, when run, be invoked 500 times (5 x 100) with every possible combination of food and order size. These combinations are referred to as the collections’ Cartesian product.

To avoid the combinatoric semantics shown above, use `zip()`:

@Test("Can make large orders", arguments: zip(Food.allCases, 1 ... 100))
func makeLargeOrder(of food: Food, count: Int) async throws {
let foodTruck = FoodTruck(selling: food)
#expect(await foodTruck.cook(food, quantity: count))

The zipped sequence will be “destructured” into two arguments automatically, then passed to the test function for evaluation.

This revised test function is invoked once for each tuple in the zipped sequence, for a total of five invocations instead of 500 invocations. In other words, this test function is passed the inputs `(.burger, 1)`, `(.iceCream, 2)`, …, `(.kebab, 5)` instead of `(.burger, 1)`, `(.burger, 2)`, `(.burger, 3)`, …, `(.kebab, 99)`, `(.kebab, 100)`.

### Run selected test cases

If a parameterized test meets certain requirements, the testing library allows people to run specific test cases it contains. This can be useful when a test has many cases but only some are failing since it enables re-running and debugging the failing cases in isolation.

To support running selected test cases, it must be possible to deterministically match the test case’s arguments. When someone attempts to run selected test cases of a parameterized test function, the testing library evaluates each argument of the tests’ cases for conformance to one of several known protocols, and if all arguments of a test case conform to one of those protocols, that test case can be run selectively. The following lists the known protocols, in precedence order (highest to lowest):

1. `CustomTestArgumentEncodable`

2. `RawRepresentable`, where `RawValue` conforms to `Encodable`

3. `Encodable`

4. `Identifiable`, where `ID` conforms to `Encodable`

If any argument of a test case doesn’t meet one of the above requirements, then the overall test case cannot be run selectively.

## See Also

### Test parameterization

Declare a test parameterized over a collection of values.

Declare a test parameterized over two collections of values.

Declare a test parameterized over two zipped collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

`struct Case`

A single test case from a parameterized `Test`.

---

# https://developer.apple.com/documentation/testing/test(_:_:arguments:)-8kn7a

-8kn7a#app-main)

- Swift Testing
- Test(\_:\_:arguments:)

Macro

# Test(\_:\_:arguments:)

Declare a test parameterized over a collection of values.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

@attached(peer)

_ displayName: String? = nil,
_ traits: any TestTrait...,
arguments collection: C
) where C : Collection, C : Sendable, C.Element : Sendable

## Parameters

`displayName`

The customized display name of this test. If the value of this argument is `nil`, the display name of the test is derived from the associated function’s name.

`traits`

Zero or more traits to apply to this test.

`collection`

A collection of values to pass to the associated test function.

## Overview

You can prefix the expression you pass to `collection` with `try` or `await`. The testing library evaluates the expression lazily only if it determines that the associated test will run. During testing, the testing library calls the associated test function once for each element in `collection`.

## See Also

### Related Documentation

Defining test functions

Define a test function to validate that code is working correctly.

### Test parameterization

Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

Declare a test parameterized over two collections of values.

Declare a test parameterized over two zipped collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

`struct Case`

A single test case from a parameterized `Test`.

---

# https://developer.apple.com/documentation/testing/test(_:_:arguments:_:)

#app-main)

- Swift Testing
- Test(\_:\_:arguments:\_:)

Macro

# Test(\_:\_:arguments:\_:)

Declare a test parameterized over two collections of values.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

@attached(peer)

_ displayName: String? = nil,
_ traits: any TestTrait...,
arguments collection1: C1,
_ collection2: C2
) where C1 : Collection, C1 : Sendable, C2 : Collection, C2 : Sendable, C1.Element : Sendable, C2.Element : Sendable

## Parameters

`displayName`

The customized display name of this test. If the value of this argument is `nil`, the display name of the test is derived from the associated function’s name.

`traits`

Zero or more traits to apply to this test.

`collection1`

A collection of values to pass to `testFunction`.

`collection2`

A second collection of values to pass to `testFunction`.

## Overview

You can prefix the expressions you pass to `collection1` or `collection2` with `try` or `await`. The testing library evaluates the expressions lazily only if it determines that the associated test will run. During testing, the testing library calls the associated test function once for each pair of elements in `collection1` and `collection2`.

## See Also

### Related Documentation

Defining test functions

Define a test function to validate that code is working correctly.

### Test parameterization

Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

Declare a test parameterized over a collection of values.

Declare a test parameterized over two zipped collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

`struct Case`

A single test case from a parameterized `Test`.

---

# https://developer.apple.com/documentation/testing/test(_:_:arguments:)-3rzok

-3rzok#app-main)

- Swift Testing
- Test(\_:\_:arguments:)

Macro

# Test(\_:\_:arguments:)

Declare a test parameterized over two zipped collections of values.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

@attached(peer)

_ displayName: String? = nil,
_ traits: any TestTrait...,

## Parameters

`displayName`

The customized display name of this test. If the value of this argument is `nil`, the display name of the test is derived from the associated function’s name.

`traits`

Zero or more traits to apply to this test.

`zippedCollections`

Two zipped collections of values to pass to `testFunction`.

## Overview

You can prefix the expression you pass to `zippedCollections` with `try` or `await`. The testing library evaluates the expression lazily only if it determines that the associated test will run. During testing, the testing library calls the associated test function once for each element in `zippedCollections`.

## See Also

### Related Documentation

Defining test functions

Define a test function to validate that code is working correctly.

### Test parameterization

Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

Declare a test parameterized over a collection of values.

Declare a test parameterized over two collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

`struct Case`

A single test case from a parameterized `Test`.

---

# https://developer.apple.com/documentation/testing/customtestargumentencodable

- Swift Testing
- CustomTestArgumentEncodable

Protocol

# CustomTestArgumentEncodable

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

protocol CustomTestArgumentEncodable : Sendable

## Mentioned in

Implementing parameterized tests

## Overview

The testing library checks whether a test argument conforms to this protocol, or any of several other known protocols, when running selected test cases. When a test argument conforms to this protocol, that conformance takes highest priority, and the testing library will then call `encodeTestArgument(to:)` on the argument. A type that conforms to this protocol is not required to conform to either `Encodable` or `Decodable`.

See Implementing parameterized tests for a list of the other supported ways to allow running selected test cases.

## Topics

### Instance Methods

`func encodeTestArgument(to: some Encoder) throws`

Encode this test argument.

**Required**

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`

## See Also

### Related Documentation

Specify different input parameters to generate multiple test cases from a test function.

### Test parameterization

Declare a test parameterized over a collection of values.

Declare a test parameterized over two collections of values.

Declare a test parameterized over two zipped collections of values.

`struct Case`

A single test case from a parameterized `Test`.

---

# https://developer.apple.com/documentation/testing/test/case

- Swift Testing
- Test
- Test.Case

Structure

# Test.Case

A single test case from a parameterized `Test`.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct Case

## Overview

A test case represents a test run with a particular combination of inputs. Tests that are _not_ parameterized map to a single instance of `Test.Case`.

## Topics

### Instance Properties

`var isParameterized: Bool`

Whether or not this test case is from a parameterized test.

### Type Properties

`static var current: Test.Case?`

The test case that is running on the current task, if any.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Test parameterization

Implementing parameterized tests

Specify different input parameters to generate multiple test cases from a test function.

Declare a test parameterized over a collection of values.

Declare a test parameterized over two collections of values.

Declare a test parameterized over two zipped collections of values.

`protocol CustomTestArgumentEncodable`

A protocol for customizing how arguments passed to parameterized tests are encoded, which is used to match against when running specific arguments.

---

# https://developer.apple.com/documentation/testing/expectations

Collection

- Swift Testing
- Expectations and confirmations

API Collection

# Expectations and confirmations

Check for expected values, outcomes, and asynchronous events in tests.

## Overview

Use `expect(_:_:sourceLocation:)` and `require(_:_:sourceLocation:)` macros to validate expected outcomes. To validate that an error is thrown, or _not_ thrown, the testing library provides several overloads of the macros that you can use. For more information, see Testing for errors in Swift code.

Use a `Confirmation` to confirm the occurrence of an asynchronous event that you can’t check directly using an expectation. For more information, see Testing asynchronous code.

### Validate your code’s result

To validate that your code produces an expected value, use `expect(_:_:sourceLocation:)`. This macro captures the expression you pass, and provides detailed information when the code doesn’t satisfy the expectation.

@Test func calculatingOrderTotal() {
let calculator = OrderCalculator()
#expect(calculator.total(of: [3, 3]) == 7)
// Prints "Expectation failed: (calculator.total(of: [3, 3]) → 6) == 7"
}

Your test keeps running after `expect(_:_:sourceLocation:)` fails. To stop the test when the code doesn’t satisfy a requirement, use `require(_:_:sourceLocation:)` instead:

@Test func returningCustomerRemembersUsualOrder() throws {
let customer = try #require(Customer(id: 123))
// The test runner doesn't reach this line if the customer is nil.
#expect(customer.usualOrder.countOfItems == 2)
}

`require(_:_:sourceLocation:)` throws an instance of `ExpectationFailedError` when your code fails to satisfy the requirement.

## Topics

### Checking expectations

Check that an expectation has passed after a condition has been evaluated.

Check that an expectation has passed after a condition has been evaluated and throw an error if it failed.

Unwrap an optional value or, if it is `nil`, fail and throw an error.

### Checking that errors are thrown

Testing for errors in Swift code

Ensure that your code handles errors in the way you expect.

Check that an expression always throws an error of a given type.

Check that an expression always throws a specific error.

Check that an expression always throws an error matching some condition.

Deprecated

Check that an expression always throws an error of a given type, and throw an error if it does not.

Check that an expression always throws an error matching some condition, and throw an error if it does not.

### Checking how processes exit

Exit testing

Use exit tests to test functionality that might cause a test process to exit.

Check that an expression causes the process to terminate in a given fashion.

Check that an expression causes the process to terminate in a given fashion and throw an error if it did not.

`enum ExitStatus`

An enumeration describing possible status a process will report on exit.

`struct ExitTest`

A type describing an exit test.

### Confirming that asynchronous events occur

Testing asynchronous code

Validate whether your code causes expected events to happen.

Confirm that some event occurs during the invocation of a function.

`struct Confirmation`

A type that can be used to confirm that an event occurs zero or more times.

### Retrieving information about checked expectations

`struct Expectation`

A type describing an expectation that has been evaluated.

`struct ExpectationFailedError`

A type describing an error thrown when an expectation fails during evaluation.

`protocol CustomTestStringConvertible`

A protocol describing types with a custom string representation when presented as part of a test’s output.

### Representing source locations

`struct SourceLocation`

A type representing a location in source code.

## See Also

### Behavior validation

Mark issues as known when running tests.

---

# https://developer.apple.com/documentation/testing/known-issues

Collection

- Swift Testing
- Known issues

API Collection

# Known issues

Mark issues as known when running tests.

## Overview

The testing library provides several functions named `withKnownIssue()` that you can use to mark issues as known. Use them to inform the testing library that a test should not be marked as failing if only known issues are recorded.

### Mark an expectation failure as known

Consider a test function with a single expectation:

@Test func grillHeating() throws {
var foodTruck = FoodTruck()
try foodTruck.startGrill()
#expect(foodTruck.grill.isHeating) // ❌ Expectation failed
}

If the value of the `isHeating` property is `false`, `#expect` will record an issue. If you cannot fix the underlying problem, you can surround the failing code in a closure passed to `withKnownIssue()`:

@Test func grillHeating() throws {
var foodTruck = FoodTruck()
try foodTruck.startGrill()
withKnownIssue("Propane tank is empty") {
#expect(foodTruck.grill.isHeating) // Known issue
}
}

The issue recorded by `#expect` will then be considered “known” and the test will not be marked as a failure. You may include an optional comment to explain the problem or provide context.

### Mark a thrown error as known

If an `Error` is caught by the closure passed to `withKnownIssue()`, the issue representing that caught error will be marked as known. Continuing the previous example, suppose the problem is that the `startGrill()` function is throwing an error. You can apply `withKnownIssue()` to this situation as well:

@Test func grillHeating() {
var foodTruck = FoodTruck()
withKnownIssue {
try foodTruck.startGrill() // Known issue
#expect(foodTruck.grill.isHeating)

Because all errors thrown from the closure are caught and interpreted as known issues, the `withKnownIssue()` function is not throwing. Consequently, any subsequent code which depends on the throwing call having succeeded (such as the `#expect` after `startGrill()`) must be included in the closure to avoid additional issues.

### Match a specific issue

By default, `withKnownIssue()` considers all issues recorded while invoking the body closure known. If multiple issues may be recorded, you can pass a trailing closure labeled `matching:` which will be called once for each recorded issue to determine whether it should be treated as known:

@Test func batteryLevel() throws {
var foodTruck = FoodTruck()
try withKnownIssue {
let batteryLevel = try #require(foodTruck.batteryLevel) // Known

} matching: { issue in
guard case .expectationFailed(let expectation) = issue.kind else {
return false
}
return expectation.isRequired
}
}

### Resolve a known issue

If there are no issues recorded while calling `function`, `withKnownIssue()` will record a distinct issue about the lack of any issues having been recorded. This notifies you that the underlying problem may have been resolved so that you can investigate and consider removing `withKnownIssue()` if it’s no longer necessary.

### Handle a nondeterministic failure

If `withKnownIssue()` sometimes succeeds but other times records an issue indicating there were no known issues, this may indicate a nondeterministic failure or a “flaky” test.

The first step in resolving a nondeterministic test failure is to analyze the code being tested and determine the source of the unpredictable behavior. If you discover a bug such as a race condition, the ideal resolution is to fix the underlying problem so that the code always behaves consistently even if it continues to exhibit the known issue.

If the underlying problem only occurs in certain circumstances, consider including a precondition. For example, if the grill only fails to heat when there’s no propane, you can pass a trailing closure labeled `when:` which determines whether issues recorded in the body closure should be considered known:

@Test func grillHeating() throws {
var foodTruck = FoodTruck()
try foodTruck.startGrill()
withKnownIssue {
// Only considered known when hasPropane == false
#expect(foodTruck.grill.isHeating)
} when: {
!hasPropane
}
}

If the underlying problem is unpredictable and fails at random, you can pass `isIntermittent: true` to let the testing library know that it will not always occur. Then, the testing library will not record an issue when zero known issues are recorded:

@Test func grillHeating() throws {
var foodTruck = FoodTruck()
try foodTruck.startGrill()
withKnownIssue(isIntermittent: true) {
#expect(foodTruck.grill.isHeating)

## Topics

### Recording known issues in tests

Invoke a function that has a known issue that is expected to occur during its execution.

`typealias KnownIssueMatcher`

A function that is used to match known issues.

### Describing a failure or warning

`struct Issue`

A type describing a failure or warning which occurred during a test.

## See Also

### Behavior validation

Check for expected values, outcomes, and asynchronous events in tests.

---

# https://developer.apple.com/documentation/testing/attachments

Collection

- Swift Testing
- Attachments

API Collection

# Attachments

Attach values to tests to help diagnose issues and gather feedback.

## Overview

Attach values such as strings and files to tests. Implement the `Attachable` protocol to create your own attachable types.

## Topics

### Attaching values to tests

`struct Attachment`

A type describing values that can be attached to the output of a test run and inspected later by the user.

`protocol Attachable`

A protocol describing a type that can be attached to a test report or written to disk when a test is run.

`protocol AttachableWrapper`

A protocol describing a type that can be attached to a test report or written to disk when a test is run and which contains another value that it stands in for.

---

# https://developer.apple.com/documentation/testing/definingtests)



---

# https://developer.apple.com/documentation/testing/organizingtests)



---

# https://developer.apple.com/documentation/testing/migratingfromxctest)



---

# https://developer.apple.com/documentation/testing/test(_:_:))



---

# https://developer.apple.com/documentation/testing/test)



---

# https://developer.apple.com/documentation/testing/suite(_:_:))



---

# https://developer.apple.com/documentation/testing/parameterizedtesting)



---

# https://developer.apple.com/documentation/testing/test(_:_:arguments:)-8kn7a)



---

# https://developer.apple.com/documentation/testing/test(_:_:arguments:_:))



---

# https://developer.apple.com/documentation/testing/test(_:_:arguments:)-3rzok)



---

# https://developer.apple.com/documentation/testing/customtestargumentencodable)



---

# https://developer.apple.com/documentation/testing/test/case)



---

# https://developer.apple.com/documentation/testing/test).



---

# https://developer.apple.com/documentation/testing/expectations)



---

# https://developer.apple.com/documentation/testing/known-issues)



---

# https://developer.apple.com/documentation/testing/attachments)



---

# https://developer.apple.com/documentation/testing/trait

- Swift Testing
- Trait

Protocol

# Trait

A protocol describing traits that can be added to a test function or to a test suite.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

protocol Trait : Sendable

## Overview

The testing library defines a number of traits that can be added to test functions and to test suites. Define your own traits by creating types that conform to `TestTrait` or `SuiteTrait`:

`TestTrait`

Conform to this type in traits that you add to test functions.

`SuiteTrait`

Conform to this type in traits that you add to test suites.

You can add a trait that conforms to both `TestTrait` and `SuiteTrait` to test functions and test suites.

## Topics

### Enabling and disabling tests

Constructs a condition trait that disables a test if it returns `false`.

Constructs a condition trait that disables a test unconditionally.

Constructs a condition trait that disables a test if its value is true.

### Controlling how tests are run

Construct a time limit trait that causes a test to time out if it runs for too long.

`static var serialized: ParallelizationTrait`

A trait that serializes the test to which it is applied.

### Categorizing tests and adding information

Construct a list of tags to apply to a test.

[`var comments: [Comment]`](https://developer.apple.com/documentation/testing/trait/comments)

The user-provided comments for this trait.

**Required** Default implementation provided.

### Associating bugs

Constructs a bug to track with a test.

### Running code before and after a test or suite

`protocol TestScoping`

A protocol that tells the test runner to run custom code before or after it runs a test suite or test function.

Get this trait’s scope provider for the specified test and optional test case.

**Required** Default implementations provided.

`associatedtype TestScopeProvider : TestScoping = Never`

The type of the test scope provider for this trait.

**Required**

`func prepare(for: Test) async throws`

Prepare to run the test that has this trait.

### Type Methods

Constructs an trait that transforms issues recorded by a test.

Constructs a trait that filters issues recorded by a test.

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`

### Inherited By

- `SuiteTrait`
- `TestTrait`

### Conforming Types

- `Bug`
- `Comment`
- `ConditionTrait`
- `IssueHandlingTrait`
- `ParallelizationTrait`
- `Tag.List`
- `TimeLimitTrait`

## See Also

### Creating custom traits

`protocol TestTrait`

A protocol describing a trait that you can add to a test function.

`protocol SuiteTrait`

A protocol describing a trait that you can add to a test suite.

---

# https://developer.apple.com/documentation/testing/conditiontrait

- Swift Testing
- ConditionTrait

Structure

# ConditionTrait

A type that defines a condition which must be satisfied for the testing library to enable a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct ConditionTrait

## Mentioned in

Migrating a test from XCTest

## Overview

To add this trait to a test, use one of the following functions:

- `enabled(if:_:sourceLocation:)`

- `enabled(_:sourceLocation:_:)`

- `disabled(_:sourceLocation:)`

- `disabled(if:_:sourceLocation:)`

- `disabled(_:sourceLocation:_:)`

## Topics

### Instance Properties

`var sourceLocation: SourceLocation`

The source location where this trait is specified.

### Instance Methods

Evaluate this instance’s underlying condition.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/trait)



---

# https://developer.apple.com/documentation/testing/conditiontrait)



---

# https://developer.apple.com/documentation/testing/enablinganddisabling)



---

# https://developer.apple.com/documentation/testing/issue/kind-swift.enum/timelimitexceeded(timelimitcomponents:)

#app-main)

- Swift Testing
- Issue
- Issue.Kind
- Issue.Kind.timeLimitExceeded(timeLimitComponents:)

Case

# Issue.Kind.timeLimitExceeded(timeLimitComponents:)

An issue due to a test reaching its time limit and timing out.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

indirect case timeLimitExceeded(timeLimitComponents: (seconds: Int64, attoseconds: Int64))

## Parameters

`timeLimitComponents`

The time limit reached by the test.

## Mentioned in

Limiting the running time of tests

---

# https://developer.apple.com/documentation/testing/issue/kind-swift.enum/timelimitexceeded(timelimitcomponents:)).

).#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/testing/bug

- Swift Testing
- Bug

Structure

# Bug

A type that represents a bug report tracked by a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct Bug

## Mentioned in

Interpreting bug identifiers

Adding comments to tests

## Overview

To add this trait to a test, use one of the following functions:

- `bug(_:_:)`

- `bug(_:id:_:)`

## Topics

### Instance Properties

`var id: String?`

A unique identifier in this bug’s associated bug-tracking system, if available.

`var title: Comment?`

The human-readable title of the bug, if specified by the test author.

`var url: String?`

A URL that links to more information about the bug, if available.

## Relationships

### Conforms To

- `Copyable`
- `Decodable`
- `Encodable`
- `Equatable`
- `Hashable`
- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/bugidentifiers

- Swift Testing
- Traits
- Interpreting bug identifiers

Article

# Interpreting bug identifiers

Examine how the testing library interprets bug identifiers provided by developers.

## Overview

The testing library supports two distinct ways to identify a bug:

1. A URL linking to more information about the bug; and

2. A unique identifier in the bug’s associated bug-tracking system.

A bug may have both an associated URL _and_ an associated unique identifier. It must have at least one or the other in order for the testing library to be able to interpret it correctly.

To create an instance of `Bug` with a URL, use the `bug(_:_:)` trait. At compile time, the testing library will validate that the given string can be parsed as a URL according to RFC 3986.

To create an instance of `Bug` with a bug’s unique identifier, use the `bug(_:id:_:)` trait. The testing library does not require that a bug’s unique identifier match any particular format, but will interpret unique identifiers starting with `"FB"` as referring to bugs tracked with the Apple Feedback Assistant. For convenience, you can also directly pass an integer as a bug’s identifier using `bug(_:id:_:)`.

### Examples

| Trait Function | Inferred Bug-Tracking System |
| --- | --- |
| `.bug(id: 12345)` | None |
| `.bug(id: "12345")` | None |
| `.bug("https://www.example.com?id=12345", id: "12345")` | None |
| `.bug("https://github.com/swiftlang/swift/pull/12345")` | GitHub Issues for the Swift project |
| `.bug("https://bugs.webkit.org/show_bug.cgi?id=12345")` | WebKit Bugzilla |
| `.bug(id: "FB12345")` | Apple Feedback Assistant |

## See Also

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Associating bugs with tests

Associate bugs uncovered or verified by tests.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

Constructs a bug to track with a test.

---

# https://developer.apple.com/documentation/testing/associatingbugs

- Swift Testing
- Traits
- Associating bugs with tests

Article

# Associating bugs with tests

Associate bugs uncovered or verified by tests.

## Overview

Tests allow developers to prove that the code they write is working as expected. If code isn’t working correctly, bug trackers are often used to track the work necessary to fix the underlying problem. It’s often useful to associate specific bugs with tests that reproduce them or verify they are fixed.

## Associate a bug with a test

To associate a bug with a test, use one of these functions:

- `bug(_:_:)`

- `bug(_:id:_:)`

The first argument to these functions is a URL representing the bug in its bug-tracking system:

@Test("Food truck engine works", .bug("https://www.example.com/issues/12345"))
func engineWorks() async {
var foodTruck = FoodTruck()
await foodTruck.engine.start()
#expect(foodTruck.engine.isRunning)
}

You can also specify the bug’s _unique identifier_ in its bug-tracking system in addition to, or instead of, its URL:

@Test(
"Food truck engine works",
.bug(id: "12345"),
.bug("https://www.example.com/issues/67890", id: 67890)
)
func engineWorks() async {
var foodTruck = FoodTruck()
await foodTruck.engine.start()
#expect(foodTruck.engine.isRunning)

A bug’s URL is passed as a string and must be parseable according to RFC 3986. A bug’s unique identifier can be passed as an integer or as a string. For more information on the formats recognized by the testing library, see Interpreting bug identifiers.

## Add titles to associated bugs

A bug’s unique identifier or URL may be insufficient to uniquely and clearly identify a bug associated with a test. Bug trackers universally provide a “title” field for bugs that is not visible to the testing library. To add a bug’s title to a test, include it after the bug’s unique identifier or URL:

@Test(
"Food truck has napkins",
.bug(id: "12345", "Forgot to buy more napkins")
)
func hasNapkins() async {
...
}

## See Also

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Interpreting bug identifiers

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

Constructs a bug to track with a test.

---

# https://developer.apple.com/documentation/testing/addingtags

- Swift Testing
- Traits
- Adding tags to tests

Article

# Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

## Overview

A complex package or project may contain hundreds or thousands of tests and suites. Some subset of those tests may share some common facet, such as being _critical_ or _flaky_. The testing library includes a type of trait called _tags_ that you can add to group and categorize tests.

Tags are different from test suites: test suites impose structure on test functions at the source level, while tags provide semantic information for a test that can be shared with any number of other tests across test suites, source files, and even test targets.

## Add a tag

To add a tag to a test, use the `tags(_:)` trait. This trait takes a sequence of tags as its argument, and those tags are then applied to the corresponding test at runtime. If any tags are applied to a test suite, then all tests in that suite inherit those tags.

The testing library doesn’t assign any semantic meaning to any tags, nor does the presence or absence of tags affect how the testing library runs tests.

Tags themselves are instances of `Tag` and expressed as named constants declared as static members of `Tag`. To declare a named constant tag, use the `Tag()` macro:

extension Tag {
@Tag static var legallyRequired: Self
}

@Test("Vendor's license is valid", .tags(.legallyRequired))
func licenseValid() { ... }

If two tags with the same name ( `legallyRequired` in the above example) are declared in different files, modules, or other contexts, the testing library treats them as equivalent.

If it’s important for a tag to be distinguished from similar tags declared elsewhere in a package or project (or its dependencies), use reverse-DNS naming to create a unique Swift symbol name for your tag:

extension Tag {
enum com_example_foodtruck {}
}

extension Tag.com_example_foodtruck {
@Tag static var extraSpecial: Tag
}

@Test(
"Extra Special Sauce recipe is secret",
.tags(.com_example_foodtruck.extraSpecial)
)
func secretSauce() { ... }

### Where tags can be declared

Tags must always be declared as members of `Tag` in an extension to that type or in a type nested within `Tag`. Redeclaring a tag under a second name has no effect and the additional name will not be recognized by the testing library. The following example is unsupported:

extension Tag {
@Tag static var legallyRequired: Self // ✅ OK: Declaring a new tag.

static var requiredByLaw: Self { // ❌ ERROR: This tag name isn't
// recognized at runtime.
legallyRequired
}
}

If a tag is declared as a named constant outside of an extension to the `Tag` type (for example, at the root of a file or in another unrelated type declaration), it cannot be applied to test functions or test suites. The following declarations are unsupported:

@Tag let needsKetchup: Self // ❌ ERROR: Tags must be declared in an extension
// to Tag.
struct Food {
@Tag var needsMustard: Self // ❌ ERROR: Tags must be declared in an extension
// to Tag.
}

## See Also

### Annotating tests

Adding comments to tests

Add comments to provide useful information about tests.

Associating bugs with tests

Associate bugs uncovered or verified by tests.

Interpreting bug identifiers

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

Constructs a bug to track with a test.

---

# https://developer.apple.com/documentation/testing/addingcomments

- Swift Testing
- Traits
- Adding comments to tests

Article

# Adding comments to tests

Add comments to provide useful information about tests.

## Overview

It’s often useful to add comments to code to:

- Provide context or background information about the code’s purpose

- Explain how complex code implemented

- Include details which may be helpful when diagnosing issues

Test code is no different and can benefit from explanatory code comments, but often test issues are shown in places where the source code of the test is unavailable such as in continuous integration (CI) interfaces or in log files.

Seeing comments related to tests in these contexts can help diagnose issues more quickly. Comments can be added to test declarations and the testing library will automatically capture and show them when issues are recorded.

## Add a code comment to a test

To include a comment on a test or suite, write an ordinary Swift code comment immediately before its `@Test` or `@Suite` attribute:

// Assumes the standard lunch menu includes a taco
@Test func lunchMenu() {
let foodTruck = FoodTruck(
menu: .lunch,
ingredients: [.tortillas, .cheese]
)
#expect(foodTruck.menu.contains { $0 is Taco })
}

The comment, `// Assumes the standard lunch menu includes a taco`, is added to the test.

The following language comment styles are supported:

| Syntax | Style |
| --- | --- |
| `// ...` | Line comment |
| `/// ...` | Documentation line comment |
| `/* ... */` | Block comment |
| `/** ... */` | Documentation block comment |

### Comment formatting

Test comments which are automatically added from source code comments preserve their original formatting, including any prefixes like `//` or `/**`. This is because the whitespace and formatting of comments can be meaningful in some circumstances or aid in understanding the comment — for example, when a comment includes an example code snippet or diagram.

## Use test comments effectively

As in normal code, comments on tests are generally most useful when they:

- Add information that isn’t obvious from reading the code

- Provide useful information about the operation or motivation of a test

If a test is related to a bug or issue, consider using the `Bug` trait instead of comments. For more information, see Associating bugs with tests.

## See Also

### Annotating tests

Adding tags to tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Associating bugs with tests

Associate bugs uncovered or verified by tests.

Interpreting bug identifiers

Examine how the testing library interprets bug identifiers provided by developers.

`macro Tag()`

Declare a tag that can be applied to a test function or test suite.

Constructs a bug to track with a test.

---

# https://developer.apple.com/documentation/testing/tag()

#app-main)

- Swift Testing
- Tag()

Macro

# Tag()

Declare a tag that can be applied to a test function or test suite.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

@attached(accessor) @attached(peer)
macro Tag()

## Mentioned in

Adding tags to tests

## Overview

Use this tag with members of the `Tag` type declared in an extension to mark them as usable with tests. For more information on declaring tags, see Adding tags to tests.

## See Also

### Annotating tests

Use tags to provide semantic information for organization, filtering, and customizing appearances.

Adding comments to tests

Add comments to provide useful information about tests.

Associating bugs with tests

Associate bugs uncovered or verified by tests.

Interpreting bug identifiers

Examine how the testing library interprets bug identifiers provided by developers.

Constructs a bug to track with a test.

---

# https://developer.apple.com/documentation/testing/bug)



---

# https://developer.apple.com/documentation/testing/bugidentifiers)



---

# https://developer.apple.com/documentation/testing/associatingbugs)



---

# https://developer.apple.com/documentation/testing/addingtags)



---

# https://developer.apple.com/documentation/testing/addingcomments)



---

# https://developer.apple.com/documentation/testing/tag())



---

# https://developer.apple.com/documentation/testing/testtrait

- Swift Testing
- TestTrait

Protocol

# TestTrait

A protocol describing a trait that you can add to a test function.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

protocol TestTrait : Trait

## Overview

The testing library defines a number of traits that you can add to test functions. You can also define your own traits by creating types that conform to this protocol, or to the `SuiteTrait` protocol.

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`
- `Trait`

### Conforming Types

- `Bug`
- `Comment`
- `ConditionTrait`
- `IssueHandlingTrait`
- `ParallelizationTrait`
- `Tag.List`
- `TimeLimitTrait`

## See Also

### Creating custom traits

`protocol Trait`

A protocol describing traits that can be added to a test function or to a test suite.

`protocol SuiteTrait`

A protocol describing a trait that you can add to a test suite.

`protocol TestScoping`

A protocol that tells the test runner to run custom code before or after it runs a test suite or test function.

---

# https://developer.apple.com/documentation/testing/suitetrait

- Swift Testing
- SuiteTrait

Protocol

# SuiteTrait

A protocol describing a trait that you can add to a test suite.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

protocol SuiteTrait : Trait

## Overview

The testing library defines a number of traits that you can add to test suites. You can also define your own traits by creating types that conform to this protocol, or to the `TestTrait` protocol.

## Topics

### Instance Properties

`var isRecursive: Bool`

Whether this instance should be applied recursively to child test suites and test functions.

**Required** Default implementation provided.

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`
- `Trait`

### Conforming Types

- `Bug`
- `Comment`
- `ConditionTrait`
- `IssueHandlingTrait`
- `ParallelizationTrait`
- `Tag.List`
- `TimeLimitTrait`

## See Also

### Creating custom traits

`protocol Trait`

A protocol describing traits that can be added to a test function or to a test suite.

`protocol TestTrait`

A protocol describing a trait that you can add to a test function.

`protocol TestScoping`

A protocol that tells the test runner to run custom code before or after it runs a test suite or test function.

---

# https://developer.apple.com/documentation/testing/parallelization

- Swift Testing
- Traits
- Running tests serially or in parallel

Article

# Running tests serially or in parallel

Control whether tests run serially or in parallel.

## Overview

By default, tests run in parallel with respect to each other. Parallelization is accomplished by the testing library using task groups, and tests generally all run in the same process. The number of tests that run concurrently is controlled by the Swift runtime.

## Disabling parallelization

Parallelization can be disabled on a per-function or per-suite basis using the `serialized` trait:

@Test(.serialized, arguments: Food.allCases) func prepare(food: Food) {
// This function will be invoked serially, once per food, because it has the
// .serialized trait.
}

@Suite(.serialized) struct FoodTruckTests {
@Test(arguments: Condiment.allCases) func refill(condiment: Condiment) {
// This function will be invoked serially, once per condiment, because the
// containing suite has the .serialized trait.
}

@Test func startEngine() async throws {
// This function will not run while refill(condiment:) is running. One test
// must end before the other will start.
}
}

When added to a parameterized test function, this trait causes that test to run its cases serially instead of in parallel. When applied to a non-parameterized test function, this trait has no effect. When applied to a test suite, this trait causes that suite to run its contained test functions and sub-suites serially instead of in parallel.

This trait is recursively applied: if it is applied to a suite, any parameterized tests or test suites contained in that suite are also serialized (as are any tests contained in those suites, and so on.)

This trait doesn’t affect the execution of a test relative to its peers or to unrelated tests. This trait has no effect if test parallelization is globally disabled (by, for example, passing `--no-parallel` to the `swift test` command.)

## See Also

### Running tests serially or in parallel

`static var serialized: ParallelizationTrait`

A trait that serializes the test to which it is applied.

---

# https://developer.apple.com/documentation/testing/trait/serialized

- Swift Testing
- Trait
- serialized

Type Property

# serialized

A trait that serializes the test to which it is applied.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

static var serialized: ParallelizationTrait { get }

Available when `Self` is `ParallelizationTrait`.

## Mentioned in

Migrating a test from XCTest

Running tests serially or in parallel

## See Also

### Related Documentation

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

### Running tests serially or in parallel

Control whether tests run serially or in parallel.

---

# https://developer.apple.com/documentation/testing/trait/compactmapissues(_:)

#app-main)

- Swift Testing
- Trait
- compactMapIssues(\_:)

Type Method

# compactMapIssues(\_:)

Constructs an trait that transforms issues recorded by a test.

Swift 6.2+Xcode 26.0+

Available when `Self` is `IssueHandlingTrait`.

## Parameters

`transform`

A closure called for each issue recorded by the test this trait is applied to. It is passed a recorded issue, and returns an optional issue to replace the passed-in one.

## Return Value

An instance of `IssueHandlingTrait` that transforms issues.

## Discussion

The `transform` closure is called synchronously each time an issue is recorded by the test this trait is applied to. The closure is passed the recorded issue, and if it returns a non- `nil` value, that will be recorded instead of the original. Otherwise, if the closure returns `nil`, the issue is suppressed and will not be included in the results.

The `transform` closure may be called more than once if the test records multiple issues. If more than one instance of this trait is applied to a test (including via inheritance from a containing suite), the `transform` closure for each instance will be called in right-to-left, innermost-to- outermost order, unless `nil` is returned, which will skip invoking the remaining traits’ closures.

Within `transform`, you may access the current test or test case (if any) using `current` `current`, respectively. You may also record new issues, although they will only be handled by issue handling traits which precede this trait or were inherited from a containing suite.

## See Also

### Handling issues

Constructs a trait that filters issues recorded by a test.

---

# https://developer.apple.com/documentation/testing/trait/filterissues(_:)

#app-main)

- Swift Testing
- Trait
- filterIssues(\_:)

Type Method

# filterIssues(\_:)

Constructs a trait that filters issues recorded by a test.

Swift 6.2+Xcode 26.0+

Available when `Self` is `IssueHandlingTrait`.

## Parameters

`isIncluded`

The predicate with which to filter issues recorded by the test this trait is applied to. It is passed a recorded issue, and should return `true` if the issue should be included, or `false` if it should be suppressed.

## Return Value

An instance of `IssueHandlingTrait` that filters issues.

## Discussion

The `isIncluded` closure is called synchronously each time an issue is recorded by the test this trait is applied to. The closure is passed the recorded issue, and if it returns `true`, the issue will be preserved in the test results. Otherwise, if the closure returns `false`, the issue will not be included in the test results.

The `isIncluded` closure may be called more than once if the test records multiple issues. If more than one instance of this trait is applied to a test (including via inheritance from a containing suite), the `isIncluded` closure for each instance will be called in right-to-left, innermost-to- outermost order, unless `false` is returned, which will skip invoking the remaining traits’ closures.

Within `isIncluded`, you may access the current test or test case (if any) using `current` `current`, respectively. You may also record new issues, although they will only be handled by issue handling traits which precede this trait or were inherited from a containing suite.

## See Also

### Handling issues

Constructs an trait that transforms issues recorded by a test.

---

# https://developer.apple.com/documentation/testing/testscoping

- Swift Testing
- TestScoping

Protocol

# TestScoping

A protocol that tells the test runner to run custom code before or after it runs a test suite or test function.

Swift 6.1+Xcode 16.3+

protocol TestScoping : Sendable

## Overview

Provide custom scope for tests by implementing the `scopeProvider(for:testCase:)` method, returning a type that conforms to this protocol. Create a custom scope to consolidate common set-up and tear-down logic for tests which have similar needs, which allows each test function to focus on the unique aspects of its test.

## Topics

### Instance Methods

Provide custom execution scope for a function call which is related to the specified test or test case.

**Required**

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`

### Conforming Types

- `IssueHandlingTrait`
- `ParallelizationTrait`

## See Also

### Creating custom traits

`protocol Trait`

A protocol describing traits that can be added to a test function or to a test suite.

`protocol TestTrait`

A protocol describing a trait that you can add to a test function.

`protocol SuiteTrait`

A protocol describing a trait that you can add to a test suite.

---

# https://developer.apple.com/documentation/testing/comment

- Swift Testing
- Comment

Structure

# Comment

A type that represents a comment related to a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct Comment

## Overview

Use this type to provide context or background information about a test’s purpose, explain how a complex test operates, or include details which may be helpful when diagnosing issues recorded by a test.

To add a comment to a test or suite, add a code comment before its `@Test` or `@Suite` attribute. See Adding comments to tests for more details.

## Topics

### Instance Properties

`var rawValue: String`

The single comment string that this comment contains.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Decodable`
- `Encodable`
- `Equatable`
- `ExpressibleByExtendedGraphemeClusterLiteral`
- `ExpressibleByStringInterpolation`
- `ExpressibleByStringLiteral`
- `ExpressibleByUnicodeScalarLiteral`
- `Hashable`
- `RawRepresentable`
- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/issuehandlingtrait

- Swift Testing
- IssueHandlingTrait

Structure

# IssueHandlingTrait

A type that allows transforming or filtering the issues recorded by a test.

Swift 6.2+Xcode 26.0+

struct IssueHandlingTrait

## Overview

Use this type to observe or customize the issue(s) recorded by the test this trait is applied to. You can transform a recorded issue by copying it, modifying one or more of its properties, and returning the copy. You can observe recorded issues by returning them unmodified. Or you can suppress an issue by either filtering it using `filterIssues(_:)` or returning `nil` from the closure passed to `compactMapIssues(_:)`.

When an instance of this trait is applied to a suite, it is recursively inherited by all child suites and tests.

To add this trait to a test, use one of the following functions:

- `compactMapIssues(_:)`

- `filterIssues(_:)`

## Topics

### Instance Methods

Handle a specified issue.

## Relationships

### Conforms To

- `Copyable`
- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestScoping`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/parallelizationtrait

- Swift Testing
- ParallelizationTrait

Structure

# ParallelizationTrait

A type that defines whether the testing library runs this test serially or in parallel.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct ParallelizationTrait

## Overview

When you add this trait to a parameterized test function, that test runs its cases serially instead of in parallel. This trait has no effect when you apply it to a non-parameterized test function.

When you add this trait to a test suite, that suite runs its contained test functions (including their cases, when parameterized) and sub-suites serially instead of in parallel. If the sub-suites have children, they also run serially.

This trait does not affect the execution of a test relative to its peers or to unrelated tests. This trait has no effect if you disable test parallelization globally (for example, by passing `--no-parallel` to the `swift test` command.)

To add this trait to a test, use `serialized`.

## Relationships

### Conforms To

- `Copyable`
- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestScoping`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/tag

- Swift Testing
- Tag

Structure

# Tag

A type representing a tag that can be applied to a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct Tag

## Mentioned in

Adding tags to tests

## Overview

To apply tags to a test, use the `tags(_:)` function.

## Topics

### Structures

`struct List`

A type representing one or more tags applied to a test.

## Relationships

### Conforms To

- `CodingKeyRepresentable`
- `Comparable`
- `Copyable`
- `CustomStringConvertible`
- `Decodable`
- `Encodable`
- `Equatable`
- `Hashable`
- `Sendable`
- `SendableMetatype`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/tag/list

- Swift Testing
- Tag
- Tag.List

Structure

# Tag.List

A type representing one or more tags applied to a test.

iOSiPadOSMac CatalystmacOStvOSvisionOSwatchOSSwift 6.0+Xcode 16.0+

struct List

## Overview

To add this trait to a test, use the `tags(_:)` function.

## Topics

### Instance Properties

[`var tags: [Tag]`](https://developer.apple.com/documentation/testing/tag/list/tags)

The list of tags contained in this instance.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Hashable`
- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct TimeLimitTrait`

A type that defines a time limit to apply to a test.

---

# https://developer.apple.com/documentation/testing/timelimittrait

- Swift Testing
- TimeLimitTrait

Structure

# TimeLimitTrait

A type that defines a time limit to apply to a test.

visionOSSwift 6.0+Xcode 16.0+

struct TimeLimitTrait

## Overview

To add this trait to a test, use `timeLimit(_:)`.

## Topics

### Structures

`struct Duration`

A type representing the duration of a time limit applied to a test.

### Instance Properties

`var timeLimit: Duration`

The maximum amount of time a test may run for before timing out.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`
- `SuiteTrait`
- `TestTrait`
- `Trait`

## See Also

### Supporting types

`struct Bug`

A type that represents a bug report tracked by a test.

`struct Comment`

A type that represents a comment related to a test.

`struct ConditionTrait`

A type that defines a condition which must be satisfied for the testing library to enable a test.

`struct IssueHandlingTrait`

A type that allows transforming or filtering the issues recorded by a test.

`struct ParallelizationTrait`

A type that defines whether the testing library runs this test serially or in parallel.

`struct Tag`

A type representing a tag that can be applied to a test.

`struct List`

A type representing one or more tags applied to a test.

---

# https://developer.apple.com/documentation/testing/testtrait),



---

# https://developer.apple.com/documentation/testing/suitetrait)



---

# https://developer.apple.com/documentation/testing/parallelization)



---

# https://developer.apple.com/documentation/testing/trait/serialized)



---

# https://developer.apple.com/documentation/testing/trait/compactmapissues(_:))



---

# https://developer.apple.com/documentation/testing/trait/filterissues(_:))



---

# https://developer.apple.com/documentation/testing/testtrait)



---

# https://developer.apple.com/documentation/testing/testscoping)



---

# https://developer.apple.com/documentation/testing/comment)



---

# https://developer.apple.com/documentation/testing/issuehandlingtrait)



---

# https://developer.apple.com/documentation/testing/parallelizationtrait)



---

# https://developer.apple.com/documentation/testing/tag)



---

# https://developer.apple.com/documentation/testing/tag/list)



---

# https://developer.apple.com/documentation/testing/timelimittrait)



---

# https://developer.apple.com/documentation/testing/timelimittrait).



---

# https://developer.apple.com/documentation/testing/issue/kind-swift.enum/timelimitexceeded(timelimitcomponents:))

)#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

