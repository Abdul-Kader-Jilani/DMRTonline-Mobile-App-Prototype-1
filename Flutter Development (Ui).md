# DMRT Online — Flutter Development (UI & Architecture Blueprint)

> **Document Scope**: This context file is **exclusively dedicated to the Flutter mobile application frontend** for DMRT Online (Dhaka Mass Rapid Transit). It serves as the primary technical specification, design system standard, widget hierarchy catalog, state machine blueprint, and development roadmap for building an industry-grade, ultra-responsive Flutter UI with a completely replaceable mock/dummy data layer.
>
> For overall system architecture, embedded turnstiles, and backend microservices, refer to [`Full Porject Contex.md`](file:///d:/DMRT%20Online/Full%20Porject%20Contex.md). For end-to-end mobile app lifecycle, prototypes, and database schemas, refer to [`Mobile App Contex.md`](file:///d:/DMRT%20Online/Mobile%20App%20Contex.md).

---

## Table of Contents
1. [Developer Role & Architectural Vision](#1-developer-role--architectural-vision)
2. [The "Replaceable-Frontend" Clean Architecture](#2-the-replaceable-frontend-clean-architecture)
3. [DMRT Design System & Visual Tokens](#3-dmrt-design-system--visual-tokens)
4. [Custom Widget Engineering (Ticket Cards & Notches)](#4-custom-widget-engineering-ticket-cards--notches)
5. [Complete Screen Inventory & Widget Hierarchy](#5-complete-screen-inventory--widget-hierarchy)
6. [State Management Architecture (Riverpod / BLoC)](#6-state-management-architecture-riverpod--bloc)
7. [Domain Layer & Repository Contracts](#7-domain-layer--repository-contracts)
8. [Stage 1 Mock Data Layer (In-Memory & Storage)](#8-stage-1-mock-data-layer-in-memory--storage)
9. [Mobile Performance & Hardened Security Guidelines](#9-mobile-performance--hardened-security-guidelines)
10. [Step-by-Step UI Development Roadmap](#10-step-by-step-ui-development-roadmap)

---

## 1. Developer Role & Architectural Vision

As an **Expert Flutter Architect**, the goal is to build an application for Dhaka Metro Rail (MRT Line 6) that:
* **Performs Flawlessly on Budget Hardware**: Runs at a locked 60/120 FPS even on entry-level Android devices commonly used by daily commuters in Bangladesh.
* **Is 100% Decoupled from Backend Logistics**: Every UI widget is built against clean domain contracts. The entire app can run, simulate journeys, display animated QR timers, calculate group fares, and persist trip histories using local mock repositories without needing a live backend server.
* **Provides Zero-Friction Future Replacement**: When the Node.js/FastAPI microservices and Drift SQLite database are ready, swapping from `LocalMockRepository` to `ApiRepository` requires **zero modifications to any UI widget or screen**.
* **Protects Transit Integrity**: Integrates native security channels (`FLAG_SECURE`, root detection, brightness boosting, camera frame parsing) directly into Flutter's native architecture.

---

## 2. The "Replaceable-Frontend" Clean Architecture

The native Flutter codebase follows a **Feature-First Clean Architecture** with strict dependency inversion:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                            │
│  Widgets • Screens • Animation Controllers • Dialogs • Custom Painters   │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ (watches / dispatches)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         APPLICATION / STATE LAYER                       │
│  Riverpod Notifiers / BLoC State Machines • Immutable UI State Classes  │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ (calls use cases)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              DOMAIN LAYER                               │
│  Entities • Value Objects • Business Rules • Repository Interfaces     │
│  (Pure Dart — 100% framework-independent & testable)                    │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ (implements)
                  ┌──────────────────┴──────────────────┐
                  ▼                                     ▼
┌───────────────────────────────────┐ ┌───────────────────────────────────┐
│      DATA LAYER (STAGE 1 - UI)    │ │   DATA LAYER (STAGE 2 - PROD)     │
│  LocalMockTicketRepository        │ │  DriftSqliteTicketRepository      │
│  MockStationRepository            │ │  ApiTicketRepository (REST/JSON)  │
│  MockPaymentRepository            │ │  SecureTokenStorage (Keystore)    │
│  (In-Memory / Fake Latency Sim)   │ │  WebSocket Live Sync Engine       │
└───────────────────────────────────┘ └───────────────────────────────────┘
```

### Folder Structure (Feature-First)
```text
lib/
├── app/
│   ├── app.dart                   # MaterialApp configuration, routes, themes
│   └── theme/                     # DMRT colors, typography, elevations, radiuses
├── core/
│   ├── constants/                 # Asset paths, SVG icons, storage keys
│   ├── errors/                    # Failure models, exceptions
│   ├── security/                  # Native channels (FLAG_SECURE, brightness)
│   └── utils/                     # Formatters (currency ৳, dates, durations)
├── shared/
│   ├── widgets/                   # DmrtAppBar, DmrtButton, GlassmorphicNavBar
│   └── painters/                  # TicketNotchPainter, TicketWaveMaskPainter
└── features/
    ├── home/                      # Presentation & State for Home / Wallet
    ├── buy_ticket/                # Station picker, passenger counter, checkout
    ├── ticket_details/            # Detailed ticket receipt, refund triggers
    ├── qr_transit/                # Viewfinder scanner & dynamic QR countdown
    ├── history/                   # Completed/expired/refunded tabbed receipts
    └── profile/                   # User profile form, hamburger drawer, guidelines
```

---

## 3. DMRT Design System & Visual Tokens

The app follows the authentic visual identity established in the `index.html` prototype:

### 3.1 Color Palette
```dart
class DmrtColors {
  // Brand Primaries
  static const Color primary = Color(0xFF005140);       // Deep DMRT Forest Green
  static const Color primaryDark = Color(0xFF00382C);   // Pressed / Active Header
  static const Color primaryLight = Color(0xFF0B9175);  // Accent Mint Green
  static const Color brandOrange = Color(0xFFE86C1F);   // Secondary Warning / Accent

  // Background & Canvases
  static const Color canvas = Color(0xFFD0E1DF);        // Soft Sage Canvas Background
  static const Color surface = Color(0xFFFFFFFF);       // Card / Section White
  static const Color surfaceTint = Color(0xFFF2F7F6);   // Subtle Container Gray/Green

  // Status & Semantic
  static const Color statusAvailable = Color(0xFF005140); // Available (Primary Green)
  static const Color statusRiding = Color(0xFF0284C7);    // In-Transit Blue
  static const Color statusLocked = Color(0xFF64748B);    // Locked Trip Gray
  static const Color statusExpired = Color(0xFF94A3B8);   // Expired Muted Slate
  static const Color statusRefunded = Color(0xFFB51B00);  // Refunded / Fined Red

  // Glassmorphism & Overlays
  static const Color navBarGlass = Color(0xCCFFFFFF);   // 80% Frosted White
  static const Color navBarBorder = Color(0x33FFFFFF);  // Glass Border Highlight
  static const Color loaderBackdrop = Color(0xCCEEF5F3);// Transparent Blur Tint
}
```

### 3.2 Typography Tokens
* **Headings**: `Outfit` / `Inter`, Bold `700`, Dark Slate `#0F172A`.
* **Body / Meta**: `Inter`, Regular `400` / Medium `500`, Muted Slate `#475569`.
* **Ticket Numbers / Prices**: Monospaced tabular figures, Semibold `600` (e.g. `৳60`).
* **Icons**: Google Material Symbols Outlined font (bundled locally to eliminate web font latency).

### 3.3 Shape & Elevation Constants
* `radiusSm`: `8.0`
* `radiusMd`: `12.0`
* `radiusLg`: `16.0`
* `radiusXl`: `20.0`
* `radius2Xl`: `24.0` (Standard for ticket cards and bottom sheets)
* `cardShadow`: `BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))`

---

## 4. Custom Widget Engineering (Ticket Cards & Notches)

The signature visual element of DMRT Online is the **Authentic Metro Ticket Card**:
1. **S-Curve Wave Header Mask**:
   * An organic transition separating the upper-left green header badge from the upper-right ticket metadata (passenger count and total price).
   * Implemented via a custom `CustomPainter` or `ClipPath` using cubic Bézier curves (`C 46,56 46,100 36,100`).
2. **Semi-Circular Cutout Notches**:
   * Left and right inward semicircular punch holes positioned at the exact dividing line between the ticket body and the action footer.
   * Rendered using a path that subtracts an arc matching the background canvas color (`#D0E1DF`), creating a realistic physical ticket punch.
3. **Dashed Perforation Line**:
   * Horizontal dashed divider connecting the left and right punch notches.
   * Rendered with `CustomPainter` drawing alternating stroke dashes.
4. **Group Ticket Counter**:
   * Prominent pill badge displaying `01 Person` up to `05 Persons`.

---

## 5. Complete Screen Inventory & Widget Hierarchy

### 5.1 Screen 1: Home / Digital Wallet (`HomeScreen`)
* **Hero Greeting Banner (`GreetingHero`)**:
  * Seamless background bleeding under the transparent system status bar.
  * DMRT circular logo, bold branding, time-aware dynamic greeting (`"Good Morning"`, `"Good Noon"`, `"Good Afternoon"`, `"Good Evening"`).
  * Profile avatar circle with tap-to-profile action.
  * Compact "Buy Ticket" pill action.
* **Active Tickets Section (`TicketWalletCard`)**:
  * Rounded container with upper curved corners (`24px`).
  * Scrollable list of active tickets (`Available`, `Riding`, `Locked`).
  * Empty state placeholder (`NoTicketsPlaceholder`) when wallet is empty with an illustration and quick buy button.
* **Floating Glassmorphic Bottom Navigation Bar (`DmrtBottomNavBar`)**:
  * Frosted glass background (`ImageFilter.blur(sigmaX: 28, sigmaY: 28)`).
  * 4 Tab Destinations: **Home**, **Buy**, **History**, **Profile**.
  * Center Elevated Action FAB: Glowing emerald QR scan button for instant turnstile transit.

### 5.2 Screen 2: Buy Ticket (`BuyTicketScreen`)
* **Route Selection Card (`RouteSelectorCard`)**:
  * Origin station selector with custom modal picker.
  * Destination station selector with validation (cannot match origin).
  * Dynamic vertical connector line turning black when both stations are valid.
  * Rapid station swap icon button.
* **Passenger Count Stepper (`PassengerStepperCard`)**:
  * Single group purchase model: Stepper controls from **1 to 5 passengers**.
  * Instant fare multiplier calculation: $\text{Total} = \text{UnitFare} \times \text{Count}$.
* **Fare Rate & Total Summary Bar (`FareSummaryBar`)**:
  * Displays base fare rate per person and bold aggregate total (`৳60` – `৳500`).
* **Payment Method Selector (`MfsSelectorSheet`)**:
  * Radio selections for bKash, Nagad, Cards, and Online Banking.
* **Proceed to Checkout Button (`ProceedButton`)**:
  * Disabled gray state when stations are unselected.
  * Primary Green active state with tap ripple and loading indicator.

### 5.3 Screen 3: Ticket Details (`TicketDetailScreen`)
* Full receipt breakdown showing ticket ID, purchase timestamp, 24h expiration timer.
* Route transit path with origin and destination station names.
* Detailed fare breakdown (Unit price $\times$ passengers $=$ total amount).
* **Refund Policy Card**:
  * Outlines 80% refund policy if cancelled within valid window.
  * Interactive "Request Refund" button triggering modal confirmation.
* **"Use Ticket" Floating Action Button**:
  * Initiates transit flow, leading directly to the dynamic QR screen.

### 5.4 Screen 4: Dynamic Passenger QR Flow (`DynamicQrScreen`)
* **Security Shield Header**: Displays 24-hour validity countdown and active journey status.
* **Dynamic QR Display Viewport**:
  * High-resolution, high-contrast QR code rendered via `qr_flutter`.
  * **Dynamic Countdown Timer Bar**:
    * Calculated using the group formula: $\text{Duration} = 60 + ((\text{Count} - 1) \times 20)\text{ seconds}$.
    * Smooth animated linear progress bar transitioning from primary green to warning amber.
  * **Regenerate QR Button**:
    * Appears when the active countdown reaches zero.
    * Recomputes an ephemeral challenge QR session without repurchasing.
* **Anti-Fraud Security**:
  * Invokes native platform channel to enforce `FLAG_SECURE` (blocks screenshots/screen recording).
  * Auto-maximizes device screen brightness for turnstile optical reader accuracy.

### 5.5 Screen 5: Gate QR Scanner (`GateScannerScreen`)
* Camera viewfinder overlay with rounded emerald green corner brackets (`L-brackets`).
* Smooth animated laser pulse line traveling vertically across the scan window.
* Native camera integration via `mobile_scanner` or platform camera channel.
* **Hardware Simulation Sheet (For Development & Testing)**:
  * Bottom test panel with quick-trigger buttons: `"Simulate Inbound Gate (Secretariat)"` and `"Simulate Outbound Gate (Motijheel)"`.
  * Allows end-to-end verification on emulators and phones without physical turnstile hardware.

### 5.6 Screen 6: Trip History (`TripHistoryScreen`)
* **Segmented Filter Bar**: 3 Sliding pill tabs:
  1. **Completed**: Successfully finished trips within the 60-minute transit window.
  2. **Expired**: Unused tickets that exceeded the 24-hour validity window.
  3. **Refunded**: Cancelled tickets with processed refund receipts.
* **Touch-Swipe Gesture Controller**: Seamless horizontal swipe between tabs with physics-based spring transitions.
* **Historical Ticket Receipt Card**: Displays origin $\rightarrow$ destination, completion timestamp, total fare, and green/amber/red status badge.

### 5.7 Screen 7: Profile & Navigation Drawer (`ProfileScreen`)
* **Header Row**: Profile avatar, commuter name, and hamburger menu toggle.
* **Slide-in Side Drawer (60% Screen Width)**:
  * Bilingual Language Toggle pill (`"EN"` | `"বাং"`).
  * Split Transit Guidelines: Expandable accordions for **Do's** (keep ticket ready, stand behind yellow line) and **Don'ts** (no smoking, no loitering).
  * Red-themed "Logout / Reset Local State" button.
* **Editable Profile Form**:
  * Name, Phone Number, Email fields.
  * Custom Calendar Date-of-Birth picker modal.
  * Custom Gender selector bottom sheet (`Male`, `Female`, `Other`).
  * "Save Changes" action button (disabled until fields are modified).

### 5.8 Reusable Modals & Dialogs
* **Multi-Ticket Selector Sheet (`TicketSelectOverlay`)**: Prompts commuter to choose which ticket to activate if multiple valid tickets exist in wallet.
* **Demo Loading Scene (`DmrtLoadingOverlay`)**: Centered loading animation with blurred `#d9e8e5` backdrop (1000ms standard demo delay).
* **Network Connectivity Toast**: Non-blocking floating warning banner when device is offline.

---

## 6. State Management Architecture (Riverpod / BLoC)

The recommended production state management for DMRT Online is **Riverpod (2.x)** with code generation or **BLoC**:

### 6.1 State Machines & Notifiers
1. **`AuthNotifier`**: Manages commuter identity, profile state, language preference, and device installation ID.
2. **`TicketNotifier`**:
   * Holds `AsyncValue<List<Ticket>>`.
   * Manages active wallet tickets, filtering `Available`, `Riding`, and `Locked`.
   * Enforces **Journey Lock**: When one ticket shifts to `Riding`, all other active tickets automatically evaluate as `Locked`.
3. **`BuyTicketNotifier`**:
   * Manages origin/destination station selection, passenger count (1–5), calculated fare, and selected MFS provider.
4. **`TransitSessionNotifier`**:
   * Manages live QR countdown timers, session tokens, and regeneration states.
   * Decrements remaining seconds every 1000ms using a `Timer.periodic`.

### 6.2 Immutable State Models (Freezed)
```dart
enum TicketStatus { available, riding, locked, completed, expired, refunded }

class Ticket {
  final String ticketId;
  final String routeId;
  final String originStation;
  final String destinationStation;
  final int passengerCount;
  final double farePerPerson;
  final double totalFare;
  final TicketStatus status;
  final DateTime purchaseTime;
  final DateTime validUntil;
  final DateTime? enteredAt;
  final DateTime? exitedAt;

  const Ticket({
    required this.ticketId,
    required this.routeId,
    required this.originStation,
    required this.destinationStation,
    required this.passengerCount,
    required this.farePerPerson,
    required this.totalFare,
    required this.status,
    required this.purchaseTime,
    required this.validUntil,
    this.enteredAt,
    this.exitedAt,
  });
}
```

---

## 7. Domain Layer & Repository Contracts

The Domain Layer defines pure abstract interfaces that insulate the UI from data origins:

```dart
abstract class ITicketRepository {
  Future<List<Ticket>> getActiveTickets();
  Future<List<Ticket>> getHistoryTickets(HistoryFilter filter);
  Future<Ticket> purchaseGroupTicket({
    required String originStationId,
    required String destinationStationId,
    required int passengerCount,
    required String paymentChannel,
  });
  Future<QrSession> generateQrSession({
    required String ticketId,
    required String gateChallengeNonce,
  });
  Future<void> simulateGateEntry({required String ticketId, required String gateId});
  Future<void> simulateGateExit({required String ticketId, required String gateId});
  Future<RefundReceipt> requestRefund({required String ticketId});
}

abstract class IStationRepository {
  Future<List<Station>> getAllStations();
  Future<double> getFare({required String originId, required String destinationId});
}

abstract class IUserRepository {
  Future<UserProfile> getUserProfile();
  Future<void> updateProfile(UserProfile profile);
}
```

---

## 8. Stage 1 Mock Data Layer (In-Memory & Storage)

During the current UI perfection stage, all repositories are implemented using `LocalMock` classes:

### 8.1 `LocalMockTicketRepository` Implementation Details
* **In-Memory Store with LocalStorage/SharedPrefs Sync**: Retains created tickets and trip histories across app restarts.
* **Configurable Fake Latency**: Introduces an artificial 800ms–1200ms async delay (`Future.delayed`) to test loading skeletons and the `DmrtLoadingOverlay`.
* **Realistic Business Simulation**:
  * Pre-loaded with realistic MRT Line 6 dummy routes (Uttara North -> Motijheel, Secretariat -> Mirpur 10).
  * Automatically shifts tickets to `Expired` if simulated time advances >24 hours.
  * Handles the single group ticket model, multiplying fares accurately.
  * Decrements and resets the dynamic QR countdown timer accurately.

---

## 9. Mobile Performance & Hardened Security Guidelines

To guarantee high throughput in crowded stations, the following Flutter engineering rules are mandatory:

### 9.1 Rendering & Widget Optimization
1. **Aggressive `const` Usage**: All non-dynamic widgets, decorators, paddings, and styles must use `const` to eliminate unnecessary memory allocations during re-renders.
2. **`RepaintBoundary` Isolation**: Wrap high-frequency updating widgets (the dynamic QR code image, the countdown timer progress bar, and the scanner laser beam) in `RepaintBoundary` widgets so their 60fps repaints do not trigger full-screen re-renders.
3. **Image & Asset Optimization**:
   * Pre-cache the hero greeting background (`home_bg_extended_green_aroplane.png`) and logo in `didChangeDependencies()` to prevent image popping.
   * Use SVG paths instead of high-density raster masks where possible.

### 9.2 Device Security & Screen Integrity
1. **`FLAG_SECURE` Platform Binding**: Invoke native Android window flags (`WindowManager.LayoutParams.FLAG_SECURE`) whenever the `DynamicQrScreen` or `TicketDetailScreen` mounts, and clear it on unmount.
2. **Screen Brightness Booster**: Call `screen_brightness` plugin to temporarily boost device brightness to 100% when presenting the passenger QR code, reverting upon exit.
3. **Hardware Back Button Bridge**: Intercept back-button presses on the Home screen to require a double-tap within 2000ms to exit (`PopScope`).

---

## 10. Step-by-Step UI Development Roadmap

```text
  PHASE 1: Foundations       PHASE 2: Domain & Mock      PHASE 3: UI Screens         PHASE 4: Polishing
┌───────────────────────┐   ┌───────────────────────┐   ┌───────────────────────┐   ┌───────────────────────┐
│ • DmrtTheme & Tokens  │──>│ • Domain Entities     │──>│ • Home & Ticket Card  │──>│ • 120fps Gesture Polish│
│ • Custom Painters     │   │ • Repository Contracts│   │ • Buy Ticket Flow     │   │ • FLAG_SECURE Testing │
│ • Local Fonts/Icons   │   │ • Mock Repositories   │   │ • Dynamic QR & Scanner│   │ • Edge-to-Edge Verify │
│ • Asset Catalog Setup │   │ • Fake Latency Sim    │   │ • History & Profile   │   │ • Real Device Testing │
└───────────────────────┘   └───────────────────────┘   └───────────────────────┘   └───────────────────────┘
```

1. **Phase 1: Foundations & Design Tokens**: Configure `ThemeData`, custom colors, typography, and write `TicketNotchPainter` and `TicketWaveMaskPainter`.
2. **Phase 2: Domain Entities & Mock Layer**: Build the pure Dart data models (`Ticket`, `Station`, `Route`, `UserProfile`), abstract repositories, and the fully functional `LocalMockTicketRepository`.
3. **Phase 3: Screen-by-Screen Implementation**:
   * Build `HomeScreen` with greeting hero and active ticket list.
   * Build `BuyTicketScreen` with station pickers, stepper, and checkout button.
   * Build `TicketDetailScreen` and `DynamicQrScreen` with the group timer formula.
   * Build `GateScannerScreen` with viewfinder overlay and dev simulator panel.
   * Build `TripHistoryScreen` with 3-segment slider and swipe gestures.
   * Build `ProfileScreen` with hamburger drawer, language toggle, and form validation.
4. **Phase 4: Real Phone Verification & Edge Polish**: Test on physical Android devices (e.g. `U8MFEA9XFQ9XFECM`), verifying responsive touch targets, smooth keyboard avoidance, edge-to-edge system navigation bars, and instant transit transitions.


---

## 11. Current Status: Clean Slate for Step-by-Step 1:1 Pixel Rebuild

* **Status Date**: September 11, 2026
* **Decision**: The entire initial Flutter UI implementation was safely archived to d:\DMRT Online\.archive\lib_backup outside the mobile app repository, and lib/ was cleared to a clean starter state.
* **Core Principle**: The user has established a **strict 1:1 visual match requirement** against Web Prototype/index.html. The native Flutter UI must look and feel identical to the web prototype in every color token, layout spacing, card elevation, shadow, and typography.
* **Execution Protocol**:
  1. Build **one single screen at a time**.
  2. Directly inspect and translate the exact CSS styles from Web Prototype/index.html into Flutter widgets.
  3. Run and present the screen for user review and approval.
  4. Only proceed to the subsequent screen upon explicit user confirmation.
* **Current Target**: **Screen 1 — Splash / Home Screen** (Airplane green hero card, time-based greeting, active ticket stack, bottom navigation bar).


### 11.1 Screen 1 Milestone: Upper Home Section (Welcome Card)
* Implemented: lib/features/home/widgets/welcome_card.dart and lib/features/home/home_screen.dart.
* Visual Match: Reconstructed from .welcome-card in Web Prototype/index.html:
  - assets/dmrt/new_home_vector.png background image.
  - #006B56 container color, #B51B00 4px bottom border, 32px bottom border radius.
  - Exact typography, icon sizes, and gradient Buy Ticket button.
* Simulator Launcher: run_simulator_web.cmd enabled for instant Chrome live preview.

### 11.2 Multi-Platform Simulator Support Configured
* Generated official Flutter `web/` and `windows/` platform runners.
* Added `run_simulator_web.cmd` (Google Chrome with multi-device switcher overlay) and `run_simulator_windows.cmd` (Native Windows desktop runner).
* Zero analyze errors (`flutter analyze`: 0 issues), 100% test pass rate.

### 11.3 Pure Flutter Simulator Frame & Instant Preview Launcher
* Replaced prerelease `device_preview` with native `DeviceSimulatorOverlay` in `lib/shared/device_simulator_overlay.dart`.
* Fixed `WidgetsFlutterBinding.ensureInitialized()` in `lib/main.dart`.
* Built production web bundle in `build/web/`.
* Added `run_instant_preview.cmd` (instant load under 1 second) and updated `run_simulator_web.cmd` (Live hot-reload development).

### 11.4 Dynamic Island Clearance & Web-Server Mode
* Added `safeTop: 48px` in `DeviceSimulatorOverlay` to prevent notch overlap.
* Implemented `aspect-ratio: 1536 / 1024` and `BoxFit.cover` in `WelcomeCard`.
* Configured `run_simulator_web.cmd` with `-d web-server --web-port 8080` for reliable hot reload in default browser.
* Verified `flutter analyze` (0 issues) and `flutter test` (100% pass).

### 11.5 Complete Home Screen 1:1 Rebuild
* Reconstructed `#view-home` from `Web Prototype/index.html` in native Flutter.
* Added `TicketWaveClipper` (exact SVG wave path `M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z`).
* Added `TicketNotchClipper` and `DashedPerforationLine` (`r=12px` punch cutouts, dashed tear line).
* Built authentic `TicketCardWidget` and `NoTicketsPlaceholder`.
* Built `BottomNavBar` with glowing elevated Scan FAB.
* Verified `flutter analyze` (0 issues) and `flutter test` (100% pass).

### 11.6 Multi-Width Device Testing Suite (360px, 380px, 400px, 420px)
* Added 1-tap width switcher buttons [360px] [380px] [400px] [420px] on `DeviceSimulatorOverlay`.
* General fixed height of 840px across all widths.
* Built updated `build/web` for instant browser refresh on `http://localhost:8085`.

### 11.7 Anti-Cache Web Bundle & Direct Width Testing
* Added anti-caching meta tags and service worker cleanup to `web/index.html`.
* Rebuilt `build/web/` so every browser refresh fetches the latest multi-width simulator directly.

### 11.8 Fixed 360px Viewport Proportional Scaling Engine
* **Origin**: Matches `Web Prototype/index.html` (lines 7–22 `adjustViewport()`) which dynamically sets `<meta name="viewport" content="width=360, initial-scale=...">`.
* **Flutter Architecture**: Created `ScaledViewportWrapper` (`lib/shared/scaled_viewport_wrapper.dart`) using `FittedBox(fit: BoxFit.fitWidth)` and scaling `scale = min(screenWidth, 480) / 360.0`.
* **Locked Coordinates**: All element positions, ticket card punch notches, S-curve wave masks, font sizes, and layout gaps stay 100% frozen in relative position across 360px, 380px, 400px, and 420px device widths.
* **Scaled MediaQuery**: Injected scaled `MediaQueryData` (scaled size, padding, viewPadding, and viewInsets) so `SafeArea` and dialogs behave accurately without distortion.
* **Testing & Verification**: 0 linter issues (`flutter analyze`), 100% test pass rate (`flutter test`), compiled production web bundle in `build/web/` for instant inspection at `http://localhost:8085`.

### 11.9 1:1 Precision Alignment: Welcome Banner & Ticket Card Hierarchy
* **Welcome Card**:
  - Logo row (`welcome-logo-row`) at top, followed directly by greeting row (`welcome-card__row`) with `gap: 8px`.
  - Buy Ticket button positioned in-line with greeting text.
* **Ticket Card Header**:
  - Meta items (date, passenger count, fare) rendered in white (`#ffffff`) over S-curve wave gradient.
  - Expiry tag with red icon (`#B51B00`) and refund pill button (`rgba(186, 26, 26, 0.1)`).
* **Station Route Columns**:
  - Vertical station stacks (Label at top, 40px circle icon in middle, station name centered below).
  - Grey station icons (`#6E7A75`) in initial Available state.
* **Side Cutout Notches**:
  - Clean semi-circular notches matching `#D9E8E5` page background without shadow artifacts.

### 11.10 Punch Hole Border Alignment & Button Gradient Restoration
* **Punch Hole Overlay**: Unclipped perforation stack (`clipBehavior: Clip.none`) allowing 24px notch cutouts to cover the 1px card border cleanly, with an authentic 1px circular border arc.
* **Button Gradients**: Restored `[#0B9175, #005140]` gradient, border highlight, and emerald shadow on both Buy Ticket and Use Ticket buttons.


### Checkpoint 105: Home Welcome Alignment, Compact Ticket Header Meta & 1:1 Rounded Concave Bottom Navigation Bar
- **Date**: 12 September 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Welcome Card Upward Grouping**:
     - Reduced top padding from `12px` to `4px` and inter-row spacing to `6px` in `WelcomeCard`.
     - Grouped the Brand Logo, Title, User Avatar, Greeting text, and Buy Ticket action button together tightly at the top of the welcome container.
  2. **Compact Ticket Header Meta & Actions**:
     - Resized header meta icons (Date, Passenger, Fare) to `12px` and font sizes to `11px` with `11px` vertical divider.
     - Resized Expiry Clock icon to `12px`, Expiry text to `11px`.
     - Compacted Refund pill button (padding `6px 2.5px`, exchange icon `12px`, text `11px`, chevron `13px`) for pristine visual balance.
  3. **1:1 Pure Recreation of Rounded Concave Bottom Navigation Bar (`.bottom-nav-rounded`)**:
     - Implemented `_BottomNavNotchClipper` rendering the exact SVG cubic Bézier concave notch curve (`M 0 0 L 135 0 C 150 0 155 32 180 32 C 205 32 210 0 225 0 L 360 0 L 360 64 L 0 64 Z`).
     - Added `_BottomNavShadowPainter` rendering the frosted glass drop shadow (`filter: drop-shadow(0px -4px 10px rgba(0,0,0,0.15))`).
     - Added Frosted Glass background (`rgba(255, 255, 255, 0.93)` + `ImageFilter.blur(50, 50)`).
     - Added Active Icon Pill Highlight (`40x28` rounded pill container with `rgba(0, 81, 64, 0.10)` background on active tab).
     - Connected icons: Home (`Icons.account_balance_wallet_outlined` / `account_balance_wallet`), Buy Ticket (`Icons.confirmation_number_outlined` / `confirmation_number`), History (`Icons.history_outlined` / `history`), Profile (`Icons.person_outline` / `person`).
     - Positioned Floating Glowing Action Button (56x56 circular FAB with `linear-gradient(#0B9175, #005140)` and glowing box shadow) resting seamlessly within the top concave curve.
  4. **Verification**:
     - `flutter analyze` completed with 0 errors / 0 warnings.
     - `flutter test` passed all widget/layout tests.
     - Flutter web build deployed to local preview server (`http://localhost:8085`).



### Checkpoint 108: Revert to Checkpoint 105 & Enabled Full Page Scrollability
- **Date**: 12 September 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Reset to Clean Stable Base (Checkpoint 105 / commit 97be5ae)**:
     - Undid the last two experimental edits per user instruction.
     - Restored the exact punch hole styling, top welcome grouping, and bottom navigation bar structure from Checkpoint 105.
  2. **Full Page Scrollability Enabled**:
     - Configured `SingleChildScrollView` with `physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())` on `HomeScreen`.
     - Ensures the entire screen (Welcome card, My Tickets section, ticket cards) scrolls seamlessly on any screen size.
  3. **Verification**:
     - `flutter analyze` passed with 0 errors / 0 warnings.
     - `flutter test` passed 100%.
     - Flutter web build compiled and deployed to local preview server (`http://localhost:8085`).

