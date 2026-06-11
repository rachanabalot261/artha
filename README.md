# Artha 💰
### Privacy-First AI Personal Finance Assistant for Android

> Your money. Your phone. Your business.

Artha is a local-first personal finance assistant that automatically tracks 
your UPI transactions, stores everything encrypted on your device, and lets 
you ask an AI anything about your finances — without a single byte of your 
data ever leaving your control.

No cloud. No account. No subscription. No ads. No trust required.

---

## The Problem

Every finance app that actually works requires you to hand over your financial 
life to a company you don't know.

- **YNAB, Copilot** — connect your bank, data goes to their servers
- **ET Money, Walnut** — SMS access sent to cloud, AI runs on their machines  
- **Money View, CRED** — your spending profile is their product

Indians specifically face a trust problem — multiple fintech breaches, tightening 
RBI regulations, and a general discomfort linking bank accounts to third-party apps.

**Artha solves this architecturally, not with a privacy policy.**

---

## How It Works
UPI Transaction → SMS on your phone
↓
Artha reads SMS locally (never sent anywhere)
↓
Parses merchant, amount, category, date
↓
Stores in AES-256 encrypted SQLite database
↓
You ask a question in plain language
↓
App builds context from your database
↓
Phi-3 Mini reasons about your actual numbers
↓
Answer appears on screen

Zero bytes of your financial data reach any external server.

---

## Features

### Core
- **Automatic SMS import** — reads last 12 months of UPI transaction SMS 
  on first launch, captures new ones in real time
- **Multi-bank support** — HDFC, SBI, ICICI, Axis, Kotak, Paytm, 
  GPay, PhonePe, BHIM and more
- **Smart categorization** — auto-assigns Food, Transport, Entertainment, 
  Shopping, Health, Utilities, Education, Rent, Subscriptions from 
  merchant keywords
- **Manual entry** — add cash transactions that don't generate SMS
- **Search** — find any transaction instantly
- **Swipe to delete** — remove incorrect or duplicate entries

### Dashboard
- Monthly income, spending, savings at a glance
- Category breakdown with proportional segmented bar
- 6-month income vs spending trend chart
- Month navigation — browse any past month
- Smart number formatting (₹1.5L, ₹5K)

### AI Chat — Ask Artha
- Natural language financial Q&A powered by Phi-3 Mini
- Streaming responses — answers appear word by word
- Grounded in your real transaction data — no hallucinated numbers
- Quick suggestion chips for common questions
- Runs on your home network via Ollama — never reaches any cloud

### Security
- **AES-256 encrypted database** via SQLCipher
- **Hardware-backed encryption key** stored in Android Keystore 
  (Trusted Execution Environment)
- **Biometric lock screen** — fingerprint or face unlock
- **Auto-lock** — re-locks after 30 seconds in background
- **Manual lock** — lock instantly from settings

---

## Architecture
┌─────────────────────────────────────┐
│           Flutter UI Layer          │
│  Dashboard │ Spends │ Chat │ Settings│
└──────────────────┬──────────────────┘
│ watches
┌──────────────────▼──────────────────┐
│         Riverpod State Layer        │
│  Providers auto-update UI on change │
└──────────────────┬──────────────────┘
│ queries
┌──────────────────▼──────────────────┐
│          Data & Service Layer       │
│  DatabaseHelper │ SmsService        │
│  AiService      │ KeyManager        │
└──────────────────┬──────────────────┘
│ encrypts with
┌──────────────────▼──────────────────┐
│     SQLCipher (AES-256) Database    │
│         artha_secure.db             │
│      Key → Android Keystore TEE     │
└─────────────────────────────────────┘

**The AI never touches your database directly.**
It receives a formatted text summary built from your data.
Your raw transactions never leave the device.

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Mobile Framework | Flutter 3.41 + Dart | Single codebase Android/iOS, native performance |
| State Management | Riverpod 2.4 | Type-safe, compile-time errors, auto-rebuilds |
| Database | SQLite via sqflite_sqlcipher | Local-first, AES-256 encrypted at file level |
| Key Storage | flutter_secure_storage | Hardware-backed Android Keystore TEE |
| Biometrics | local_auth | System BiometricPrompt API, OS handles auth |
| SMS Reading | telephony | Local inbox access, no network transmission |
| AI Model | Phi-3 Mini 3.8B (Q4 quantized) | Best reasoning/size ratio for edge deployment |
| AI Runtime | Ollama (local network) | Runs model on your hardware, not cloud |
| Charts | fl_chart | Smooth, customizable Flutter-native charts |
| HTTP | http package | Local network calls to Ollama only |

---

## Privacy Architecture

### What stays on your phone
- All transaction data
- Encrypted database file
- Encryption key (in hardware)
- SMS parsing logic
- All UI and app code

### What goes to your laptop (home WiFi only)
- Your question + a formatted summary of your finances
- Example: "Food: ₹4200, Transport: ₹1800... User: Can I afford ₹10,000?"
- Never reaches the internet

### What goes nowhere
- Raw transaction data
- Bank account details
- SMS message content
- Personal information of any kind

### Comparison

| | Artha | Walnut | ET Money | CRED |
|---|---|---|---|---|
| Data on your device | ✅ | ❌ | ❌ | ❌ |
| No account needed | ✅ | ❌ | ❌ | ❌ |
| AI on your hardware | ✅ | ❌ | ❌ | ❌ |
| No ads | ✅ | ❌ | ❌ | ❌ |
| Open source | ✅ | ❌ | ❌ | ❌ |
| Works offline | ✅ | ❌ | ❌ | ❌ |

---

## Setup

### Prerequisites
- Android phone with 4GB+ RAM (tested on Samsung M35)
- Windows/Mac/Linux laptop on same WiFi
- Flutter 3.41+
- Android Studio (for SDK tools only)

### Run the app

```bash
git clone https://github.com/rachanabalot261/artha.git
cd artha
flutter pub get
flutter run
```

### Set up AI (one time)

```bash
# Install Ollama from https://ollama.ai
ollama pull phi3:mini

# Start server on your network
# Windows:
$env:OLLAMA_HOST="0.0.0.0"; ollama serve

# Mac/Linux:
OLLAMA_HOST=0.0.0.0 ollama serve
```

Update your laptop IP in `lib/services/ai_service.dart`:
```dart
static const _base = 'http://YOUR_LAPTOP_IP:11434';
```

### First launch
1. Open app — biometric lock skipped on first launch
2. Go to Settings → Import from SMS
3. Grant SMS permission
4. Wait 30-60 seconds for import
5. Check Dashboard — your finances are there
6. Go to Ask Artha — ask anything

---

## Current Status

| Feature | Status |
|---|---|
| SMS auto-import (HDFC, SBI, Paytm, GPay, PhonePe) | ✅ Complete |
| AES-256 encrypted SQLite database | ✅ Complete |
| Hardware-backed key in Android Keystore | ✅ Complete |
| Biometric lock screen | ✅ Complete |
| Auto-lock after 30s background | ✅ Complete |
| Dashboard — income, spent, savings | ✅ Complete |
| Category breakdown with segmented bar | ✅ Complete |
| 6-month trend chart | ✅ Complete |
| AI chat with streaming responses | ✅ Complete |
| Manual transaction entry | ✅ Complete |
| Search and swipe-to-delete | ✅ Complete |
| Dark theme — custom design system | ✅ Complete |
| GitHub repository | ✅ Live |
| CSV import | 🔄 In Progress |
| Budget alerts | 🔄 In Progress |

---

## Roadmap

### v1.1 — Data
- CSV import for bank statements (HDFC, SBI, ICICI, Axis)
- Credit card statement parsing
- Recurring transaction detection — auto-detect subscriptions
- Data export as PDF monthly report

### v1.2 — Intelligence
- True on-device AI via MLC LLM (no laptop needed)
- Spending predictions — "at this rate you'll overspend Food by ₹1,200"
- Anomaly detection — "this is 3x your usual Swiggy spend"
- Investment suggestions based on consistent savings pattern

### v1.3 — Features
- Budget setting per category with progress bars and alerts
- Multi-account support (separate salary and savings accounts)
- Net worth tracking
- Custom categories
- Widget for home screen — quick balance glance

### v1.4 — Platform
- iOS support
- Scheduled SMS background sync
- Biometric-protected data export
- Dark/light theme toggle

### Long Term
- Account Aggregator integration (when registered as FIU with RBI)
- Support for international banks and non-UPI markets
- Completely offline AI — no laptop, no network, pure on-device

---

## Why This Matters

On-device AI for sensitive data is the defining trend of 2025-2027.

Apple Intelligence, Google's Gemini Nano, Qualcomm's AI roadmap — 
all moving toward keeping sensitive computation local. Artha is built 
on this principle before it becomes the industry standard.

The Indian market specifically has 500M+ UPI users, growing distrust 
of data-sharing fintech apps, and zero polished privacy-first finance 
tools. That gap is the opportunity.

---

## Resume

Built Artha — a privacy-first personal finance assistant for Android.
AES-256 encrypted local database (SQLCipher) with hardware-backed key 
storage in Android Keystore TEE. Biometric authentication with 
auto-lock on background. Real-time SMS parsing across HDFC, SBI, ICICI, 
Paytm, GPay, PhonePe using regex pattern matching with auto-categorization 
across 50+ merchants. On-device LLM financial Q&A via Phi-3 Mini (3.8B, 
Q4 quantized) running locally — zero cloud transmission of financial data.

**Stack:** Flutter • Dart • SQLCipher • Riverpod • Phi-3 Mini • Ollama • 
Android Keystore • BiometricPrompt API

---

## License

MIT License — use it, build on it, share it.

---

*Built with the conviction that your financial life is yours alone.*