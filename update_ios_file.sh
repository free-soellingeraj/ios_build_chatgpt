#!/bin/bash

# Validate input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./automation-script.sh path_to_your_script"
    exit 1
fi

# Variables
script_to_run=$1
project_name="YourProjectName"
scheme="YourSchemeName"
simulator_name="iPhone 12"
app_path="path/to/your/app.app"
bundle_id="your.app.bundle.id"

# Step 1: Make the input script executable
chmod +x $script_to_run

# Step 2: Run your script for modifications
./$script_to_run

# Step 3: Clear Derived Data
derived_data_folder=~/Library/Developer/Xcode/DerivedData
rm -rf "$derived_data_folder/$project_name"

# Step 4: Get the simulator ID
simulator_id=$(xcrun simctl list devices | grep "$simulator_name" | grep -oE '([A-Z0-9\-])+' | head -1)

# Step 5: Build the app in the simulator
xcodebuild -scheme "$scheme" -destination "id=$simulator_id" clean build

# Step 6: Boot the simulator
xcrun simctl boot "$simulator_id"

# Step 7: Install the app on the simulator
xcrun simctl install "$simulator_id" "$app_path"

# Step 8: Launch the app
xcrun simctl launch "$simulator_id" "$bundle_id"

# Inform user
echo "Script finished. The app should now be running in the simulator."

