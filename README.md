# Dhaka Mass Rapid Transit (DMRT) Online — Mobile App (Prototype 1)

A modern, high-performance, native **Flutter** passenger mobile application for Bangladesh's Dhaka Metro Rail (MRT Line 6) with **Supabase (PostgreSQL 17)** Cloud Backend Integration, Direct Ticket QR Transit, and Offline-First Dual-Layer Persistence.

Built with clean architecture, pixel-perfect Dhaka Metro Rail visual branding, and verified with a 100% automated test suite.

---

## 🌟 Key Features

* **Complete Supabase Backend Integration**: 10 PostgreSQL tables (`stations`, `routes`, `passengers`, `authentications`, `live_tickets`, `payments`, `refunds`, `archive_tickets`, `events`, `fines`) and atomic PL/pgSQL RPC stored procedures (`rpc_request_otp`, `rpc_verify_otp`, `rpc_buy_ticket`, `rpc_pass_entry_barrier`, `rpc_pass_exit_barrier`, `rpc_request_refund`).
* **Direct Ticket QR Transit**: Immediate Ticket QR presentation at station gates with simulated entry/exit turnstile clearance without hardware hurdles.
* **Phone Authentication & Dynamic Provisioning**: Auto-provisions new commuters with testing code `000000` and syncs commuter profile names.
* **Offline-First Resilience**: Full dual-layer persistence (local `SharedPreferences` + Supabase) enabling seamless offline transit.
* **Authentic Ticket Wave & Punch Notch UI**: Custom Bézier S-curve clippers (`C 46,56 46,100 36,100`) and mathematical gradient punch notches (`DynamicTicketNotchCutout`).
* **1-Second Hold-to-Purchase Confirmation**: Clockwise SVG circular progress hold confirmation on a dedicated review card with haptic feedback.
* **16-Station Fare Matrix**: Complete MRT Line 6 catalog (Uttara North to Motijheel) with gap-based fare calculations and station swap logic.
* **Live Web & PWA Deployment**: Hosted live on Netlify at [`https://dmrt-online.netlify.app`](https://dmrt-online.netlify.app).
* **Standalone Android Release APK**: Pre-compiled self-signed release APK (`build/app/outputs/flutter-apk/app-release.apk`).

---

## 🏛️ Clean Architecture Structure

```text
lib/
├── main.dart                             # Application entry, Theme, DevicePreview binding
├── presentation/
│   ├── app_shell.dart                    # Root navigation container & scan FAB routing
│   └── providers/
│       └── app_providers.dart            # Riverpod StateNotifierProviders & FutureProviders
├── domain/
│   ├── models/                           # Pure immutable business models
│   │   ├── ticket.dart                   # Ticket model with Journey Lock & QR expiry
│   │   ├── user_profile.dart             # Commuter profile model
│   │   └── qr_session.dart               # QR transit session & group formula
│   └── repositories/                     # Abstract repository contracts (Drift/REST ready)
│       ├── i_ticket_repository.dart
│       └── i_user_repository.dart
├── data/
│   └── mock/                             # ACID local storage via SharedPreferences
│       ├── mock_ticket_repository.dart
│       └── mock_user_repository.dart
├── core/
│   ├── constants/                        # DmrtColors, DmrtAssets, StationsCatalog
│   ├── painters/                         # TicketWaveMaskPainter, TicketNotchPainter, DashedLinePainter
│   └── utils/                            # Time greetings, Bengali digits & date formatters
├── features/
│   ├── auth/                             # Phone (+880), 6-digit OTP, profile setup
│   ├── home/                             # Airplane green hero banner, active tickets stack
│   ├── buy_ticket/                       # Station picker modal, stepper, multi-channel payment, hold confirmation
│   ├── ticket_details/                   # Route breakdown, 10% refund confirmation modal
│   ├── qr_transit/                       # Live dynamic QR, countdown pill, AFC scanner & simulator
│   ├── history/                          # 3 sliding tabs: Completed, Expired, Refunded
│   └── profile/                          # Commuter profile form, custom gender sheet, DOB picker
└── shared/
    └── widgets/                          # TicketCardWidget, GlassBottomNavBar, DmrtSideDrawer, DeviceSimulatorOverlay
```

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `^3.44.0` or higher
* **Dart SDK**: `^3.12.0` or higher

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Quality Checks
```bash
# Verify static analysis (0 errors, 0 warnings)
flutter analyze

# Run complete automated test suite (100% pass rate)
flutter test
```

### 3. Launch the Application

#### Google Chrome (Web with Multi-Device Simulator):
```bash
flutter run -d chrome
```

#### Windows Desktop:
```bash
flutter run -d windows
```

#### Android / iOS Device:
```bash
flutter run
```

> **Local Toolchain Note (Current PC)**: If developing on the primary setup with portable toolchains, you can simply run:
> ```cmd
> .\run_local.cmd run -d chrome
> .\run_local.cmd test
> ```

---

## 📱 Multi-Device Responsiveness Simulator

In debug/development mode, a floating **`📱 Sim: [Device Name]`** badge appears at the top of the screen:
* Tap the badge to open the simulator control sheet.
* Select any target device preset (**iPhone 16 Pro Max, iPhone 16, Google Pixel 9, Samsung Galaxy S24, iPad Pro 11"**).
* Switch between **Portrait** and **Landscape** orientations.
* Drag the **Text Scale** slider (`0.8x` to `2.0x`) to verify that no labels or cards clip or overflow.

---

## 📦 Pushing to GitHub & Transferring to Another Machine

This folder is **100% self-contained and Git-ready**:
1. Open a terminal inside this folder (`DMRTonline Mobile App`).
2. Initialize and link to your GitHub repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: DMRT Online native Flutter mobile app"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo-name>.git
   git push -u origin main
   ```
3. To clone on a new machine:
   ```bash
   git clone https://github.com/<your-username>/<your-repo-name>.git "DMRTonline Mobile App"
   cd "DMRTonline Mobile App"
   flutter pub get
   flutter run
   ```

---

## 📄 License & Specifications
Dhaka Mass Rapid Transit Development Project (MRT Line 6). All rights reserved.
Detailed architectural context and specifications are available in [`Mobile App Context.md`](./Mobile%20App%20Context.md) and [`Flutter Development (Ui).md`](./Flutter%20Development%20(Ui).md).
