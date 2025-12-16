# Swift Android native cross-compiler and test runner action

This GitHub action will build and run Swift package tests on an Android emulator.
This uses the official [Swift SDK for Android](https://github.com/marketplace/actions/swift-android-action)
provide a cross-compilation Swift SDK for building
Swift natively for Android from a Linux or macOS host.

After building the package, it will run the SwiftPM
test targets on an Android emulator (which is provided by the
[Android Emulator Runner action](https://github.com/marketplace/actions/android-emulator-runner)).
To build the package for Android without running the tests
(which is considerably faster), set the `run-tests` option to `false`.

You can add this action to your Swift CI workflow from the
[GitHub Marketplace](https://github.com/marketplace/actions/swift-android-action),
or you can manually create a workflow by adding a
`.github/workflows/swift-ci.yml` file to your project.
This sample action will run your Swift package's test cases
on a host macOS machine, as well as on an Android emulator
and an iOS simulator.

## Example

The following `ci.yml` workflow will check out the current repository and test the Swift package on Linux and Android:

```yml
name: ci
on:
  push:
    branches:
      - '*'
  workflow_dispatch:
  pull_request:
    branches:
      - '*'
jobs:
  linux-android:
    runs-on: ubuntu-latest
    steps:
      # Ubuntu runners can run low on space can cause the emulator to fail to install
      - name: "Free Disk Space"
        run: |
          sudo rm -rf /usr/share/dotnet /opt/ghc /opt/hostedtoolcache/CodeQL
          docker image prune --all --force
          docker builder prune -a
      - uses: actions/checkout@v4
      - name: "Test Swift Package on Linux"
        run: swift test
      - name: "Test Swift Package on Android"
        uses: skiptools/swift-android-action@v2
```


## Configuration

The following configuration options can be passed to the workflow. For example, to specify the version of Swift you want to use for building and testing, you can use the `swift-version` parameter like so:

```yml
jobs:
  linux-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: "Test Swift Package on Linux"
        run: swift test
      - name: "Test Swift Package on Android"
        uses: skiptools/swift-android-action@v2
        with:
          swift-version: 6.2
```

### Swift Versions

The `swift-version` input can be set to a specific version number (e.g., "6.2" or "6.1.1").

> [!NOTE]
> Prior to Swift 6.3, the SDK that is installed is the 
> pre-official Swift SDK for Android created from the
> [swift-android-sdk](https://github.com/swift-android-sdk/swift-android-sdk)
> repository.
> As of the [announcement of the official SDK](https://www.swift.org/blog/nightly-swift-sdk-for-android/)
at swift.org,
> the official toolchain can be used in testing, starting with the
> `nightly-main` tag.

Snapshots can be specified with their full name, like
`swift-DEVELOPMENT-SNAPSHOT-2025-10-16-a`,
or the most recent snapshot/nightly build can be specified with
`nightly-main` or `nightly-6.3`.

### Configuration Options

| Parameter | Description | Default  |
|-----|-----|-----|
| swift-version | The version of the Swift toolchain to use | 6.2 |
| ndk-version | The version of the Android NDK to use | <default> |
| package-path | The folder where the swift package is checked out | . |
| swift-configuration | Whether to build with debug or release configuration | debug |
| swift-build-flags | Additional flags to pass to the swift build command |  |
| swift-test-flags | Additional flags to pass to the swift test command |  |
| installed-sdk | The name of a pre-installed Swift SDK to use |  |
| custom-sdk-url | A direct url to a custom SDK that will be downloaded. `custom-sdk-id` and `installed-sdk` must be provided, if this is used. |  |
| custom-sdk-id | The ID of the custom SDK that will be installed |  |
| installed-swift | The path to a pre-installed host Swift toolchain |  |
| test-env | Test environment variables key=value |  |
| build-package | Whether to build the Swit package | true |
| build-tests | Whether to build the package tests or just the sources | true |
| run-tests | Whether to run the tests or just perform the build | true |
| copy-files | Additional files to copy to emulator for testing | |
| android-emulator-test-folder | Emulator folder where tests are copied | /data/local/tmp/android-xctest |
| android-api-level | The API level of the Android emulator to run against | 28 |
| android-channel | SDK component channel: stable, beta, dev, canary | stable |
| android-profile | Hardware profile used for creating the AVD | pixel |
| android-target | Target of the system image | aosp_atd |
| android-cores | Number of cores to use for the emulator | 2 |
| android-emulator-options | Options to pass to the Android emulator | -no-window … |
| android-emulator-boot-timeout | Emulator boot timeout in seconds | 600 |

### Platform Support

This action can be run on any of the GitHub `ubuntu-*` and `macos-*` [runner images](https://github.com/actions/runner-images). However, due to the inability of macOS on ARM to run nested virtualization ([issue](https://github.com/ReactiveCircus/android-emulator-runner/issues/350)), the Android emulator cannot be run on these platforms, and so running on any macOS image that uses ARM (including `macos-14` and `macos-15`) requires disabling tests with `run-tests: false`. Running tests are supported on the Intel runner `macos-15-intel`, as well as the large (paid) macOS images like `macos-14-large` and `macos-15-large`.

An example of disabling running tests on ARM macOS images is:

```yml
jobs:
  macos-android:
    runs-on: macos-26
    steps:
      - uses: actions/checkout@v4
      - name: "Test Swift Package on macOS"
        run: swift test
      - name: "Build Swift Package on Android"
        uses: skiptools/swift-android-action@v2
        with:
          run-tests: false
```

### Test Resources and Environment Variables

Unit tests sometimes need to load local resources, such as configuration
files and mocking or parsing inputs. This is typically handled
using [Bundle.module](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package),
which will be automatically copied up to the Android emulator when
testing and so should work transparently.

However, in some cases a test script may expect a specific set
of local files to be present, such as when a unit test needs to
examine the contents of the source code itself. In these cases,
you can use the `copy-files` input parameter to specify local files
to copy up to the emulator when running.

Similarly, some test cases may expect a certain environment to be set.
This can be accomplished using the `test-env` parameter, which
is a space separated list of key=value pairs of environment
variables to set when running the tests.

For example:

```yml
  - name: Test Android Package
    uses: skiptools/swift-android-action@v2
    with:
      copy-files: Tests
      test-env: TEST_WORKSPACE=1
```

### Installing without Building

You may wish to use this action to just install the toolchain and
Android SDK without performing the build. For example, if you
wish to build multiple packages consecutively, and don't need to
run the test cases. In this case, you can set the
`build-package` input to false, and then use the action's
`swift-build` output to get the complete `swift build` command
with all the appropriate paths and arguments to build using the
SDK.

For example:

```yml
  - name: Setup Toolchain
    id: setup-toolchain
    uses: skiptools/swift-android-action@v2
    with:
      # just set up the toolchain but don't build anything
      build-package: false
  - name: Checkout apple/swift-numerics
    uses: actions/checkout@v4
  - name: Build Package With Toolchain
    run: |
      # build twice, once with debug and once with release
      ${{ steps.setup-toolchain.outputs.swift-build }} -c debug
      ls .build/${{ steps.setup-toolchain.outputs.swift-sdk }}/debug
      ${{ steps.setup-toolchain.outputs.swift-build }} -c release
      ls .build/${{ steps.setup-toolchain.outputs.swift-sdk }}/release
```

The actual `swift-build` command will vary between operating systems
and architectures. For example, on Ubuntu 24.04, it might be:

```
/home/runner/swift/toolchains/swift-6.1-RELEASE/usr/bin/swift build --swift-sdk x86_64-unknown-linux-android24
```

while on macOS-15 it will be:

```
/Users/runner/Library/Developer/Toolchains/swift-6.1-RELEASE.xctoolchain/usr/bin/swift build --swift-sdk aarch64-unknown-linux-android24
```


## Complete Universal CI Example

Following is an example of a `ci.yml` workflow that checks out and tests a Swift package on each of macOS, iOS, Linux, Android, and Windows.

```yml
name: swift-algorithms ci
on:
  push:
    branches:
      - '*'
  workflow_dispatch:
  pull_request:
    branches:
      - '*'
jobs:
  linux-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: "Test Swift Package on Linux"
        run: swift test
      - name: "Test Swift Package on Android"
        uses: skiptools/swift-android-action@v2
  macos-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: "Test Swift Package on macOS"
        run: swift test
      - name: "Test Swift Package on iOS"
        run: xcodebuild test -sdk "iphonesimulator" -destination "platform=iOS Simulator,name=iPhone 17" -scheme "$(xcodebuild -list -json | jq -r '.workspace.schemes[-1]')"
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: "Setup Swift on Windows"
        uses: compnerd/gha-setup-swift@main
        with:
          branch: swift-6.2-release
          tag: 6.2-RELEASE
      - name: "Test Swift Package on Windows"
        run: swift test

```

For an example of this workflow in action, see a run history
for the [swift-sqlite](https://github.com/swift-android-sdk/swift-sqlite/actions) package.

## Adding Android Support to existing Packages

Recommendations for adding Android compatibility to
existing Swift packages can be found at
[Bringing Swift Packages to Android](https://skip.tools/blog/android-native-swift-packages/).

## Releasing new versions

To create a new release, make a new tag (like 2.0.2),
and then update the symbolic major v2 tag with:

```
git tag v2.0.2 && git push --tags
git tag -fa v2 -m "Update v2 tag" && git push origin v2 --force
gh release create --generate-notes --latest
```

## Who is using the Swift Android Action?

These are some of the open-source projects using (or have used) the Swift Android Action:

[![swift-android-native](https://img.shields.io/github/stars/skiptools/swift-android-native?style=for-the-badge&logoSize=auto&color=red&label=skiptools%2Fswift-android-native&link=https%3A%2F%2Fgithub.com%2Fskiptools%2Fswift-android-native%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/skiptools/swift-android-native/tree/main/.github/workflows)
[![Alamofire/Alamofire](https://img.shields.io/github/stars/Alamofire/Alamofire?style=for-the-badge&logoSize=auto&color=green&label=Alamofire%2FAlamofire&link=https%3A%2F%2Fgithub.com%2FAlamofire%2FAlamofire%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/Alamofire/Alamofire/tree/master/.github/workflows)
[![stephencelis/SQLite.swift](https://img.shields.io/github/stars/stephencelis/SQLite.swift?style=for-the-badge&logoSize=auto&color=orange&label=stephencelis%2FSQLite.swift&link=https%3A%2F%2Fgithub.com%2Fstephencelis%2FSQLite.swift%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/stephencelis/SQLite.swift/tree/master/.github/workflows)
[![SwifterSwift/SwifterSwift](https://img.shields.io/github/stars/SwifterSwift/SwifterSwift?style=for-the-badge&logoSize=auto&color=yellow&label=SwifterSwift%2FSwifterSwift&link=https%3A%2F%2Fgithub.com%2FSwifterSwift%2FSwifterSwift%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/SwifterSwift/SwifterSwift/tree/master/.github/workflows)
[![pointfreeco/swift-snapshot-testing](https://img.shields.io/github/stars/pointfreeco/swift-snapshot-testing?style=for-the-badge&logoSize=auto&color=purple&label=pointfreeco%2Fswift-snapshot-testing&link=https%3A%2F%2Fgithub.com%2Fpointfreeco%2Fswift-snapshot-testing%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/pointfreeco/swift-snapshot-testing/tree/main/.github/workflows)
[![skiptools/Skip](https://img.shields.io/github/stars/skiptools/Skip?style=for-the-badge&logoSize=auto&color=teal&label=skiptools%2FSkip&link=https%3A%2F%2Fgithub.com%2Fskiptools%2Factions%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/skiptools/actions/tree/main/.github/workflows)
[![jpsim/Yams](https://img.shields.io/github/stars/jpsim/Yams?style=for-the-badge&logoSize=auto&color=red&label=jpsim%2FYams&link=https%3A%2F%2Fgithub.com%2Fjpsim%2FYams%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/jpsim/Yams/tree/main/.github/workflows)
[![supabase/supabase-swift](https://img.shields.io/github/stars/supabase/supabase-swift?style=for-the-badge&logoSize=auto&color=orange&label=supabase%2Fsupabase-swift&link=https%3A%2F%2Fgithub.com%2Fsupabase%2Fsupabase-swift%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/supabase/supabase-swift/tree/main/.github/workflows)
[![pointfreeco/swift-case-paths](https://img.shields.io/github/stars/pointfreeco/swift-case-paths?style=for-the-badge&logoSize=auto&color=blue&label=pointfreeco%2Fswift-case-paths&link=https%3A%2F%2Fgithub.com%2Fpointfreeco%2Fswift-case-paths%2Fblob%2Fmain%2F.github%2Fworkflows%2Fci.yml)](https://github.com/pointfreeco/swift-case-paths/blob/main/.github/workflows/ci.yml)
[![krzyzanowskim/CryptoSwift](https://img.shields.io/github/stars/krzyzanowskim/CryptoSwift?style=for-the-badge&logoSize=auto&color=DodgerBlue&label=krzyzanowskim%2FCryptoSwift&link=https%3A%2F%2Fgithub.com%2Fkrzyzanowskim%2FCryptoSwift%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/krzyzanowskim/CryptoSwift/tree/main/.github/workflows)
[![migueldeicaza/SwiftGodot](https://img.shields.io/github/stars/migueldeicaza/SwiftGodot?style=for-the-badge&logoSize=auto&color=cyan&label=migueldeicaza%2FSwiftGodot&link=https%3A%2F%2Fgithub.com%2Fmigueldeicaza%2FSwiftGodot%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/migueldeicaza/SwiftGodot/tree/main/.github/workflows)
[![attaswift/BigInt](https://img.shields.io/github/stars/attaswift/BigInt?style=for-the-badge&logoSize=auto&color=violet&label=attaswift%2FBigInt&link=https%3A%2F%2Fgithub.com%2Fattaswift%2FBigInt%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/attaswift/BigInt/tree/master/.github/workflows)
[![egeniq/app-remote-config](https://img.shields.io/github/stars/egeniq/app-remote-config?style=for-the-badge&logoSize=auto&color=lightgreen&label=egeniq%2Fapp-remote-config&link=https%3A%2F%2Fgithub.com%2Fegeniq%2Fapp-remote-config%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/egeniq/app-remote-config/tree/main/.github/workflows)
[![drewmccormack/Forked](https://img.shields.io/github/stars/drewmccormack/Forked?style=for-the-badge&logoSize=auto&color=lightred&label=drewmccormack%2FForked&link=https%3A%2F%2Fgithub.com%2Fdrewmccormack%2FForked%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/drewmccormack/Forked/tree/main/.github/workflows)
[![GraphQLSwift/GraphQL](https://img.shields.io/github/stars/GraphQLSwift/GraphQL?style=for-the-badge&logoSize=auto&color=aliceblue&label=GraphQLSwift%2FGraphQL&link=https%3A%2F%2Fgithub.com%2FGraphQLSwift%2FGraphQL%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/GraphQLSwift/GraphQL/tree/main/.github/workflows)
[![beatt83/jose-swift](https://img.shields.io/github/stars/beatt83/jose-swift?style=for-the-badge&logoSize=auto&color=orange&label=beatt83%2Fjose-swift&link=https%3A%2F%2Fgithub.com%2Fbeatt83%2Fjose-swift%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/beatt83/jose-swift/tree/main/.github/workflows)
[![marcprux/MemoZ](https://img.shields.io/github/stars/marcprux%2FMemoZ?style=for-the-badge&logoSize=auto&color=yellow&label=marcprux%2FMemoZ&link=https%3A%2F%2Fgithub.com%2Fmarcprux%2FMemoZ%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/marcprux/MemoZ/tree/main/.github/workflows)
[![mxcl/PromiseKit](https://img.shields.io/github/stars/mxcl/PromiseKit?style=for-the-badge&logoSize=auto&color=green&label=mxcl%2FPromiseKit&link=https%3A%2F%2Fgithub.com%2Fmxcl%2FPromiseKit%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/mxcl/PromiseKit/tree/master/.github/workflows)
[![MortenGregersen/Bagbutik](https://img.shields.io/github/stars/MortenGregersen/Bagbutik?style=for-the-badge&logoSize=auto&color=teal&label=MortenGregersen%2FBagbutik&link=https%3A%2F%2Fgithub.com%2FMortenGregersen%2FBagbutik%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/MortenGregersen/Bagbutik/tree/main/.github/workflows)
[![DeclarativeHub/ReactiveKit](https://img.shields.io/github/stars/DeclarativeHub/ReactiveKit?style=for-the-badge&logoSize=auto&color=azure&label=DeclarativeHub%2FReactiveKit&link=https%3A%2F%2Fgithub.com%2FDeclarativeHub%2FReactiveKit%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/DeclarativeHub/ReactiveKit/tree/master/.github/workflows)
[![soto-project/soto-core](https://img.shields.io/github/stars/soto-project/soto-core?style=for-the-badge&logoSize=auto&color=beige&label=soto-project%2Fsoto-core&link=https%3A%2F%2Fgithub.com%2Fsoto-project%2Fsoto-core%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/soto-project/soto-core/tree/main/.github/workflows)
[![valpackett/SwiftCBOR](https://img.shields.io/github/stars/valpackett/SwiftCBOR?style=for-the-badge&logoSize=auto&color=lightcoral&label=valpackett%2FSwiftCBOR&link=https%3A%2F%2Fgithub.com%2Fvalpackett%2FSwiftCBOR%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/valpackett/SwiftCBOR/tree/master/.github/workflows)
[![swhitty/SwiftDraw](https://img.shields.io/github/stars/swhitty/SwiftDraw?style=for-the-badge&logoSize=auto&color=lavender&label=swhitty%2FSwiftDraw&link=https%3A%2F%2Fgithub.com%2Fswhitty%2FSwiftDraw%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/swhitty/SwiftDraw/tree/main/.github/workflows)
[![Quick/swift-fakes](https://img.shields.io/github/stars/Quick/swift-fakes?style=for-the-badge&logoSize=auto&color=burlywood&label=Quick%2Fswift-fakes&link=https%3A%2F%2Fgithub.com%2FQuick%2Fswift-fakes%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/Quick/swift-fakes/tree/main/.github/workflows)
[![pointfreeco/swift-macro-testing](https://img.shields.io/github/stars/pointfreeco/swift-macro-testing?style=for-the-badge&logoSize=auto&color=cornsilk&label=pointfreeco%2Fswift-macro-testing&link=https%3A%2F%2Fgithub.com%2Fpointfreeco%2Fswift-macro-testing%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/pointfreeco/swift-macro-testing/tree/main/.github/workflows)
[![pointfreeco/swift-issue-reporting](https://img.shields.io/github/stars/pointfreeco/swift-issue-reporting?style=for-the-badge&logoSize=auto&color=darkgoldenrod&label=pointfreeco%2Fswift-issue-reporting&link=https%3A%2F%2Fgithub.com%2Fpointfreeco%2Fswift-issue-reporting%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/pointfreeco/swift-issue-reporting/tree/main/.github/workflows)
[![skiptools/swift-jni](https://img.shields.io/github/stars/skiptools/swift-jni?style=for-the-badge&logoSize=auto&color=forestgreen&label=skiptools%2Fswift-jni&link=https%3A%2F%2Fgithub.com%2Fskiptools%2Fswift-jni%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/skiptools/swift-jni/tree/main/.github/workflows)
[![tayloraswift/swift-png](https://img.shields.io/github/stars/tayloraswift/swift-png?style=for-the-badge&logoSize=auto&color=cadetblue&label=tayloraswift%2Fswift-png&link=https%3A%2F%2Fgithub.com%2Ftayloraswift%2Fswift-png%2Ftree%2Fmaster%2F.github%2Fworkflows)](https://github.com/tayloraswift/swift-png/tree/master/.github/workflows)
[![skiptools/swift-sqlcipher](https://img.shields.io/github/stars/skiptools/swift-sqlcipher?style=for-the-badge&logoSize=auto&color=indianred&label=skiptools%2Fswift-sqlcipher&link=https%3A%2F%2Fgithub.com%2Fskiptools%2Fswift-sqlcipher%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/skiptools/swift-sqlcipher/tree/main/.github/workflows)
[![marcprux/universal](https://img.shields.io/github/stars/marcprux%2Funiversal?style=for-the-badge&logoSize=auto&color=goldenrod&label=marcprux%2Funiversal&link=https%3A%2F%2Fgithub.com%2Fmarcprux%2Funiversal%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/marcprux/universal/tree/main/.github/workflows)
[![vapor/ci](https://img.shields.io/github/stars/vapor/ci?style=for-the-badge&logoSize=auto&color=beige&label=vapor%2Fci&link=https%3A%2F%2Fgithub.com%2Fvapor%2Fci%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/vapor/ci/tree/main/.github/workflows)
[![swiftwasm/WasmKit](https://img.shields.io/github/stars/swiftwasm/WasmKit?style=for-the-badge&logoSize=auto&color=red&label=swiftwasm%2FWasmKit&link=https%3A%2F%2Fgithub.com%2Fswiftwasm%2FWasmKit%2Ftree%2Fmain%2F.github%2Fworkflows)](https://github.com/swiftwasm/WasmKit/tree/main/.github/workflows)

