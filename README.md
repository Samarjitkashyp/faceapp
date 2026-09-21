# VisionAI - Face Recognition & Biometric Attendance App

A high-performance, enterprise-grade Facial Recognition & Attendance mobile application built with **Flutter** and powered by a **Django REST + ArcFace (InsightFace)** AI backend.

---

## 🚀 Key Features

- **5-Angle Biometric Setup Wizard**:
  - Sequential calibration (Front, Left, Right, Up, Smile).
  - Hands-free auto-capture countdown synchronized with AI voice guidance.
  - Step-by-step verification pipeline with backend facial embedding extraction.
- **Biometric Check-In & Live Scan**:
  - Live viewfinder with mirror effect on front camera.
  - Interactive HUD scanner with real-time feedback.
  - Voice-guided instructions with multilingual TTS support (English & Hindi).
  - Instant timestamped check-in / check-out recording.
- **Robust Security & User Isolation**:
  - Guarded biometric check-in locked until all 5 angles are calibrated.
  - Per-user face vector isolation to ensure accurate identity matching.
  - Dark glassmorphism UI design with customized animations.
- **Dynamic Server Configuration**:
  - In-app LAN / Localhost / Cloud API URL configuration.
  - Persistent local cache with fallback offline handling.

---

## 📱 Tech Stack

- **Framework**: [Flutter 3.x](https://flutter.dev)
- **Language**: Dart
- **State Management**: Provider
- **Camera Integration**: `camera` plugin with custom viewfinder mirroring
- **Text-to-Speech**: `flutter_tts` with custom speech synthesis and bilingual dictionaries
- **Networking**: `dio` & `http` with multipart image uploads
- **Local Storage**: `shared_preferences`

---

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.19+)
- Android Studio / VS Code with Flutter extension
- Android device or emulator with camera support
- Backend server running (Django ArcFace API)

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Samarjitkashyp/faceapp.git
   cd faceapp
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Analysis & Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📦 Building the App

### Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split per-ABI APK (Smaller Size)
```bash
flutter build apk --split-per-abi --release
```

---

## 📄 License

This project is licensed under the MIT License.
