#!/bin/bash

if [[ $TRAVIS_OS_NAME = 'osx' ]]; then
  swiftformat --lint . && swiftlint
elif [[ $TRAVIS_OS_NAME = 'linux' ]]; then
  # What to do in Ubunutu
  RELEASE_DOT=$(lsb_release -sr)
  RELEASE_NUM=${RELEASE_DOT//[-._]/}
  RELEASE_NAME=$(lsb_release -sc)
  [[ $TRAVIS_CPU_ARCH = "arm64" ]] && ARCH_PREFIX="aarch64" || ARCH_PREFIX="x86_64"
  export PATH="${PWD}/swift-${SWIFT_VER}-RELEASE-ubuntu${RELEASE_DOT}/usr/bin:$PATH"
fi

ARCH=${TRAVIS_CPU_ARCH:-amd64}
[[ $TRAVIS_CPU_ARCH = "arm64" ]] && ARCH_PREFIX="aarch64" || ARCH_PREFIX="x86_64"
  
swift build
swift test  --enable-code-coverage --enable-test-discovery

if [[ $TRAVIS_OS_NAME = 'osx' ]]; then
  xcrun llvm-cov export -format="lcov" .build/debug/${FRAMEWORK_NAME}PackageTests.xctest/Contents/MacOS/${FRAMEWORK_NAME}PackageTests -instr-profile .build/debug/codecov/default.profdata > info.lcov
  bash <(curl https://codecov.io/bash) -F travis -F macOS -n $TRAVIS_JOB_NUMBER-$TRAVIS_OS_NAME
else
  llvm-cov export -format="lcov" .build/${ARCH_PREFIX}-unknown-linux-gnu/debug/${FRAMEWORK_NAME}PackageTests.xctest -instr-profile .build/debug/codecov/default.profdata > info.lcov
  bash <(curl https://codecov.io/bash) -F travis -F $RELEASE_NAME -F $ARCH -n $TRAVIS_JOB_NUMBER-$TRAVIS_OS_NAME
fi

curl -s https://raw.githubusercontent.com/daveverwer/SwiftPMLibrary/master/script.sh | bash -s -- mine

if [[ $TRAVIS_OS_NAME = 'osx' ]]; then
  pod lib lint
  swift package generate-xcodeproj
  pod install --silent --project-directory=Example
  xcodebuild -quiet -workspace Example/Example.xcworkspace -scheme "iOS_Example"  ONLY_ACTIVE_ARCH=NO  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO  CODE_SIGNING_ALLOWED=NO
  xcodebuild -quiet -workspace Example/Example.xcworkspace -scheme "tvOS_Example"  ONLY_ACTIVE_ARCH=NO   CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO  CODE_SIGNING_ALLOWED=NO
  xcodebuild -quiet -workspace Example/Example.xcworkspace -scheme "macOS_Example"  ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO  CODE_SIGNING_ALLOWED=NO
fi
