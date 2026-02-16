# ActivLock 🔒💪

**Lock Apps. Earn Access. Get Fit.**

ActivLock is a Flutter-based Android application that helps you break phone addiction by locking your distracting apps and requiring physical activity (Squats) to unlock them.

Built with a futuristic **Wakanda-inspired** theme 🙅🏿‍♂️💜.

## 📥 Download

**[Download Latest APK (v1.0)](./app-release.apk)**

## ✨ Features

- **App Locking**: Select apps to lock (e.g., Instagram, TikTok, YouTube).
- **Squat to Unlock**: Use ML Kit Pose Detection to verify you actually did the squats!
- **Daily Limits**: Set a maximum number of unlocks per day for each app.
- **Strict Mode**: Once the daily limit is reached, the app stays locked until tomorrow.
- **Beautiful UI**: Sleek, dark-mode futuristic design.

## 🚀 Installation & Permissions (IMPORTANT)

Since this app uses advanced features like "Display over other apps" and "Accessibility Services" to lock other apps, you need to grant special permissions.

**For Android 13+ Users:**

When you first install the app from an APK (not Play Store), Android restricts the "Accessibility Service" for security. **You must manually allow it.**

1.  **Install the APK**.
2.  Open the app. It will ask for permissions.
3.  When asked for **Accessibility Service**, if the switch is grayed out or says "Restricted Settings":
    *   Go to your phone's **Settings** -> **Apps** -> **ActivLock**.
    *   Tap the **three dots (⋮)** in the top-right corner.
    *   Tap **"Allow restricted settings"**.
    *   Now go back to **Settings -> Accessibility -> ActivLock** and enable it.

4.  Grant **"Display over other apps"** permission when prompted.
5.  Grant **"Camera"** permission for squat detection.

## 🛠️ Built With

- **Flutter** - UI Framework
- **Google ML Kit** - Pose Detection
- **Riverpod** - State Management
- **Flutter Background Service** - To keep the lock running

---
*Created by [SivaSekar-P](https://github.com/SivaSekar-P)*
