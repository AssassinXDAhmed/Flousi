<div align="center">

  <h1>💰 Flousi (فلوسي)</h1>
  <p><strong>A modern، personal finance and expense tracker engineered with Flutter & Cloudflare Worker AI microservices.</strong></p>

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Cloudflare](https://img.shields.io/badge/Cloudflare_Workers-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://workers.cloudflare.com)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

</div>

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Directory Structure](#-directory-structure)
- [Cloudflare AI Worker Pipeline](#-cloudflare-ai-worker-pipeline)
- [Getting Started](#-getting-started)
- [Environment Configuration](#-environment-configuration)
- [License](#-license)

---

## 🌟 Overview

**Flousi** (Arabic for *"My Money"*) is a high-performance cross-platform mobile application designed to simplify personal wealth tracking. Built using **Flutter** and **Firebase**, it delivers zero-latency optimistic UI updates, full multi-currency tracking (LYD, USD, EUR, GBP), granular multi-tier budget controls, and seamless real-time syncing. 

Flousi leverages **Serverless Cloudflare Workers** to run edge AI tasks — including predictive spending forecasting via Groq LLMs and automated OCR receipt parsing via Google AI Studio Vision models.

---

## ✨ Key Features

* **⚡ Optimistic UI & Full Offline Resilience**:
  * Write transactions locally instantly without blocking on network futures.
  * Automatic background retry queues with automatic rollback handling and reactive UI sync status notifications.
* **🤖 Edge AI Intelligence**:
  * **AI Receipt OCR**: Capture receipts via camera or gallery to automatically extract amounts, categories, dates, and payment types.
  * **Predictive Forecasting**: Groq-powered AI model analyzes 7-day spending trends to predict upcoming week expenses and output tailored budgeting advice.
* **💳 Multi-Currency & Payment Method Tracking**:
  * Multi-method payment segregation: **Cash (LYD)**, **LYD Debit Card**, **Bank Transfer**, and **USD Virtual/Physical Cards**.
  * Dynamic currency formatting tailored to North African/Libyan regional contexts (`en_LY`).
* **📊 Visual Analytics & Reports**:
  * Interactive `fl_chart` spending breakdown donuts and category lists.
  * Interactive spotlight-bordered cards with mesh gradients, meteors particle background systems, and custom dynamic theme animations.
* **🔒 Biometric App Security**:
  * Integrated OS-level biometric gate lock (`local_auth` fingerprint/FaceID) with instant password failover.
* **🌍 Full Arabic/English Localization**:
  * Real-time language switcher with complete Right-To-Left (RTL) & Left-To-Right (LTR) adaptive UI mirroring.

---

## 🏗 Architecture & Tech Stack

Flousi strictly adheres to **Clean Architecture Principles** grouped by feature modules:

`[ Presentation Layer ]` --> `[ Domain Layer ]` <-- `[ Data Layer ]`
*(Providers, Screens)* → *(Pure Dart Core)* ← *(Firestore, Workers, Storage)*

* **Frontend Framework**: Flutter (Dart)
* **State Management**: `provider` (`ChangeNotifier` + `Consumer`/`MultiProvider`)
* **Backend Infrastructure**: Firebase Auth, Cloud Firestore
* **Edge Proxy / AI Orchestration**: Cloudflare Workers (JavaScript/TypeScript ES Modules)
* **AI Models**: Groq API (`openai/gpt-oss-20b`), Google AI Studio Vision (`gemma-4-26b-a4b-it`, `gemma-4-31b-it`)
* **Local Storage**: `shared_preferences`
* **Text Recognition**: `google_mlkit_text_recognition`, `flutter_tesseract_ocr`

---

### 📁 Directory Structure

```text
lib/
├── core/                        # Global app components
│   ├── constants/               # Mock data & global constants
│   ├── fx/                      # Aurora, Meteors, Spotlight, Scramble animations
│   ├── localization/            # Shared language providers
│   ├── network/                 # Custom HTTP client & Cloudflare proxy adapters
│   ├── theme/                   # Custom dark glassmorphism design system
│   ├── utils/                   # Currency & precision formatters
│   └── widgets/                 # Reusable UI states (Empty states, loaders)
├── features/                    # Feature-driven modular structure
│   ├── analytics/               # Donut charts, category breakdowns, report generators
│   ├── auth/                    # Login, Signup, Password Reset state gates
│   ├── biometric/               # OS Fingerprint/Face ID verification
│   ├── budget/                  # Total, Category, and Payment Method limits
│   ├── categories/              # Dynamic expense category managers
│   ├── dashboard/               # Main dashboard, quick actions, balance summary
│   ├── debts/                   # Debts & Loans ledger tracker
│   ├── home/                    # Bottom navigation scaffold & route stack
│   ├── profile/                 # User settings, security config, language options
│   ├── receipt_ai/              # Image OCR & receipt extraction pipeline
│   ├── subscriptions/           # Monthly/Weekly recurring billing manager
│   ├── transactions/            # Core financial transactions CRUD & sync engine
│   └── user/                    # App settings & user profile state
├── l10n/                        # ARB Localization translation bundles (AR / EN)
├── firebase_options.dart        # Platform-specific Firebase client options
└── main.dart                    # Application bootstrap & Provider lifecycle initialization
```

---

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.4.0)
* [Node.js 18+](https://nodejs.org/) (for deploying the optional AI worker)
* A [Firebase Project](https://console.firebase.google.com/)

### 1. Firebase Setup

1. Copy the example configuration or generate fresh options using FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=your-firebase-project-id
   ```
2. Deploy Firestore Security Rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 2. (Optional) Cloudflare AI Worker Setup

The AI features (receipt scanning and predictive insights) proxy calls through a serverless Cloudflare Worker so that no API keys are embedded in client binaries:

```bash
cd worker
npm install
cp wrangler.jsonc.example wrangler.jsonc
# Edit wrangler.jsonc with your FIREBASE_PROJECT_ID

# Set your AI API secrets
npx wrangler secret put GROQ_API_KEY
npx wrangler secret put GOOGLE_AI_API_KEY

# Deploy to Cloudflare
npx wrangler deploy
```

### 3. Run the App

```bash
# Standard run
flutter run

# With custom AI Worker URL
flutter run --dart-define=AI_WORKER_URL=https://your-worker.your-subdomain.workers.dev
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).