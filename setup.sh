#!/bin/bash
# NutriTrack Flutter — Setup Script
# Run: bash setup.sh

set -e

echo "🥗 NutriTrack Flutter Setup"
echo "================================"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Install from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Create project
echo ""
echo "📦 Creating Flutter project..."
flutter create nutritrack_app --org com.yourname --platforms android,ios

cd nutritrack_app

# Copy our source files
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "📋 Copying source files..."
rm -rf lib/
cp -r "$SCRIPT_DIR/lib" .
cp "$SCRIPT_DIR/pubspec.yaml" .

# Copy Android config
echo "🤖 Configuring Android..."
cp -r "$SCRIPT_DIR/android/app/src/main/AndroidManifest.xml" android/app/src/main/AndroidManifest.xml
cp -r "$SCRIPT_DIR/android/app/src/main/res/xml" android/app/src/main/res/ 2>/dev/null || true
cp "$SCRIPT_DIR/android/app/build.gradle" android/app/build.gradle
cp "$SCRIPT_DIR/android/gradle.properties" android/gradle.properties

# Fix package name in build.gradle
sed -i 's/com.yourname.nutritrack/com.yourname.nutritrack/g' android/app/build.gradle

# Copy iOS config
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Configuring iOS..."
    cp "$SCRIPT_DIR/ios/Runner/Info.plist" ios/Runner/Info.plist
fi

# Install dependencies
echo ""
echo "📥 Installing packages..."
flutter pub get

echo ""
echo "================================"
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Add API keys:"
echo "     lib/services/usda_service.dart  → replace DEMO_KEY"
echo "     lib/services/ai_service.dart    → replace YOUR_OPENROUTER_API_KEY"
echo ""
echo "  2. Run the app:"
echo "     flutter run"
echo ""
echo "  3. Build APK:"
echo "     flutter build apk --release"
echo "================================"
