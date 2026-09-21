# VisionAI - Face Recognition & Biometric Attendance App

[![Backend Repository](https://img.shields.io/badge/Backend_API-faceapp--backend-0052CC?style=for-the-badge&logo=django&logoColor=white)](https://github.com/Samarjitkashyp/faceapp-backend)
[![Frontend App](https://img.shields.io/badge/Mobile_App-faceapp-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://github.com/Samarjitkashyp/faceapp)

A high-performance, enterprise-grade Facial Recognition & Attendance mobile application built with **Flutter** and powered by the [VisionAI Django REST + ArcFace Backend](https://github.com/Samarjitkashyp/faceapp-backend).

> 🔗 **Backend Repository**: This Flutter mobile client connects to the companion Django AI API hosted at **[https://github.com/Samarjitkashyp/faceapp-backend](https://github.com/Samarjitkashyp/faceapp-backend)**.

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
