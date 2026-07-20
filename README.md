# 🌱 BloomOS – Smart Plant Care Assistant

BloomOS is a smart plant care system that combines Artificial Intelligence (AI), Internet of Things (IoT), and a Flutter mobile application to help users monitor plant health, detect diseases, and automate irrigation.

The system allows users to manage their plants, scan leaves for disease detection using AI, and connect to an ESP32 device for smart irrigation and environmental monitoring.

---

## 🚀 Features

- User authentication (Firebase Authentication)
- Add and manage plants
- AI-based plant disease detection
- Upload image or capture using camera
- Smart irrigation using ESP32
- Bluetooth connection with ESP32
- Optional Wi-Fi setup for Firebase synchronization
- Plant monitoring dashboard
- Diagnosis history
- Edit and delete plants
- Guest Mode support

---

## 🛠 Technologies

### Mobile Application
- Flutter
- Dart

### Artificial Intelligence
- Python
- TensorFlow / Keras
- MobileNetV2
- CNN

### Backend
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

### IoT
- ESP32
- Bluetooth
- Wi-Fi
- Soil Moisture Sensor
- Temperature Sensor

---

## 📂 Project Structure

```
BloomOS
├── lib/
├── assets/
├── android/
├── ios/
├── python/
├── model/
├── screenshots/
├── pubspec.yaml
└── README.md
```

---

## 📱 Application Screenshots

### Welcome
![Welcome](screenshott/Wlecome.jpeg)

### Hello Screen
![Hello](screenshott/Hello.jpeg)

### Login
![Login](screenshott/Login.jpeg)

### Onboarding
![Onboarding](screenshott/Onboarding.jpeg)

### Scan Plant
![Scan Plant](screenshott/scan%20plant.jpeg)

### Plant Detection
![Plant Detection](screenshott/Scanplants.jpeg)

### Upload Image
![Upload](screenshott/Upload.jpeg)

### Device Setup
![Device Setup](screenshott/Device%20set%20up.jpeg)

### Settings
![Settings](screenshott/Seetings.jpeg)

### Device Setup

![Device Setup](screenshott/device-setup.png)

---

## 🤖 AI Model

The AI model analyzes plant leaf images to detect diseases using a Convolutional Neural Network (CNN) based on MobileNetV2.

The prediction is displayed inside the mobile application with a diagnosis and recommendation.

---

## 🌿 Smart Irrigation

BloomOS integrates with an ESP32 microcontroller to:

- Monitor soil moisture
- Monitor temperature
- Control irrigation automatically
- Connect through Bluetooth
- Optionally synchronize data using Wi-Fi and Firebase

---

## ▶️ Getting Started

### Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/BloomOS.git
```

### Install Flutter packages

```bash
flutter pub get
```

### Run the application

```bash
flutter run
```

---

## 👩‍💻 My Contributions

- Developed Flutter application features.
- Integrated AI prediction with the mobile application.
- Contributed to Python development and system integration.
- Participated in testing, debugging, and project documentation.

---

## 📄 License

This project was developed as a Graduation Project at Prince Sattam Bin Abdulaziz University.
