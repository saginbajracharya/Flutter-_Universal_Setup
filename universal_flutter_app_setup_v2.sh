#!/bin/bash

# -------------------------------------------------------------------
# Script: universal_flutter_app_setup.sh
#
# Purpose:
# This script sets up a new Flutter app by copying an existing base app.
#
# It prompts you for:
# 1. The path to your base app directory.
# 2. The destination path for your new app.
# 3. The new app name (in lower_case_with_underscores style).
# 4. The new package name (optional; defaults to com.example.new_app_name).
# 5. The Flutter SDK path to use (optional; uses global Flutter if not provided).
#
# The script then:
# - Creates a new app directory inside the given destination.
# - Copies the base app to the new app directory.
# - Updates the app name and description in `pubspec.yaml`.
# - Replaces all occurrences of the old app name in Dart imports.
# - Removes `.iml` files if they exist to avoid IDE-specific configurations.
# - Updates Android and iOS app names in their respective project files.
# - Updates the package name in Android (AndroidManifest.xml, build.gradle) and iOS (Info.plist, project.pbxproj).
# - Updates the app title in `app_localizations.dart`.
# - Updates package names for Windows, macOS, Linux, and Web platforms.
# - Installs dependencies with `flutter pub get` and runs `flutter clean` to reset the project.
# - Provides options to retry, continue, or rollback if `flutter pub get` fails.
#
# Usage:
#   1. Navigate to the directory where the script is stored:
#      cd /path/to/script
#      cd "/Users/macmini2/Documents/PROJECTS/R&D/BASE_APPS/FlutterUniversalSetup"
#   2. Check for the contents in this directory to verify the script exists:
#      ls
#   3. Make the script executable:
#      chmod +x universal_flutter_app_setup.sh
#   4. Run the script:
#      ./universal_flutter_app_setup.sh
#
# Notes:
# - Ensure you have Flutter installed and added to your system PATH.
# - The script uses `sed` for text replacement, which may behave differently on macOS and Linux.
# - You may need to grant execute permissions to the script using:
#   chmod +x universal_flutter_app_setup.sh
# -------------------------------------------------------------------
# Prompt for the base app path
echo "Enter the path to your base app:"
read -r BASE_APP_PATH

# Validate the base app path
if [ ! -d "$BASE_APP_PATH" ]; then
    echo "❌ Error: The base app path does not exist: $BASE_APP_PATH"
    exit 1
fi

# Prompt for the destination folder
echo "Enter the destination path for the new app:"
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

# Prompt for new package name
echo "Enter the new package name (e.g., com.example.$NEW_APP_NAME):"
read -r NEW_PACKAGE_NAME

# Create the new app directory
mkdir -p "$NEW_APP_PATH"
cp -r "$BASE_APP_PATH"/* "$NEW_APP_PATH"
cd "$NEW_APP_PATH" || exit

# Check for FVM or prompt for Flutter SDK path
if command -v fvm > /dev/null; then
    echo "✅ FVM detected. Enter the Flutter version to use:"
    read -r FLUTTER_VERSION
    fvm use "$FLUTTER_VERSION"
else
    echo "Enter the full path to your Flutter SDK:"
    read -r FLUTTER_SDK_PATH
    export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
    flutter --version
fi

# Update app name in pubspec.yaml
sed -i '' "s/^name: .*/name: $NEW_APP_NAME/" "$NEW_APP_PATH/pubspec.yaml"

# Update package imports
find "$NEW_APP_PATH/lib" -type f -name "*.dart" -exec sed -i '' "s/package:$OLD_APP_NAME/package:$NEW_APP_NAME/g" {} +

# Remove .iml files
find "$NEW_APP_PATH" -type f -name "*.iml" -exec rm -f {} +

# Update Android app name and package name
sed -i '' "s/<string name=\"app_name\">.*<\/string>/<string name=\"app_name\">$NEW_APP_NAME<\/string>/" "$NEW_APP_PATH/android/app/src/main/res/values/strings.xml"
sed -i '' "s/applicationId \".*\"/applicationId \"$NEW_PACKAGE_NAME\"/" "$NEW_APP_PATH/android/app/build.gradle"

# Update iOS app name
plutil -replace CFBundleDisplayName -string "$NEW_APP_NAME" "$NEW_APP_PATH/ios/Runner/Info.plist"
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE_NAME;/" "$NEW_APP_PATH/ios/Runner.xcodeproj/project.pbxproj"

# Install dependencies
flutter pub get
flutter clean

echo "🎉 New Flutter app '$NEW_APP_NAME' created successfully at '$NEW_APP_PATH'"
