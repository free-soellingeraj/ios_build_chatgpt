#!/bin/bash

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq could not be found. Please install yq to parse YAML files."
    exit
fi

# Variables
config_file="config.yaml"

# Read values from config.yaml
YourAppBundleID=$(yq eval '.YourAppBundleID' $config_file)
iPhone=$(yq eval '.iPhone' $config_file)

# Check Input Arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: ./ios_app_rapid_test.sh <code_file_path> <golden_code_file_path>"
    exit 1
fi

# Variables
code_file_path=$1
golden_code_file_path=$2

# Show the difference
git diff --no-index "$golden_code_file_path" "$code_file_path"

# Run the emulator
xcrun simctl boot "$iPhone" || echo "Failed to boot the emulator."
xcrun simctl install "$iPhone" "$YourAppBundleID" || echo "Failed to install the app."
xcrun simctl launch "$iPhone" "$YourAppBundleID" || echo "Failed to launch the app."

# Prompt the user to accept the emulator state
read -p "Accept the emulator state? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Emulator state rejected."
    exit 1
fi

echo "Emulator state accepted."

