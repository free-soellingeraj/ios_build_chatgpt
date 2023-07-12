
# Set the scheme and the name of the simulator you want to use
SCHEME="YourSchemeName"
SIMULATOR_NAME="iPhone 12"

# Get the simulator ID
SIMULATOR_ID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -oE '([A-Z0-9\-])+' | head -1)

# Build and run the app in the simulator
xcodebuild -scheme "$SCHEME" -destination "id=$SIMULATOR_ID" clean build

# Boot the simulator
xcrun simctl boot "$SIMULATOR_ID"

# Install the app on the simulator
xcrun simctl install "$SIMULATOR_ID" "path/to/your/app.app"

# Launch the app
xcrun simctl launch "$SIMULATOR_ID" "your.app.bundle.id"

