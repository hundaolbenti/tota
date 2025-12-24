---
description: How to build the Tota app on Appcircle
---

# Appcircle Build Configuration for Tota

Since your Flutter project is located in a subdirectory (`app/`), you need to configure Appcircle specifically to locate it.

## 1. Project Configuration
- **Repository**: Connect your Git repository.
- **Main Module**: Select the repository you just connected.

## 2. Build Profile
- Create a new Build Profile (e.g., "Tota Android").
- **Target Platform**: Android.

## 3. Workflow Configuration
1. Go to the **Workflows** tab and edit the workflow.
2. **Flutter Version**: Appcircle's "Stable" channel often points to the very latest usage (e.g. 3.24+ or 3.27+). We have upgraded the Gradle configuration to support these newer versions. If you prefer `3.19.x`, you must explicitly select it in Appcircle configuration. Current project config supports 3.22+ primarily.
3. **Important: Working Directory**:
   - In the **Flutter Build** step (and `Flutter Install`, `Flutter Analyze` etc.), look for a setting called **Working Directory** or **Project Path**.
   - Set this to: `./app` or just `app`.
   - **Why?** Your `pubspec.yaml` is inside the `app` folder, not the root of the repository. If you don't set this, the build will fail with "No pubspec.yaml found".

## 4. Signing (Optional but Recommended)
- If you want a release-ready APK, configure the **Android Sign** step in Appcircle.
- Upload your Keystore file to the Appcircle Signing Identities module.
- The build will produce an APK signed with a debug key by default (due to `signingConfig signingConfigs.debug` in `build.gradle`). The **Android Sign** step will resign it with your release key.

## 5. Environment Variables
- Ensure you have set any necessary environment variables if your app uses them (e.g., API keys).

## 6. Artifacts
- The output APK will typically be found in `app/build/app/outputs/flutter-apk/app-release.apk`.
- Appcircle should automatically pick this up if the "Export Build Artifacts" step is configured correctly.
