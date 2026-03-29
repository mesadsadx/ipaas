@echo off
REM NutriTrack Flutter — Windows Setup
REM Run: setup.bat

echo 🥗 NutriTrack Flutter Setup
echo ================================

REM Check Flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found.
    echo    Install from: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo ✅ Flutter found

REM Create project
echo.
echo 📦 Creating Flutter project...
flutter create nutritrack_app --org com.yourname --platforms android,ios
cd nutritrack_app

REM Copy files
echo 📋 Copying source files...
rmdir /s /q lib
xcopy /s /e /y "..\lib" "lib\"
copy /y "..\pubspec.yaml" "pubspec.yaml"

REM Android config
echo 🤖 Configuring Android...
copy /y "..\android\app\src\main\AndroidManifest.xml" "android\app\src\main\AndroidManifest.xml"
copy /y "..\android\app\build.gradle" "android\app\build.gradle"
copy /y "..\android\gradle.properties" "android\gradle.properties"
if not exist "android\app\src\main\res\xml" mkdir "android\app\src\main\res\xml"
copy /y "..\android\app\src\main\res\xml\file_paths.xml" "android\app\src\main\res\xml\file_paths.xml"

REM Install packages
echo.
echo 📥 Installing packages...
flutter pub get

echo.
echo ================================
echo ✅ Setup complete!
echo.
echo 📝 Next steps:
echo   1. Add API keys:
echo      lib\services\usda_service.dart  - replace DEMO_KEY
echo      lib\services\ai_service.dart    - replace YOUR_OPENROUTER_API_KEY
echo.
echo   2. Run the app:
echo      flutter run
echo.
echo   3. Build APK:
echo      flutter build apk --release
echo ================================
pause
