#!/bin/bash
# -------------------------------------------------------------------
# Script: universal_flutter_app_setup.sh
#
# Purpose:
# This script sets up a new Flutter app by copying an existing base app.
#
# It prompts you for:
# 1. The path to your base app directory. [eg : /Users/macmini2/Documents/PROJECTS/R&D/base_app_3271]
# 2. The destination path for your new app. [eg: /Users/macmini2/Documents/PROJECTS/R&D]
# 3. The new app name. [eg: flutterpie]
# 4. The Flutter version to use. [eg: /Users/macmini2/Documents/FRAMEWORKS/flutter]
#
# The script then:
# - Creates a new app directory inside the given destination.
# - Copies the base app to the new app directory.
# - Updates the app name in `pubspec.yaml`.
# - Replaces all occurrences of the old app name in imports.
# - Removes `.iml` files if they exist.
# - Updates the Android and iOS app names.
# - Runs `flutter pub get` and `flutter clean` to initialize the project.
#
# -------------------------------------------------------------------
#
# Usage:
#   1. Navigate to the directory where the script is stored 
#      cd ~/Desktop
#
#   2. Check for the contents in this directory
#      ls
#
#   3. Make the script executable:
#         chmod +x universal_flutter_app_setup.sh
#
#   4. Run the script:
#         ./universal_flutter_app_setup.sh
#
# Notes for macOS:
#   - If FVM is not installed, you'll be prompted to enter the full Flutter SDK path.
#   - If FVM is installed, you can select the Flutter version from the list.
#
# Notes for Windows:
#   - Run this script using Git Bash or WSL.
#   - Ensure FVM is installed and configured if you want to select the Flutter version via FVM.
#
# -------------------------------------------------------------------

# Prompt for the base app path
echo "Enter the path to your base app (e.g., /Users/macmini2/Documents/PROJECTS/R&D/base_app_3271):"
read -r BASE_APP_PATH

# Validate the base app path
if [ ! -d "$BASE_APP_PATH" ]; then
    echo "❌ Error: The base app path does not exist: $BASE_APP_PATH"
    exit 1
fi

# Prompt for the destination folder
echo "Enter the destination path where the new app should be created (e.g., /Users/macmini2/Documents/PROJECTS/R&D):"
read -r DESTINATION_PATH

# Validate the destination path
if [ ! -d "$DESTINATION_PATH" ]; then
    echo "❌ Error: The destination path does not exist: $DESTINATION_PATH"
    exit 1
fi

# Ask for the new app name
echo "Enter the new app name (e.g., my_new_app):"
read -r NEW_APP_NAME

NEW_APP_PATH="$DESTINATION_PATH/$NEW_APP_NAME"

# Extract the base app's name from pubspec.yaml
OLD_APP_NAME=$(grep '^name:' "$BASE_APP_PATH/pubspec.yaml" | awk '{print $2}')

# Create the new app directory
mkdir -p "$NEW_APP_PATH"

echo "📂 Copying the base app from '$BASE_APP_PATH' to '$NEW_APP_PATH'..."
cp -r "$BASE_APP_PATH"/* "$NEW_APP_PATH"

echo "📍 Navigating to the new app directory: '$NEW_APP_PATH'"
cd "$NEW_APP_PATH" || exit

# Ask for Flutter version setup
if command -v fvm > /dev/null; then
    echo "✅ FVM is installed. Available Flutter versions:"
    fvm list
    echo "Enter the Flutter version to use (e.g., 3.27.1):"
    read -r FLUTTER_VERSION
    USE_FVM=true
else
    echo "⚠️ FVM is not installed."
    # Check if the script is running on Windows or macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Please enter the full path to the Flutter SDK you wish to use."
        echo "(Example for macOS: /Users/macmini2/Documents/FRAMEWORKS/flutter)"
        read -r FLUTTER_SDK_PATH
        if [ ! -d "$FLUTTER_SDK_PATH" ]; then
            echo "❌ Error: The Flutter SDK path does not exist: $FLUTTER_SDK_PATH"
            exit 1
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "Please enter the full path to the Flutter SDK you wish to use on Windows."
        echo "(Example for Windows: C:/flutter)"
        read -r FLUTTER_SDK_PATH
        if [ ! -d "$FLUTTER_SDK_PATH" ]; then
            echo "❌ Error: The Flutter SDK path does not exist: $FLUTTER_SDK_PATH"
            exit 1
        fi
    else
        echo "Unsupported OS. Please ensure you are running this script on macOS or Windows."
        exit 1
    fi
    USE_FVM=false
fi

# Set Flutter version or SDK path
if [ "$USE_FVM" = true ]; then
    echo "⚡ Setting Flutter version to '$FLUTTER_VERSION' using FVM..."
    fvm use "$FLUTTER_VERSION"
else
    echo "⚡ Configuring Flutter to use SDK at: '$FLUTTER_SDK_PATH'"
    export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
    flutter --version
fi

# Update app name in pubspec.yaml
echo "📝 Updating app name in pubspec.yaml..."
sed -i '' "s/^name: .*/name: $NEW_APP_NAME/" "$NEW_APP_PATH/pubspec.yaml"

# Replace old app name in imports and code
echo "🔄 Updating package imports from '$OLD_APP_NAME' to '$NEW_APP_NAME'..."
find "$NEW_APP_PATH/lib" -type f -name "*.dart" -exec sed -i '' "s/package:$OLD_APP_NAME/package:$NEW_APP_NAME/g" {} +

# Remove .iml files (IntelliJ/Android Studio module files)
echo "🧹 Removing .iml files..."
find "$NEW_APP_PATH" -type f -name "*.iml" -exec rm -f {} +

# Update Android app name in strings.xml
echo "📝 Updating Android app name in strings.xml..."
sed -i '' "s/<string name=\"app_name\">.*<\/string>/<string name=\"app_name\">$NEW_APP_NAME<\/string>/" "$NEW_APP_PATH/android/app/src/main/res/values/strings.xml"

# Update iOS app name in Info.plist
echo "📝 Updating iOS app name in Info.plist..."
plutil -replace CFBundleDisplayName -string "$NEW_APP_NAME" "$NEW_APP_PATH/ios/Runner/Info.plist"

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Clean the project
echo "🧹 Cleaning project..."
flutter clean

echo "🎉 New Flutter app '$NEW_APP_NAME' created successfully at '$NEW_APP_PATH'"
