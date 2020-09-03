# Get the package name based on the directory name
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PACKAGE_NAME=`basename $DIR`

# Get the user name based on the git repo url
USER_NAME=`basename $(dirname $(git remote get-url origin))`

# Create the Swift Package Library
swift package init --type library

# Use `sed` to replace the package name 
#   in the Github Action CI Workflows
sed -i '' "s/_PACKAGE_NAME/$PACKAGE_NAME/g" .github/workflows/macOS.yml
sed -i '' "s/_PACKAGE_NAME/$PACKAGE_NAME/g" .github/workflows/ubuntu.yml
#   in the Travis CI Setup
sed -i '' "s/_PACKAGE_NAME/$PACKAGE_NAME/g" .travis.yml
#   in the README.md
sed -i '' "s/_PACKAGE_NAME/$PACKAGE_NAME/g" README.md
#   in the License
sed -i '' "s/_PACKAGE_NAME/$PACKAGE_NAME/g" LICENSE

# Use `sed` to replace the package name 
#   in the Github Action CI Workflows
sed -i '' "s/_USER_NAME/$USER_NAME/g" .github/workflows/macOS.yml
sed -i '' "s/_USER_NAME/$USER_NAME/g" .github/workflows/ubuntu.yml
#   in the Travis CI Setup
sed -i '' "s/_USER_NAME/$USER_NAME/g" .travis.yml
#   in the README.md
sed -i '' "s/_USER_NAME/$USER_NAME/g" README.md
#   in the License
sed -i '' "s/_USER_NAME/$USER_NAME/g" LICENSE
#   in the xcodegen Example project for Cocoapods
sed -i '' "s/_USER_NAME/$USER_NAME/g" Example/project.yml

# Create a CocoaPod spec
pod spec create $(git remote get-url origin) --silent

# Update the CocoaPod Spec with valid settings for all operating systems
perl -pi -e '$_ .= qq(Lorem Description\n) if /spec.description  = <<-DESC/' $PACKAGE_NAME.podspec
sed -i '' 's|spec.summary.*|spec.summary      = "Lorem Ipsum"|g' $PACKAGE_NAME.podspec 
sed -i '' 's|"MIT (example)"|{ :type => "MIT", :file => "LICENSE" }|g' $PACKAGE_NAME.podspec
sed -i '' 's|spec.source_files  =.*|spec.source_files  = "Sources/**/*.swift"|g' $PACKAGE_NAME.podspec 
sed -i '' 's|spec.exclude_files.*|spec.swift_versions = "5"|g' $PACKAGE_NAME.podspec 

sed -i '' 's|spec.ios.deployment_target.*|spec.ios.deployment_target = "8.0"|g' $PACKAGE_NAME.podspec
sed -i '' 's|spec.osx.deployment_target.*|spec.osx.deployment_target = "10.9"|g' $PACKAGE_NAME.podspec
sed -i '' 's|spec.watchos.deployment_target.*|spec.watchos.deployment_target = "2.0"|g' $PACKAGE_NAME.podspec
sed -i '' 's|spec.tvos.deployment_target.*|spec.tvos.deployment_target = "9.0"|g' $PACKAGE_NAME.podspec

# Build the Swift Package
swift build
# Test the Swift Package
swift test
# Generate the first set of docs
sourcedocs generate --spm-module $PACKAGE_NAME --output-folder docs
# Generate the Example project using xcodegen
pushd Example
xcodegen generate
# Generate Podfile
pod init
# Setup the Podfile for using the new Pod
sed -i '' "s|# Pods for.*|pod '$PACKAGE_NAME', :path => '../'|g" Podfile 
# Setup the Example workspace
pod install
popd 

# Build all the schemes on the example workspace
xcodebuild -workspace Example/Example.xcworkspace -scheme "iOS_Example"  ONLY_ACTIVE_ARCH=NO  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO  CODE_SIGNING_ALLOWED=NO &
xcodebuild -workspace Example/Example.xcworkspace -scheme "tvOS_Example"  ONLY_ACTIVE_ARCH=NO   CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO  CODE_SIGNING_ALLOWED=NO &
xcodebuild -workspace Example/Example.xcworkspace -scheme "macOS_Example"  ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO  CODE_SIGNING_ALLOWED=NO &
wait
