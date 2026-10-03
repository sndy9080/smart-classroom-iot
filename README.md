# IoT-Based Smart Classroom

*An IoT-based smart classroom system that combines ESP32, PIR occupancy sensing, priority-based control, Firebase event logging, and a Flutter mobile application for real-time monitoring and control.*

## 📌 The Problem

Electrical load management in educational facilities often relies on manual control, which can lead to unnecessary energy use and conflicts between automated sensors and manual switches.

Traditional classroom control also provides limited centralized monitoring and makes it difficult to distinguish which input triggered a device state change.

## 💡 The Solution

Developed a centralized **IoT-based Smart Classroom** architecture using an **ESP32 Dev Module**, **PIR occupancy sensors**, physical buttons, relay-controlled lighting, **Firebase Realtime Database**, and a **Flutter mobile application**.

The system implements a three-level hierarchical priority control mechanism:

**Force Mode (Admin) > Auto Mode (PIR Sensor) > Manual Mode (Physical Button)**

This priority architecture resolves conflicts between different control inputs. When Force Mode is active, admin commands take precedence over sensor and physical-button inputs. In Auto Mode, lighting responds to PIR occupancy detection with a timeout mechanism, while Manual Mode allows local control through physical buttons.

The system also records device-state changes to Firebase Realtime Database together with the **timestamp** and **event source**, enabling contextual monitoring and historical auditing.

The main workflow consists of:

1. PIR sensors and physical buttons provide local input.
2. ESP32 processes the incoming control events.
3. The priority algorithm determines the active control source.
4. Relay outputs control the classroom lighting.
5. Device-state changes are logged to Firebase Realtime Database.
6. The Flutter application provides real-time monitoring and remote control.

## 🚀 The Impact / Results

* Functional **Black Box Testing** showed that the priority logic successfully prevented control conflicts across the tested scenarios.
* The system correctly prioritized **Force Mode** over physical-button and PIR inputs.
* The conventional operating scenario required **35.5 hours/week** of lighting operation.
* The Smart Classroom scenario reduced operating duration to **26.2 hours/week**.
* The resulting operational-time efficiency was **26.2%**.
* Scenario-based load profiling showed that the reduction mainly occurred during classroom transitions, breaks, and other periods when rooms were not occupied.
* Firebase logging preserved the **device status, timestamp, and event source**, providing additional context for energy analysis and system auditing.
* The research was published in **Digital Transformation Technology (Digitech)**, Vol. 6 No. 1, pp. 239–247, on **18 May 2026**.
* DOI: **10.47709/digitech.v6i1.8130**

## 📂 Repository Structure

The repository contains the system documentation, hardware prototype and wiring, ESP32 firmware, and Flutter mobile application.

```text
smart-classroom-iot/
├── README.md
│
├── docs/
│   ├── Control Page.jpg
│   ├── Dashboard Page.jpg
│   ├── History Page.jpg
│   ├── Priority Logic Flowchart.png
│   ├── Settings Page.jpg
│   ├── System Block Diagram.png
│   └── Total Duration Comparison Chart.png
│
├── hardware/
│   ├── images/
│   │   ├── Circuit Diagram.png
│   │   └── Hardware Prototype.jpg
│   │
│   └── sourcode_esp32/
│       └── sourcode_esp32.ino
│
└── software/
    └── flutter/
        ├── lib/
        │   ├── firebase_options.dart
        │   ├── main.dart
        │   ├── models/
        │   │   └── room.dart
        │   ├── screens/
        │   │   ├── history_screen.dart
        │   │   ├── home_screen.dart
        │   │   └── room_card.dart
        │   └── services/
        │       └── firebase_service.dart
        │
        ├── android/
        ├── ios/
        ├── web/
        ├── windows/
        ├── linux/
        ├── macos/
        ├── pubspec.yaml
        └── README.md
```

## 🛠️ Tech Stack

* **ESP32 Dev Module**
* **HC-SR501 PIR Sensor**
* **Physical Momentary Buttons**
* **Relay Module**
* **LED Lighting**
* **Arduino / C++**
* **Flutter / Dart**
* **Firebase Realtime Database**
* **Firebase**
* **Android / iOS / Web / Desktop Flutter Support**

## 📸 Project Gallery

### System Architecture

<p align="center">
  <img src="docs/System Block Diagram.png" alt="Smart Classroom System Block Diagram" width="800">
</p>

### Priority Control Logic

<p align="center">
  <img src="docs/Priority Logic Flowchart.png" alt="Priority Control Logic Flowchart" width="800">
</p>

### Hardware Prototype

<p align="center">
  <img src="hardware/images/Hardware Prototype.jpg" alt="Smart Classroom Hardware Prototype" width="800">
</p>

### Circuit Diagram

<p align="center">
  <img src="hardware/images/Circuit Diagram.png" alt="Smart Classroom Circuit Diagram" width="800">
</p>

### Flutter Dashboard

<p align="center">
  <img src="docs/Dashboard Page.jpg" alt="Flutter Dashboard Page" width="350">
</p>

### Flutter Control

<p align="center">
  <img src="docs/Control Page.jpg" alt="Flutter Control Page" width="350">
</p>

### Flutter History

<p align="center">
  <img src="docs/History Page.jpg" alt="Flutter History Page" width="350">
</p>

### Flutter Settings

<p align="center">
  <img src="docs/Settings Page.jpg" alt="Flutter Settings Page" width="350">
</p>

### Energy Efficiency

<p align="center">
  <img src="docs/Total Duration Comparison Chart.png" alt="Smart Classroom Total Duration Comparison" width="800">
</p>
