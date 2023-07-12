#!/bin/bash

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq could not be found. Please install yq to parse YAML files."
    exit
fi

# Variables
config_file="chatgpt_app_config.yaml"

# Read values from config.yaml
YourAppPath=$(yq eval '.YourAppPath' $config_file)
iPhone=$(yq eval '.iPhone' $config_file)

# Check Input Arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: ./ios_app_rapid_test.sh <toolpath> (must be inside the relevant git repo)"
    exit 1
fi

toolpath=$1

# Show the difference
diff_output=$(git diff --color=always)
echo "$diff_output"

# Prompt the developer to accept the git diff
read -p "Accept the code changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Code changes rejected."
    exit 1
fi

echo "Code changes accepted."

rm -rf build
log=$(xcodebuild -scheme MixCulture -configuration Debug -sdk iphonesimulator -derivedDataPath build 2>&1)

echo "Build log: $log"

# Pass the output to the Python script
build_outcome=$(python3.8 "$toolpath/parse_xcodebuild_log.py" "$log" "outcome")
build_errors=$(python3.8 "$toolpath/parse_xcodebuild_log.py" "$log" "errors_string")

echo "Outcome: $build_outcome"
if [[ $build_outcome == *"FAILED"* ]]; then
  echo "Build failed with errors: $build_errors"
  exit 1
fi

# Check if the emulator is already booted
if ! xcrun simctl list | grep "$iPhone" | grep "Booted"; then
    # Boot the emulator if not already booted
    xcrun simctl erase "$iPhone" 2>&1 || (echo "Failed to erase emulator" && exit 1)

else
    xcrun simctl shutdown "$iPhone" || (echo "Failed to shutdown emulator" && exit 1)
    xcrun simctl erase "$iPhone" || (echo "Failed to erase emulator" && exit 1)
fi

xcrun simctl boot "$iPhone" || (echo "Failed to boot emulator" && exit 1)

# Install and launch the app on the emulator
xcrun simctl install "$iPhone" "$YourAppPath" || (echo "Failed to install the app." && exit 1)

# Check if app is installed
is_installed=$(xcrun simctl listapps "$iPhone" | grep "$bundle_identifier")

echo "Checking $YourAppPath/Info.plist"

if [ -z "$is_installed" ]; then
    echo "App is not installed. Checking Info.plist..."
    # Check if Info.plist contains CFBundleVersion
    if ! grep -q "CFBundleVersion" "$YourAppPath/Info.plist"; then
        echo "Info.plist does not contain a valid CFBundleVersion."
        exit 1
    fi
else
    echo "App is installed."
fi

# Launch the app and capture the output
echo "Launching the app..."
open -a Simulator
xcrun simctl launch "$iPhone" "com.mixculuture.MixCulture" || (echo "Failed to launch the app." && exit 1)

