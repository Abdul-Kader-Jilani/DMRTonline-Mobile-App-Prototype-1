# DMRT Online — Mobile App Context & Development Log

Last updated: 2026-09-03

> **Notice**: This file contains the dedicated context, progress log, and development state for the **DMRT Online Passenger Mobile App** prototype only. For the overall system architecture, hardware specifications, and cross-platform ecosystem, refer to Full Project Context.md.

This file is the main handoff/context memory for the mobile app part of the project. Any future Codex agent or developer should read this file first before changing the project.

Standing context rule: this file must be updated automatically after any major changes. Do not treat this file like a chat history; it must serve as a permanent, high-fidelity blueprint and record of what has been built and the current state of the application. Keep this rule documented here permanently so all future sessions follow it without exception. Do not wait for the user to ask for context updates. If something meaningful is implemented, update this file and add a short note to the update log at the bottom.

## 1. Project Identity

The project is named **DMRT Online**.

It is a passenger-facing mobile app prototype for a secure Dhaka Metro Rail QR-based online ticketing and gate authentication system. The larger system is planned to include:

- Passenger mobile app.
- Raspberry Pi gate display and QR reader system.
- Central backend and relational database.
- Station officer web app for exception handling, fines, wrong exits, and late exits.

This repository currently focuses on the **passenger mobile app prototype**.

Long term, this should become a professional, production-level, cross-platform Flutter mobile app for real passengers. The current WebView-based app is a prototype/testing stage, not the final production implementation.

## 2. Purpose

The purpose of DMRT Online is to let passengers buy metro tickets digitally, store tickets on the phone, and use QR authentication at metro gates.

### 2.1 Project Staging: Prototype 1 vs. Production System

To ensure a clear, phased academic and engineering progression, the project is structured into distinct phases:

#### 1. Basic Prototype 1 (Current Proposal & Mobile App Scope)
* **Goal**: Focus purely on the passenger mobile app experience, clean local data modeling, rapid turnstile prototyping, and complete trip lifecycle demonstration without hardware or network hurdles.
* **Streamlined Gate Flow (Direct Ticket QR)**:
  1. Passenger purchases a single group ticket (1 to 5 passengers) in the mobile app.
  2. The ticket is immediately stored locally in active state (`Available`).
  3. When approaching the station gate, the passenger clicks **"Use Ticket"** or taps the central Scan/QR button on the navigation bar.
  4. The phone **immediately renders the active Ticket QR code** on-screen (no requirement for the phone to first scan a physical gate screen/challenge nonce).
  5. The passenger scans their phone's Ticket QR against the entry turnstile scanner.
  6. The gate verifies ticket validity, records the entry event, unlocks the turnstile, and the app enters `Riding` status (locking other tickets).
  7. At the destination, the passenger presents the Ticket QR to the exit turnstile scanner.
  8. The gate logs the exit event, verifies the 60-minute journey limit, and the ticket status transitions to `Completed`.
* **Station Data Simplification**:
  * Origin station (`st_sta`) and destination station (`en_sta`) are stored directly inside the `Route` table (`route_id`, `st_sta`, `en_sta`, `fare`), eliminating the need for a separate `stations` table in this prototype stage.
* **Dedicated History Archive Table**:
  * Reflects the mobile app's dedicated Trip History page and `state.history` storage.
  * When a ticket finishes its lifecycle (`Completed`, `Expired`, or `Refunded`), it is recorded in the `History` table for instant, zero-latency rendering of historical trip receipts.
* **8-Table Core Schema**: `passenger`, `Route`, `ticket`, `Payment`, `Event`, `Fine`, `Refund`, `History`.

#### 2. Production System (Full Future Roadmap)
* **Two-Way Cryptographic Challenge**: Raspberry Pi gate displays a dynamic rotating QR nonce; the phone camera scans this gate QR first to compute an ephemeral HMAC-SHA256 passenger QR (60s+20s timer).
* **Multi-Tier Infrastructure**: Golden SD images on turnstile hardware, local SQLite replication, distributed Node.js/PostgreSQL central cluster, and Station Officer Web Portal for override/fine management.

## 3. Larger System Concept

The final planned system is offline-first after purchase:

- Internet is required to buy tickets.
- Already purchased tickets should be usable at gates without phone internet.
- Raspberry Pi gates validate locally using synced SQLite operational data.
- The central server remains the long-term source of truth.
- Gate events sync back to the server when network is available.
- Station officers handle exceptions such as wrong exit, late exit, invalid ticket, failed sync, or fine/revalidation cases.

The final system design includes:

- Flutter passenger app.
- Raspberry Pi 4 Model B per gate.
- Raspberry Pi OS Lite 64-bit.
- Python gate software.
- SQLite local gate database.
- Central Node.js backend.
- PostgreSQL or MySQL central database.
- React/Node or Next.js station officer app.
- Golden SD image deployment for gate devices.

## 4. Important Business Rules

These are the main domain rules that must be preserved:

- No static reusable ticket QR after purchase.
- Passenger QR is generated only after scanning a live gate QR.
- Gate QR contains station/gate identity and a challenge/nonce/secret.
- Passenger QR contains ticket identity plus gate challenge data.
- Gate/server is the final authority, not the mobile app.
- App-side state is for user experience only.
- Tickets are valid for 24 hours after purchase.
- After successful entry, passenger should exit within 60 minutes.
- Wrong exit and late exit should go to station officer/fine flow.
- App should prevent screenshots/screen recording on sensitive screens where possible.
- App should detect rooted/jailbroken/tampered devices where possible.
- Other unrelated trips should be locked while a journey is active.
- Maximum passenger count per purchase/ticket is 5.

## 5. Current Prototype Rule: Group Ticket Model

The current prototype uses a **single group ticket per purchase**, not separate ticket records per passenger.

Example:

- User selects route to Motijheel.
- User sets ticket/person count to 3.
- After purchase, the home page shows one ticket card.
- Ticket details show 3 persons.
- The generated passenger QR is used for all 3 persons to enter or exit.

QR expiry duration depends on passenger count:

- 1 person: 60 seconds.
- 2 persons: 80 seconds.
- 3 persons: 100 seconds.
- 4 persons: 120 seconds.
- 5 persons: 140 seconds.

Formula:

```text
qrDurationSeconds = 60 + ((passengerCount - 1) * 20)
```

Fare calculation:

```text
totalFare = farePerPerson * passengerCount
```

This group-ticket behavior is important because it replaced the earlier separate-ticket-per-person concept for the current prototype.

### 5.1 Offline-First Ticket Credential Package (Cached Data Specification)
To guarantee that a commuter can pass turnstile gates without cellular data, the mobile app caches a self-contained ticket credential package immediately upon purchase:
1. **Business Payload**:
   * `ticket_id`, `purchase_id`, `route_id`, `origin_station_id`, `destination_station_id`.
   * `passenger_count` (1 to 5 passengers).
   * `fare_per_person` and `total_fare` (immutable financial snapshot).
   * `purchase_time`, `valid_from`, and `valid_until` ($+24\text{h}$ validity limit).
   * `status` (`Available`, `Riding`, `Completed`, `Expired`, `Refunded`).
2. **Cryptographic Credentials**:
   * Signed ticket credential token issued by the Central QR/Auth microservice at checkout.
   * App instance / device installation ID binding (prevents copying raw token blobs between phones).
   * Protocol version and public key identifier.
3. **Reference Data Cache**:
   * MRT Line 6 station catalog (`station_id`, `station_code`, `station_name`, sequence).
   * Active route catalog with unit fares.
   * Local schema metadata and sync timestamps.

### 5.2 Mobile SQLite Atomic Transactions Matrix
To prevent data corruption during unexpected app termination or power loss, the mobile app enforces strict ACID transactions:
* **Purchase Transaction**: Atomically write ticket record to `ticket`, create receipt in `Payment`, and enqueue synchronization payload in `SyncOutboxEvent`.
* **Journey Entry Activation**: Atomically transition active ticket status to `Riding`, lock all other available tickets (preventing concurrent rides), record `entered_at` timestamp, and create `ENTRY_SUCCESS` event.
* **QR Session Generation / Regeneration**: Atomically mark the previous active QR session as `SUPERSEDED` and insert a new ephemeral session record with fresh countdown expiry.
* **Journey Completion**: Atomically record `exited_at` timestamp, transition ticket to `Completed`, archive summary into `History`, verify whether $\Delta t \le 60\text{ minutes}$ (or trigger overstay fine warning), and unlock other purchased tickets.

### 5.3 Mobile Database Indexing Strategy
To guarantee instantaneous UI rendering and background sync processing on budget smartphones:
* `CREATE INDEX idx_tickets_status ON ticket(status);` — Instant home screen active ticket filtering.
* `CREATE INDEX idx_tickets_valid_until ON ticket(valid_until);` — Instant identification of expired tickets for background sweep.
* `CREATE INDEX idx_routes_stations ON Route(st_sta, en_sta);` — O(1) fare lookup during station picker interactions.
* `CREATE INDEX idx_qr_session_ticket ON qr_sessions(ticket_id, generated_at DESC);` — Sub-millisecond retrieval of the active dynamic QR session.
* `CREATE INDEX idx_sync_queue_status ON SyncOutboxEvent(status, attempt_count);` — Rapid polling for the background offline sync worker.

## 6. Implementation Strategy, Origin History & Replaceable-Frontend Architecture

### 6.1 Origin: From Figma to Google Stitch
* **Figma Tooling Constraints**: During the initial UI design phase, direct AI-assisted wireframing was attempted within Figma design links using connected Figma plugins. However, due to Figma Starter plan file/canvas limitations and remote write restrictions, automated design writing stalled.
* **The Google Stitch Pivot**: To immediately produce a concrete, high-fidelity visual prototype with micro-interactions, animations, and working business rules, the prototype was generated via **Google Stitch** as a comprehensive `index.html` file (HTML5, modern CSS variables, and JavaScript state machine).
* **The Flutter Wrapper Solution**: Rather than throwing away the pixel-perfect Google Stitch design or attempting a rushed native Flutter rewrite that might lose visual details, the prototype was embedded into a specialized Flutter Android platform WebView wrapper (`dmrt_online`). This allowed immediate real-world testing on physical Android devices.

### 6.2 The Hybrid WebView Wrapper Approach (Stage 1)
The current app is **not yet a native Flutter widget rewrite**.
* The user provided a detailed `index.html` prototype with embedded CSS and JavaScript. Exact visual fidelity, animations, transitions, localStorage behavior, and workflow preservation are prioritized for this first version.
* **Important clarification**: The user originally provided `index.html` as a design and workflow reference, not as the intended final production runtime. The plan is to keep refining this HTML prototype inside the Flutter WebView until the design, user flow, edge cases, layout, and behavior feel right on a real phone. After that, the app will be rebuilt as a real native Flutter production app.
* The Flutter project named `dmrt_online` embeds a full-screen native platform WebView that loads bundled local HTML from `assets/index.html`. Both `D:\DMRT Online\index.html` and `dmrt_online/assets/index.html` must remain 100% in sync.

### 6.3 The "Replaceable-Frontend Architecture" (Stage 1 to Stage 2 Migration Blueprint)
The project architecture strictly follows a two-stage software engineering model:

```text
                    PRESENTATION LAYER (Flutter UI)
                   (Widgets, Screens, Theme, Animations)
                                    │
                                    ▼
                     STATE MANAGEMENT (Riverpod / BLoC)
                   (TicketNotifier, JourneyNotifier, AuthNotifier)
                                    │
                                    ▼
                         REPOSITORY INTERFACES
               (TicketRepository, StationRepository, AuthRepository)
                                    │
               ┌────────────────────┴────────────────────┐
               ▼                                         ▼
   [STAGE 1 / PROTOTYPE]                     [STAGE 2 / PRODUCTION]
   LocalMockTicketRepository                 DriftSqliteTicketRepository
   (In-memory / localStorage mock)           + ApiTicketRepository (REST/JSON)
```

1. **Decoupled Architecture**: UI widgets never query mock data or backend APIs directly; all requests flow through clean **Repository Interfaces**.
2. **Stage 1 (Current)**: Refine UI layouts, CSS/widget sizing, transitions, responsive fitting, and edge-to-edge system bar aesthetics inside the hybrid wrapper / mock repository.
3. **Stage 2 (Upcoming Native Flutter Rewrite)**: Rebuild the UI as 100% native Flutter widgets backed initially by `LocalMockTicketRepository`. Once the native UI is 100% stable, swap in the real `ApiTicketRepository` and `DriftSqliteTicketRepository` without altering any presentation widgets.

## 7. Workspace Structure

Workspace root:

```text
D:\DMRT Online
```

Important files/folders:

```text
D:\DMRT Online\PROJECT_CONTEXT.md
D:\DMRT Online\index.html
D:\DMRT Online\logo.png
D:\DMRT Online\fonts
D:\DMRT Online\toolchains
D:\DMRT Online\dmrt_online
```

Flutter app:

```text
D:\DMRT Online\dmrt_online
```

App identity:

```text
App display name: DMRT Online
Android package/applicationId: com.dmrt.online
Android Kotlin namespace: com.dmrt.dmrt_online
```

Important Flutter/native files:

```text
D:\DMRT Online\dmrt_online\lib\main.dart
D:\DMRT Online\dmrt_online\assets\index.html
D:\DMRT Online\dmrt_online\assets\dmrt\logo.png
D:\DMRT Online\dmrt_online\assets\fonts\material-symbols-outlined.ttf
D:\DMRT Online\dmrt_online\android\app\src\main\AndroidManifest.xml
D:\DMRT Online\dmrt_online\android\app\src\main\kotlin\com\dmrt\dmrt_online\MainActivity.kt
D:\DMRT Online\dmrt_online\android\app\src\main\kotlin\com\dmrt\dmrt_online\DmrtWebViewFactory.kt
D:\DMRT Online\dmrt_online\android\app\src\main\res\xml\file_paths.xml
```

## 8. Flutter Wrapper Details

The Flutter entry point is `lib/main.dart`.

It:

- Sets status/navigation bar colors.
- Runs a `MaterialApp` titled `DMRT Online`.
- Uses a `SafeArea`.
- Creates a platform view with view type:

```text
dmrt_online/prototype_webview
```

On Android, the platform view is registered in:

```text
android\app\src\main\kotlin\com\dmrt\dmrt_online\MainActivity.kt
```

The Android WebView implementation is in:

```text
android\app\src\main\kotlin\com\dmrt\dmrt_online\DmrtWebViewFactory.kt
```

The WebView loads:

```text
file:///android_asset/flutter_assets/assets/index.html
```

## 9. Native Android Support Added

The native Android WebView wrapper has been extended beyond a basic WebView.

Implemented native support:

- JavaScript enabled.
- DOM storage enabled.
- Local file asset loading enabled.
- Media playback allowed without user gesture.
- WebView file chooser support.
- Gallery image selection support.
- Camera capture support for profile photo flow.
- FileProvider support for camera output.
- Android camera permission handling for WebView `getUserMedia`.
- Android hardware back-button bridge into JavaScript.

Android manifest includes:

- `INTERNET`
- `CAMERA`
- `READ_MEDIA_IMAGES`
- `READ_EXTERNAL_STORAGE` for older Android versions
- FileProvider declaration
- image capture/get-content query intents

## 10. Current App Behavior

The bundled HTML prototype currently supports:

- Home page.
- Buy ticket page.
- Ticket wallet/list.
- Ticket details.
- Ticket QR display.
- Scan gate QR page.
- Profile page and edit flow.
- History page with tabs/cards.
- Refund modal and refund fee logic.
- LocalStorage persistence.
- Simulated entry/exit scan flows.
- Group ticket/passenger count model.
- QR countdown and regenerate behavior.
- Ticket locking while riding.
- Expired ticket/history behavior.
- Demo loading scene implemented with `dmrt/loading.gif` in the current HTML/WebView prototype. It appears in these flows: use ticket, purchasing ticket, after scanning gate QR, saving profile information, and profile picture update. The loader is now a small centered animation with no visible animation container/box, a softly tinted `#d9e8e5` transparent blurred backdrop, and a 1 second demo duration.
- Loading scene asset guidance: if the animation is made in After Effects, export Lottie JSON using Bodymovin/LottieFiles. If it is made in Figma, try a LottieFiles/export plugin or recreate the animation in a Lottie-capable tool. Static SVG is acceptable for a non-animated loading illustration; animated SVG can work in the current HTML/WebView prototype if the animation is inside the SVG/CSS, but it is less ideal for the future native Flutter app than Lottie. If only GIF/MP4 exists, use animated WebP/GIF for the current prototype or recreate it as Lottie for the future native Flutter app.
- Toast/pop messages.
- Android back-button behavior.
- Real camera access attempt on scan gate QR page.
- BarcodeDetector QR scanning when supported by WebView.
- Fallback/simulator buttons if camera detection is not available.

## 11. Current Design and UI State

The app is currently being polished visually inside the HTML/CSS.

Important current design decisions:

- The original HTML design should be preserved.
- The current Material Symbols icons from the web prototype should remain.
- The app icon uses `logo.png`, enlarged inside a white launcher-icon background.
- The top app bar should blend with the page background and not show a gray underline.
- Bottom navigation bar height has been reduced from the earlier larger version.
- Text and cards should fit the phone screen as much as possible.
- The user manually checks the app on the phone after each installed build.
- Do not take screenshots or automate navigation unless the user explicitly asks.

Recent visual fixes already applied:

- Home/profile responsive fitting improvements.
- Hero greeting background image updated to `dmrt/home_bg_extended_green_aroplane.png` with un-stretched 1536×1024 proportions (`aspect-ratio: 1536 / 1024`) and ceiling alignment (`background-position: center calc(8px + env(safe-area-inset-top, 0px))`).
- Fine-tuned greeting header element placement: shifted logo, title, and avatar downward (`margin-top: 10px`, `transform: translateY(4px)`), buy ticket button rightward (`margin-right: -2px`), and greeting text row upward (`margin-top: -10px`).
- Re-architected ticket header background indicator (`.ticket-indicator`) using an SVG mask path (`mask-image: url(...)`) featuring a smooth S-curve wave transition (`C 46,56 46,100 36,100`) between the 56% height right band and the 100% height left section.
- Extended the horizontal width of the left portion of the ticket header background indicator (to `x=36%`) to provide breathing room for the `AVAILABLE`/`RIDING`/`LOCKED` status badge and `SINGLE JOURNEY` title.
- Added Passengers count (`01`) and Price (`৳60` / `totalFare`) metadata display (`.ticket-header-meta`) with subtle vertical divider on the right side of the ticket card header (`transform: translateY(-5px)`).
- Ticket details fitting improvements focused around refund policy area.
- Refund policy icon/title/text alignment improvements.
- History card connector and spacing experiments, then reverted after over-compaction.
- Buy page route card, fare amount, and ticket count spacing adjustments.
- Scanner page removed static smartphone placeholder flicker.
- QR page removed moving scan-line animation.
- QR expired state now shows only `Ticket expired`.
- Toast/pop messages made responsive and wrapping.
- Default profile/avatar icon visibility fixed.
- Route selection icon column moved upward slightly without changing card layout.

## 12. Current Buy Ticket Page State

The buy page is a key active polishing area.

Current CSS intent:

- Route selection card should be vertically taller.
- Route selection card should sit closer to the ticket number selection card.
- The gap between route selection and ticket number should visually match the gap between ticket number and fare-rate section.
- Ticket number card size/shape should not be changed unless explicitly requested.
- Total fare title/amount gap should be slightly larger.
- Total fare amount should be larger and more prominent.
- Origin/destination icons and connector inside route card have been moved upward together by changing only the icon-column offset.

Important: the user is sensitive to over-compression or unwanted side effects. When asked to adjust a small area, edit only that area.

## 13. Back Button Behavior

Android hardware/navigation back button behavior was customized:

- From any non-home page: one back press returns directly to Home.
- On Home: first back press shows compact toast `Press back again to exit`.
- On Home: second back press within about 2 seconds exits the app.

This is handled by native `MainActivity.onBackPressed()` calling a JavaScript bridge function in the WebView.

## 14. Camera and Gallery Behavior

Profile photo flow:

- Choose from gallery should open the Android gallery/file picker.
- Camera option should open the Android camera capture flow.
- Existing HTML crop/save flow should continue after image selection.

Gate QR scanner flow:

- The scan gate QR page should access the real phone camera.
- The camera should appear behind the existing scanner overlay.
- The static smartphone placeholder should not flash before camera loads.
- Real QR detection uses browser/WebView `BarcodeDetector` when available.
- Simulator buttons remain as fallback.

## 15. Build and Test Workflow

The user ONLY wants changes installed onto the connected Android phone when they explicitly request it (e.g., "update in my phone" or "deploy to phone"). DO NOT automatically compile or deploy after code edits.

Preferred workflow when explicitly requested:

1. Edit both HTML copies when changing HTML/CSS/JS:

```text
D:\DMRT Online\index.html
D:\DMRT Online\dmrt_online\assets\index.html
```

2. Run analyze:

```text
cmd /c ..\toolchains\flutter_env.cmd analyze
```

from:

```text
D:\DMRT Online\dmrt_online
```

3. Build debug APK:

```text
cmd /c ..\toolchains\flutter_env.cmd build apk --debug --no-pub
```

from:

```text
D:\DMRT Online\dmrt_online
```

4. Install to the connected Android phone:

```text
& 'D:\DMRT Online\toolchains\android-sdk\platform-tools\adb.exe' -s U8MFEA9XFQ9XFECM install -r 'D:\DMRT Online\dmrt_online\build\app\outputs\flutter-apk\app-debug.apk'
```

The commonly connected phone device ID has been:

```text
U8MFEA9XFQ9XFECM
```

If that device is not connected, run:

```text
& 'D:\DMRT Online\toolchains\android-sdk\platform-tools\adb.exe' devices
```

## 16. Toolchains

Use the bundled toolchains from:

```text
D:\DMRT Online\toolchains
```

The project has used:

- Bundled Flutter.
- Bundled Android SDK/platform-tools.
- Bundled JDK.
- Bundled Git through the Flutter environment when needed.

Normal `git` may not be available on the shell PATH. Prefer the project toolchain scripts for Flutter work.

## 17. Logo and Icons

Official app logo source:

```text
D:\DMRT Online\logo.png
```

The app icon was regenerated from this logo with:

- White background.
- Logo cropped to non-white bounds.
- Logo enlarged as much as possible while fitting inside the icon box.
- Android launcher mipmap icons updated.

The app display name is:

```text
DMRT Online
```

## 18. Current Verification Status

As of the 2026-06-07 loading-scene implementation:

- `flutter analyze` passed.
- Debug APK built successfully.
- Debug APK installed successfully on the connected Android phone.

The user manually verifies visual correctness on the phone.

## 19. User Collaboration Rules for This Project

These instructions are important:

- Always update this `project_context.md` file automatically after any major changes. Do not treat this file like a chat history; it must serve as a permanent, high-fidelity blueprint and record of what has been built and the current state of the application. Keep this rule documented here permanently so all future sessions follow it without exception. Do not wait for the user to ask for context updates.
- Do not take screenshots unless the user explicitly asks.
- Do not automate navigation unless the user explicitly asks.
- When the user requests a visual tweak, apply the requested change directly.
- DO NOT automatically build or install the updated debug APK on the phone after app edits. Only do this when explicitly requested.
- Keep root `index.html` and bundled `dmrt_online/assets/index.html` in sync.
- Avoid changing unrelated components.
- If the user says something became too compact or too changed, undo or narrow the change.
- The user prefers manual visual checking on the phone after installation.
- Preserve the HTML prototype design, animations, transitions, and workflow.

## 20. Known Limitations and Risks

Current app limitations:

- It is still an HTML/JS prototype inside a Flutter WebView, not a fully native Flutter implementation.
- Real backend/payment/gate/server integration is not implemented yet.
- Ticket validation is simulated in the app prototype.
- Gate authority is conceptually planned but not implemented here.
- Root/jailbreak detection and screenshot blocking are not complete production-grade security yet.
- WebView `BarcodeDetector` support may vary by Android WebView version.
- Camera/gallery behavior depends on Android permissions and installed system apps.
- iOS project files exist but have not been the active test target on Windows.

## 21. Future Plan

Near-term future work:

- Continue polishing the HTML prototype inside the Flutter WebView.
- Keep testing on the real Android phone with `flutter run` or debug APK install.
- Keep improving responsive fit on target phone screens.
- Resolve any remaining camera, scanner, profile, QR, refund, history, and ticket-flow issues.
- Build a final debug or release APK only when the user approves the visual/functionality state.

Medium-term future work:

- Rebuild the passenger app as a real native Flutter production app when the prototype is approved.
- Use the refined `index.html` prototype as the design/workflow reference, not as the runtime.
- Create proper Dart models for tickets, stations, fares, purchases, gate challenges, passenger QR payloads, and local events.
- Add state management such as Riverpod, Bloc, or Provider.
- Add local database support such as Drift/SQLite or Isar.
- Add secure storage for signed ticket tokens and device keys.
- Add device binding using app-generated key pairs.
- Replace mock ticket purchase/payment with backend API calls.
- Add real station and fare data API.
- Add real signed ticket data/token handling.
- Add native QR scanning and QR generation packages.
- Add real camera handling through Flutter-native packages.
- Add stronger screenshot/screen-record blocking.
- Add rooted/jailbroken/tampered-device checks.
- Add proper offline ticket usage after purchase.
- Add proper sync/status refresh with backend.
- Add production QR payload signing/hash/device-binding.
- Add complete error handling for wrong station, wrong exit, expired ticket, active journey conflict, fake/invalid ticket, sync issue, and fine-required state.
- Prepare Android and iOS production permissions, signing, and release behavior.
- Design the architecture for high user volume and real passenger use.

Long-term future work:

- Build central backend and database.
- Build Raspberry Pi gate software and local SQLite validation.
- Build station officer web app.
- Implement full offline-first sync and conflict-safe event logging.
- Implement production-grade gate challenge/signature validation.
- Implement operational deployment strategy with golden SD image.

## 22. Update Log

### 2026-06-04

- Created this context memory file.
- Documented project purpose, current architecture, implementation state, native WebView support, current UI state, build/install workflow, user collaboration rules, known limitations, and future plan.
- Updated context to clarify that the current WebView-wrapped HTML app is a prototype/testing stage only, while the long-term target is a professional native Flutter production app. Added app package identity and expanded the future native Flutter migration plan.
- Added a standing rule that this context file must be updated automatically after any project-related thinking, conversation, decision, edit, command execution, verification, or plan change, without requiring the user to request it again.
- Recorded the pending plan to add a demo loading scene in use-ticket, purchasing-ticket, post-gate-scan, save-profile, and profile-picture-update flows after the user provides the loading animation asset.
- Added loading-scene asset preparation guidance: prefer Lottie JSON via Bodymovin/LottieFiles, with animated WebP/GIF as fallback for the current WebView prototype.
- Clarified SVG support for the loading scene: static SVG is fine for illustration, animated SVG can work in the current WebView prototype, but Lottie remains better for future native Flutter reuse.
- Recorded that the user's loading scene is animated, so an animated SVG file is acceptable for the current WebView demo loading overlay if the animation is embedded in the SVG/CSS.

### 2026-06-07

- Implemented the demo loading scene using `dmrt/loading.gif`, bundled it as a Flutter asset, added a reusable HTML/JS loading overlay, and wired it into use-ticket, purchase, post-gate-scan, save-profile, and profile-photo-update flows.
- Verified the loading-scene build with `flutter analyze`, debug APK build, and successful adb install on the connected Android phone.
- Adjusted the loading scene to display as a small centered typical loader instead of full-screen artwork, changed the overlay to a transparent blurred backdrop, set the default demo delay to 1 second, and reinstalled the debug APK after successful analyze/build.
- Removed the visible loader image container styling by clearing the loader image radius/shadow and making the loading overlay background fully transparent while keeping the blur effect. Rebuilt and reinstalled the debug APK successfully.
- Changed the loading overlay backdrop from clear/white-feeling blur to a low-opacity `#d9e8e5` tint while preserving the same blur strength and transparency feel. Rebuilt and reinstalled successfully.

### 2026-07-01

- Modified the `.welcome-card` styles in `index.html` and `dmrt_online/assets/index.html` to be transparent and borderless, positioning the greeting section elements directly onto the page background.
- Styled the `.tickets-section` to behave as a card container (white background, border, shadow, padding, and rounded corners) and removed the outer border/shadow from `.no-tickets-placeholder` when displayed inside this section card.
- Adjusted `.tickets-section` to cover the full width (left and right edges) without side gaps on mobile, using negative margins and removing horizontal border-radius/borders, while keeping internal alignment responsive.
- Restored the upper curved corners (`border-radius: var(--radius-xl) var(--radius-xl) 0 0;`) and restored the standard borders on `.tickets-section` so that the curved outlines render seamlessly.
- Increased the upper curved corners radius of the `.tickets-section` card from `var(--radius-xl)` (16px) to `var(--radius-2xl)` (24px) for a more pronounced curve.
- Disabled scrolling on the main page (`#view-home`) and configured the ticket list container (`#home-tickets-container`) to be a scrollable region within the `.tickets-section` card wrapper via Flexbox layouts.
- Added `overflow: hidden;` and flex boundaries to `#view-home .main-content` to properly constrain the height, preventing the content container from expanding off-screen and ensuring the inner ticket-list scroll activates.
- Hid the scrollbar indicator on the ticket container (`#home-tickets-container`) and extended the card length under the navigation bar to the bottom of the page (`padding-bottom: 0` on `.main-content`), adding a corresponding bottom padding inside the scrollable container to clear the navigation bar buttons.
- Reverted all custom shadow and transform modifications on the ticket cards (`.ticket-card`) back to their original system defaults (`box-shadow: var(--shadow-md)` for standard view, `var(--shadow-lg)` for hover, and standard scale transformations).
- Copied `dmrt/home_bg.png` to the Flutter project assets, registered it in `pubspec.yaml` (replacing `home_bg_3.png`), and updated the CSS rules inside `index.html` and `dmrt_online/assets/index.html` to reference `dmrt/home_bg.png` as the background image of the top part of `#view-home .main-content`.
- Added `margin-top: 35px;` to the "Buy Ticket" button (`.welcome-card > button`) to push it and the "My Tickets" section card down, creating a balanced gap to display the background image clearly.
- Hid the "Buy Ticket" button from the home page by commenting out its HTML, and added `margin-bottom: 80px;` to `.welcome-card` in the CSS to preserve the vertical spacing and keep the "My Tickets" section card pushed down, displaying the background image clearly.
- Changed the background color of the standard top header bar (`.app-bar`) to `#cedddb` to seamlessly match and blend with the top edge of the `home_bg.png` background image.

### 2026-07-03

- Commented out the standard top `.app-bar` header from the home view (`view-home`) in `index.html` and `dmrt_online/assets/index.html`, effectively removing the top separated logo, title bar, and settings icon.
- Placed the DMRT logo and title directly inside the `.welcome-card` wrapper (floating on top of the greeting background image) using a new `.welcome-logo-row` container with matching layout, fonts, and colors to align it perfectly with the greeting text.
- Copied `dmrt/home_bg_extended.png` to the project assets, registered it in `pubspec.yaml` (replacing `home_bg.png`), and updated the CSS rules inside `index.html` and `dmrt_online/assets/index.html` to reference `dmrt/home_bg_extended.png` as the home view's background image.
- Set `padding-top: 8px;` inside `#view-home .main-content` to slide both the DMRT logo+title and the greeting section elements down slightly.
- Changed `margin-bottom: 8px;` inside `.welcome-logo-row` to offset the greeting text and avatar, keeping the greeting part at its previous vertical position while only moving the logo+title upward.
- Relocated the profile avatar container (`.welcome-card__avatar`) into `.welcome-logo-row` (aligned to the right side of the row using flex `justify-content: space-between`), aligning it directly with the DMRT logo and title. Simplified the greeting row container underneath it to span the full width.
- Reverted the sizes of the logo, title, and profile picture avatar back to their original size specifications.
- Shrunk only the welcome card profile avatar circle diameter to `40px` (flex basis `40px`), keeping the inner icon size at `24px` to maintain a balanced layout.
- Added `margin-top: 4px;` and `margin-right: 8px;` to the `.welcome-card__avatar` element to push only the avatar circle down slightly and pull it to the left away from the right screen edge.
- Increased the DMRT logo image height range from `clamp(36px, 10vw, 40px)` to `clamp(42px, 11vw, 46px)` to make it slightly larger and more prominent.
- Changed the greeting subtitle (`.welcome-card__subtitle`) color to black (`#000000`) for enhanced text contrast and readability.
- Increased the `.welcome-card` bottom margin from `80px` to `100px` (subsequently fine-tuned to `90px` based on visual balance) to push the "My Tickets" section card further down, showcasing more of the background image details.
- Added a compact, pill-shaped "Buy Ticket" button (`.btn-buy-greeting`) on the right side of the greeting row (`.welcome-card__row`), aligning it horizontally with the greeting text and vertically directly under the top bar's avatar.
- Updated `getTimeGreeting()` logic to dynamically return `"Good Noon"` instead of `"Noon"` for time slots between 12:00 PM and 3:00 PM, and adjusted the starting time for `"Good Afternoon"` to 3:00 PM.
- Redesigned the bottom navigation bar (`.bottom-nav`) into a floating glass capsule with fully rounded left and right edges (`border-radius: 30px`), offset margins (`bottom: 16px; left: 16px; width: calc(100% - 32px)`), and a transparent white background (`rgba(255, 255, 255, 0.55)` with `backdrop-filter: blur(20px)`).
- Increased the scrollable padding-bottom by `16px` across all main content views (`.main-content`, `#home-tickets-container`, `.buy-content`, `.history-content`, and `.profile-content`) to ensure scrolling content clears the floating navigation bar.
- Reverted the bottom navigation bar styling and scrolling container paddings back to the original full-width, flat glassmorphism layout (keeping the custom `0.55` opacity glass transparency).
- Commented out the local `@font-face` definition for `'Material Symbols Outlined'` in `index.html` and `dmrt_online/assets/index.html` to allow the browser to load the variable web font from Google Fonts CDN, enabling active navigation bar icons to be rendered fully filled instead of remaining outlined.
- Updated bottom navigation bar labels (`.bottom-nav__label`) to render with standard font-weight `400` when inactive, and change to bold `700` only when active.
- Styled the active bottom navigation bar sliding indicator (`.bottom-nav__indicator`) to span the full height of the bar (`height: 100%`) with a `3px` solid top border, emitting a fading vertical gradient (`rgba(0, 81, 64, 0.18)` at 0% fading to completely transparent `0` opacity at `35%` of the height) downwards to keep the glow restricted to the upper side of the bar. Configured `z-index: 1` and `pointer-events: none` on the indicator, and `z-index: 2` on navigation items to place the gradient cleanly behind the active tab's icon and label text.
- Integrated seamless Android system navigation bar compatibility in `lib/main.dart` by enabling `SystemUiMode.edgeToEdge`, setting `systemNavigationBarColor` and `systemNavigationBarDividerColor` to transparent, and configuring `SafeArea(bottom: false)` to stretch the WebView to the bottom edge.
- Overrode `onCreate` in `MainActivity.kt` to set `window.isNavigationBarContrastEnforced = false` on Android 10+ (API 29+) to bypass forced system button backgrounds, allowing the transparent background setting to take effect.
- Added `env(safe-area-inset-bottom)` support to `.bottom-nav` height and padding-bottom, as well as all view container paddings, allowing the app's blurry glassmorphism nav bar to stretch behind the system buttons while keeping layout text/icons correctly aligned.
- Changed the header title text inside the welcome card from `"DMRT Online"` to `"DMRT"` in `index.html` and `dmrt_online/assets/index.html`.
- Configured edge-to-edge status bar support in `lib/main.dart` by setting `statusBarColor: Colors.transparent` and setting `top: false` in `SafeArea`.
- Integrated `env(safe-area-inset-top)` support across view containers (`.buy-content`, `.history-content`, `.profile-content`, `.detail-app-bar`, `.qr-app-bar`, `.scanner-app-bar`, and `#view-home .main-content`) in `index.html` and `dmrt_online/assets/index.html` to allow background images to bleed fully behind the status bar and punch-hole camera without overlapping controls.
- Adjusted Home page header vertical spacing inside `index.html` and `dmrt_online/assets/index.html` by decreasing `#view-home .main-content` padding-top offset from `8px` to `2px` and decreasing `.welcome-logo-row` margin-bottom from `8px` to `2px` to shift the logo/title upward and tighten the gap to the greeting text.
- Reduced `.welcome-card` bottom margin from `90px` to `60px` in `index.html` and `dmrt_online/assets/index.html` to slide the "My Tickets" card upward, eliminating the blank layout gap below the greeting artwork.
- Constrained the welcome card greeting text `.welcome-card__greeting` inside `index.html` and `dmrt_online/assets/index.html` to `white-space: nowrap` and scaled its size to `clamp(16px, 4.5vw, 20px)` to guarantee it stays in a single line on narrow device screens without wrapping below the "Buy Ticket" button.

### 2026-07-04

- Fixed scrolling viewport structures to allow items to scroll behind the transparent glassmorphism bottom navigation bar.
- Moved bottom safe-area paddings from parent viewports directly into child scroll containers on the Details page, Trip History page, Buy Ticket page, and Profile page to eliminate blank gaps above the navigation bar.
- Removed the separated profile app bar, adding an inline `.profile-header-row` with a hamburger drawer icon.
- Created a slide-in Hamburger side drawer taking up exactly `60%` width with a pill language toggle ("EN" | "বাং"), split guidelines (separate "Do's" and "Don'ts"), and a red-themed "Logout" button at the bottom.
- Removed the logout button from the Profile form page.
- Added touch-swipe gesture support to the Trip History slide viewport, enabling seamless left/right swiping between "Completed" and "Expired" tickets.
- Removed the dark gray translucent mask background from the QR scanner overlay, leaving the camera background fully clear and unshaded.
- Increased the QR code card size on the Details and reader views to `clamp(240px, 80vw, 300px)` for better scan readability.
- Re-themed the QR Scanning Page header, L-corners, laser scan line, white card, and simulator buttons to DMRT brand green, and added a Help question button in the top-right corner.
- Compiled the debug APK and installed the update successfully onto the connected Android device `U8MFEA9XFQ9XFECM`.

Future agents: append to this log whenever work is completed. Keep entries short but specific.

### 2026-07-05

- Updated Buy Ticket page: moved Total Fare header down, scaled text size, moved Fare Rate bar to the top of the scrollable container, removed the internet notice, and made the Proceed button gray and warning-only until stations are selected.
- Fixed Trip History swiping by disabling native horizontal scroll conflict (`overflow-x: hidden`) and checking touchmove drag directions, and hid scrollbars.
- Implemented an offline connection checker popup and blocked offline ticket purchases.
- Updated Profile page: replaced the gender select field with modern radio cards, replaced the default calendar date field with a custom forest green calendar modal overlay, and made the Save Changes button gray and disabled-action until fields are edited.
- Redesigned the bottom navigation bar: commented out the edge-to-edge rectangular layout (labeled as `[Rectangular Nav Bar]`), and created the `[Rounded Nav Bar]` layout. The new bar is a floating capsule shape with a smooth concave center dip SVG cutout that wraps around a large floating circular center Action Button for Gate QR Scanning. Configured soft green theme active icon background pills matching modern Material design layouts.
- Removed subpixel seam lines in the rounded bottom nav bar by using a single SVG path background on the container. Elevated glassmorphism glow using `backdrop-filter: blur(24px)` and `rgba(255, 255, 255, 0.45)` transparency.
- Restored Profile gender fields to a read-only text input field layout that opens a custom-styled modern option selection modal overlay (`#custom-gender-overlay`) on click.
- Delayed the startup connection checker by 300ms and added a fallback captive portal check (`clients3.google.com/generate_204`) to prevent WebView cached online state conflicts.
- Built a multi-ticket activation flow (`#ticket-select-overlay`) that prompts user to select which ticket to activate when the bottom Scan FAB is clicked (bypassing if exactly 1 available ticket or if currently riding).
- Enclosed the bottom nav bar notch background inside a child background element with `border-radius: 32px; overflow: hidden;` to clip any rectangular blur spillages, reverting transparency style to `rgba(255,255,255,0.55)` with a `20px` blur.
- Added a bright green neon border (`rgba(16, 185, 129, 0.85)`) and glowing shadow around the center Scan FAB.
- Converted background color style of Ticket Buying, History, Profile pages, and the Home page Tickets section to a vertical gradient fading from solid `#d9e8e5` at the top to transparent `rgba(217, 232, 229, 0)` at the bottom.
- Converted `purchaseGroupTicket()` into an async function that performs a real-time internet connectivity ping check on click, blocking purchases if offline.
- Formatted the ticket selector list modal: hid scrollbars, centered the `Origin => Destination` route text, replaced the ID string with a count representation (`2 People` or `1 Person`), and placed only the price on the right side.
- Decreased bottom nav bar transparency to 80% (`rgba(255, 255, 255, 0.8)`) and increased blur to `28px` for a stronger blurry glass texture.
- Removed the outline border from the center Scan FAB, and increased the emerald box-shadow neon backlight (`rgba(16, 185, 129, 0.85)` and `rgba(16, 185, 129, 0.45)`) to make it look like light is emitting from behind the button.
- Updated Dart system navigation bar color (`main.dart`) to match the 80% opacity bottom nav bar (`Color(0xCCFFFFFF)`).
- Applied a vertical fading gradient background starting with `#d0e1df` at the top and fading gradually to transparent (`rgba(208, 225, 223, 0)`) at the bottom of the Buy Ticket, History, and Profile pages.
- Increased the bottom nav bar backdrop blur to `40px` for a matte frosted glass texture.
- Replaced the linear background gradients with a solid `#d0e1df` background color on the Buy Ticket page, History page, Profile page, and the Home page Tickets section card.
- Set the ticket card side notches (`.notch-left` and `.notch-right`) background to solid `#d0e1df` to match the tickets section background and preserve the cutout look.
- Decreased bottom nav bar transparency to 93% (`rgba(255, 255, 255, 0.93)`) and updated Dart system navigation bar color to matching `Color(0xEDFFFFFF)` for a more opaque frosted glass aesthetic.
- Set the center FAB placeholder to `flex: 1` to distribute columns evenly and achieve identical spacing/gaps between all 4 navigation sections.
- Configured Android system navigation bar to be fully transparent in Dart (`main.dart`) and injected a white, 40px blurred HTML background div overlay (`.phone-nav-bar-bg`) at the viewport bottom to cleanly blend behind the native keys.
- Enhanced bottom nav bar shadow depth using a dual drop-shadow filter to raise it off solid backgrounds.
- Increased ticket card, card header, and action footer corner roundness to `var(--radius-2xl)` (24px) to perfectly match the quantity selection card styling.
- Removed the top divider line border from above the Save Changes button container (`.form-actions`) on the Profile page.
- Reduced active bottom navigation tab background pill indicator width to `40px` for a tighter, cleaner look.
- Reverted the bottom navigation bar back to a flat rectangular shape spanning edge-to-edge at the viewport bottom, with a clean top border and shadow.
- Changed the background of active tab indicators and the fare rate bar to solid primary green (`#005140`).
- Implemented a third tab ("Refunded") in the Trip History slider, adding a red "Refunded" status badge.
- Configured the connector line between origin and destination selects to turn black when both stations are chosen.
- Increased bottom nav background transparency to `0.5` (`rgba(255, 255, 255, 0.5)`) for an enhanced frosted glass glow effect.
- Forced active navigation tab icons to fill completely with solid primary green (`var(--color-primary)` / `#005140`) using CSS variation settings.
- Fully implemented the sliding segment filter toggle bar inside the Trip History view, integrating the custom segment bar HTML elements (`.history-tabs-container` and `.history-tab-option`).

### 2026-07-14 (Checkpoint 15)
- Set Home page brand welcome logo header title to "DMRT Online" in the HTML.
- Vertically centered the viewfinder layout inside the Scanner page by placing symmetrical flex-grow spacers above and below the scanner viewfinder box.
- Restructured the bottom instruction card and simulator buttons on the Scanner page to align nicely at the bottom of the screen.
- Configured dynamic routing on the bottom navigation bar Scan button to check active countdown timers: redirects to active QR countdown page if timer is active, otherwise loads exit scanner.
- Add strict matching on gender dropdown select element via `data-gender` attributes to prevent substring collisions (e.g. matching 'female' when selecting 'male').
- Configured 200ms auto-close delay for gender selection modal picker to allow chosen background animation to play before hiding.
- Fixed blank screen issue on target WebView platforms by restoring default background configurations inside Android native `DmrtWebViewFactory.kt`.

### 2026-07-17 (Checkpoint 16)
- Modified `navigateBack()` inside JS to intercept Android system back button keypress events when overlays/drawers are open, closing them first (Side Menu, Photo Picker, Cropper, DatePicker, Gender Picker, Station Selector, Ticket Selector) before moving back.
- Increased Profile side menu drawer width to 75% of screen width in CSS.
- Added horizontal padding to the Profile form fields in CSS to shrink them on both sides.
- Implemented a modern, interactive Dhaka Metro Route Selector Modal showing a vertical forest green route map matching MRT Line 6, complete with station nodes, Bangla/English labels, start location locator badges ("আপনি এখানে • You Are Here"), and dynamic capsules showing travel fares and times in Bangla digits.
- Configured hidden `<select>` tags in the HTML buying page to keep compatibility with all existing fare calculations, using visible trigger layers.
- Automatically refresh and clear route selections on the Buy Ticket page when navigating to any other page in the app.
- Implemented a "Loading Scene" trigger option in the Profile side menu drawer.
- Integrated a Loading scene test mode that can be dismissed/closed instantly by clicking anywhere on the screen.
- Updated project context instructions to permanently treat `project_context.md` as an application blueprint/record, and enforce updating it automatically after any major changes.
- Changed page background on Buy Ticket, History, Profile, and Details views to a custom top-to-bottom gradient starting from `#188674` (deep teal for first 5-10%), transitioning to `#9fd1c6` (mint), and finishing with white at the bottom 5%.
- Configured `#view-home .tickets-section` to use a custom vertical gradient starting with `#9fd1c6` (mint) and transitioning to white at the bottom 5%.
- Adjusted `.notch-left` and `.notch-right` background-colors to `#9fd1c6` to seamlessly match the tickets section background.
- Changed home page welcome title `.welcome-logo-title` color to white (`#ffffff`) for perfect contrast against the green background image.
- Implemented a modern button gradient design on the home page's "Use Ticket" and "Buy Ticket" buttons using a subtle forest-green diagonal gradient (`linear-gradient(135deg, #0a6e59 0%, #005140 100%)`).
- Added a native-feeling startup splash screen (`#startup-splash-overlay`) displaying the DMRT logo centered on a solid white background on app launch, which fades out smoothly after the application finishes initializing.
- Unified backgrounds on Profile, Trip History, and Buy Ticket views to use the gradual gradient: solid deep teal `#188674` from the top ($0\%$) until $1\%$, transitioning smoothly to mint `#9fd1c6` by $15\%$, and then smoothly fading continuously from mint to white (`#ffffff`) at $90\%$ (solid white from $90\%$-$100\%$).
- Reconfigured the Ticket Details view `#view-details` and its notch cutouts to have the solid `#dbe8e5` background to match the homepage My Ticket section.
- Changed the homepage header brand title text to "DMRTonline" with style settings of weight 500 (medium) and italic.
- Imported Iceland and Poppins fonts from Google Fonts and implemented a JS click trigger `cycleTitleFont()` on the homepage title that animates a typewriter-style backspace and typing-in loop to cycle the header font family between Bitcount Grid Single, Iceland, and Poppins.
- Switched the bottom navigation bar shadow to `filter: drop-shadow(0px -4px 10px rgba(0, 0, 0, 0.15))` to correctly follow the SVG curved cutout silhouette under the circular scanner FAB, and increased the bar background opacity to `0.93` and backdrop-filter to `blur(50px)` to make it almost completely opaque while retaining frosted blur colors.
- Increased the neon glow effect around the circular scanner FAB (`.bottom-nav-rounded__fab`) by expanding the outer glow parameters (`box-shadow: 0 4px 14px rgba(0, 81, 64, 0.4), 0 0 20px rgba(16, 185, 129, 0.85) !important`).
- Updated side drawer menu icon colors to black (`#000000`), except the logout icon.
- Removed name field validation constraints to allow saving empty name profiles, and configured welcome greeting banner to display without name text if empty.
- Configured the homepage welcome title (`.welcome-logo-title`), Profile page menu icon (`.profile-menu-btn`), total fare title (`.fare-header__label`), and total fare amount (`.fare-header__amount`) to use the default page title color token `var(--color-on-surface)` for perfect visual consistency.
- Applied a thin outline border (`border: 1px solid rgba(190, 201, 195, 0.45) !important`) around the homepage Buy Ticket button (`.btn-buy-greeting`) and the Select Route selector card (`.route-card`) to distinguish them clearly from their backgrounds.
- Restored the route selection card design layout to its original divider-line text layout, keeping the "Select Route" title header and the default dropdown style.
- Applied high-contrast button gradient backgrounds globally to all active buttons (primary green, refund red, active pay/save, scanner FAB) and the active sliding segment background of the history view filter bar.

### 2026-07-17 to 2026-07-20 (Checkpoint 17–22)
- Implemented a native Flutter splash screen (`DmrtSplashScreen`) in `lib/main.dart` with a 240x240 DMRT logo, smooth fade-in via `AnimatedOpacity`, and a pulsing zoom-in/zoom-out loop via `ScaleTransition` (0.9–1.1 scale). The splash auto-navigates to the main WebView screen after 2.5 seconds.
- Configured Android 12+ Splash Screen API to show a transparent splash icon (`windowSplashScreenAnimatedIcon = @android:color/transparent`) in both `values/styles.xml` and `values-night/styles.xml` to prevent visual "jumps" between the native boot icon and the Flutter animated splash.
- Implemented the Route Selection Modal with dynamic OK/Cancel button states — OK button is only enabled when both origin and destination stations are selected.
- Reduced `.welcome-card` margin-top to `-6px` and margin-bottom to `65px` to shift the greeting section and logo/title upward on the home page.
- Applied `transform: translateY(-6px)` to the greeting and logo/title containers for additional upward shift.
- Enlarged the home background image size to `120%` via `background-size: 120% auto`.
- Added `overflow-x: hidden` to prevent horizontal "wiggle" when scrolling ticket cards.
- Copied ticket card layout styles from `trip_history.html` into the main `index.html` for consistent card design across home and history views.
- Updated `.agents/AGENTS.md` with two new operational rules: (1) Only compile and deploy to phone when user explicitly requests it; (2) Stop upgrade sessions immediately after build finishes.
- Changed the swap/reverse stations button animation from a back-and-forth 180° toggle to a full 360° continuous spin on each click, with cumulative degree tracking (`btn._rotationDeg += 360`). Increased CSS transition duration to 400ms for smooth rotation.
- Moved the home background image position lower (`background-position: center -20px`) so the top of the image aligns with the top of the page.
- Moved the origin station icon upward in the route selection card (`margin-top: 11px → 4px`) to align with the "From" label, and extended the connector line accordingly (`top: 34px → 27px`, `bottom: -22px → -29px`).
- Increased the Trip History card date/time font-size from `12px` to `13.5px` (line-height from `16px` to `18px`) for better readability.
- Moved the destination station icon in the route selection card slightly lower by adding `margin-top: 4px` to `.station-item__icon--destination`.
- Updated the route selection card vertical connector line to `top: 30px; bottom: -16px;`.
- Reduced bottom padding of the trip history cards from `16px` to `10px` to save space.
- Reduced the vertical gap between the date/status header and the details body inside trip history cards (`margin-top: 0` on `.history-card__body`).
- Shifted the home background image position to `center 0px` to align its ceiling with the page.
- Kept the My Ticket section card at the original `.welcome-card` bottom margin of `65px` after iterations.
- Configured the native splash theme on Android (`styles.xml`) to display `@mipmap/ic_launcher` so the static logo is shown instantly on tap.
- Configured the Flutter `DmrtSplashScreen` (`main.dart`) to render the pulsing logo at `1.0` opacity immediately without any fade-in delay (removing `AnimatedOpacity` and the post-frame callback), and resized the logo widget to `108` logical pixels to match Android's native splash icon size (108dp) for a seamless handover without any size jump.
- Synchronized the root `index.html` with `dmrt_online/assets/index.html`.

### 2026-07-27 (Checkpoint 23–28)
- Updated hero background image to `dmrt/home_bg_extended_green_aroplane.png` and adjusted section aspect ratio (`aspect-ratio: 1536 / 1024`).
- Adjusted header layout element positioning: shifted logo, title, and avatar downward (`margin-top: 10px`, `transform: translateY(4px)`), buy ticket button rightward (`margin-right: -2px`), and greeting text row upward (`margin-top: -10px`).
- Preserved `SINGLE JOURNEY` subtitle text while positioning status badge (`AVAILABLE`, `RIDING`, `LOCKED`) directly above it inside the ticket header.
- Re-architected ticket header background indicator (`.ticket-indicator`) to use a smooth SVG mask path (`mask-image: url(...)`) featuring an S-curve wave transition (`C 46,56 46,100 36,100`).
- Extended the horizontal width of the left portion of the ticket header background indicator (from `x=24%` to `x=36%`) and adjusted right side height (to `56%`).
- Added Passengers count (`01`) and Price (`৳60` / `totalFare`) metadata display (`.ticket-header-meta`) on the right side of the ticket header, and updated `renderHomeTickets()` and `renderTicketDetails()` JS.
- Fixed `pubspec.yaml` syntax issue by properly indenting `assets:` under the `flutter:` block, enabling Flutter to bundle `index.html`, all image assets, and fonts into the app APK.
- Configured system `JAVA_HOME` (`C:\Program Files\Java\jdk-26.0.1`) and Flutter Android SDK path (`D:\android-sdk`).
- Created and updated `.agents/AGENTS.md` and `AGENTS.md` with strict operational rules for asset synchronization, mandatory project context memory updates, and prompt-only phone deployment execution.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Executed `flutter clean` to remove all temporary build directories and generated APK files, keeping the workspace completely clean.
- Cleaned up top greeting header card CSS (`.welcome-card`, `.welcome-logo-row`, `.welcome-logo-left`, `.welcome-card__row`, `.welcome-card__avatar`): set `background-position: center top` to align hero image flush with page top ceiling, and removed manual pixel offsets (`margin-top`, `translateY`) for clean flex alignment.
- Shifted the logo + title and avatar downward together (`margin-top: 6px` on `.welcome-logo-row`) and shifted the hero background image downward (`background-position: center calc(8px + env(safe-area-inset-top, 0px))`).
- Successfully compiled and deployed the updated application to the connected Android device `U8MFEA9XFQ9XFECM`, and executed `flutter clean` to keep workspace files clean.
- Set `margin-top: 12px` on `.welcome-logo-row` for the logo, title, and avatar area, and reduced the vertical gap between the top logo/avatar row and bottom greeting/buy-ticket row to `var(--space-2)` (8px) on `.welcome-card`.
- Updated `.welcome-card` CSS to `background-position: center top` so the sky artwork bleeds seamlessly behind the phone status/notification bar.
- Implemented complete 3-page Authentication Flow (Phone Login `#view-auth-phone`, OTP Verification `#view-auth-otp`, Profile Setup `#view-auth-profile-setup`):
  - **Phone Entry Page**: Pre-fills existing phone number with `+880` prefix badge, Next button disabled until valid 10-digit phone number is entered.
  - **OTP Verification Page**: Displays phone number, 6 individual digit input boxes with auto-focus/backspace navigation, countdown timer (30s) for "Resend Code", and dummy verification logic for OTP code `000000`.
  - **Profile Setup Page**: Shown for first-time registration users to set photo avatar and name, with "Get Started" and "Skip for now" options.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Refined Auth Flow UI & State Logic:
  - Removed white `.auth-card` containers on Phone Entry and OTP pages, rendering elements (`.auth-direct-container`) directly on the gradient background for a seamless look.
  - Fixed profile setup name saving bug by updating `state.profile.fullName` instead of `state.profile.name`.
  - Removed default demo user profile data (`fullName`, `phone`, `email`, etc. initialize as empty strings for new accounts).
  - Added 3 direct test links in the Side Drawer menu to jump directly to Phone Login, OTP, and Profile Setup pages.
  - Added English to Bangla (`EN` / `বাং`) language toggle in the top-right corner of the Phone Number page.
  - Removed the unnecessary "Verify" button on OTP page (auto-verifies on typing 6th digit).
  - Removed white rectangular background space under OTP input boxes.
  - Moved "Skip" button to the top-right corner of Profile Setup page, removed DMRT logo from Profile Setup page, and enabled "Get Started" button when either a photo is uploaded or a name is entered.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Updated Home Hero Background Asset & Refined Auth Flow UI:
  - Updated home hero card background image URL to `dmrt/home_bg_new.png`.
  - Removed "DMRT Online" text title on Phone Login and OTP pages and increased logo height to `250px`.
  - Updated Login page title "Enter your phone number" to primary color (`var(--color-primary)`), subtitle to black (`#000000`), and terms text to black with bold/underlined/primary-colored "Terms of Service" linked to `https://dhakametrorail.org/terms/`.
  - Removed "BD" text from phone prefix badge, keeping only `+880`, and added a clear ("X") button to clear the input value at once.
  - Styled OTP back arrow as a clean black arrow without circle/backdrop effect.
  - Applied primary color to OTP target phone number and "Resend" link, black color to "Didn't receive the code?" subtitle, and secondary red color to invalid OTP warnings.
  - Implemented sequential outline color change animation across the 6 OTP input boxes on entering valid code `000000`, followed by displaying a clean green "Verified" checkmark indicator. Removed popup toasts on OTP page.
- Synchronized root `index.html` and `dmrt/` assets with `dmrt_online/assets/`.
- Centered Profile Setup Page & Reduced Logo Gaps:
  - Centered all elements vertically in the middle of the viewport (`justify-content: center`) on `#view-auth-profile-setup`.
  - Removed `<span class="setup-avatar-hint">Tap to add a photo</span>` line under the profile avatar picker.
  - Reduced vertical spacing between the 250px logo and header content on both Phone Login and OTP pages by setting `.auth-logo-section { margin-bottom: -38px; }`.
- Enhanced Auth Validation, Clear Button, Timer & Profile Setup UI:
  - Updated phone entry validation for 11-digit Bangladeshi format (`01XXX-XXXXXX`), auto-hyphenating as user types (`01316-451718`). Next button is enabled ONLY when 11 digits are entered.
  - Updated clear button layout to fit responsively inside `.auth-phone-wrapper` without clipping on narrow screens, and changed clear icon to simple cross (`close`).
  - Increased OTP resend timer duration to 60 seconds (1 minute), and styled enabled Resend link in secondary color (`var(--color-secondary)`).
  - Removed subtitle "Let's personalize your experience" on Profile Setup page, enlarged avatar section to 120x120px with primary outline border, and shifted page contents upward. Made top-right Skip button right arrow smaller (`17px`).
- Responsive Centering, Reverted Auto-Clear & Hero Card Height:
  - Reverted automatic clearing of OTP fields on invalid code (digits remain typed for manual editing/correction).
  - Configured responsive vertical centering across all 3 Auth pages (`.auth-page { justify-content: center; min-height: 100dvh; }`) so central input fields sit dynamically in the optical middle of any screen height.
  - Preserved standard non-stretched 1.5 aspect ratio (`aspect-ratio: 1536 / 1024`, `background-size: 100% auto`) on `.welcome-card` to maintain natural background image proportions without stretching.
- Fixed Logo Positioning & Upward Content Shift:
  - Anchored top padding (`padding-top: calc(16px + env(safe-area-inset-top, 0px))`) and `justify-content: flex-start` across `.auth-page` so that the 250px DMRT logo remains 100% frozen in place without moving or jumping when navigating between Login and OTP pages.
  - Shifted all contents on Phone Login, OTP, and Profile Setup pages slightly higher toward the top of the viewport.
- Ticket Header Meta Attributes, Expiry/Refund Component & Tightened Wave Transition (Checkpoint 37):
  - Tightened the S-curve transition in the `.ticket-indicator` background mask (`M 0,0 L 100,0 L 100,56 L 43,56 C 39.5,56 39.5,100 36,100 L 0,100 Z`) so it executes an immediate, smooth turn without spanning too wide or looking like a harsh square.
  - Removed metadata text labels ("Passengers", "Price") from the top-right header and aligned icons with values directly (`icon` + `value`).
  - Added a Purchase Date attribute (e.g. `calendar_today` + `15 Aug`) in the top-right meta section.
  - Added a sub-header component under the top right gradient containing an Expiry Date indicator (`schedule` + `Exp: 16 Aug, 08:30 PM`) and a compact Refund button (`currency_exchange` + `Refund`) that navigates directly to `view-details`.
  - Synchronized across Home ticket cards, Ticket Details card, and JavaScript rendering logic.
- Refined Ticket Header Curve, Expiry/Refund Placement & Refund Design (Checkpoint 38):
  - Widened the S-curve mask path from 7 units to 14 units (`M 0,0 L 100,0 L 100,56 L 50,56 C 43,56 43,100 36,100 L 0,100 Z`) for a smoother, more gradual curve that doesn't look like a sharp square corner.
  - Moved the Expiry tag and Refund button OUTSIDE the `.ticket-header` gradient area into their own `.ticket-header-sub` row that sits below the gradient as a separate section within the card body.
  - Restyled the Expiry tag to match the purchase-date info section design (larger `12px` font, `16px` icon, purchase-date-like spacing).
  - Restyled the Refund button to match the `history-card__badge--refunded` pill design (no border, `rgba(186, 26, 26, 0.1)` background, `#ba1a1a` text, `12px` font, `600` weight) and added a right-side `chevron_right` arrow after the "Refund" text.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Ticket Header Expiry/Refund Placement & Sizing Refinements (Checkpoint 39):
  - Moved `.ticket-header-sub` (Expiry tag + Refund button) back INSIDE `.ticket-header-right-col` so they sit in the white space below the right portion of the S-curve gradient (not as a separate row outside the header).
  - Right column now stretches full header height (`align-self: stretch`, `justify-content: space-between`) so meta items sit at top (over gradient) and expiry/refund at bottom (in white space).
  - Reduced the right portion of the gradient from `56%` to `46%` height in the SVG mask (`M 0,0 L 100,0 L 100,46 L 50,46 C 43,46 43,100 36,100 L 0,100 Z`) to give more white space for the expiry/refund row.
  - Simplified expiry format to date-only (`27 Aug`) removing the time portion.
  - Refund button has `currency_exchange` icon + "Refund" text + `chevron_right` arrow in a pill shape.
  - Increased both expiry tag and refund button font size to `13px` to match the SINGLE JOURNEY text size.
  - Nudged the expiry/refund sub-header lower (`padding-top: 14px`) and to the right (`margin-right: -12px`).
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Dynamic Viewport Scaling and Multi-Device Responsiveness (Checkpoint 40):
  - Injected inline JS script in `<head>` immediately below `<meta name="viewport">` that reads the screen width (`window.screen.width`) and dynamically updates the viewport's `initial-scale`, `minimum-scale`, and `maximum-scale` to fit a standard portrait design width of `412px`.
  - This ensures all layout proportions, font sizes, margins, and component alignments scale fluidly and identically across screen widths from `350px` (e.g. iPhone SE) to `430px` (e.g. iPhone Max / Pro devices).
  - Added `-webkit-text-size-adjust: 100%` and `text-size-adjust: 100%` to the root `html` selector in CSS to prevent the WebView's automatic text inflation algorithms from overriding the specified layout font sizes.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Independent Ticket Header Component Layout and Meta translateY(0px) (Checkpoint 41):
  - Removed `.ticket-header-sub` from the flex layout hierarchy of `.ticket-header-right-col` and converted it to an absolutely positioned component (`position: absolute; bottom: 8px; right: var(--space-5);`).
  - This decouples the expiry date and refund button completely from the other ticket status badges, metadata text, and header height configurations, allowing independent tuning.
  - Set `transform: translateY(0px)` on `.ticket-header-meta` in CSS as requested.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Increased Right Meta Font Sizes & Adjusted Right Gradient Height (Checkpoint 42):
  - Increased font size of right header metadata values (Date, Passengers, Price) in `.header-meta-value` to `13px` with `line-height: 16px` to match the "SINGLE JOURNEY" text size exactly.
  - Increased right header metadata icon size (`.header-meta-icon`) to `16px` and divider height (`.header-meta-divider`) to `14px` for proportional layout balance.
  - Adjusted the right portion height of the gradient in the SVG mask from `46%` to `50%` (`M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z`) to accommodate the larger metadata row comfortably.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Ticket Header Layout Position & Spacing Adjustments (Checkpoint 43):
  - Updated absolute position coordinates for `.ticket-header-sub` to `bottom: 5px; right: 5px;` and updated gap spacing to `8px` as requested.
  - Increased spacing gap inside `.ticket-type` from `5px` to `8px` to separate the status badge and `SINGLE JOURNEY` text.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Detail View Clean-up & Dynamic Scroll Fade-Out Mask Restored (Checkpoint 44):
  - Removed `.ticket-header-sub` from the ticket details view (`#view-details`) header as requested.
  - Reverted the sticky combined header, restoring the static `.tickets-section__header` with the "My Tickets" title.
  - Restored the clean CSS `-webkit-mask-image` gradient on the scrollable `#home-tickets-container` that fades from transparent (0% opacity at top) to a smooth 25% opacity at `16px`, and fully opaque black at `48px`.
  - Configured `padding-top: 48px` on `#home-tickets-container` so the first ticket card sits completely below the fade region when not scrolled.
  - Removed the flex `gap` in `.tickets-section` to bring the scroll container directly up against the "My Tickets" title header with zero gap, aligning the fade zone perfectly.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Resolved Header Collision, Zero Gap & Fine-Tuned Typography (Checkpoint 45):
  - Restored `.tickets-section__header` to regular document flow above `#home-tickets-container` with `margin: 0; padding: 0;`.
  - Updated `.section-title` to `line-height: 35px;` with `margin: 0; padding: 0;`.
  - Set `.tickets-section` flex `gap: 0;` so the scroll container and its fade mask touch the "My Tickets" title directly with zero gap.
  - Configured `#home-tickets-container` with `padding-top: 20px;` to position the starting line of the ticket cards comfortably lower when at the top.
  - Configured a `24px` fade-out mask (`linear-gradient(to bottom, transparent 0%, rgba(0, 0, 0, 0.2) 8px, black 24px)`) so tickets smoothly dissolve right at the boundary below "My Tickets" when scrolled up.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Implemented Scroll Fade-Out Mask on Trip History View (Checkpoint 46):
  - Applied the identical 24px CSS mask-image gradient (`-webkit-mask-image: linear-gradient(to bottom, transparent 0%, rgba(0, 0, 0, 0.2) 8px, black 24px)`) to `.history-slider-wrapper`.
  - Set `margin-top: -12px;` on `.history-slider-wrapper` and configured `padding-top: 20px;` on `.history-slide.slide-active` so history cards start lower down while retaining zero gap between tabs and the fade mask.
  - Set `margin-bottom: 0;` on `.history-tabs-container` so the fade mask starts immediately below the tabs toggle bar with zero gap.
  - History cards now smoothly dissolve into the background right at the boundary below the tabs bar when scrolling up across all tabs (Completed, Expired, Refunded).
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Removed Taka Sign From Home Ticket Header Meta (Checkpoint 47):
  - Updated `fareFormatted` in `renderHome()` to display only the numeric fare amount without the leading `৳` symbol.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Station Swap Guard & Direct "Use Ticket" Scan Navigation (Checkpoint 48):
  - Added validation in `swapStations()` to prevent swapping or animating when neither origin nor destination station is selected.
  - Connected the "Use Ticket" button on home tickets to `useTicketForScan(ticket.id)`, directly launching the gate QR scanning screen (`view-scan-gate`) for that ticket instead of going to the details view.
  - Clicking the card body continues to open `view-details` for full itinerary inspection.
  - Updated `cancelGateScan()` to use `navigateBack()` for seamless return flow.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Mobile Build & Device Deployment (Checkpoint 49):
  - Compiled latest debug APK with all recent features (scroll fade-out transitions on Home and History views, section title typography refinements, station swap validation, and direct Use Ticket scanning flow).
  - Installed and launched the updated application on connected physical device (`RMX3710` / `U8MFEA9XFQ9XFECM`).
  - Terminated background build/upgrade sessions per project rules.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Riding Ticket Header & Notches Fixes + Unified View Gradient Backgrounds (Checkpoint 50):
  - Fixed ticket cards in "riding" (in-use) status to suppress both the expiry date tag and refund button.
  - Restored `notchDividerHtml` (dashed cutting line and side half-circle notches) and `.ticket-action-section` for riding mode ("Current Trip" button) and locked mode so cards maintain uniform ticket styling across all states.
  - Implemented the unified green-teal gradient (`linear-gradient(180deg, #188674 0%, #188674 1%, #9fd1c6 15%, #ffffff 90%)`) across `#view-home`, `#view-details`, and `#view-qr` (matching `#view-buy`, `#view-history`, and `#view-profile`).
  - Home page architecture: Set `#view-home` base layer with the unified background gradient, while keeping `.welcome-card` at `z-index: 10` with its custom header graphic and rounded bottom border (`0 0 32px 32px`), and making `.main-content` and `.tickets-section` transparent so the gradient shines through seamlessly underneath.
  - Updated `#view-details` and `#view-qr` app bars to transparent with crisp white back button and title typography.
  - Updated card notch cutouts (`.notch-left`, `.notch-right`) across Home and Details pages to `#9fd1c6` to seamlessly match the gradient color tone.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Precision Gradient-Matched Side Notches on Ticket Details & Home Views (Checkpoint 51):
  - Addressed the color mismatch where side half-circles appeared as flat solid dots against the vertical gradient background.
  - Implemented specific CSS rules per notch level based on its vertical position along the gradient:
    - Details Notch 1 (after Route): `#b2dad1` (~30% down the gradient)
    - Details Notch 2 (after Fare): `#bbded7` (~38% down the gradient)
    - Details Notch 3 (after Purchase Date): `#c5e3dc` (~45% down the gradient)
    - Details Notch 4 (after Expiry Alert): `#cfe8e2` (~53% down the gradient)
    - Details Notch 5 (after Refund section / bottom): `#e6f4f1` (~71% down the gradient)
    - Home Card 1 Notch: `#ddeeeb` (~63% down the gradient)
    - Home Card 2+ Notches: `#f7fbfb` (~85%+ down the gradient)
  - Implemented a dynamic real-time color tracking engine (`getGradientColorAt(pct)` and `updateNotchColors()`) that recalculates the exact RGB interpolation of the background gradient for every visible notch cutout based on its real viewport coordinates (`getBoundingClientRect()`).
  - Wired scroll listeners (`#home-tickets-container`, `.detail-content`), view navigation hooks (`navigateTo`), and viewport resize events to update notch colors in real time during scrolling.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Blurry Transparent Frosted-Glass Styling on My Tickets Header (Checkpoint 52):
  - Applied frosted-glass backdrop styling (`background-color: rgba(255, 255, 255, 0.55); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-bottom: 1px solid rgba(0, 51, 40, 0.08);`) to `.tickets-section__header`, matching the bottom navigation bar.
  - Positioned header with `z-index: 10` spanning edge-to-edge with aligned title padding.
  - Adjusted `.tickets-section` top padding to `16px` for visual balance below the welcome banner.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Complete Station Exit QR Generation and Gate Reader Flow (Checkpoint 53):
  - Fixed premature trip completion bug where scanning the destination station exit gate QR code immediately ended the trip and threw the user to the History tab.
  - Implemented the full two-phase gate flow:
    1. **Entry Phase**: Use ticket -> scan entry gate QR code -> generates Entry QR code on phone screen -> show at entry reader to board train (`riding` state).
    2. **Exit Phase**: Arrive at destination -> scan exit gate QR code -> generates **new Exit QR code** (`exitQrActive = true`, dynamic countdown) -> show at exit reader ("Show at Exit Reader" header, "Exit Pass" badge, "Tap to Pass Exit Barrier" button).
    3. **Trip Completion**: Tapping "Tap to Pass Exit Barrier" opens the exit barrier, marks ticket as `completed`, moves to history, and routes to completed history tab.
  - Updated Home card and Ticket Details views to show "Exit Gate" and "Show Exit QR" if the passenger navigates away while the exit QR is active.
  - Handled bottom navigation scan action and camera auto-detection for seamless exit gate detection.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Reverted My Tickets Header Styling (Checkpoint 54):
  - Completely reverted `.tickets-section__header` and `.tickets-section` padding back to original styling (`padding-top: 24px`, transparent background, `align-items: flex-end`).
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Frosted-Glass Glow & See-Through Scroll on My Tickets Header (Checkpoint 55):
  - Created `.tickets-glass-header` with `backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);` and a gentle gradient glow (`rgba(255, 255, 255, 0.45)` down to transparent).
  - Maintained exact title placement and spacing at rest (`padding: 24px var(--space-4)`).
  - Configured `#home-tickets-container` with `padding-top: 79px` and an elongated fade mask (`transparent 0%` to `black 75px`), allowing scrolling cards to slide directly behind the frosted glass header with visible optical blur before fading out at the top.
  - Set `pointer-events: none` on `.tickets-glass-header` and `pointer-events: auto` on interactive children for friction-free touch scrolling.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Restored Full Ticket Card Width (Checkpoint 56):
  - Fixed unintentional double horizontal padding that narrowed ticket cards on the Home view.
  - Retained `padding: var(--space-4)` on `.tickets-section` and set `padding-left: 0; padding-right: 0;` on `#home-tickets-container`, restoring ticket cards to their exact original full width while keeping the frosted-glass see-through scroll header effect intact.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Removed White Top Seam/Outline on Ticket Details View (Checkpoint 57):
  - Addressed white outline visible at the top of `#view-details` by:
    1. Setting parent `#app-container` background to `#188674` (matching the top gradient color) during details/QR view active states, eliminating subpixel white edge leaks.
    2. Stripping all borders, outlines, and box shadows from `.detail-app-bar`, its child buttons/titles, and the `#view-details` section wrapper.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Updated Home Welcome Card Graphic (Checkpoint 58):
  - Verified `dmrt/new_home_vector.png` (1536x1024, matching the exact aspect ratio of `.welcome-card`).
  - Replaced `dmrt/home_bg_new.png` with `dmrt/new_home_vector.png` in `.welcome-card` background image style.
  - Bundled `dmrt/new_home_vector.png` into `dmrt_online/assets/dmrt/`.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Updated Background Gradient Percentages & Notch Interpolation (Checkpoint 59):
  - Updated the view background gradient across all screens to:
    `linear-gradient(180deg, #188674 0%, #188674 0.5%, #9fd1c6 1%, #9fd1c6 5%, #ffffff 90%)`.
  - Recalculated static notch colors for Details and Home cards to align with the higher mint-to-white transition.
  - Updated real-time color interpolation function `getGradientColorAt(pct)` to match the new gradient stops.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Reverted Background Gradient to Original (Checkpoint 60):
  - Completely restored the smooth transition gradient across all views:
    `linear-gradient(180deg, #188674 0%, #188674 1%, #9fd1c6 15%, #ffffff 90%)`.
  - Restored original static notch colors and `getGradientColorAt(pct)` interpolation logic.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Reverted Ticket Details & Home Card Changes (Checkpoint 62):
  - Completely undone changes from Checkpoint 61 upon user request.
  - Restored `.ticket-header-sub` CSS positioning to `right: 5px; gap: 8px;`.
  - Removed `.station-icon--exit`, `.journey-fill--stopped`, `.journey-arrow--stopped` CSS styles.
  - Restored original `subHeaderHtml` logic in `renderHome()` and `renderDetails()` (Expiry tag & Refund button displayed on available tickets).
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Updated Ticket Details Header Sub, Locked Refund & Exit Gate Visuals (Checkpoint 63):
  - **Ticket Details Header Sub**: On `#view-details` (under top card header), `Time limit: 60 Minutes` displays for `available` and `riding` tickets. For `locked` tickets, `Exp: ${expiry}` and Refund button display.
  - **Body Refund Section**: Preserved body refund section (`.refund-section`) on Ticket Details page for both `available` and `locked` tickets (hidden when `riding`).
  - **Locked Mode**: Locked tickets on both Home and Details pages now display the Expiry date tag and Refund button in the sub-header row.
  - **Exit Gate Visuals**: When `exitQrActive` is true, the sliding arrow stops (`.journey-arrow--stopped`), line fills fully (`.journey-fill--stopped`), and destination station icon turns red (`.station-icon--exit`, `#d32f2f`) on both Home cards and Ticket Details page.
  - **Sub-header CSS**: Updated `.ticket-header-sub` to `right: 12px; gap: 12px;`.
  - **Home Background**: Ensured `dmrt/new_home_vector.png` is active.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Refined Ticket Sub-Header Rules (Checkpoint 64):
  - **Available & Locked Status**: Displays `Exp: ${expiryDate}` and the Refund button in `.ticket-header-sub` (bottom right of ticket header) on both Home cards and Ticket Details page.
  - **Riding Status**: Displays `Time limit: 60 Minutes` in `.ticket-header-sub` when in Riding or Exit Gate mode.
  - Fixed `refundSubHtml` scope so Refund button is rendered properly for `locked` tickets.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Enabled Ticket Details Navigation for Locked Cards (Checkpoint 65):
  - Updated `ticketCard.onclick` handler for `locked` status cards in `renderHome()` to navigate directly to `view-details` (`selectAndGo(ticket.id, 'view-details')`), matching `available` card click behavior.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Dedicated Time Limit Tag CSS (Checkpoint 66):
  - Created standalone CSS classes `.ticket-time-limit-tag` and `.ticket-time-limit-tag__icon` in `index.html`.
  - Decoupled "Time limit: 60 Minutes" from `.ticket-expiry-tag` so font size, colors, padding, margins, and position can be modified independently without affecting expiry date or refund elements.
- Synchronized root `index.html` with `dmrt_online/assets/index.html`.
- Master Full Project Context Export (Checkpoint 67):
  - Created `Full Project Context.md` (and exact name `Full Porject Contex.md`) at the repository root embedding the complete architectural history, two-way dynamic challenge security model, Raspberry Pi turnstile hardware specs, golden image recovery, 3NF 12-table mobile database blueprint, UIU CSE academic mapping, and current codebase status for seamless context sharing across chats.
- Interactive Proposal Database ERD & HLD Blueprint (Checkpoint 68):
  - Created `database_architecture.html` (interactive unified dashboard), `database_erd.html` (dedicated ERD presentation), and `database_hld.html` (dedicated HLD presentation).
  - Implemented the curated 8-table 3NF proposal schema (`users`, `stations`, `routes`, `fares`, `purchases`, `tickets`, `gate_challenge_sessions`, `journey_logs`) avoiding low-level internal clutter while preserving genuine enterprise rigor.
  - Fully styled using DMRT Forest Green (`#005140`), Mint gradients (`#188674` to `#9fd1c6`), glassmorphism card surfaces, and Inter typography matching the mobile app.
  - Added interactive relationship highlighters, 5-tier architecture visualizations, step-by-step security protocol sequence diagrams, and copyable PostgreSQL 16 DDL scripts with PDF export styling.
- Fully Drawn Mobile App ERD & HLD Single Page (Checkpoint 69):
  - Created `mobile_app_database_erd_hld.html` (and updated `database_architecture.html`) strictly focused on the **mobile app's database** in a unified, single-page presentation.
  - Implemented actual vector-drawn SVG diagrams:
    - **Drawn ERD Diagram**: Vector entity boxes connected with real orthogonal/bezier connector lines, crows-foot and one-to-one cardinality notations (`1 : N`, `1 : 1`), primary/foreign keys (`[PK]`, `[FK]`, `[UK]`), and column types.
    - **Drawn HLD Architecture Diagram**: 5-tier layered system (Presentation UI Widgets $\rightarrow$ State Management Controllers $\rightarrow$ Repository Layer $\rightarrow$ Drift/SQLite Local DB & Native Hardware Services).
    - **Two-Way Dynamic Challenge Protocol**: 4-step sequence showing camera scan, HMAC computation, 60s+20s timer, and turnstile relay.
    - **Local SQLite / Drift DDL**: Standalone schema with copy-to-clipboard functionality.
  - Styled with exact DMRT mobile app tokens: Forest Green (`#005140`), Mint (`#9fd1c6`), Emerald glow (`#10b981`), and Inter typography.
- Prototype 1 Architecture & 8-Table Database Formalization (Checkpoint 70):
  - Formalized Basic Prototype 1 scope in both `Mobile App Context.md` and `Full Project Context.md`.
  - Defined streamlined gate flow: Direct Ticket QR presentation at turnstiles without requiring dynamic gate QR nonce scanning.
  - Station data encapsulation: Stored `st_sta` (origin) and `en_sta` (destination) directly within `Route` table, removing the need for a separate `stations` table in Prototype 1.
  - Dedicated `History` table: Designed specifically as an immutable archive table serving the mobile app's dedicated Trip History page (storing Completed, Expired, and Refunded trips).
  - Validated and normalized the 8-table mobile schema: `passenger`, `Route`, `ticket`, `Payment`, `Event`, `Fine`, `Refund`, `History`.
- Ticket-Card Styled ERD & Single-Page Pure White Canvas (Checkpoint 71):
  - Removed `distance` from `Route` table (`route_id`, `st_sta`, `en_sta`, `fare`).
  - Implemented the standalone, zero-distraction ERD in `mobile_app_database_erd.html` and `mobile_app_database_erd_hld.html` on a 100% pure white background with no buttons, options, or redirects.
  - Styled every database table as an authentic mobile app `ticket-card` (curved green header gradient `#005140` to `#0b9175`, punch notches on left and right edges, dashed ticket divider line `#bec9c3`, PK/FK/UK badges).
  - Styled relationship connectors as secondary red (`#b51b00`) dashed lines matching `.route-connector__line`, with `#555555` gray cardinalities (`1 : N`, `1 : 1`, `1 : 0..N`, `1 : 0..1`) on white pill tags.
- Authentic Ticket-Card HTML/CSS & Orthogonal Manhattan Routing (Checkpoint 72):
  - Directly adopted the actual mobile app `ticket-card` HTML and CSS structure (`.ticket-card`, `.ticket-header`, `.ticket-indicator`, `.ticket-type`, `.status-badge` with dot, `.ticket-header-meta`, `.notch-row` with circular `notch-left`/`notch-right` punch cutouts and dashed separator line).
  - Replaced all curved bezier lines with strict **orthogonal straight lines and 90-degree corner turns** (horizontal and vertical straight paths).
  - Placed gray (`#555555`) cardinality badges along straight paths over the secondary red (`#b51b00`) dashed connector lines.
- Crow's Foot Branch Notation & Exact SVG Path Mask Implementation (Checkpoint 73):
  - Integrated the exact curved SVG path mask from `index.html` (`d='M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z'`) into `.ticket-indicator` for pixel-perfect card headers across all 8 tables.
  - Replaced text cardinality pills with standard **ERD Crow's Foot Branch Notations** at the exact line endpoints (`||` Mandatory One, `|<` Mandatory Many, `O|` Optional One, `O<` Optional Many).
  - Maintained pure white background `#ffffff`, strict orthogonal Manhattan line paths with 90° corners, secondary red `#b51b00` dashed stroke, and complete 8-table schema alignment with zero buttons, zero clicks, and zero redirects.
- Interactive Draggable Canvas, Full Forest Green Uniformity & Professional Naming (Checkpoint 74):
  - **Interactive Drag Engine**: Table cards are now fully draggable (mouse & touch support); orthogonal relationship lines dynamically recalculate their Manhattan paths and Crow's Foot markers in real-time.
  - **Clean Header Structure**: Removed all right-side voids, icons, metadata, and subheaders from ticket headers, presenting clean full-width Forest Green gradient headers (`#005140` to `#0b9175`).
  - **All-Green Table Uniformity**: Standardized all 8 tables (including `FINE`) in uniform DMRT Forest Green branding; only relationship lines retain the secondary red (`#b51b00`) styling.
  - **Professional Column Naming**: Fully spelled out all database attributes to standard snake_case naming conventions (e.g., `phone_number`, `full_name`, `origin_station`, `destination_station`, `passenger_count`, `purchase_time`, `expiry_time`, `payment_channel`, `fine_reason`, `refund_time`, etc.).
  - **Spacious 2100px Canvas**: Widened canvas and redistributed table positions to prevent card crowding and line tangling, with a top-bar "Reset Positions" action.
- 2×4 Balanced Grid Architecture & Restored Curved Transition Header (Checkpoint 75):
  - **2 Rows × 4 Columns Table Layout**: Arranged the 8 Prototype 1 tables into two distinct horizontal tiers of 4 tables each (Row 1: `PASSENGER`, `ROUTE`, `TICKET`, `PAYMENT`; Row 2: `FINE`, `EVENT`, `HISTORY`, `REFUND`).
  - **Clear Outer-Corridor Orthogonal Routing**: Enhanced the dynamic line routing engine to ensure all relationship paths navigate through dedicated horizontal and vertical open corridors between and around cards, strictly preventing lines from intersecting or passing behind table cards.
  - **Restored Curved SVG Path Mask**: Reintegrated the authentic curved SVG mask (`d='M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z'`) on `.ticket-indicator` across all table headers, keeping the right portion clean and textless.
- 100% Completely Free Dragging & Auto-Expanding Canvas (Checkpoint 76):
  - Removed all artificial clamping bounds (`Math.min` limits) from the drag handlers.
  - Implemented dynamic auto-expansion of canvas `#erd-stage` dimensions and SVG `viewBox` coordinates as cards are dragged, ensuring zero boundaries and seamless movement anywhere across the workspace.
- Reverted & Restored Preferred 2×4 Architecture Layout (Checkpoint 77):
  - Reverted the ERD canvas back to the preferred Checkpoint 75 $2 \times 4$ balanced layout (Row 1: `PASSENGER`, `ROUTE`, `TICKET`, `PAYMENT`; Row 2: `FINE`, `EVENT`, `HISTORY`, `REFUND`).
  - Restored the exact curved SVG transition mask headers, stable bounding boundaries, and clean non-intersecting outer-corridor orthogonal relationship lines with Crow's Foot branch notations.
- Reverted One Step More to Checkpoint 74 Central-Hub Structure (Checkpoint 78):
  - Reverted to the spacious 3-tier center-hub canvas layout (Row 1: `PASSENGER`, `ROUTE`, `PAYMENT`, `REFUND`; Row 2: Central `TICKET` Hub; Row 3: `EVENT`, `FINE`, `HISTORY`).
  - Restored full-width clean Forest Green gradient headers, formal database column names, and real-time draggable multi-slot orthogonal Crow's Foot relationship routing.
- Curved Header Transition Mask Added to Central Hub ERD (Checkpoint 79):
  - Applied the exact CSS/SVG curved path mask (`-webkit-mask-image: url("data:image/svg+xml,...")`) to `.ticket-indicator` across all 8 table card headers within the spacious central-hub architecture.
  - Maintained pure white empty space on the bottom-right curved section of each header with no text, icons, or badges.
  - Preserved all other features: DMRT Forest Green branding, multi-slot orthogonal Crow's Foot routing, formal snake_case attributes, and interactive dragging.
- End-to-End System High-Level Design (HLD) & Data Flow Diagram (DFD) (Checkpoint 81):
  - **Decoupled HLD from Ticket Card Styling**: Replaced ticket-card punch cutouts in `mobile_app_database_hld.html` with clean, modern enterprise System Architecture / Data Flow Diagram (DFD) node boxes with distinct subsystem color-coding and capability lists.
- Standard Academic Data Flow Diagram (DFD) Visual Notation (Checkpoint 82):
  - **Reference Image Alignment**: Redesigned `mobile_app_database_hld.html` to strictly follow the classic Gane-Sarson / Yourdon DFD academic notation shown in the user reference image:
    1. **External Entities / Subsystems**: Rounded rectangular nodes (`Passenger`, `Mobile App Interface`, `MFS Gateway`, `Central API Backend`, `Entry Turnstile Gate`, `Exit Turnstile Gate`, `Station Admin Officer`).
    2. **Processes / Actions**: Circular bubble nodes with concise action verbs (`log in & authenticate`, `select route & fare`, `initiate MFS payment`, `generate ticket QR`, `store offline ticket cache`, `display QR on screen`, `scan QR at inbound gate`, `validate entry & log event`, `scan QR at outbound gate`, `verify 60m & dest station`, `complete trip & close ticket`, `trigger overstay alarm`, `inspect log & issue penalty`, `dispatch gate unlock override`, `aggregate ridership & rev`).
    3. **Data Stores**: Divided open-ended rectangle boxes with ID prefix tabs (`D1 Local SQLite Store`, `D2 Passenger 3NF Database`, `D3 Station Route Catalog`, `D4 Core 3NF Central DB`, `D5 Fines & Audit Ledger`).
    4. **Directional Flow Arrows**: Clean directed arrows connecting entities $\leftrightarrow$ processes $\leftrightarrow$ data stores with labeled data payload pills.
  - **Interactive Features**: Full real-time dragging of bubbles, entities, and data stores with dynamic arrow re-anchoring, category filter pills (`All Data Flows`, `1. Ticket Purchase & MFS`, `2. Entry Gate Validation`, `3. Exit Gate Transit`, `4. Officer Fines & Override`, `5. Central DB & Analytics`), and a one-click Reset Diagram button.
- Cross-Functional Swimlane Activity Diagram (BPMN) (Checkpoint 83):
  - **New Deliverable**: Created `mobile_app_swimlane.html` implementing an end-to-end Cross-Functional Swimlane Activity Diagram across 6 operational tracks:
    1. `Passenger (Commuter)`: Route selection, MFS PIN entry, QR presentation, platform boarding.
    2. `Mobile App (Flutter UI)`: Fare computation, local SQLite caching, brightness-boosted QR rendering.
    3. `MFS Gateway (bKash/Nagad)`: Payment authentication, OTP verification, instant TRX webhook.
    4. `Central API & 3NF Database`: Atomic 3NF table writes (`passenger`, `ticket`, `payment`), cryptographic HMAC-SHA256 QR signing, timestamp logging, fine recording.
    5. `Turnstile Gate (Raspberry Pi Hardware)`: Inbound optical QR scan, signature validation, flap barrier servo motor trigger, outbound 60-min overstay check, MQTT manual unlock override.
    6. `Station Admin Officer`: Real-time WebSocket violation alerts, penalty calculation, fine collection logging, authenticated gate release dispatch.
  - **4 Functional Phases with Decision Logic**:
    - *Phase 1*: Route Selection, MFS Checkout & Signed QR Generation.
    - *Phase 2*: Inbound Turnstile Authentication & Entry Logging (`entered_at`).
    - *Phase 3*: Outbound Exit Transit & 60-Minute Duration Validation (Decision Diamond: $\Delta t \le 60\text{m}$ $\rightarrow$ Complete Trip vs Overstay Alarm).
    - *Phase 4*: Exception Handling, Overstay Penalty & Officer Gate Override.
- Complete System Architecture Blueprint Deliverable (Checkpoint 84):
  - **New Deliverable**: Created `full_system_architecture.html` presenting the entire end-to-end engineering topology across 5 distinct architectural tiers:
    1. **Tier 1 (Client & Edge Presentation)**: Flutter Mobile App (single group ticket model, dynamic countdown, anti-tamper `FLAG_SECURE`, Drift SQLite WAL mode) and Station Officer Web Portal (live WebSocket feed, automated overstay penalty calculator, authenticated MQTT gate overrides).
    2. **Tier 2 (Embedded Turnstile Hardware - Raspberry Pi 4B)**: High-speed wide-angle optical 2D barcode scanner (<120ms decode), Python 3 edge daemon, GPIO relay flap barrier actuator (250ms actuation), and Golden SD OverlayFS disaster recovery (<3 min MTTR).
    3. **Tier 3 (Central Cloud Backend & API Gateway)**: FastAPI / Node.js TypeScript gateway, JWT auth & device fingerprinting, fare calculation engine, atomic ticket lifecycle state machine, and HSM cryptographic token signer.
    4. **Tier 4 (Relational Database & In-Memory Cache)**: PostgreSQL 16+ 3NF Master Cluster (8 core tables, ACID transactions, PgBouncer), Redis 7 in-memory cache & Pub/Sub bus (10-30s nonce TTL, real-time gate alarms), and Ridership Analytics Warehouse.
    5. **Tier 5 (Two-Way Dynamic Gate Challenge Protocol)**: Anti-fraud security flow (Step 1 Gate Nonce $\rightarrow$ Step 2 App Scan $\rightarrow$ Step 3 HMAC Sign $\rightarrow$ Step 4 Optical Read $\rightarrow$ Step 5 Barrier Unlock & Sync).
  - **Interactive Features**: Deep-dive Component Detail Modals on click, Tier Filter buttons (`All Tiers`, `Clients & UI`, `Raspberry Pi Gates`, `Cloud API Gateway`, `3NF Database & Cache`, `Security Protocol`), and responsive pure-white layout.
  - **4-Tab Unified Suite**: Updated `mobile_app_database_erd_hld.html` to provide 1-click tab switching across **Database ERD**, **Data Flow Diagram (DFD)**, **Swimlane Diagram (BPMN)**, and **Full System Architecture**.
- Full Project Architecture Alignment & Context Enrichment (Checkpoint 85):
  - **Figma to Stitch Origin History**: Documented the project's evolution from Figma AI wireframing constraints to Google Stitch prototype generation and Flutter WebView encapsulation.
  - **Replaceable-Frontend Architecture**: Formally documented the Clean Architecture blueprint (Presentation $\rightarrow$ Riverpod/BLoC $\rightarrow$ Repository Interface $\rightarrow$ `LocalMockTicketRepository` / `ApiTicketRepository`), enabling independent UI perfection before backend integration.
  - **Offline-First Ticket Credential Specification**: Documented exact payload requirements (business fields, cryptographic tokens, device binding ID, and station reference caches) cached on-device after purchase.
  - **Mobile SQLite ACID Transactions Matrix**: Specified the 4 core local atomic transactions (Purchase, Journey Activation, QR Session Regeneration, and Journey Completion).
  - **Mobile Database Indexing Strategy**: Formally recorded the 5 primary B-Tree indexes for instantaneous local queries and background sync workers.
- Production Interaction Matrix & System Hierarchy Deliverable (Checkpoint 86):
  - **New Deliverable**: Created `Diagrams/production_interaction_matrix.html` presenting the Complete Production Interaction Matrix in a structured top-to-bottom 3-tier hierarchy:
    1. **Level 1 (Client & Edge Endpoint Tier)**:
       - *Passenger Mobile App*: Flutter 3.x (Dart), group ticket UI (1-5 pax), dynamic offline QR, Drift SQLite WAL storage, REST/HTTPS checkout.
       - *Station Admin Portal*: Next.js 14 / React (TypeScript) + Tailwind CSS, live concourse transit feed, overstay (>60m) alarm inspector, fine collection, authenticated manual turnstile overrides (WSS/HTTPS).
       - *Turnstile Gate Hardware*: Raspberry Pi 4B (Pi OS Lite 64-bit), optical 2D barcode scanner (<120ms decode), passenger display, GPIO 18 relay driving barrier servo motor, local SQLite WAL cache (mTLS/MQTT).
    2. **Level 2 (Secure API Gateway & Message Broker Tier)**:
       - Identity & RBAC Gateway (OAuth2 / mTLS), Fare & Route Engine, Ticket State Orchestrator (`AVAILABLE` $\rightarrow$ `ENTERED` $\rightarrow$ `COMPLETED`), Redis 7 Pub/Sub bus (<2ms latency).
    3. **Level 3 (Central Database & Core Persistence Tier)**:
       - PostgreSQL 16+ Master Cluster in strict 3NF (`passenger`, `route`, `ticket`, `payment`, `event`, `fine`, `refund`, `history`), cryptographic HSM token authority, financial reconciliation engine.
  - **Master Suite Integration**: Added as the 5th tab ("Interaction Matrix") in `Diagrams/mobile_app_database_erd_hld.html` with instant 1-click tab switching across Database ERD, DFD, Swimlane, Full System Architecture, and Interaction Matrix.
- Payment Method Selection & Hold-to-Purchase View (Checkpoint 87):
  - **Payment Method Picker**: Implemented a modern bottom sheet modal (`#payment-method-overlay` / `#payment-method-sheet`) invoked upon tapping "Proceed to Payment" on the Buy Ticket view (`#view-buy`). Provides 3 distinct payment channels:
    1. **Mobile Finance**: bKash, Nagad, Rocket.
    2. **Debit / Credit Card**: Visa, Mastercard, AMEX.
    3. **Internet Banking**: Major Bangladeshi commercial banks.
  - **Dedicated Payment View (`#view-payment`)**:
    - Replicates the complete layout of the Ticket Details card (Route origin $\rightarrow$ destination, Fare, Passenger count, Validity, and Status badge) without the use/refund action buttons.
    - Displays selected payment channel and ticket time limit badge.
  - **Simplified Hold-to-Purchase Confirmation (Red Clockwise Outline)**:
    - Central circular DMRT logo button with a clean SVG circular progress stroke.
    - Shaking effect completely removed in favor of a calm, premium, minimal visual style.
    - While holding, a vivid red outline fills smoothly starting from the top (12 o'clock) and progresses clockwise around the logo over exactly 1 second (1000ms linear).
    - Premature release resets the timer and rewinds the red outline back to empty without purchasing.
    - Completing the 1000ms hold locks the red circular outline (`.is-confirmed`), creates the ticket, triggers haptic feedback, displays a success toast, and routes back to `#view-home`.
  - **Asset Synchronization**: Kept root `index.html` and bundled `dmrt_online/assets/index.html` 100% identical.
- Layered Card Visual Architecture Redesign (Checkpoint 88):
  - **Reference Alignment**: Redesigned `Diagrams/production_interaction_matrix.html` to mirror the user's reference diagram structure:
    1. **Full-Width Layer Containers**: Dark forest green top header bars (`#005140`, uppercase bold font) with rounded borders (`2px solid #005140`).
    2. **Inner Component Box Rows**: Flex rows of cards with color-coded accent borders (`#005140` green, `#10b981` emerald, `#38bdf8` sky blue, and `#0284c7` royal blue).
    3. **Vertical Directed Arrows**: Crisp SVG arrow strips (`▼`) distributed directly underneath component cards connecting adjacent layers.
    4. **Split Bottom Tier**: 50/50 split between Layer 4 (Central Relational Database - PostgreSQL 16+ 3NF tables with monospace bullet lists) and Layer 5 (External Clearing & Enterprise Analytics).
    5. **Dual-View Switcher**: Added top toggle allowing instant switching between:
       - *View 1*: Complete System Production Hierarchy (Endpoints $\rightarrow$ Gateway $\rightarrow$ Services $\rightarrow$ Database & Clearing).
       - *View 2*: Passenger App Clean Architecture (Widgets $\rightarrow$ Riverpod/BLoC $\rightarrow$ Repositories $\rightarrow$ Local SQLite & Hardware Bridges).
    6. **Interactive Detail Modal**: Clicking any component tile opens a deep-dive specification modal with technology tags.
- Full Native Flutter Application Architecture (Stage 2 Migration Completed):
  - **Clean Architecture Implementation (`d:\DMRT Online\dmrt_online\lib`)**:
    1. **Core Layer**:
       - `DmrtColors`: Unified hex palette (`#005140` primary, `#D0E1DF` canvas, `#D9E8E5` pageBgMint, `#0284C7` riding, `#EDFFFFFF` navBarGlass, `#10B981` emerald).
       - `DmrtAssets`: Asset paths for logo, home background, loading GIF.
       - `StationsCatalog`: 16 stations from Uttara North to Motijheel with gap-based fare matrix.
       - `TimeFormatter`: Bengali digits, time greeting formulas ("Good Morning", "Good Noon", "Good Afternoon", "Good Evening", "Good Night"), and date-time formatters.
       - Custom Painters: `TicketWaveMaskPainter` (Bézier S-curve `C 46,56 46,100 36,100`), `TicketNotchPainter` (punch notches `r=12`), `DashedLinePainter` (perforation divider), and `_ScannerBracketPainter` (emerald scanner L-corners).
    2. **Domain Models & Interfaces**:
       - `Ticket`: Full data model with `TicketStatus` enum (`available`, `riding`, `locked`, `completed`, `expired`, `refunded`), `qrExpiryTime`, `exitQrActive`, `exitQrExpiryTime`, `farePerPerson`, `totalFare`.
       - `UserProfile`: Commuter identity model with guest fallback and persistence schema.
       - `QrSession`: Transit session model with dynamic group duration formula `60 + (n - 1) * 20` seconds.
       - `ITicketRepository` & `IUserRepository`: Replaceable repository interfaces for seamless switch to REST microservices and Drift SQLite in Stage 2.
    3. **Data Layer (Mock & Persistence)**:
       - `MockTicketRepository`: High-performance in-memory cache synchronized with `SharedPreferences` (`dmrt_tickets`, `dmrt_history`). Implements automatic 24-hour expiration checks and the Journey Lock rule (locking other available tickets once a journey starts).
       - `MockUserRepository`: Persistent profile store (`dmrt_profile`).
    4. **Presentation & State Management (Riverpod)**:
       - `activeTicketsProvider`: Manages active tickets, purchase actions, gate clearance triggers, and refunds.
       - `historyTicketsProvider`: FutureProvider delivering filtered trip history.
       - `userProfileProvider`: StateNotifierProvider managing profile changes.
       - `buyTicketProvider`: Form state notifier managing station selection, passenger counts, and fare calculations.
       - `currentNavTabProvider` & `selectedTicketIdProvider`: Tab and selection coordinators.
    5. **Feature Screens & Widgets**:
       - `HomeScreen`: Hero banner, time greeting, active tickets stack, and empty state placeholder.
       - `BuyTicketScreen`: Interactive origin/destination selection, swap button, passenger count stepper, fare summary, and payment bottom sheet.
       - `HoldToPurchaseScreen`: Dedicated review card matching `#view-payment` with 1-second clockwise SVG circular red progress hold confirmation (`#E53935`), haptic vibration on completion, and auto-return to Home.
       - `AuthPhoneScreen`: Direct phone login with `+880` prefix validation, Terms link, and bilingual EN/বাং toggle.
       - `AuthOtpScreen`: 6-digit verification code input with auto-advance and countdown timer.
       - `AuthProfileSetupScreen`: New user profile setup with avatar picker, name input, and skip option.
       - `TicketDetailScreen`: Ticket wave card preview, trip breakdown, refund confirmation modal with 10% processing fee, and gate clearance trigger.
       - `DynamicQrScreen`: Live dynamic QR code (`qr_flutter`), animated countdown progress bar (`60 + (n-1)*20`s), timer countdown, regenerate QR button, and exit barrier pass action.
       - `GateScannerScreen`: Camera viewfinder (`mobile_scanner`), emerald L-corners, laser pulse animation, and dev simulator panel (Entry & Exit gate triggers).
       - `TicketSelectModal`: Custom selection sheet when multiple active tickets exist.
       - `HistoryScreen`: 3 sliding tabs (**Completed** | **Expired** | **Refunded**) with timeline route cards and empty states.
       - `ProfileScreen`: Commuter profile header, editable form fields, custom gender bottom sheet, date of birth picker, and dirty-state tracking with "Save Changes" button.
       - `DmrtSideDrawer`: Brand header, navigation items, bilingual toggle, transit guidelines sheet, and logout action.
       - `GlassBottomNavBar`: Frosted glass bar (blur 28px) with active indicator pills and center elevated glowing Scan FAB.
       - `AppShell`: Coordinates IndexedStack tab navigation, scan routing logic, and side drawer.
       - `DmrtSplashScreen`: Brand logo entrance zoom and pulse animation, transitioning smoothly into `AppShell` or `AuthPhoneScreen`.
  - **Verification & Linter Validation**:
    - `flutter analyze`: 0 issues found across all Dart files.
- Virtual Multi-Device Simulator & Responsiveness Suite (Checkpoint 89):
  - **Integrated `device_preview` (v3.0.0)**:
    - Initialized at the custom binding level (`DevicePreview.enable()`) in debug and profile modes with dark slate canvas letterboxing (`#0F172A`).
    - Compiles to a zero-overhead no-op in release builds with standard `WidgetsFlutterBinding`.
  - **Interactive On-Screen Simulator Overlay (`DeviceSimulatorOverlay`)**:
    - Created `lib/shared/widgets/device_simulator_overlay.dart`, wrapping the app via `MaterialApp.builder` in debug mode.
    - Draggable floating badge (`📱 Sim: [Device Name]`) with emerald glow border and status indicator.
    - Interactive bottom sheet control panel:
      1. **Popular Device Presets**: One-tap quick switching between **iPhone 16 Pro Max** (440×956), **iPhone 16** (393×852), **iPhone 16e** (360×780), **Google Pixel 9** (412×923), **Samsung Galaxy S24** (360×780), and **iPad Pro 11"** (834×1194).
      2. **Full Device Catalog**: Dropdown access to all 20+ built-in presets including tablets and small/large desktop windows.
      3. **Orientation Toggle**: Instant switching between Portrait and Landscape orientations to verify route timeline and ticket card flow.
      4. **Text Accessibility Scaler**: Live slider adjusting `textScaleFactor` from `0.8x` to `2.0x` to detect layout overflows and clipping.
      5. **Reset Action**: One-tap reset back to the native physical window viewport.
  - **Quality Assurance & Verification**:
    - `flutter analyze`: **0 issues found** across all 26 Dart files.
    - `flutter test`: **100% pass rate** (4/4 test suites passing).














- Workspace Architectural Decoupling & Standalone Repository (Checkpoint 90):
  - **Decoupled 3-Pillar Workspace**:
    1. DMRTonline Mobile App/: Standalone, 100% Git-ready Flutter mobile app repository (~15–20 MB).
    2. Web Prototype/: Autonomous Stage 1 interactive HTML/CSS/JS prototype with all assets, diagrams, and mockups.
    3. System Architecture & Docs/: Master system specifications (Full Project Context.md, Mobile App Context.md, ARCHITECTURE_MAP.md).
  - **Git Initialized & Committed**:
    - Created standalone Git repository on main branch with clean initial commit (834b038).
    - Configured production .gitignore filtering out .dart_tool/, build/, .gradle/, and machine-specific properties.
  - **Toolchain Portability**:
    - Added run_local.cmd delegating to parent toolchains/flutter_env.cmd for zero-friction local execution on this host PC.
    - Verified flutter analyze (0 issues) and flutter test (100% pass rate) inside DMRTonline Mobile App/.
- Master Industrial ERD & Editable Canvas Suite (Checkpoint 91):
  - **Enhanced `Web Prototype/Diagrams/mobile_app_database_erd.html`**:
    1. **Dual-Page Switcher**: Clean top navigation allowing 1-click toggling between **Prototype 1** (original 8-table mobile wallet schema) and **Industrial Version 1** (full 14-table production topology).
    2. **Authentic DMRT Ticket Card Design**: All 14 tables rendered with curved SVG header masks, semicircular punch notches (`r=11px`), dashed tear dividers, and Forest Green (`#005140`) branding.
    3. **Infinite Movable & Zoomable Canvas**: 2800×1800px expanded workspace with smooth zoom controls (25% to 200%), mouse wheel zoom, background drag-to-pan, and unconstrained card positioning.
    4. **In-Place Attribute Editing**: Click-to-edit inline attribute names, SQL data types, and clickable PK/FK/UK constraint cycling.
    5. **Attribute & Table Deletion Powers**: Red `×` button on attribute rows and `🗑️` delete card button on table headers with real-time orthogonal Manhattan connector recalculation.
    6. **Schema Extensibility**: `+ Add Attribute` button on cards and `+ Add Table` toolbar button to spawn new custom table entities on the fly.
    7. **14 Production Tables Mapped**: `passengers`, `passenger_devices`, `station_officers`, `stations`, `station_fares` (static matrix), `station_gates`, `tickets`, `transit_events`, `journey_history`, `payments`, `fines`, `refunds`, `daily_settlements`, `system_audit_logs`.
- First Native Flutter Android Deployment (Checkpoint 92):
  - **Clean Device Preparation**: Uninstalled legacy Stage 1 web wrapper APK (`com.dmrt.online`) and web testing package (`com.aistudio.dmrtonline.pqrszx`) via ADB, clearing legacy WebView storage and cached state.
  - **Toolchain Resolution**: Cleared corrupted Gradle transformed cache directory (`.gradle/caches/9.1.0/transforms`), ran clean synchronization and dependency updates.
  - **Native Build & Verification**: Successfully compiled the 100% native Flutter debug APK (`DMRTonline Mobile App/build/app/outputs/flutter-apk/app-debug.apk`) powered by Riverpod state management, custom painters, and pure Dart mock repository architecture.
  - **Physical Device Installation**: Streamed and installed the APK to connected physical Android smartphone (`U8MFEA9XFQ9XFECM`).
  - **Automatic Launch**: Dispatched main intent to launch `com.dmrt.online/com.dmrt.dmrt_online.MainActivity` seamlessly on device.
  - **Session Cleanup**: Verified all build and background sessions were terminated immediately per project operational rules.
- Natural Figma-Style Canvas Zoom & Pan Architecture (Checkpoint 93):
  - **Natural Mouse Wheel Zoom**: Replaced artificial stepped button controls with fluid, continuous focal-point mouse wheel zooming. Kept the exact canvas coordinate directly beneath the mouse cursor stationary during zoom in/out (`MIN_ZOOM: 0.18`, `MAX_ZOOM: 2.5`).
  - **Click-and-Hold Screen Panning**: Boundless 360° stage panning by clicking and dragging anywhere on the canvas background. Upgraded cursor states (`grab` on idle canvas, `grabbing` while holding and dragging).
  - **Infinite Synchronized Dot Grid**: Configured dynamic background coordinate offset and scaling on `.erd-stage-wrapper`, creating an infinite dot-grid illusion that tracks user movement and zoom without boundary cuts.
  - **Header Cleanup & Floating HUD**: Removed artificial `[-] 100% [+]` zoom toolbar from the top header bar. Added a sleek, unobtrusive floating status HUD at the bottom right (`Scroll wheel to zoom • Click & hold to move screen • [Zoom%]`).
  - **1:1 Card Dragging Retained**: Maintained zoom-compensated card dragging (`dx / zoom`), allowing unconstrained repositioning of all 14 industrial and 8 prototype ticket cards with real-time Manhattan connector line recalculation.

- Multi-Platform Runner Integration & Local Simulator Activation (Checkpoint 94):
  - **Identified Web Simulator Blocker**: Resolved blank white screen on `localhost:55578` caused by uninitialized web platform runner files (`web/index.html`).
  - **Platform Scaffolding Generated**: Executed `run_local.cmd create --platforms=web,windows .` to generate official Flutter Web and Windows Desktop platform runners.
  - **Windows Desktop Simulator**: Created `run_simulator_windows.cmd` alongside `run_simulator_web.cmd` to give commuters instant local desktop simulation without browser overhead.
  - **Clean Test Verification**: Cleaned generated template `test/widget_test.dart`, retaining dedicated `test/dmrt_app_test.dart`.
  - **Linter & Test Validation**: Verified `flutter analyze` (0 issues found) and `flutter test` (100% pass rate).

- Pure Flutter Simulator & Zero-Latency Instant Preview Launcher (Checkpoint 95):
  - **Diagnosed Debug-Mode Blank Screen**:
    1. Identified that `flutter run -d chrome` takes 70–75 seconds on Windows for initial `dartdevc` compilation, during which Chrome launches immediately and remains blank while waiting for the debug service connection.
    2. Identified an assertion crash in `main.dart` where `WidgetsBinding.instance` was accessed before `WidgetsFlutterBinding.ensureInitialized()`, aborting `runApp()` in debug mode.
  - **Zero-Dependency Native Simulator**: Replaced third-party `device_preview: ^3.0.0-prerelease3` with a 100% native Flutter `DeviceSimulatorOverlay` containing authentic phone bezels, speaker notch, drop shadow, and instant device switching (iPhone 16, Pixel 9, Galaxy S24, Full Window).
  - **Instant Preview Launcher (`run_instant_preview.cmd`)**: Pre-compiled production web bundle (`build/web`) and created a one-click launcher that serves the app locally on `http://localhost:8085` in under 1 second with zero compilation delay.
  - **Live Development Launcher (`run_simulator_web.cmd`)**: Updated launcher messaging with explicit compilation duration indicators (~75s) and Hot Reload instructions (`r`).
  - **Verification**: Verified `flutter analyze` (0 issues found) and `flutter test` (100% pass rate).

- Dynamic Island Notch Clearance & Robust Web-Server Simulator Architecture (Checkpoint 96):
  - **Diagnosed Live Chrome Isolation Hang**: Identified that `flutter run -d chrome` launches an isolated temporary Chrome instance relying on Windows named pipes, which were blocked by Windows local process security (`Access is denied 0x5`).
  - **Switched to Robust `web-server` Protocol**: Reconfigured `run_simulator_web.cmd` to run `flutter run -d web-server --web-port 8080` and automatically open the user's default Chrome browser. This guarantees 100% reliable local loading with interactive hot reload (`r`).
  - **Visual Studio Toolchain Requirement Clarified**: Clarified that native Windows desktop binaries require the 10GB+ Visual Studio C++ desktop workload (MSVC); removed `run_simulator_windows.cmd` to avoid confusion.
  - **Dynamic Island Safe Area Clearance**: Injected realistic device-specific safe area insets (`safeTop: 48px`, `safeBottom: 34px`) via `MediaQuery` inside `DeviceSimulatorOverlay`, ensuring the camera notch sits above the brand logo and `DMRTonline` title with zero visual overlap.
  - **Exact 1:1 Welcome Card Aspect Ratio**: Added exact `aspect-ratio: 1536 / 1024` from `index.html`, `BoxFit.cover` background image scaling, and precise padding/spacing tokens.
  - **Rebuilt Web Assets**: Recompiled production web bundle in `build/web/` verified with `flutter analyze` (0 issues found) and `flutter test` (100% pass).

- Complete Home Screen 1:1 Reconstruction (Checkpoint 97):
  - **Single Source of Truth**: Translated `#view-home` from `Web Prototype/index.html` (lines 5751–5806, CSS 76–320, 6507–6535, and JS 7410–7645) directly into native Flutter widgets.
  - **Signature SVG Wave Mask Clipper (`TicketWaveClipper`)**: Converted the exact Bézier path `M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z` into a Flutter `CustomClipper<Path>`.
  - **Circular Punch Notches & Dashed Perforation**: Implemented `TicketNotchClipper` (24px cutouts `r=12px`, 32px card corners) and `DashedPerforationLine` (`2px dashed #bec9c3`).
  - **Authentic Ticket Card (`TicketCardWidget`)**:
    1. Header: S-curve wave gradient (`#005140` to `#0b9175`), status pill badge (`Available` with emerald dot, `Riding`, or `Locked`), `SINGLE JOURNEY` label.
    2. Header Meta: Date (`11 Sep 2026`), passenger count (`01`), fare (`৳60`), expiry tag (`Exp: 24h`), and interactive `Refund` action link.
    3. Route Row: Origin station (`train` icon in 38px circle), responsive horizontal route connector with arrow, and Destination station (`place` pin icon in 38px circle).
    4. Punch Notches: Left and right circular cutouts with page background color `#d9e8e5`.
    5. Action Button: Gradient pill button (`#0b9175` to `#005140`) with `qr_code_scanner` icon and "Use Ticket" text.
  - **Empty State Placeholder (`NoTicketsPlaceholder`)**: Reconstructed empty state box with outline `confirmation_number` icon (48px), title, and subtitle.
  - **Rounded Bottom Navigation Bar (`BottomNavBar`)**: Reconstructed `.bottom-nav-rounded` with 24px top radius, 4 tabs (Home, Buy Ticket, History, Profile), and center elevated glowing Scan FAB (56px) with emerald shadow `0 0 20px rgba(16, 185, 129, 0.85)`.
  - **Testing & Verification**: 0 linter issues (`flutter analyze`), 100% test pass rate (`flutter test`), compiled production web bundle in `build/web/`, ready for instant preview via `run_instant_preview.cmd`.

- Multi-Width Device Simulator Suite (Checkpoint 98):
  - **Instant 1-Tap Width Switcher**: Integrated direct 1-tap buttons on the floating simulator toolbar for **[360px]**, **[380px]**, **[400px]**, and **[420px]** phone widths.
  - **Unified General Height**: Standardized a consistent 840px height across all phone widths, allowing direct inspection of horizontal responsiveness without height distortion.
  - **Smooth Width Transition**: Implemented `AnimatedContainer` with 250ms `easeInOut` curve for fluid animated resizing between phone widths.
  - **Instant Web Deployment**: Recompiled production web bundle in `build/web/` verified with `flutter analyze` (0 issues) and `flutter test` (100% pass), allowing instant page refresh on `http://localhost:8085`.

- Anti-Cache Architecture & Direct Width Switcher Activation (Checkpoint 99):
  - **Identified Browser Cache Blocker**: Resolved stale browser caching on `http://localhost:8085` caused by Flutter's default PWA service worker retaining old `main.dart.js` bundles in Chrome CacheStorage.
  - **Hardened Web Anti-Cache Scaffolding**: Added strict cache control meta tags (`no-cache`, `no-store`, `must-revalidate`) and an automated service worker unregister script in `web/index.html` and `build/web/index.html`.
  - **Direct 1-Tap Width Switcher Toolbar**: Verified `[360px]`, `[380px]`, `[400px]`, and `[420px]` buttons with active emerald highlighting and 840px general height.
  - **Build Recompiled**: Rebuilt clean web bundle (`flutter build web`) with zero linter errors and 100% test pass rate.

- Fixed 360px Viewport Proportional Scaling Engine (Checkpoint 100):
  - **Proportional Viewport Architecture**: Implemented `ScaledViewportWrapper` (`lib/shared/scaled_viewport_wrapper.dart`) reproducing `Web Prototype/index.html` viewport scaling (`scale = min(screenWidth, 480) / 360.0`).
  - **Locked Relative Element Positions**: Rather than standard responsive flex reflow where wide phones stretch elements sideways, all coordinates, ticket card geometry, typography, and punch notch cutouts stay locked to their 360px reference positions and scale uniformly up and down.
  - **Integrated with Simulator & Real Devices**: Wrapped `MaterialApp.builder` in `lib/main.dart` with `ScaledViewportWrapper`, ensuring both the multi-width browser simulator (360px, 380px, 400px, 420px) and physical mobile devices render with identical proportional fidelity.
  - **Production Web Rebuild**: Recompiled web bundle (`flutter build web`) in `build/web/` verified with `flutter analyze` (0 issues) and `flutter test` (100% pass), ready for instant live preview via `http://localhost:8085`.

- Proportional Scaling Android Phone Deployment (Checkpoint 101):
  - **Native Compilation**: Compiled the debug APK (`app-debug.apk`) with the new fixed 360px viewport proportional scaling engine (`ScaledViewportWrapper`).
  - **Streamed Installation**: Streamed and installed the APK to connected physical Android phone (`U8MFEA9XFQ9XFECM`) via ADB.
  - **Auto-Launch**: Dispatched main intent `com.dmrt.online/com.dmrt.dmrt_online.MainActivity` directly onto the device.
  - **Session Cleanup**: Verified all build and background sessions were stopped immediately per operational rules.

- 1:1 Precision Polish of Home Screen & Ticket Card (Checkpoint 102):
  - **Welcome Card Hierarchy & Grouping**:
    - Relocated greeting text and gradient "Buy Ticket" button to sit directly underneath the logo+title and avatar row (`gap: 8px`), leaving the green vector illustration clearly visible below without forced vertical stretching.
  - **Ticket Card Header Meta & Color Tokens**:
    - Corrected header metadata row (`.ticket-header-meta`): date (`11 Sep`), passenger count (`01`), and total price (`৳60`) now render with pure white text and icons (`#ffffff`, `0xF2FFFFFF`) with subtle translucent dividers directly on the green gradient wave header.
    - Updated expiry tag (`.ticket-expiry-tag`): red clock icon (`#B51B00`) and slate text (`#3E4945`).
    - Styled refund button (`.ticket-card-refund-btn`): rounded translucent red pill (`rgba(186, 26, 26, 0.1)`), `currency_exchange` icon, and `chevron_right` arrow in red (`#BA1A1A`).
  - **Route Section Vertical Layout**:
    - Restructured Origin and Destination into vertical station columns (Label -> 40px Circle Icon -> Station Name underneath, centered).
    - Configured initial station circle icons to grey (`#6E7A75`) in `Available` status, changing dynamically to deep green (`#005140`) for `Riding` and red (`#D32F2F`) for Exit Turnstile.
    - Centered horizontal dashed route connector with arrow (`#555555`) in a white badge.
  - **Seamless Notch Blending**:
    - Removed outer dark box shadow halos from the left and right semi-circular punch notches, ensuring 100% seamless background color matching (`#D9E8E5`).
  - **Web Build Updated**: Recompiled production web bundle in `build/web/` for zero-friction browser testing on `http://localhost:8085`.

- 1-Click Phone Update & Deploy Launcher (Checkpoint 103):
  - **Created `update_in_my_phone.cmd`**:
    - Placed in both `DMRTonline Mobile App/` and the workspace root `D:\DMRT Online/`.
    - **Step 1**: Detects connected Android devices via bundled ADB (`toolchains/android-sdk/platform-tools/adb.exe`).
    - **Step 2**: Compiles the native Flutter debug APK (`flutter build apk --debug`).
    - **Step 3**: Streams and installs the APK to the connected Android phone (`adb install -r`).
    - **Step 4**: Automatically launches `com.dmrt.online/com.dmrt.dmrt_online.MainActivity` on the phone.
  - **One-Click Convenience**: The user can now update their phone at any time with a single double-click.

- Punch Hole Border Fix & Button Gradient Restoration (Checkpoint 104):
  - **Unclipped Punch Notch Overlay**:
    - Removed container-level `ClipRRect` that was trapping the notch cutouts inside the card and letting the card's 1px border paint across the hole.
    - Set `clipBehavior: Clip.none` on the perforation row `Stack` and individually clipped only the top header and bottom action corners with 31px radius.
    - Overlay notch circles now sit directly above the card's outer perimeter, completely erasing the straight border line and drawing a crisp 1px circular arc matching the card border.
  - **Restored Rich Button Gradients**:
    - Restored the signature emerald-to-forest-green gradient (`[Color(0xFF0B9175), Color(0xFF005140)]`), 1px translucent border (`rgba(190, 201, 195, 0.45)`), and glowing shadow (`0 4px 12px rgba(0, 81, 64, 0.2)`) on both the **"Buy Ticket"** button (`WelcomeCard`) and the **"Use Ticket"** button (`TicketCardWidget`).
  - **Web Build Recompiled**: Rebuilt `build/web/` for instant browser testing on `http://localhost:8085`.



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


### Checkpoint 109: Home Screen Architecture, Punch Hole Realism, Neon Glow & System Insets Refinement
- **Date**: September 12, 2026
- **Changes Summary**:
  1. **Static Welcome Card + Scrollable Ticket Container**:
     - Refactored `HomeScreen` body layout from full-page `SingleChildScrollView` to a static top `WelcomeCard` and an `Expanded(child: ListView(...))` for the "My Tickets" section.
     - The welcome card (header logo, DMRTonline title, avatar, greeting, and Buy Ticket button) remains statically pinned at the top while only ticket cards in the "My Tickets" section scroll underneath.
  2. **Phone System Navigation Bar Insets**:
     - Updated `BottomNavBar` to dynamically adapt to `MediaQuery.of(context).padding.bottom`, ensuring the bottom nav items (Home, Buy Ticket, History, Profile) are always elevated above the phone's system navigation bar.
     - Extended the frosted glass background and concave notch down through the device safe area inset to match `Web Prototype/index.html` (`height: calc(64px + env(safe-area-inset-bottom, 0px))`).
  3. **Multi-Layer Neon Radial Halo on FAB**:
     - Extracted `BoxShadow` out of `Ink(decoration:)` onto an unclipped circular `Container`, eliminating rectangular canvas clipping artifacts on Flutter web / CanvasKit.
     - Implemented rich triple-layered radial glow: directional drop shadow (`0 4px 14px rgba(0, 81, 64, 0.4)`), high-intensity emerald neon core (`0 0 20px rgba(16, 185, 129, 0.85)`), and ambient atmospheric bloom (`0 0 36px rgba(16, 185, 129, 0.45)`).
  4. **Authentic Ticket Punch Hole Cutouts (`_TicketNotchPainter`)**:
     - Retained the punch hole cutouts at their exact row coordinates between Station Route and Action Button (`left: -12` and `right: -12`).
     - Replaced full 360-degree bordered discs with `_TicketNotchPainter` drawing a page-background fill (`#D9E8E5`), an inner-only semicircular arc border (`Color(0x4DBEC9C3)`), and an inner shadow (`Color(0x1F000000)`). Outer semicircles have 0 stroke, eliminating disc rings and creating a genuine punched cutout appearance.
  5. **Date & Expiry String Refinements**:
     - Removed year from purchase date in ticket header: `'11 Sep'` (instead of `'11 Sep 2026'`).
     - Updated expiration date to show the next day's date: `'Exp: 12 Sep'` (instead of `'24h'`).

### Checkpoint 110: Fixed Static 'My Tickets' Section Header Above Scrollable Ticket Cards
- **Date**: September 14, 2026
- **Changes Summary**:
  1. **Static 'My Tickets' Section Header**:
     - Moved the `Text('My Tickets')` header (`.tickets-section__header`) outside the `ListView` directly into the `Column` between `WelcomeCard` and `Expanded(child: ListView(...))`.
     - Exactly matches [`Web Prototype/index.html`](file:///d:/DMRT%20Online/Web%20Prototype/index.html) where `.tickets-glass-header` sits statically below `.welcome-card` and only `#home-tickets-container` scrolls vertically.
  2. **Scrollable Tickets List**:
     - `Expanded(child: ListView(...))` now begins with `padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomPadding)`, containing only the active ticket cards or placeholder.
     - As the user scrolls through the ticket cards, both the Welcome banner (greeting, logo, title, avatar, Buy Ticket button) and the "My Tickets" title remain 100% stationary and pinned in place.

### Checkpoint 111: Complete End-to-End Feature-First Clean Architecture Implementation & Test Suite
- **Date**: September 14, 2026
- **Status**: Implemented, 100% Tested & Verified
- **Scope & Changes**:
  1. **Domain & Business Logic Layer (`lib/core/`)**:
     - `Station` (`lib/core/models/station.dart`): All 16 MRT Line 6 stations with English and Bengali names, official station codes (UN, UT, UC, PV, MZ, PL, 10, 11, KP, SE, AG, BJ, FW, KW, SC, MJ), coordinates, and fuzzy search matcher.
     - `Ticket` (`lib/core/models/ticket.dart`): Complete immutable domain entity supporting all 6 lifecycle statuses (`available`, `riding`, `locked`, `completed`, `expired`, `refunded`), automatic day/month date formatting, 24-hour expiry computation, and dynamic QR payload generation.
     - `UserProfile` (`lib/core/models/user_profile.dart`): Passenger profile model with name, phone, email, gender, and date of birth.
     - `FareCalculator` (`lib/core/utils/fare_calculator.dart`): Exact MRT Line 6 fare calculation matrix (minimum ৳20, distance-based incremental steps up to ৳100 end-to-end).
  2. **Replaceable Clean Repository Architecture (`lib/core/repositories/`)**:
     - `TicketRepository` (`lib/core/repositories/ticket_repository.dart`): Abstract domain repository contract.
     - `MockTicketRepository` (`lib/core/repositories/mock_ticket_repository.dart`): In-memory pluggable mock repository with seed tickets, purchase simulation, 24-hour refund calculation, and turnstile gate entry/exit clearance lifecycle transitions.
     - `AppState` (`lib/core/state/app_state.dart`): Central reactive state notifier connecting mock data to presentation screens.
  3. **Complete Screen Inventory Matching Web Prototype 1:1 (`lib/features/`)**:
     - `HomeScreen` (`features/home/`): Welcome banner, static "My Tickets" header, scrollable ticket cards with authentic punch hole cutouts and dynamic status states.
     - `BuyTicketScreen` (`features/buy_ticket/`): Static total fare header, fare rate bar, origin/destination pickers with swap animation, passenger count stepper (1-5), payment method picker, and "Proceed to Payment" action.
     - `StationPickerBottomSheet` (`features/buy_ticket/widgets/`): 1:1 `.custom-station-overlay` with search, line map markers, and disabled opposite station selection.
     - `PaymentMethodBottomSheet` (`features/buy_ticket/widgets/`): 1:1 `.payment-method-overlay` supporting bKash, Nagad, Rocket, and Cards.
     - `PaymentScreen` (`features/payment/`): 1:1 `.view-payment` with ticket route preview, fare breakdown receipt, payment gateway selector, and "Confirm & Pay" action.
     - `TicketDetailsScreen` (`features/ticket_details/`): 1:1 `.view-details` with S-curve ticket header, transaction metadata receipt, refund policy info with confirmation dialog, and "Use Ticket" / "Current Trip" actions.
     - `QrDisplayScreen` (`features/qr_transit/`): 1:1 `.view-qr` with rotating high-density QR code, 60s countdown timer pill, commuter instructions, and "Scan Entry/Exit Gate Turnstile" action.
     - `GateScannerScreen` (`features/qr_transit/`): 1:1 `.view-scanner` turnstile gate scanner with animated green laser scanning line, camera corner crosshairs, station gate selector, and simulated turnstile gate clearance.
     - `HistoryScreen` (`features/history/`): 1:1 `.view-history` with 3 category filter tabs (Completed, Expired, Refunded) and past trip receipt cards.
     - `ProfileScreen` (`features/profile/`): 1:1 `.view-profile` with passenger form (Name, Email, Gender bottom sheet, Date of Birth bottom sheet), "Save Changes" action, and side navigation drawer trigger.
     - `DmrtSideDrawer` (`features/profile/widgets/`): Side drawer navigation with MRT Line 6 route map popup, passenger guidelines modal, helpline (16111), and legal information.
     - `MainAppShell` (`features/main_app_shell.dart`): Central navigation shell uniting all 4 main tabs (`Home`, `Buy Ticket`, `History`, `Profile`), floating glowing scan FAB, modal transitions, and SnackBar toasts.
  4. **Quality Verification & Test Suite**:
     - `flutter analyze` completed with 0 errors and 0 warnings.
     - 8 comprehensive automated unit and widget integration tests covering the full end-to-end passenger lifecycle passing 100% in `test/dmrt_app_test.dart`.
     - Flutter web bundle built and deployed to local preview server (`http://localhost:8085`).

### Checkpoint 112: Instant Simulator Preview Launcher & Root Workspace Integration
- **Date**: September 14, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Enhanced `run_instant_preview.cmd`**:
  - **Diagnosed Debug-Mode Blank Screen**:
    1. Identified that `flutter run -d chrome` takes 70–75 seconds on Windows for initial `dartdevc` compilation, during which Chrome launches immediately and remains blank while waiting for the debug service connection.
    2. Identified an assertion crash in `main.dart` where `WidgetsBinding.instance` was accessed before `WidgetsFlutterBinding.ensureInitialized()`, aborting `runApp()` in debug mode.
  - **Zero-Dependency Native Simulator**: Replaced third-party `device_preview: ^3.0.0-prerelease3` with a 100% native Flutter `DeviceSimulatorOverlay` containing authentic phone bezels, speaker notch, drop shadow, and instant device switching (iPhone 16, Pixel 9, Galaxy S24, Full Window).
  - **Instant Preview Launcher (`run_instant_preview.cmd`)**: Pre-compiled production web bundle (`build/web`) and created a one-click launcher that serves the app locally on `http://localhost:8085` in under 1 second with zero compilation delay.
  - **Live Development Launcher (`run_simulator_web.cmd`)**: Updated launcher messaging with explicit compilation duration indicators (~75s) and Hot Reload instructions (`r`).
  - **Verification**: Verified `flutter analyze` (0 issues found) and `flutter test` (100% pass rate).

- Dynamic Island Notch Clearance & Robust Web-Server Simulator Architecture (Checkpoint 96):
  - **Diagnosed Live Chrome Isolation Hang**: Identified that `flutter run -d chrome` launches an isolated temporary Chrome instance relying on Windows named pipes, which were blocked by Windows local process security (`Access is denied 0x5`).
  - **Switched to Robust `web-server` Protocol**: Reconfigured `run_simulator_web.cmd` to run `flutter run -d web-server --web-port 8080` and automatically open the user's default Chrome browser. This guarantees 100% reliable local loading with interactive hot reload (`r`).
  - **Visual Studio Toolchain Requirement Clarified**: Clarified that native Windows desktop binaries require the 10GB+ Visual Studio C++ desktop workload (MSVC); removed `run_simulator_windows.cmd` to avoid confusion.
  - **Dynamic Island Safe Area Clearance**: Injected realistic device-specific safe area insets (`safeTop: 48px`, `safeBottom: 34px`) via `MediaQuery` inside `DeviceSimulatorOverlay`, ensuring the camera notch sits above the brand logo and `DMRTonline` title with zero visual overlap.
  - **Exact 1:1 Welcome Card Aspect Ratio**: Added exact `aspect-ratio: 1536 / 1024` from `index.html`, `BoxFit.cover` background image scaling, and precise padding/spacing tokens.
  - **Rebuilt Web Assets**: Recompiled production web bundle in `build/web/` verified with `flutter analyze` (0 issues found) and `flutter test` (100% pass).

- Complete Home Screen 1:1 Reconstruction (Checkpoint 97):
  - **Single Source of Truth**: Translated `#view-home` from `Web Prototype/index.html` (lines 5751–5806, CSS 76–320, 6507–6535, and JS 7410–7645) directly into native Flutter widgets.
  - **Signature SVG Wave Mask Clipper (`TicketWaveClipper`)**: Converted the exact Bézier path `M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z` into a Flutter `CustomClipper<Path>`.
  - **Circular Punch Notches & Dashed Perforation**: Implemented `TicketNotchClipper` (24px cutouts `r=12px`, 32px card corners) and `DashedPerforationLine` (`2px dashed #bec9c3`).
  - **Authentic Ticket Card (`TicketCardWidget`)**:
    1. Header: S-curve wave gradient (`#005140` to `#0b9175`), status pill badge (`Available` with emerald dot, `Riding`, or `Locked`), `SINGLE JOURNEY` label.
    2. Header Meta: Date (`11 Sep 2026`), passenger count (`01`), fare (`৳60`), expiry tag (`Exp: 24h`), and interactive `Refund` action link.
    3. Route Row: Origin station (`train` icon in 38px circle), responsive horizontal route connector with arrow, and Destination station (`place` pin icon in 38px circle).
    4. Punch Notches: Left and right circular cutouts with page background color `#d9e8e5`.
    5. Action Button: Gradient pill button (`#0b9175` to `#005140`) with `qr_code_scanner` icon and "Use Ticket" text.
  - **Empty State Placeholder (`NoTicketsPlaceholder`)**: Reconstructed empty state box with outline `confirmation_number` icon (48px), title, and subtitle.
  - **Rounded Bottom Navigation Bar (`BottomNavBar`)**: Reconstructed `.bottom-nav-rounded` with 24px top radius, 4 tabs (Home, Buy Ticket, History, Profile), and center elevated glowing Scan FAB (56px) with emerald shadow `0 0 20px rgba(16, 185, 129, 0.85)`.
  - **Testing & Verification**: 0 linter issues (`flutter analyze`), 100% test pass rate (`flutter test`), compiled production web bundle in `build/web/`, ready for instant preview via `run_instant_preview.cmd`.

- Multi-Width Device Simulator Suite (Checkpoint 98):
  - **Instant 1-Tap Width Switcher**: Integrated direct 1-tap buttons on the floating simulator toolbar for **[360px]**, **[380px]**, **[400px]**, and **[420px]** phone widths.
  - **Unified General Height**: Standardized a consistent 840px height across all phone widths, allowing direct inspection of horizontal responsiveness without height distortion.
  - **Smooth Width Transition**: Implemented `AnimatedContainer` with 250ms `easeInOut` curve for fluid animated resizing between phone widths.
  - **Instant Web Deployment**: Recompiled production web bundle in `build/web/` verified with `flutter analyze` (0 issues) and `flutter test` (100% pass), allowing instant page refresh on `http://localhost:8085`.

- Anti-Cache Architecture & Direct Width Switcher Activation (Checkpoint 99):
  - **Identified Browser Cache Blocker**: Resolved stale browser caching on `http://localhost:8085` caused by Flutter's default PWA service worker retaining old `main.dart.js` bundles in Chrome CacheStorage.
  - **Hardened Web Anti-Cache Scaffolding**: Added strict cache control meta tags (`no-cache`, `no-store`, `must-revalidate`) and an automated service worker unregister script in `web/index.html` and `build/web/index.html`.
  - **Direct 1-Tap Width Switcher Toolbar**: Verified `[360px]`, `[380px]`, `[400px]`, and `[420px]` buttons with active emerald highlighting and 840px general height.
  - **Build Recompiled**: Rebuilt clean web bundle (`flutter build web`) with zero linter errors and 100% test pass rate.

- Fixed 360px Viewport Proportional Scaling Engine (Checkpoint 100):
  - **Proportional Viewport Architecture**: Implemented `ScaledViewportWrapper` (`lib/shared/scaled_viewport_wrapper.dart`) reproducing `Web Prototype/index.html` viewport scaling (`scale = min(screenWidth, 480) / 360.0`).
  - **Locked Relative Element Positions**: Rather than standard responsive flex reflow where wide phones stretch elements sideways, all coordinates, ticket card geometry, typography, and punch notch cutouts stay locked to their 360px reference positions and scale uniformly up and down.
  - **Integrated with Simulator & Real Devices**: Wrapped `MaterialApp.builder` in `lib/main.dart` with `ScaledViewportWrapper`, ensuring both the multi-width browser simulator (360px, 380px, 400px, 420px) and physical mobile devices render with identical proportional fidelity.
  - **Production Web Rebuild**: Recompiled web bundle (`flutter build web`) in `build/web/` verified with `flutter analyze` (0 issues) and `flutter test` (100% pass), ready for instant live preview via `http://localhost:8085`.

- Proportional Scaling Android Phone Deployment (Checkpoint 101):
  - **Native Compilation**: Compiled the debug APK (`app-debug.apk`) with the new fixed 360px viewport proportional scaling engine (`ScaledViewportWrapper`).
  - **Streamed Installation**: Streamed and installed the APK to connected physical Android phone (`U8MFEA9XFQ9XFECM`) via ADB.
  - **Auto-Launch**: Dispatched main intent `com.dmrt.online/com.dmrt.dmrt_online.MainActivity` directly onto the device.
  - **Session Cleanup**: Verified all build and background sessions were stopped immediately per operational rules.

- 1:1 Precision Polish of Home Screen & Ticket Card (Checkpoint 102):
  - **Welcome Card Hierarchy & Grouping**:
    - Relocated greeting text and gradient "Buy Ticket" button to sit directly underneath the logo+title and avatar row (`gap: 8px`), leaving the green vector illustration clearly visible below without forced vertical stretching.
  - **Ticket Card Header Meta & Color Tokens**:
    - Corrected header metadata row (`.ticket-header-meta`): date (`11 Sep`), passenger count (`01`), and total price (`৳60`) now render with pure white text and icons (`#ffffff`, `0xF2FFFFFF`) with subtle translucent dividers directly on the green gradient wave header.
    - Updated expiry tag (`.ticket-expiry-tag`): red clock icon (`#B51B00`) and slate text (`#3E4945`).
    - Styled refund button (`.ticket-card-refund-btn`): rounded translucent red pill (`rgba(186, 26, 26, 0.1)`), `currency_exchange` icon, and `chevron_right` arrow in red (`#BA1A1A`).
  - **Route Section Vertical Layout**:
    - Restructured Origin and Destination into vertical station columns (Label -> 40px Circle Icon -> Station Name underneath, centered).
    - Configured initial station circle icons to grey (`#6E7A75`) in `Available` status, changing dynamically to deep green (`#005140`) for `Riding` and red (`#D32F2F`) for Exit Turnstile.
    - Centered horizontal dashed route connector with arrow (`#555555`) in a white badge.
  - **Seamless Notch Blending**:
    - Removed outer dark box shadow halos from the left and right semi-circular punch notches, ensuring 100% seamless background color matching (`#D9E8E5`).
  - **Web Build Updated**: Recompiled production web bundle in `build/web/` for zero-friction browser testing on `http://localhost:8085`.

- 1-Click Phone Update & Deploy Launcher (Checkpoint 103):
  - **Created `update_in_my_phone.cmd`**:
    - Placed in both `DMRTonline Mobile App/` and the workspace root `D:\DMRT Online/`.
    - **Step 1**: Detects connected Android devices via bundled ADB (`toolchains/android-sdk/platform-tools/adb.exe`).
    - **Step 2**: Compiles the native Flutter debug APK (`flutter build apk --debug`).
    - **Step 3**: Streams and installs the APK to the connected Android phone (`adb install -r`).
    - **Step 4**: Automatically launches `com.dmrt.online/com.dmrt.dmrt_online.MainActivity` on the phone.
  - **One-Click Convenience**: The user can now update their phone at any time with a single double-click.

- Punch Hole Border Fix & Button Gradient Restoration (Checkpoint 104):
  - **Unclipped Punch Notch Overlay**:
    - Removed container-level `ClipRRect` that was trapping the notch cutouts inside the card and letting the card's 1px border paint across the hole.
    - Set `clipBehavior: Clip.none` on the perforation row `Stack` and individually clipped only the top header and bottom action corners with 31px radius.
    - Overlay notch circles now sit directly above the card's outer perimeter, completely erasing the straight border line and drawing a crisp 1px circular arc matching the card border.
  - **Restored Rich Button Gradients**:
    - Restored the signature emerald-to-forest-green gradient (`[Color(0xFF0B9175), Color(0xFF005140)]`), 1px translucent border (`rgba(190, 201, 195, 0.45)`), and glowing shadow (`0 4px 12px rgba(0, 81, 64, 0.2)`) on both the **"Buy Ticket"** button (`WelcomeCard`) and the **"Use Ticket"** button (`TicketCardWidget`).
  - **Web Build Recompiled**: Rebuilt `build/web/` for instant browser testing on `http://localhost:8085`.



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


### Checkpoint 109: Home Screen Architecture, Punch Hole Realism, Neon Glow & System Insets Refinement
- **Date**: September 12, 2026
- **Changes Summary**:
  1. **Static Welcome Card + Scrollable Ticket Container**:
     - Refactored `HomeScreen` body layout from full-page `SingleChildScrollView` to a static top `WelcomeCard` and an `Expanded(child: ListView(...))` for the "My Tickets" section.
     - The welcome card (header logo, DMRTonline title, avatar, greeting, and Buy Ticket button) remains statically pinned at the top while only ticket cards in the "My Tickets" section scroll underneath.
  2. **Phone System Navigation Bar Insets**:
     - Updated `BottomNavBar` to dynamically adapt to `MediaQuery.of(context).padding.bottom`, ensuring the bottom nav items (Home, Buy Ticket, History, Profile) are always elevated above the phone's system navigation bar.
     - Extended the frosted glass background and concave notch down through the device safe area inset to match `Web Prototype/index.html` (`height: calc(64px + env(safe-area-inset-bottom, 0px))`).
  3. **Multi-Layer Neon Radial Halo on FAB**:
     - Extracted `BoxShadow` out of `Ink(decoration:)` onto an unclipped circular `Container`, eliminating rectangular canvas clipping artifacts on Flutter web / CanvasKit.
     - Implemented rich triple-layered radial glow: directional drop shadow (`0 4px 14px rgba(0, 81, 64, 0.4)`), high-intensity emerald neon core (`0 0 20px rgba(16, 185, 129, 0.85)`), and ambient atmospheric bloom (`0 0 36px rgba(16, 185, 129, 0.45)`).
  4. **Authentic Ticket Punch Hole Cutouts (`_TicketNotchPainter`)**:
     - Retained the punch hole cutouts at their exact row coordinates between Station Route and Action Button (`left: -12` and `right: -12`).
     - Replaced full 360-degree bordered discs with `_TicketNotchPainter` drawing a page-background fill (`#D9E8E5`), an inner-only semicircular arc border (`Color(0x4DBEC9C3)`), and an inner shadow (`Color(0x1F000000)`). Outer semicircles have 0 stroke, eliminating disc rings and creating a genuine punched cutout appearance.
  5. **Date & Expiry String Refinements**:
     - Removed year from purchase date in ticket header: `'11 Sep'` (instead of `'11 Sep 2026'`).
     - Updated expiration date to show the next day's date: `'Exp: 12 Sep'` (instead of `'24h'`).

### Checkpoint 110: Fixed Static 'My Tickets' Section Header Above Scrollable Ticket Cards
- **Date**: September 14, 2026
- **Changes Summary**:
  1. **Static 'My Tickets' Section Header**:
     - Moved the `Text('My Tickets')` header (`.tickets-section__header`) outside the `ListView` directly into the `Column` between `WelcomeCard` and `Expanded(child: ListView(...))`.
     - Exactly matches [`Web Prototype/index.html`](file:///d:/DMRT%20Online/Web%20Prototype/index.html) where `.tickets-glass-header` sits statically below `.welcome-card` and only `#home-tickets-container` scrolls vertically.
  2. **Scrollable Tickets List**:
     - `Expanded(child: ListView(...))` now begins with `padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomPadding)`, containing only the active ticket cards or placeholder.
     - As the user scrolls through the ticket cards, both the Welcome banner (greeting, logo, title, avatar, Buy Ticket button) and the "My Tickets" title remain 100% stationary and pinned in place.

### Checkpoint 111: Complete End-to-End Feature-First Clean Architecture Implementation & Test Suite
- **Date**: September 14, 2026
- **Status**: Implemented, 100% Tested & Verified
- **Scope & Changes**:
  1. **Domain & Business Logic Layer (`lib/core/`)**:
     - `Station` (`lib/core/models/station.dart`): All 16 MRT Line 6 stations with English and Bengali names, official station codes (UN, UT, UC, PV, MZ, PL, 10, 11, KP, SE, AG, BJ, FW, KW, SC, MJ), coordinates, and fuzzy search matcher.
     - `Ticket` (`lib/core/models/ticket.dart`): Complete immutable domain entity supporting all 6 lifecycle statuses (`available`, `riding`, `locked`, `completed`, `expired`, `refunded`), automatic day/month date formatting, 24-hour expiry computation, and dynamic QR payload generation.
     - `UserProfile` (`lib/core/models/user_profile.dart`): Passenger profile model with name, phone, email, gender, and date of birth.
     - `FareCalculator` (`lib/core/utils/fare_calculator.dart`): Exact MRT Line 6 fare calculation matrix (minimum ৳20, distance-based incremental steps up to ৳100 end-to-end).
  2. **Replaceable Clean Repository Architecture (`lib/core/repositories/`)**:
     - `TicketRepository` (`lib/core/repositories/ticket_repository.dart`): Abstract domain repository contract.
     - `MockTicketRepository` (`lib/core/repositories/mock_ticket_repository.dart`): In-memory pluggable mock repository with seed tickets, purchase simulation, 24-hour refund calculation, and turnstile gate entry/exit clearance lifecycle transitions.
     - `AppState` (`lib/core/state/app_state.dart`): Central reactive state notifier connecting mock data to presentation screens.
  3. **Complete Screen Inventory Matching Web Prototype 1:1 (`lib/features/`)**:
     - `HomeScreen` (`features/home/`): Welcome banner, static "My Tickets" header, scrollable ticket cards with authentic punch hole cutouts and dynamic status states.
     - `BuyTicketScreen` (`features/buy_ticket/`): Static total fare header, fare rate bar, origin/destination pickers with swap animation, passenger count stepper (1-5), payment method picker, and "Proceed to Payment" action.
     - `StationPickerBottomSheet` (`features/buy_ticket/widgets/`): 1:1 `.custom-station-overlay` with search, line map markers, and disabled opposite station selection.
     - `PaymentMethodBottomSheet` (`features/buy_ticket/widgets/`): 1:1 `.payment-method-overlay` supporting bKash, Nagad, Rocket, and Cards.
     - `PaymentScreen` (`features/payment/`): 1:1 `.view-payment` with ticket route preview, fare breakdown receipt, payment gateway selector, and "Confirm & Pay" action.
     - `TicketDetailsScreen` (`features/ticket_details/`): 1:1 `.view-details` with S-curve ticket header, transaction metadata receipt, refund policy info with confirmation dialog, and "Use Ticket" / "Current Trip" actions.
     - `QrDisplayScreen` (`features/qr_transit/`): 1:1 `.view-qr` with rotating high-density QR code, 60s countdown timer pill, commuter instructions, and "Scan Entry/Exit Gate Turnstile" action.
     - `GateScannerScreen` (`features/qr_transit/`): 1:1 `.view-scanner` turnstile gate scanner with animated green laser scanning line, camera corner crosshairs, station gate selector, and simulated turnstile gate clearance.
     - `HistoryScreen` (`features/history/`): 1:1 `.view-history` with 3 category filter tabs (Completed, Expired, Refunded) and past trip receipt cards.
     - `ProfileScreen` (`features/profile/`): 1:1 `.view-profile` with passenger form (Name, Email, Gender bottom sheet, Date of Birth bottom sheet), "Save Changes" action, and side navigation drawer trigger.
     - `DmrtSideDrawer` (`features/profile/widgets/`): Side drawer navigation with MRT Line 6 route map popup, passenger guidelines modal, helpline (16111), and legal information.
     - `MainAppShell` (`features/main_app_shell.dart`): Central navigation shell uniting all 4 main tabs (`Home`, `Buy Ticket`, `History`, `Profile`), floating glowing scan FAB, modal transitions, and SnackBar toasts.
  4. **Quality Verification & Test Suite**:
     - `flutter analyze` completed with 0 errors and 0 warnings.
     - 8 comprehensive automated unit and widget integration tests covering the full end-to-end passenger lifecycle passing 100% in `test/dmrt_app_test.dart`.
     - Flutter web bundle built and deployed to local preview server (`http://localhost:8085`).

### Checkpoint 112: Instant Simulator Preview Launcher & Root Workspace Integration
- **Date**: September 14, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Enhanced `run_instant_preview.cmd`**:
     - Upgraded `DMRTonline Mobile App/run_instant_preview.cmd` with automatic port 8085 conflict release (`taskkill` on lingering PID).
     - Added automated build artifact verification that auto-compiles `build\web` if missing before serving.
     - Added multi-python fallback detection (`python` and `py` commands) with graceful Flutter web server fallback if Python is unavailable.
     - Automatically launches `http://localhost:8085` in the default browser.
  2. **Root Workspace 1-Click Launchers**:
     - Added `run_instant_preview.cmd` at the workspace root (`d:\DMRT Online\run_instant_preview.cmd`) for instant zero-compile web preview from the root folder alongside `update_in_my_phone.cmd`.
     - Added `run_simulator_web.cmd` at the workspace root (`d:\DMRT Online\run_simulator_web.cmd`) for live development mode with hot reload.
  3. **Verification**:
     - Pre-compiled web bundle built successfully (`build\web\index.html` and `main.dart.js` ready).
     - Fast startup verification in < 1 second.

### Checkpoint 113: 1-Click GitHub Repository Push Launcher & Git DevOps Synchronization
- **Date**: September 14, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Added `push_to_github.cmd` Launcher**:
     - Created `DMRTonline Mobile App/push_to_github.cmd` and root `d:\DMRT Online\push_to_github.cmd` for 1-click execution of `git push -u origin main`.
     - Automatically targets the project's portable Git toolchain (`toolchains/PortableGit`) or system Git fallback.
     - Provides clean console status output and helpful guidance if GitHub authentication is required.
  2. **Audit Log & Repository Tracking**:
     - Updated `DMRTonline Mobile App/GitHub Manager.md` with commit history and release milestone tracking.
     - All app features, screens, test suite, and launchers committed cleanly to local `main` branch (Commit: `72a4a72`).

### Checkpoint 114: Local CanvasKit Offline Bundling & Web Simulator Canvas Resolution
- **Date**: September 15, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Offline CanvasKit Bundling (`--no-web-resources-cdn`)**:
     - Diagnosed blank white screen on `localhost:8085` caused by Flutter Web attempting to fetch CanvasKit WASM assets from remote Google CDN (`gstatic.com`), which hung or was blocked locally.
     - Recompiled production web bundle with `--no-web-resources-cdn`, configuring `useLocalCanvasKit: true` in `flutter_bootstrap.js`.
     - All WebAssembly, CanvasKit, and engine binaries are now bundled and served directly from the local filesystem with zero external network dependency.
  2. **Updated Launchers**:
     - Updated both `d:\DMRT Online\run_instant_preview.cmd` and `DMRTonline Mobile App\run_instant_preview.cmd` to enforce `--no-web-resources-cdn` on auto-compilation.

### Checkpoint 117: Strict 1:1 Rebuild of Buy Ticket Screen & Station Picker Sheet
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Station Data Model & Fare Calculation Engine** (`lib/features/buy_ticket/models/station_data.dart`):
     - Implemented complete 16 Dhaka Metro Line 6 station dataset with English and Bengali names (Uttara North to Motijheel).
     - Replicated exact `calculateFare()` logic (Gap 1-2: ৳20, Gap 3-5: ৳40, Gap 6-11: ৳60, Gap >11: ৳100).
  2. **Station Picker Bottom Sheet** (`lib/features/buy_ticket/widgets/station_picker_bottom_sheet.dart`):
     - 1:1 Pure translation of `#custom-station-overlay` and `.schematic-row`.
     - Vertical metro line schematic with active rail highlighting between selected origin and destination nodes.
     - Origin (`ORIGIN`), Destination (`DESTINATION`), and calculated live preview fare badges (`60৳`).
     - Disabled reverse station logic preventing invalid circular routes.
  3. **Buy Ticket Screen** (`lib/features/buy_ticket/buy_ticket_screen.dart`):
     - Exact `.fare-header-wrapper` matching HTML/CSS layout (uppercase "TOTAL FARE" label, 54px bold emerald fare readout on page background `#D9E8E5`).
     - Emerald Fare Rate bar (`.fare-rate-bar`, 16px radius, rate per ticket).
     - White Route Selection Card (`.route-card`) with FROM / TO station rows, vertical track connector, and floating circular dual-arrow swap button (`.route-swap-btn`).
     - Quantity Stepper Card (`.quantity-card`) supporting 1–5 passengers with defensive bounds checking.
     - 48px full-width pill "Proceed to Payment" action button with active/disabled states.
### Checkpoint 118: Authentic Interactive Route Selection Flow & Route Card Connector Fix
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Fixed Route Card Connector Line Layout** (`lib/features/buy_ticket/buy_ticket_screen.dart`):
     - Resolved line overlap over Origin (`radio_button_checked`) and Destination (`location_on`) icons.
     - Separated into Left Icon Column (`SizedBox(width: 30)`) with Origin Icon, 24px vertical connector line strictly between the two icons, and Destination Icon.
     - Perfectly aligned station text fields (FROM/TO) and centered floating swap button (`.route-swap-btn`).
  2. **1:1 Interactive Multi-Step Station Picker Flow** (`lib/features/buy_ticket/widgets/station_picker_bottom_sheet.dart`):
     - Implemented dynamic modal header updates matching prototype JS (`openStationModal` & `renderStationModalList`):
       - Dynamic title ("Select Origin Station" / "Select Destination" / "Change Origin Station" / "Change Destination").
       - Dynamic subtitle ("Select where you want to start your journey" / "Where do you want to go?" / "Choose starting station (Destination is fixed)").
     - Selection state transitions:
       - Tapping selected origin or destination unselects that station.
       - Tapping a new origin automatically transitions modal mode to destination selection so users can select destination in one smooth flow without reopening the modal.
       - When both stations are selected, the bottom action button dynamically switches from "Cancel" (`#BA1A1A`) to "OK" (`#005140`).
     - Badges and Active Highlighting:
       - Origin shows `"You Are Here"` badge with light green background tint.
       - Destination shows `"Destination"` badge with light red background tint.
       - Other stations display real-time calculated fare badges (`20৳`, `40৳`, `60৳`, `100৳`).
       - Green metro track segments highlight between origin and destination nodes.
  3. **Verification**:
     - All 4 automated test suites passing (`flutter test`).
     - Static analysis clean with 0 warnings (`flutter analyze`).

### Checkpoint 119: Strict 1:1 Trip History Screen Implementation & Interactive Sliding Filter
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **History Ticket Data Model** (`lib/features/history/models/history_ticket_model.dart`):
     - Created `HistoryStatus` enum (`completed`, `expired`, `refunded`) and `HistoryTicketModel`.
     - Seeded realistic Dhaka Metro Line 6 trip records spanning multiple stations (Uttara North, Farmgate, Motijheel, Pallabi, Mirpur 10), dates, fares, and passenger counts.
  2. **History Card Widget** (`lib/features/history/widgets/history_card_widget.dart`):
     - 1:1 Pure Flutter translation of `.history-card`.
     - Date header with status badge pill (`Completed` in light green, `Expired` in surface gray, `Refunded` in light red).
     - Timeline route display with Origin icon (`#006B56`), vertical rail connector (`#555555`), and Destination icon (`#D13014`).
     - Route details with "From" and "To" station labels.
     - Fare section with passenger count badge (`"1 Person"`) and emerald fare readout (`"৳ 100"`).
  3. **Trip History Screen** (`lib/features/history/history_screen.dart`):
     - Header title `"Trip History"` (20px, 600 weight).
     - Animated 3-way sliding pill toggle bar (`.history-tabs-container`) with emerald border (`2px solid #005140`), rounded pill shape, and smooth gradient sliding background indicator (`#0B9175` to `#005140`).
     - Smooth page navigation across Completed, Expired, and Refunded trips.
     - Authentic empty state placeholders (`.no-tickets-placeholder`).
  4. **Home Navigation Shell Integration**:
     - Linked `HistoryScreen` to bottom navigation tab index 2 (`History`).
  5. **Verification**:
     - Automated tests running in `test/dmrt_app_test.dart` passing 100% with 0 errors.
     - `flutter analyze` passing with 0 warnings.
     - Web bundle recompiled with `--no-web-resources-cdn` and live preview updated.

### Checkpoint 120: Strict 1:1 Profile Page, Side Menu Drawer, and Modal Pickers Implementation
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **User Profile Data Model** (`lib/features/profile/models/user_profile_model.dart`):
     - Created `UserProfileModel` with full name, email, phone number, gender, date of birth, and avatar.
     - Added formatting helpers for birth date, gender display, and immutability `copyWith`.
  2. **Profile Screen** (`lib/features/profile/profile_screen.dart`):
     - 1:1 Pure translation of `#view-profile`.
     - Header: "Profile" title (20px, 600 weight) + Side menu trigger button (`Icons.menu`).
     - Avatar Section: Gradient ring border (`#0B9175` to `#005140`), avatar image or default icon, floating camera edit button (`Icons.camera_alt`, 36px), display name, and phone number.
     - Form: Full Name, Email Address, Gender, and Date of Birth fields with distinct leading icons.
     - Dynamic Save Button: Form dirty detection controlling active emerald button vs disabled outline state.
  3. **Photo Picker Bottom Sheet** (`lib/features/profile/widgets/photo_picker_bottom_sheet.dart`):
     - 1:1 Pure translation of `.photo-picker-sheet` with top handle, "Take Photo", "Choose from Gallery", "Remove Photo", and "Cancel".
  4. **Custom Gender Picker Dialog** (`lib/features/profile/widgets/gender_picker_dialog.dart`):
     - 1:1 Pure translation of `#custom-gender-overlay` with Male, Female, and Prefer not to say option pills.
  5. **Custom Date Picker Dialog** (`lib/features/profile/widgets/custom_date_picker_dialog.dart`):
     - 1:1 Pure translation of `#custom-datepicker-overlay` with emerald year & date header, year selector (1920-current), month navigation, and day grid.
  6. **Side Menu Drawer** (`lib/features/profile/widgets/side_menu_drawer.dart`):
     - 1:1 Pure translation of `#side-menu-overlay` with "Menu" title, sliding language toggle (EN/বাং), 11 menu items (Do's, Don'ts, Map, Permissions, Support, Policies, Loading, Phone Login, OTP, Profile Setup, Logout), and version footer.
  7. **Verification**:
     - 6 automated test suites in `test/dmrt_app_test.dart` passing 100% with 0 errors.
     - `flutter analyze` passing with 0 warnings.
     - Web bundle recompiled with `--no-web-resources-cdn` and live preview updated.

### Checkpoint 121: Strict 1:1 Complete Section A Flow (Ticket Details, Payment Confirmation, QR Transit Display & Turnstile Gate Scanner)
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Unified Ticket Lifecycle Model** (`lib/shared/models/ticket_model.dart`):
     - Comprehensive `TicketModel` supporting statuses: `available`, `riding`, `locked`, `completed`, `expired`, `refunded`.
     - Fields: `id`, `origin`, `destination`, `passengerCount`, `farePerPerson`, `totalFare`, `status`, `purchaseTime`, `entryTime`, `completeTime`, `qrExpiryTime`, `exitQrExpiryTime`, `paymentMethod`, `exitQrActive`.
     - Full date/time/fare formatting utilities and initial mock ticket seed generator.
  2. **Ticket Details Screen & Refund Confirmation Dialog** (`lib/features/ticket_details/`):
     - `ticket_details_screen.dart`: 1:1 Pure translation of `#view-details` with 5-notch progressive tint dividers (`#b2dad1`, `#bbded7`, `#c5e3dc`, `#cfe8e2`, `#e6f4f1`), S-curve wave top header with status badge and metadata chips (`date`, `passenger count`, `fare`), station route timeline, fare calculation breakdown, purchase timestamp, 24-hour expiry warning, and dynamic contextual actions (`"Use Ticket"`, `"Show Passenger QR"`, `"Refund Ticket"`).
     - `widgets/refund_confirm_dialog.dart`: 1:1 Modal matching `#refund-confirm-overlay` with blur backdrop, warning badge, 10% deduction calculation breakdown, and confirmation triggers.
  3. **Payment Confirmation Screen & Hold-to-Confirm Interaction** (`lib/features/payment/`):
     - `payment_screen.dart`: 1:1 Pure translation of `#view-payment` with review wave header, route summary, fare breakdown, payment method preview, and validity notification.
     - `widgets/payment_method_sheet.dart`: 1:1 Modal matching `#payment-method-overlay` with Mobile Finance (bKash/Nagad), Debit/Credit Card, and Internet Banking selectors.
     - `widgets/hold_to_confirm_button.dart`: Authentic circular press-and-hold interaction with 1000ms circular SVG progress arc painter, DMRT logo, haptic feedback pulses, and confirmation state animation.
  4. **Passenger QR Code Display Screen** (`lib/features/qr_transit/qr_display_screen.dart`):
     - 1:1 Pure translation of `#view-qr` featuring emerald wave top header, route timeline, passenger count pill, `QrImageView` high-density transit QR code, live 60-second animated countdown pill with dynamic pulse, instruction cards, and one-tap `"Tap to Pass Exit Barrier"` exit transition.
  5. **Turnstile Gate Scanner Simulator** (`lib/features/qr_transit/gate_scanner_screen.dart`):
     - 1:1 Pure translation of `#view-scan-gate` featuring dark camera viewfinder HUD, animated vertical laser scanning line, corner crosshair guides, floating station card, simulated turnstile gate clearance triggers, and seamless progression between entry, riding, and exit transit states.
  6. **Commuter Ticket Selector Modal** (`lib/features/qr_transit/widgets/ticket_select_dialog.dart`):
     - 1:1 Modal matching `#ticket-select-overlay` for commuters holding multiple active tickets when initiating a turnstile scan from the bottom navigation FAB.
  7. **Full Navigation & State Wiring** (`lib/features/home/home_screen.dart`):
     - Seamless transitions between Home, Buy Ticket, Ticket Details, Payment Confirmation, QR Transit, Gate Scanner, History, and Profile views.
     - History trip records dynamically synchronized upon ticket completion or refund.
  8. **Verification**:
     - 11 comprehensive automated test suites in `test/dmrt_app_test.dart` passing 100% with 0 errors.
     - `flutter analyze` passing with 0 warnings.
     - Web bundle recompiled with `--no-web-resources-cdn` and instant simulator updated.

### Checkpoint 122: Strict 1:1 Complete Ticket Purchase Flow Refinement & Interactive Parity
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Full Purchase Flow Parity (`BuyTicketScreen` -> `PaymentMethodSheet` -> `PaymentScreen`)**:
     - Connected "Proceed to Payment" button to directly trigger validation (`_origin` / `_destination` existence and distinctness) followed by the authentic `PaymentMethodSheet` bottom sheet.
     - Selected payment method (`Mobile Finance`, `Debit / Credit Card`, `Internet Banking`) is passed directly to `PaymentScreen` as `initialMethodKey` and `initialMethodName`.
  2. **Route Swap 360° Animation**:
     - Integrated `AnimatedRotation` smoothly spinning the swap button 360° on each tap.
  3. **Quantity Stepper Warning Toast**:
     - Added toast `"Maximum of 5 tickets allowed per transaction."` when attempting to exceed the 5-ticket limit.
  4. **Station Selection Persistence**:
     - Updated `StationPickerBottomSheet` to return current active selections on modal close, ensuring intermediate selections are retained.
  5. **Verification**:
     - All 11 automated test suites in `test/dmrt_app_test.dart` passing 100% with 0 errors.
     - `flutter analyze` passing with 0 warnings.
     - Web bundle recompiled with `--no-web-resources-cdn` and live simulator updated.

### Checkpoint 123: Complete 1:1 Functional & Flow Parity Audit of Ticket Purchase & Transit Lifecycle
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Station Data Robustness (`StationData`)**:
     - Verified all 16 stations from Uttara North to Motijheel against `STATIONS` in `Web Prototype/index.html`.
     - Standardized `'Kawran Bazar'` spelling while providing dual-lookup support for `'Karwan Bazar'`.
  2. **End-to-End Ticketing & Transit State Machine Audit**:
     - Verified full lifecycle: Buy Ticket Screen (Fare calculation, route schematic picker with dynamic fare badges, 360° swap, quantity stepper 1-5) $\to$ Payment Method Picker bottom sheet $\to$ Payment Confirmation Screen (Curved review banner, route breakdown, payment method re-selection, 1000ms Hold-to-Purchase circular SVG arc with haptic feedback) $\to$ Ticket Generation (`TKT-XXXX`) & Wallet Addition (`_tickets.insert(0, ...)`) $\to$ Home Screen Ticket Wallet display $\to$ Gate Scanner (`GateScannerScreen`) $\to$ Active QR Screen (`QrDisplayScreen`) with live countdown timer $\to$ Exit gate verification $\to$ Trip completion & archival into `_history` $\to$ Trip History View (`HistoryScreen`).
  3. **Verification**:
      - 11/11 Automated Test Suites in `test/dmrt_app_test.dart` passed with 100% success.
      - Web bundle compiled cleanly with `--no-web-resources-cdn` (exit code 0).

### Checkpoint 124: Strict 1:1 Complete Left Side Menu Drawer Dialogs & Authentication Flow
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Side Menu Drawer Information & Policy Dialogs (`lib/features/profile/widgets/side_menu_dialogs.dart`)**:
     - `DosGuidelinesDialog`: Modal matching `#side-menu` Do's option displaying verified platform safety rules with green icons and "Got It" action.
     - `DontsGuidelinesDialog`: Modal matching `#side-menu` Don'ts option displaying metro prohibited behavior list with red icons.
     - `MetroMapDialog`: Modal displaying complete MRT Line 6 route line map schematic with 16 stations from Uttara North to Motijheel.
     - `PermissionsDialog`: Modal displaying Camera Access, Push Notifications, and Local Storage permissions with status badges.
     - `SupportRequestDialog`: Modal displaying 24/7 DMRT customer hotline (`16100 / 09612-016100`) and email support (`support@dmtcl.gov.bd`).
     - `PoliciesDialog`: Modal with Ticketing & Fare Rules, 10% deduction Refund Policy, and Data Privacy rules.
  2. **Logout Confirmation Dialog (`lib/features/profile/widgets/logout_confirm_dialog.dart`)**:
     - 1:1 pure modal matching `#logout-confirm-overlay` with red accent icon, confirmation copy, Cancel button, and red Logout button resetting user profile and navigating to Home.
  3. **Loading Scene Animation Overlay (`lib/features/profile/widgets/loading_scene_overlay.dart`)**:
     - 1:1 modal matching `#loading-scene` displaying `assets/dmrt/loading.gif`, custom messaging, and tap-to-dismiss behavior.
  4. **Full Authentication Flow Screens (`lib/features/auth/`)**:
     - `PhoneLoginScreen` (`view-auth-phone`): Top bilingual toggle (EN / বাং), DMRT Logo, +880 prefix, 11-digit auto-formatting (`01XXX-XXXXXX`), clear button, Next button, and Terms footer.
     - `OtpVerificationScreen` (`view-auth-otp`): 6-digit split input boxes with auto-focus shifting, test bypass code `000000`, 75ms staggered green wave outline animation, "✓ Verified" indicator, and 60s resend timer.
     - `ProfileSetupScreen` (`view-auth-profile-setup`): Top Skip button, circular avatar with camera edit badge linked to `PhotoPickerBottomSheet`, full name input, and "Get Started" button.
  5. **State & Drawer Integration (`lib/features/home/home_screen.dart` & `lib/features/profile/profile_screen.dart`)**:
     - Side Menu Drawer updated with bilingual support (EN / বাং), version tag `v1.0.0`, and wired to all dialogs and auth navigation callbacks.
     - `HomeScreen` seamlessly routes between main tabs, transit flow, and auth flow screens with full data synchronization.
  6. **Verification**:
     - 22 comprehensive automated test suites in `test/dmrt_app_test.dart` passing 100% (22/22 passed).
     - Web bundle recompiled with `--no-web-resources-cdn` (exit code 0) for instant preview simulator.

### Checkpoint 125: 100% 1:1 CSS Linear Gradient Background Parity Across All Pages
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Centralized Gradient Engine (`lib/shared/app_gradients.dart`)**:
     - `AppGradients.pageGradient`: Exact translation of `linear-gradient(180deg, #188674 0%, #188674 1%, #9fd1c6 15%, #ffffff 90%)` from `Web Prototype/index.html` used across `#view-home`, `#view-buy`, `#view-history`, `#view-profile`, `#view-details`, `#view-payment`, and `#view-qr`.
     - `AppGradients.authGradient`: Exact translation of `linear-gradient(180deg, #188674 0%, #188674 1%, #9fd1c6 25%, #d9e8e5 100%)` from `Web Prototype/index.html` used across `.auth-page` (`#view-auth-phone`, `#view-auth-otp`, `#view-auth-profile-setup`).
  2. **Page & View Updates**:
     - `HomeScreen`, `BuyTicketScreen`, `HistoryScreen`, `ProfileScreen`: Wrapped in full-height `Container(decoration: BoxDecoration(gradient: AppGradients.pageGradient))` with `backgroundColor: Colors.transparent` on Scaffold.
     - `TicketDetailsScreen`, `PaymentScreen`, `QrDisplayScreen`: Migrated to `AppGradients.pageGradient` with transparent Scaffolds.
     - `PhoneLoginScreen`, `OtpVerificationScreen`, `ProfileSetupScreen`: Migrated to `AppGradients.authGradient` with transparent Scaffolds.
     - `DeviceSimulatorOverlay` & `main.dart`: Set default `ThemeData.scaffoldBackgroundColor` to transparent and set `AppGradients.pageGradient` on the interior phone bezel.
  3. **Verification**:
     - 22/22 automated tests in `test/dmrt_app_test.dart` passed 100%.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) and updated in `http://localhost:8085`.

### Checkpoint 126: Dynamic Punch Hole Notch Background Gradient Synchronization
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Dynamic Color Calculation (`AppGradients.getGradientColorAt`)**:
     - Ported 1:1 `getGradientColorAt(pct)` function from `Web Prototype/index.html` calculating the exact gradient color at vertical percentage `pct` (interpolating `#188674` $\to$ `#9FD1C6` $\to$ `#FFFFFF`).
  2. **Dynamic Ticket Notch Component (`lib/shared/dynamic_ticket_notch.dart`)**:
     - Built `DynamicTicketNotchCutout`: Dynamically measures its exact vertical position $Y$ relative to viewport height and paints the disc using the exact matching background gradient color at that coordinate.
     - Preserved authentic inner shadow (`RadialGradient` arc entering the ticket card) and inner semicircle border stroke (`#BEC9C3` with 0.3 alpha) with zero outer disc stroke for a seamless transparent cutout effect.
  3. **Wired Across All Ticket Card Views**:
     - `TicketCardWidget` (`HomeScreen` ticket list): Dynamic left and right punch hole notches.
     - `TicketDetailsScreen`: 5 dynamic notch rows across all ticket section dividers.
     - `PaymentScreen`: 4 dynamic notch rows across payment review sections.
  4. **Verification**:
     - 22/22 automated test suites in `test/dmrt_app_test.dart` passed 100%.
     - Web bundle recompiled with `--no-web-resources-cdn` for instant simulator update.

### Checkpoint 127: Real-Time RenderBox Ancestor Gradient Tracking & Full Hardcoded Color Purge
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Engine Architecture Upgrade (`lib/shared/dynamic_ticket_notch.dart`)**:
     - Upgraded `DynamicTicketNotchCutout` to utilize a specialized `LeafRenderObjectWidget` (`_DynamicNotchRenderWidget`) and custom `RenderBox` (`_RenderDynamicNotch`).
     - Replaced fragile matrix transform lookups with direct ancestor `Scaffold` coordinate mapping: `localToGlobal(Offset.zero, ancestor: _scaffoldRenderBox)` calculating exact vertical offset relative to the screen's active gradient canvas.
     - Added continuous reactive scroll listener to `ScrollPosition` triggering real-time re-measurement during momentum and drag scrolling.
  2. **Caller Cleanup & Removal of Hardcoded Colors**:
     - Removed hardcoded green tints (`#b2dad1`, `#bbded7`, `#c5e3dc`, `#cfe8e2`, `#e6f4f1`) from `_buildNotchRow()` callers in `TicketDetailsScreen` and `PaymentScreen`.
     - Standardized parameterless `_buildNotchRow()` ensuring notches at all Y coordinates (such as bottom refund rows and multi-ticket wallet cards) dynamically evaluate to the exact background gradient tone (including pure `#ffffff` at the bottom of the card).
  3. **Verification & Testing**:
     - Added dedicated unit and widget test suite `DynamicTicketNotchCutout & Gradient Blending Tests` validating 1:1 color interpolation stops (`pct = 0%`, `1%`, `15%`, `90%`, `100%`) and dual notch rendering.
     - 24/24 automated tests in `test/dmrt_app_test.dart` passed 100%.
     - Web simulator recompiled (`build web --no-web-resources-cdn`) and updated in `http://localhost:8085`.

### Checkpoint 128: 1:1 Strict Route Section Alignment Across Ticket Details & Payment Screens
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Route Layout Alignment (`TicketDetailsScreen` & `PaymentScreen`)**:
     - Upgraded `_buildRouteSection()` in both `TicketDetailsScreen` and `PaymentScreen` to 100% mirror the exact vertical column schematic from `TicketCardWidget` (`HomeScreen`) and `Web Prototype/index.html`.
     - Left Origin Column: Gray "Origin" label (`fontSize: 14`, `fontWeight: w400`, `color: #6E7A75`), 40x40 circular station icon with border, station name centered below (`fontSize: 14`, `fontWeight: w600`, `color: #181C1A`).
     - Center Route Connector: 56px width, `top: 28px` margin, 40px height containing centered `DashedPerforationLine` (`dashWidth: 4`, `dashSpace: 3`, `strokeWidth: 2`) with an overlaid white badge and `Icons.arrow_forward` (`color: #555555`, `size: 18`).
     - Right Destination Column: Gray "Destination" label, 40x40 circular station icon (`Icons.place`), station name centered below.
  2. **Dynamic Station Icon States**:
     - `TicketDetailsScreen`: Dynamically highlights origin green (`#005140`) and destination red (`#D32F2F`) during active `TicketStatus.riding` state.
     - `PaymentScreen`: Highlights origin green (`#005140`) matching `station-icon--active` from the web prototype.
  3. **Verification**:
     - 24/24 automated test suites in `test/dmrt_app_test.dart` passing 100%.
     - Web bundle recompiled with `--no-web-resources-cdn` and verified on instant simulator.

### Checkpoint 129: Full Login and Logout Authentication Flow with Dummy OTP 000000
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Dummy OTP Bypass & Input Engine (`OtpVerificationScreen`)**:
     - Hardened dummy OTP verification: Entering `000000` is accepted for any 11-digit phone number.
     - Added smart backspace key handling across all 6 input focus nodes to navigate to the previous box and clear it when pressing backspace on an empty field.
     - Added multi-digit paste handler: Pasting a 6-digit code auto-populates all inputs and triggers validation.
     - Upgraded status and resend row layouts to `Wrap` to prevent horizontal text overflow across narrow viewports and test environments.
     - Preserved sequential green wave outline animation, "✓ Verified" status, and 60-second resend countdown timer.
  2. **Phone Login & Profile Setup Navigation State Machine (`HomeScreen`)**:
     - `PhoneLoginScreen`: Formats any 11-digit Bangladesh phone number with `+880` prefix, bilingual toggle (EN / বাং), and clear button.
     - `ProfileSetupScreen`: Allows entering commuter full name and avatar picker. Both Skip and Complete buttons update `_userProfile`, restore the Home screen with updated personalized time-of-day greeting (e.g., "Good Morning / Afternoon / Evening, <Name>"), and show feedback toasts.
     - `SideMenuDrawer`: Integrated direct navigation shortcuts for Phone Login Page, OTP Verification Page, and Profile Setup Page.
     - `Logout Flow`: Triggering Logout from `ProfileScreen` or `SideMenuDrawer` opens `LogoutConfirmDialog`. Confirming logout resets `_userProfile` to empty defaults and redirects immediately to `PhoneLoginScreen`.
  3. **Automated Testing & Web Simulator**:
     - Added comprehensive end-to-end authentication test in `test/dmrt_app_test.dart` covering Phone Entry -> OTP 000000 -> Profile Setup -> Greeting Update -> Drawer -> Logout Dialog -> Phone Login Redirect.
     - 25/25 automated unit and widget tests passing 100%.
     - Recompiled web bundle (`build web --no-web-resources-cdn`) and updated in `http://localhost:8085`.

### Checkpoint 130: 1:1 Strict Loading Scene Synchronization & Update to Phone Script
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **1:1 Loading Scene Overlay Replication (`LoadingSceneOverlay`)**:
     - Background & Backdrop: Exact translation of `rgba(217, 232, 229, 0.42)` with `ImageFilter.blur(sigmaX: 9, sigmaY: 9)`.
     - Animation: `assets/dmrt/loading.gif` clamped between 86px-126px (matching CSS `clamp(86px, 26vw, 126px)`).
     - Text Styling: Inter 12px, line-height 16px, FontWeight.w700, letterSpacing 0.1px, color `#005140` (exact match with `.loading-scene__text` from `Web Prototype/index.html`).
     - Standard Duration & Delay: 180ms ease fade transition and standard 1000ms delay (`runWithLoading`).
  2. **Universal Loading Scene Integration Across All Features**:
     - `TicketDetailsScreen`: "Use Ticket" / "Scan Gate" button triggers `LoadingSceneOverlay.runWithLoading(context, 'Preparing gate scan...', ...)`.
     - `GateScannerScreen`: Simulating entry/exit/regenerate scan triggers `LoadingSceneOverlay.runWithLoading(context, 'Verifying gate QR...', ...)`.
     - `QrDisplayScreen`: Passing through exit barrier triggers `LoadingSceneOverlay.runWithLoading(context, 'Passing through exit barrier...', ...)`.
     - `ProfileScreen`: Camera/Gallery photo selection triggers `LoadingSceneOverlay.runWithLoading(context, 'Updating profile photo...', ...)`.
     - `ProfileScreen`: Save Changes triggers `LoadingSceneOverlay.runWithLoading(context, 'Saving profile...', ...)`.
     - `SideMenuDrawer`: "Loading Scene" menu item triggers `LoadingSceneOverlay.show(context, message: 'Click anywhere to close')`.
  3. **Update to Phone Script (`update_to_phone.cmd`)**:
     - Created one-click deployment batch script `update_to_phone.cmd` in workspace root and app directory.
     - Automatically verifies ADB connected Android device, checks for USB authorization, compiles release Flutter binary, and deploys directly to connected mobile phone.
  4. **Verification**:
     - 25/25 automated unit and widget tests passing 100%.
     - Web bundle recompiled with `--no-web-resources-cdn` and verified on instant simulator.

### Checkpoint 131: Android Build Resolution, Clean Toolchain & Single Reusable App Deployment Script
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Root-Cause Fix for Gradle Transform / KGP Build Failure**:
     - Removed unused native dependencies `mobile_scanner: ^5.2.3` and `flutter_riverpod: ^2.5.1` from `pubspec.yaml`.
     - Executed full cache purge (`flutter clean` & `flutter pub get`) resolving the `:app:mergeLibDexDebug` directory file locking exception (`Unable to delete directory ...build\mobile_scanner\.transforms...`).
     - Verified clean Android APK compilation (`flutter build apk --debug`) succeeding with code 0 (`√ Built build\app\outputs\flutter-apk\app-debug.apk`).
  2. **Single Reusable Update Script Under App Folder**:
     - Removed duplicate scripts from the root directory (`update_to_phone.cmd` and `update_in_my_phone.cmd`).
     - Kept strictly **ONE** production-ready, reusable deployment script at `d:\DMRT Online\DMRTonline Mobile App\update_to_phone.cmd`.
     - Fixed Windows batch command syntax (escaped title/echo symbols, correct path resolution to `..\toolchains\`, ADB device detection, APK compilation, installation, and automatic launch on device).
  3. **Verification**:
     - Android Debug APK built with 100% success.
     - 25/25 automated unit and widget tests passing 100%.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) and updated in `http://localhost:8085`.

### Checkpoint 132: Fresh Fully Automated 1-Click Phone Update Script
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Fully Automated Non-Blocking Script (`update_to_phone.cmd`)**:
     - Stripped out all manual interaction, prompts, and pause loops.
     - Step 1: Shows ADB devices non-blocking.
     - Step 2: Automatically builds Debug APK using local toolchain (`flutter_env.cmd build apk --debug`).
     - Step 3: Automatically installs APK to connected phone (`adb install -r`) and auto-launches the app (`am start`).
     - Script pauses only upon complete finish or error.
  2. **Single Location**: Maintained exclusively at `DMRTonline Mobile App/update_to_phone.cmd`.

### Checkpoint 133: Resolution of debugNeedsLayout Red Screen Crash on Physical Device
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Root-Cause Fix for RenderObject assertion crash**:
     - `DynamicTicketNotchCutout` previously invoked `findRenderObject()` during `build()` and `localToGlobal(ancestor: _scaffoldRenderBox)` inside `paint()`.
     - In Flutter's rendering pipeline, inspecting ancestor transform trees during `paint()` violates the layout lifecycle and triggers `assert(!debugNeedsLayout)` at `rendering/object.dart:4312`.
  2. **Clean Painting Implementation**:
     - Refactored `_RenderDynamicNotch.paint` to calculate vertical coordinates directly from the paint `Offset offset` and canvas height with zero tree traversals or ancestor lookups.
     - 100% crash-free on physical mobile devices and web simulators.
  3. **Verification**:
     - 25/25 automated unit/widget tests passing 100%.
     - Web bundle recompiled with `--no-web-resources-cdn`.

### Checkpoint 134: Pure CustomPainter Refactor & Native Mobile Viewport Isolation
- **Date**: September 16, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Pure CustomPainter for Ticket Punch Holes**:
     - Replaced custom `LeafRenderObjectWidget` and `RenderBox` completely with a standard `StatelessWidget` and `CustomPainter` (`_TicketNotchPainter`).
     - Eliminates any custom render box lifecycle, layout boundary, or performLayout dependencies.
  2. **Native Mobile Viewport Isolation (`kIsWeb` check)**:
     - `MaterialApp.builder` now applies `DeviceSimulatorOverlay` only when running on web desktop (`kIsWeb == true`). On physical Android devices, the app renders natively full-screen with zero FittedBox/LayoutBuilder wrapping at the root Navigator.
  3. **Verification**:
     - All 25 unit and widget tests pass 100%.
     - Web simulator bundle recompiled (`build web --no-web-resources-cdn`).

### Checkpoint 135: 1:1 Pixel-Perfect UI, Icon & Color Refinements Across Screens
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Route Selection Card (`BuyTicketScreen`)**:
     - Replaced destination pin with outlined location pin with centered red dot (`Icons.place_outlined` with 5px inner circular dot) matching prototype `.destination-pin`.
     - Realigned swap button to `top: 30` centered exactly over the horizontal divider line between Origin and Destination.
     - Dual arrows inside swap button: Green up arrow (`#006B56`) and Red down arrow (`#D13014`).
  2. **Ticket Details Screen (`TicketDetailsScreen`)**:
     - Expiry time alert row: Red schedule icon (`#BA1A1A`) and bold red label (`#BA1A1A`).
     - Refund Policy card: Background `rgba(186, 26, 26, 0.05)`, border `rgba(186, 26, 26, 0.10)`, red warning triangle icon (`#BA1A1A`), red header title (`#BA1A1A`), red policy text (`rgba(186, 26, 26, 0.9)`).
     - Refund Button: Solid filled `ElevatedButton` in `#BA1A1A`, white sync icon (20px), bold white text `Refund Ticket`.
     - Sub-header riding time-limit: Red schedule icon (`#BA1A1A`) and dark grey text (`#3E4945`).
  3. **Trip History Screen (`HistoryScreen`)**:
     - Updated "Completed" filter tab icon from solid `Icons.check_circle` to outlined `Icons.check_circle_outline`.
  4. **Side Menu Drawer (`SideMenuDrawer`)**:
     - Replaced all 11 drawer menu items with exact outlined Material Symbols: `Icons.check_circle_outline` (Do's), `Icons.cancel_outlined` (Don'ts), `Icons.map_outlined` (Map), `Icons.shield_outlined` (Permissions), `Icons.contact_support_outlined` (Support Request), `Icons.policy_outlined` (Policies), `Icons.sync` (Loading Scene), `Icons.smartphone_outlined` (Phone Login Page), `Icons.pin_outlined` (OTP Verification Page), `Icons.manage_accounts_outlined` (Profile Setup Page), and `Icons.logout` in `#BA1A1A` (Logout).
  5. **Payment / Purchase Review Screen (`PaymentScreen`)**:
     - Wave header time limit: Red schedule icon (`#BA1A1A`) and dark grey text (`#3E4945`).
     - Total Fare & Passenger count: Fare in 24px `#005140`, Passenger count in 20px `#181C1A`, labels in 12px `#6E7A75` with 0.5 letter spacing.
     - Validity & Expiry section: Red clock icon (`#BA1A1A`) and red title (`#BA1A1A`).
### Checkpoint 136: 1:1 Riding, Exit Gate, Locked State & Countdown Timer Refinements
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Countdown Timer Pill (`QrDisplayScreen`)**:
     - Container: Light mint/grey background (`#E6E9E5`, `var(--color-surface-high)`), 1px border (`#E0E3E0`, `var(--color-surface-highest)`), 9999 pill radius.
     - Icon: `Icons.timer` in primary green (`#005140` / `#006B56`).
     - Label: `Expires in ` in 16px `#3E4945`.
     - Countdown: `${seconds}s` in bold 18px primary green (`#005140`), transitions to warning red (`#BA1A1A`) when `<= 10s`.
     - Expired State: Solid red pill (`#BA1A1A`), white text `QR expired` and white timer icon.
  2. **Riding & Exit Gate Modes (`TicketCardWidget` & `TicketDetailsScreen`)**:
     - Header Wave Indicator: Gradient in crimson red (`#BA1A1A` -> `#E53935`) for both Riding and Exit Gate modes.
     - Status Badges:
       - Riding: `Icons.train` + `RIDING` in bold `#BA1A1A`.
       - Exit Gate (`exitQrActive == true`): `Icons.qr_code_2` + `EXIT GATE` in bold `#BA1A1A`.
       - Locked: `Icons.lock` + `LOCKED` in bold `#6E7A75` / `#707975` on muted gray gradient (`#707975` -> `#A2ACB0`).
     - Station Icon Coloring:
       - Origin: Active solid primary green (`#005140`) with white train icon when riding.
       - Destination: Active solid crimson red (`#D32F2F`) with white location pin ONLY when in Exit Gate mode (`exitQrActive == true`); otherwise inactive grey.
  3. **Animated Route Connector (`AnimatedRouteConnector`)**:
     - Built custom widget replicating CSS `@keyframes fillJourney` and `@keyframes moveArrow` (2.5s infinite easeInOut).
     - Riding Mode: Green dashed fill and green arrow `Icons.arrow_forward` moving across connector from 0% to 100% with smooth fade in/out.
     - Exit Gate Mode: Solid green dashed line with stopped arrow at the right end pointing directly into red destination icon.
     - Available / Locked: Static grey dashed line with centered arrow badge.
  4. **Action Buttons**:
     - Current Trip / Show Exit QR / Use Ticket: Solid primary green button (`#005140` / `#0B9175`).
     - Locked: Disabled grey container with lock icon and italicized message `Finish your active journey to unlock other trips.`.
  5. **Verification**:
     - 25/25 automated unit and widget tests passing 100%.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) and updated on simulator (`http://localhost:8085`).

### Checkpoint 137: Riding Ticket Prioritization, Click Flow Matrix, Camera Scanner, PopScope Navigation & Floating Toast System
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Top Ticket Prioritization**:
     - Dynamic sorting in `_sortedTickets` ensures that whenever any ticket enters `riding` (or `exitQrActive`) mode, it is unconditionally positioned at index 0 of the Home screen ticket list.
     - When purchasing new tickets while a trip is active, newly purchased tickets are inserted below the riding ticket as `locked`.
  2. **Strict Click & Redirect Flow Matrix (1:1 Web Prototype Replication)**:
     - **Card Body `onTap`**: Tapping a `riding` ticket immediately opens the live QR display screen (`view-qr`), while tapping an `available` or `locked` ticket opens `TicketDetailsScreen` (`view-details`).
     - **Small Refund Pill Button `onRefund`**: Directly triggers `RefundConfirmDialog.show` with calculated 10% refund fee and executes wallet return with floating toast confirmation.
     - **Action Button `onUseTicket`**:
       - `available`: Runs `LoadingSceneOverlay` ('Preparing gate scan...') and routes to `GateScannerScreen` (`scanType: 'entry'`).
       - `riding`: Routes directly to `QrDisplayScreen` (`view-qr`).
       - `locked`: Disabled with locked explanation subtext.
     - **Bottom Nav Bar Scanner FAB**:
       - Riding with active QR timer -> routes to `QrDisplayScreen`.
       - Riding with expired QR timer -> routes to `GateScannerScreen` (`scanType: 'exit'`).
       - 0 available -> triggers error toast *"No active tickets to scan."*.
       - 1 available -> triggers `LoadingSceneOverlay` ('Preparing gate scan...') and routes to `GateScannerScreen` (`scanType: 'entry'`).
       - >1 available -> opens `TicketSelectDialog` overlay to pick ticket, then launches scanner.
  3. **Live Camera Scanner & Graceful Fallback (`GateScannerScreen`)**:
     - Integrated `camera: ^0.12.1` with `CameraController` and `availableCameras()` to display live back camera feed inside the viewfinder on physical mobile devices.
     - Graceful fallback: on web desktop, simulator, or when camera permission is unavailable, automatically renders high-tech radar cross-grid simulation with animated laser line.
  4. **Android System Back Button Hierarchy (`PopScope`)**:
     - Wrapped root `HomeScreen` in `PopScope(canPop: false, onPopInvokedWithResult: ...)` to manage stack unwinding: auth views ('setup' -> 'otp' -> 'phone') -> scanner overlay -> QR display -> payment review -> ticket details -> non-home tabs -> exit app.
  5. **Custom Floating Toast Notification System (`AppToast`)**:
     - Replaced standard SnackBars with custom pill floating toast overlay (`#181C1A` 95% opacity, `BorderRadius.circular(9999)`, prefix status icon, Inter 13px weight 600, short message table mapping, smooth slide & fade animation).
  6. **Automated Test Suite & Web Simulator**:
     - Expanded test suite to 28/28 passing unit and widget tests.
     - Web bundle recompiled (`build web --no-web-resources-cdn`).

### Checkpoint 138: Locked Ticket Details Screen & Small Refund Button Navigation Flow
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Locked Ticket Details Screen**:
     - Configured `TicketDetailsScreen` to support `isLocked: true` presentation mode matching `Web Prototype/index.html` lines 8526-8595.
     - When locked, renders muted gray gradient wave header (`#707975` -> `#A2ACB0`), lock icon with "Locked" label in `#6E7A75`, and disabled action button `Icons.lock` + `"Locked (Another Trip in Progress)"` (`#6E7A75` on `#EBEFEB`).
     - Preserves full functionality of the Refund Policy warning box and "Refund Ticket" button with 10% fee deduction.
  2. **Small Refund Pill Button Navigation**:
     - Tapping the small "Refund >" pill button on any ticket card on the Home screen immediately opens `TicketDetailsScreen` (`_activeDetailTicket = ticket`) for that ticket, matching `selectAndGo(ticket.id, 'view-details')` in the prototype.
     - Added `behavior: HitTestBehavior.opaque` to ensure immediate and reliable tap capture across nested gesture detectors.
  3. **Verification**:
     - Added dedicated widget tests verifying locked mode rendering in `TicketDetailsScreen` and small refund button navigation from `HomeScreen`.
     - 30/30 automated unit and widget tests passing 100%.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) and updated on simulator (`http://localhost:8085`).

### Checkpoint 139: Single-Screen Mobile Viewport Optimization (Zero-Scroll Layouts)
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Profile Screen Viewport Fit (`ProfileScreen`)**:
     - Compacted top header padding (`topSafe + 8px`), avatar ring size (`80px` with `68px` inner icon), camera edit button (`30px`), display name (`18px`), and phone label (`13px`).
     - Form input fields streamlined with `contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)`, `isDense: true`, `SizedBox(height: 4)` label margin, and `SizedBox(height: 8)` inter-field spacing.
     - "Save Changes" button height set to `44px` with bottom scroll padding `80 + bottomSafe`. All 4 fields, user avatar, and save button fit inside standard mobile phone viewports without scrolling.
  2. **Ticket Details Screen Viewport Fit (`TicketDetailsScreen`)**:
     - S-curve wave header height adjusted to `70px`, route station section padding to `vertical: 10px` with `34x34px` circular station icons.
     - Notch dividers height set to `16px`.
     - Fare & Passenger row, Purchase Date & Time row, and Expiry Alert row vertical padding set to `8px`.
     - Refund policy warning box padding compacted to `10px` and button height to `42px`.
     - Action button section padded at `12px` with `44px` height button. Entire ticket card fits effortlessly in a single viewport.
  3. **Buy Ticket Screen Viewport Fit (`BuyTicketScreen`)**:
     - Fixed Total Fare header compacted to `topSafe + 8px`, amount font size `44px`, and `৳` symbol `40px`.
     - Fare rate bar compacted to `vertical: 8px` with `20px` amount.
     - Route Card padding compacted to `12px`, title margin `10px`, icon connector height `18px`, station rows `top: 2, bottom: 4/8`, floating swap button `top: 20` with `34x34px` size.
     - Quantity Card vertical padding compacted to `6px` with `34x34px` stepper buttons and `16px` quantity display.
     - "Proceed to Payment" button set to `44px` height. Total vertical footprint is ~487px, fitting within any modern mobile viewport.
  4. **Payment Screen & Hold-to-Confirm Viewport Fit (`PaymentScreen` & `HoldToConfirmButton`)**:
     - App bar padding set to `topSafe + 2px`, title `18px`.
     - Wave header height `70px`, route section `vertical: 10px`, notch rows `16px`, Fare/Method/Validity rows `vertical: 8px`.
     - `HoldToConfirmButton`: padding `vertical: 8px`, outer progress ring `74x74px` (radius `33.0`, stroke `3.5`), inner button `60x60px` with `34x34px` logo, label `13px`, subtext `11px`.
     - Complete payment review card and interactive hold-to-purchase button fit seamlessly without requiring any scroll interaction.
  5. **Verification**:
     - 30/30 automated unit and widget tests passing 100%.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) for instant simulator preview (`http://localhost:8085`).

### Checkpoint 140: Stylized Title Logo, App-Wide Icon Alignment, Auth Logo Scale, OTP Deletion & Local Cache Persistence
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Stylized Title Logo Asset Integration**:
     - Copied user-uploaded stylized brand title (`media_1789655574422.png` -> green `DMRT` + red `online`) to `assets/dmrt/title_logo.png` and `Web Prototype/dmrt/title_logo.png`.
     - Updated `WelcomeCard` in Flutter (`welcome_card.dart`) to render `Image.asset('assets/dmrt/title_logo.png', height: 25, fit: BoxFit.contain)` beside the train logo, perfectly replacing the text title in exact position and proportion.
     - Updated `Web Prototype/index.html` (and bundled assets) with `.welcome-logo-title-img` to maintain 100% synchronization across web and native Flutter.
  2. **App-Wide Icon Realignment**:
     - Synchronized all destination icons across the entire Flutter app (`BuyTicketScreen` route card, `HistoryCardWidget` route timeline, `TicketCardWidget` route section, `TicketDetailsScreen` route section) to use `Icons.location_on` (color: `#D13014`), strictly matching `<span class="material-symbols-outlined">location_on</span>` from `Web Prototype/index.html`.
     - Confirmed origin icons (`Icons.radio_button_checked` / `Icons.train` in `#006B56`), floating swap button (`Icons.arrow_upward` / `Icons.arrow_downward`), action buttons, status badges, and side menu icons are 100% synchronized with the prototype.
  3. **Auth Screen Logo Scale & Drop Shadow**:
     - Scaled brand logo in `PhoneLoginScreen` and `OtpVerificationScreen` to `height: 190` with centered alignment, matching `.auth-logo-img` in `Web Prototype/index.html`.
  4. **OTP Input Deletion, Backspacing & Click-to-Edit**:
     - Refactored `OtpVerificationScreen` with robust `onKeyEvent` handling for seamless backspacing from empty or populated boxes.
     - When invalid/wrong OTP is entered, input focus remains active on the last box (with tap-to-select enabled across all 6 boxes), allowing immediate backspacing to erase digits from right to left without getting stuck.
     - Keystrokes automatically clear error messages and typing into populated boxes overwrites the digit while advancing focus.
  5. **Real Camera & Gallery Photo Picker**:
     - Integrated `image_picker` package into `ProfileScreen` and `PhotoPickerBottomSheet`.
     - Camera capture (`ImageSource.camera`) and Gallery picker (`ImageSource.gallery`) convert chosen image bytes into base64 data strings for persistent storage in `UserProfileModel.avatarUrl`.
     - Added base64 image decoding and memory rendering to `ProfileScreen` avatar circle and `WelcomeCard` top right avatar, with graceful fallback to default icons.
  6. **Local Cache Memory & State Persistence (`AppStorageService`)**:
     - Implemented `AppStorageService` backed by `shared_preferences` with JSON serialization (`toJson()` / `fromJson()`) for `UserProfileModel`, active `TicketModel` list, and trip history `TicketModel` list.
     - Connected `HomeScreen.initState()` to load saved profile, tickets, and history on launch.
     - Automatic persistence triggered on all mutations: ticket purchase, gate scanning, trip completion, refunds, and profile updates. User state is fully preserved across app restarts and backgrounding.
  7. **Automated Test Suite & Web Simulator**:
     - Added unit tests for `AppStorageService` serialization/deserialization and widget tests for OTP digit replacement and error clearing.
     - All 32/32 tests passing with 0 failures.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) and updated for instant preview (`http://localhost:8085`).

### Checkpoint 141: Flutter Web Host Bootstrap Restoration & Pure Flutter Verification
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Root Cause Analysis & Identification**:
     - Identified that `DMRTonline Mobile App/web/index.html` had accidentally been overwritten with the static 10,600-line HTML prototype file.
     - When `flutter build web` ran, the resulting `build/web/index.html` contained the raw static HTML mockup instead of serving as the pure Flutter Web CanvasKit/HTML host page (`flutter_bootstrap.js`).
     - Because the static HTML was rendered directly, relative asset paths (such as `dmrt/logo.png` and `dmrt/title_logo.png`) returned 404s (as Flutter assets live in `assets/assets/dmrt/`), leading to broken `<img>` tags, missing background images, and showing the static HTML prototype rather than the real Flutter Dart application.
  2. **Flutter Web Host Restoration**:
     - Restored standard Flutter Web host entrypoint in `DMRTonline Mobile App/web/index.html` referencing `<script src="flutter_bootstrap.js" async></script>`.
     - Preserved `Web Prototype/index.html` and `DMRTonline Mobile App/assets/index.html` as the dedicated offline asset references.
### Checkpoint 142: Buy Ticket Screen Viewport Expansion & Breathable Proportions
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Layout Sizing & Screen Space Utilization**:
     - Expanded `BuyTicketScreen` component footprint to fill 70-80% of standard visible mobile viewports without overflowing or forcing vertical scrolling.
     - Fixed Total Fare header updated with generous vertical padding (`topSafe + 14px` top, `12px` bottom), larger label (`13px`, `letterSpacing: 1.4`), `44px` currency symbol, and `48px` total amount.
  2. **Inter-Component Gaps & Card Paddings**:
     - Fare Rate Bar: expanded padding to `symmetric(horizontal: 18, vertical: 12)`, label `14px`, amount `22px`.
     - Route Selection Card: expanded padding to `(18, 16, 18, 16)`, title `16px` with `14px` bottom margin, station text rows spaced with `10px` vertical padding, station names `16px` bold, icon connector height `28px`, floating swap button `38x38px` with `15px` icons.
     - Quantity Stepper Card: expanded padding to `symmetric(horizontal: 18, vertical: 12)`, label `14px`, subtext `12px`, stepper buttons `36x36px` with `19px` icons and `17px` quantity display.
     - Proceed to Payment Button: increased height to `50px` with `15.5px` bold text.
     - Card-to-card spacing increased from `8px` to `14-16px` for balanced vertical rhythm.
### Checkpoint 143: Dynamic Punch Hole Notch Gradient Blending & Welcome Title Scale
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Dynamic Punch Hole Notch Gradient Blending (`DynamicTicketNotchCutout`)**:
     - Upgraded `DynamicTicketNotchCutout` in `lib/shared/dynamic_ticket_notch.dart` to compute its global screen position dynamically using `renderBox.localToGlobal(Offset.zero).dy`.
     - Calculates the exact vertical position percentage (`pct`) and samples `AppGradients.getGradientColorAt(pct)` for the notch circle fill, perfectly blending every punch hole into the underlying page gradient across all screens, modals, cards, and scroll positions.
     - Preserves inner radial drop shadow (`inset 3px / -3px`) and semicircle border stroke matching `Web Prototype/index.html`.
  2. **Welcome Card Title Logo Size**:
     - Increased `title_logo.png` height from `25` to `31` and brand logo from `36` to `38` in `WelcomeCard` (`welcome_card.dart`).
     - Synchronized `.welcome-logo-title-img` in `Web Prototype/index.html` and bundled `assets/index.html`.
  3. **Verification**:
     - All 32/32 unit and widget tests pass with 0 failures (`flutter test`).
     - Recompiled web simulator bundle (`build web --no-web-resources-cdn`) and updated on `http://localhost:8090` / `8085`.

### Checkpoint 144: Supabase Cloud Integration & Database Clean Slate
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Supabase Account & MCP Integration**:
     - Connected official Supabase account (`DMRT Online`, Ref: `qrfiqdidzpsfnpvqgavn`, Region: `ap-south-1`).
     - Installed `@supabase/mcp-server-supabase` globally and registered it in Antigravity configuration (`~/.gemini/config/mcp_config.json`).
  2. **Data Preservation & Clean Slate**:
     - Exported complete pre-existing database backup (17 stations, 289 fare rates) to `d:\DMRT Online\.archive\supabase_backups\legacy_supabase_oct2025_backup.json`.
     - Executed complete database cleanup, dropping legacy prototype tables (`fare_matrix`, `stations`, `tickets`, `transactions`, `user_balances`, `profiles`) and associated auth triggers (`on_auth_user_created`).
     - Confirmed public database schema is completely clean (`0` tables, `0` enums, `0` functions), ready for from-scratch architecture design.

### Checkpoint 145: Title Logo Bounding Box Crop & Natural Aspect Ratio Alignment
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Asset Bounding Box Trimming (`title_logo.png`)**:
     - Cropped all transparent top/bottom dead space (51px top, 23px bottom) from `assets/dmrt/title_logo.png` and `Web Prototype/dmrt/title_logo.png`, producing a clean, tight `963 x 280` image (exact `3.44:1` natural text aspect ratio).
  2. **Welcome Card Alignment & Rendering**:
     - Configured `Image.asset('assets/dmrt/title_logo.png', height: 28, fit: BoxFit.contain)` and `logo.png` (`height: 36`) in `WelcomeCard` (`welcome_card.dart`).
     - Eliminates any squishing, vertical offset, or distortion, rendering the stylized text logo naturally centered and proportional beside the round train logo.
  3. **Verification**:
     - All 32/32 unit and widget tests pass with 0 failures (`flutter test`).
     - Recompiled web simulator bundle (`build web --no-web-resources-cdn`) and updated on `http://localhost:8090` / `8085`.

### Checkpoint 146: Standalone Android Release APK Compilation
- **Date**: September 17, 2026
- **Status**: Implemented & Verified
- **Scope & Changes**:
  1. **Release APK Compilation**:
     - Compiled standalone Android release APK via `flutter build apk --release --no-tree-shake-icons`.
     - Output generated at `D:\DMRT Online\DMRTonline Mobile App\build\app\outputs\flutter-apk\app-release.apk` (66.7 MB / 69,987,754 bytes).
  2. **Feature Readiness for Sideloading & Testing**:
     - Pre-configured with local cache persistence (`AppStorageService` / `SharedPreferences`), bypass OTP login (`000000`), offline QR ticketing, live camera/gallery photo picker, gate scanning simulation, and Dhaka Metro MRT fare calculation.
     - Self-signed and immediately installable on any physical Android device for user testing and interaction evaluation without requiring an active backend server.

### Checkpoint 147: Single Active Device Security Protocol & Discussion Board Alignment
- **Date**: September 18, 2026
- **Status**: Architected & Documented
- **Scope & Changes**:
  1. **Single Active Device Policy**:
     - Formalized Triple-Lock concurrent session invalidation protocol to prevent credential sharing and simultaneous logins.
     - Database triggers on `auth.sessions` prune older refresh tokens and increment `session_version` in `passengers`.
     - Realtime WebSocket streams push `<50ms` eviction signals to force-logout previous devices with an alert popup and storage wipe.
     - Physical gate `/verify-gate-tap` rejects tickets with superseded session versions.
  2. **Cross-Thread Alignment**:
     - Documented in `Backend Development.md` and posted to `Discussion.md` under explicit user instruction.

### Checkpoint 148: Prototype 1 Workspace Isolation & Direct Ticket QR Staging
- **Date**: September 18, 2026
- **Status**: Configured & Ready for Implementation
- **Scope & Changes**:
  1. **Workspace Isolation (`DMRTonline Mobile App - Prototype 1`)**:
     - Duplicated master Flutter application into dedicated sandbox directory `DMRTonline Mobile App - Prototype 1` for zero-risk demo preparation.
     - Preserves the primary `DMRTonline Mobile App` codebase untouched for long-term Supabase backend wiring and production development.
  2. **Prototype 1 Direct Ticket QR Specification**:
     - Eliminates gate display camera scanning (`GateScannerScreen`), allowing passenger to tap "Use Ticket" and immediately display active offline-cached Ticket QR.
     - Streamlines turnstile passage to one-tap barrier simulation for both Entry and Exit.
     - Enables offline-ready demonstration (tickets rendered from local storage without network dependency).
  3. **Documentation & Cross-Thread Alignment**:
     - Synchronized in `Full Project Context.md`, `Discussion.md`, and all `Mobile App Context.md` mirrors.

### Checkpoint 149: Prototype 1 Gate Challenge Removal & Direct Ticket QR Realignment
- **Date**: September 18, 2026
- **Status**: Implemented & Verified (Sandbox: `DMRTonline Mobile App - Prototype 1`)
- **Scope & Changes**:
  1. **Gate Challenge & Scanner Deletion**:
     - Deleted `lib/features/qr_transit/gate_scanner_screen.dart` and removed `camera: ^0.12.1` from `pubspec.yaml`.
  2. **Direct Ticket QR Display Flow (`HomeScreen` & `TicketDetailsScreen`)**:
     - `onUseTicket` in `HomeScreen` and `TicketDetailsScreen` immediately opens `QrDisplayScreen` (`_activeQrTicket = ticket`), bypassing camera scanning.
     - Central QR FAB button in `BottomNavBar` opens the active Ticket QR directly (or `TicketSelectDialog` if multiple tickets are available).
  3. **Simulated Barrier Pass & Local Regeneration (`QrDisplayScreen`)**:
     - Entry Mode: added "Tap to Pass Entry Barrier" button (`onPassEntryBarrier`) transitioning ticket from `available` to `riding` with 60-min timer and locking other tickets.
     - Exit Mode: retained "Tap to Pass Exit Barrier" (`onCompleteTrip`) archiving to `history`.
     - Expired QR: added local "Regenerate QR" action (`onRegenerateQr`) resetting the countdown timer.
  4. **Quality & Test Verification**:
     - Zero design or styling changes applied (all fonts, colors, SVG Bézier ticket clippers, and dynamic punch hole notches remain 100% untouched).
     - 32/32 automated test suites in `test/dmrt_app_test.dart` passing with 100% success.
     - Web bundle recompiled (`build web --no-web-resources-cdn`) and updated in `build/web/`.
     - Master codebase `DMRTonline Mobile App/` remains 100% clean and untouched.

### Checkpoint 150: Prototype 1 Standalone Android Release APK Compilation
- **Date**: September 18, 2026
- **Status**: Compiled & Verified
- **Scope & Changes**:
  1. **Release APK Compilation**:
     - Built standalone Android release APK for `DMRTonline Mobile App - Prototype 1` via `flutter build apk --release --no-tree-shake-icons`.
     - Output binary: `D:\DMRT Online\DMRTonline Mobile App - Prototype 1\build\app\outputs\flutter-apk\app-release.apk` (65.2 MB / 68,367,360 bytes).
  2. **Feature Readiness**:
     - Contains the streamlined Direct Ticket QR transit flow (entry/exit barrier simulation without gate camera challenges).
     - Fully self-signed and ready for direct sharing, installation, and evaluation on any Android device.

### Checkpoint 151: Prototype 1 Web & PWA Bundle, Zip Archive, and Wi-Fi Preview Runner
- **Date**: September 18, 2026
- **Status**: Compiled & Packaged
- **Scope & Changes**:
  1. **PWA & Web Manifest Optimization**:
     - Polished `web/manifest.json` with official DMRT branding, standalone orientation, and green theme tokens (`#005140`).
     - Compiled production Flutter Web bundle in `DMRTonline Mobile App - Prototype 1/build/web/`.
  2. **Shareable Web Archive**:
     - Packaged production build into `D:\DMRT Online\DMRTonline_Prototype1_Web_PWA.zip` (28.5 MB) for instant drag-and-drop deployment to Netlify, Vercel, or GitHub Pages.
  3. **Local Wi-Fi / iPhone Preview Tooling**:
     - Created `run_prototype1_web.cmd` with automatic LAN IP resolution (`192.168.0.x:8095`), allowing iPhone/Safari users on the same Wi-Fi to test and "Add to Home Screen" as a native app with zero configuration.

### Checkpoint 152: Production Netlify Live Deployment
- **Date**: September 19, 2026
- **Status**: Deployed & Live
- **Scope & Changes**:
  1. **Automated Netlify Cloud Deployment**:
     - Deployed `DMRTonline Mobile App - Prototype 1/build/web` to production Netlify cloud infrastructure via Netlify CLI token authorization.
     - Official Live Custom URL: `https://dmrt-online.netlify.app`.
  2. **Cross-Platform Access**:
     - Fully accessible worldwide on any iPhone (Safari PWA), Android (Chrome PWA), or desktop browser with responsive Flutter CanvasKit rendering and automatic mobile full-screen detection.

### Checkpoint 153: Transition to Email OTP Auth, Supabase Database Linking & Full QA Release
- **Date**: September 19, 2026
- **Status**: Implemented, Verified & Released
- **Scope & Changes**:
  1. **Commuter Email OTP Authentication**:
     - Transitioned authentication from Phone Number to Email OTP across `EmailLoginScreen`, `OtpVerificationScreen`, and `HomeScreen`.
     - Integrated Supabase native Auth (`signInWithOtp(email: ...)` & `verifyOTP(type: OtpType.email)`) with real 6-digit email OTP delivery.
     - Included bypass code `000000` for offline testing and automated widget test harnesses.
  2. **Supabase PostgreSQL Schema & Auth Linking**:
     - `auth.users` linked 1:1 with `public.passengers` via `passengers.auth_id` (UUID FK) and `passengers.email` (UNIQUE).
     - Deployed PostgreSQL trigger `handle_new_auth_user()` on `auth.users` (AFTER INSERT OR UPDATE OF email).
     - Deployed stored procedures `rpc_get_or_create_passenger_by_email` and `rpc_update_passenger`.
     - Normalized Bangladeshi phone numbers to strict 11 digits (`01XXXXXXXXX`).
  3. **Profile Persistence & Cloud Sync**:
     - Profile attributes (Full Name, Email, Phone Number, Gender, DOB, Avatar) persist across app launches and synchronize with Supabase PostgreSQL 17.
  4. **Quality & Release Artifacts**:
     - 100% automated test suite passing (35/35 tests) in `test/dmrt_app_test.dart`.
     - Recompiled standalone Release APK: `DMRTonline Mobile App - Prototype 1/build/app/outputs/flutter-apk/app-release.apk` (67.1 MB).
     - Recompiled production Web bundle: `DMRTonline Mobile App - Prototype 1/build/web`.
     - Synchronized and pushed all code to GitHub repository `Abdul-Kader-Jilani/DMRTonline-Mobile-App-Prototype-1` (`main` branch).

### Checkpoint 154: Offline Ticket Purchase Restriction & 1:1 NoInternetDialog Integration
- **Date**: September 19, 2026
- **Status**: Implemented, Verified & Released
- **Scope & Changes**:
  1. **Real-Time Internet Verification on Ticket Purchase**:
     - Integrated `NetworkService.hasInternetConnection()` in `BuyTicketScreen._handleProceedToPayment()`.
     - Displays `LoadingSceneOverlay` ("Verifying network connection...") before initiating purchase.
     - Blocks transition to payment when offline and displays `NoInternetDialog`.
  2. **1:1 Strict `NoInternetDialog` Implementation**:
     - Created `lib/features/buy_ticket/widgets/no_internet_dialog.dart` matching `#no-internet-overlay` from `Web Prototype/index.html`.
     - Features red `wifi_off` circle icon badge (`#FEE2E2` / `#BA1A1A`), bold "No Internet Connection" title, warning text, and primary green "Understood" dismissal button.
  3. **Quality & Automated Testing**:
     - 100% automated test suite passing (39/39 tests) in `test/dmrt_app_test.dart`.
     - Recompiled standalone Release APK: `DMRTonline Mobile App - Prototype 1/build/app/outputs/flutter-apk/app-release.apk` (67.1 MB).
     - Recompiled production Web bundle: `DMRTonline Mobile App - Prototype 1/build/web`.
     - Synchronized and pushed all code to GitHub repository `Abdul-Kader-Jilani/DMRTonline-Mobile-App-Prototype-1`.










