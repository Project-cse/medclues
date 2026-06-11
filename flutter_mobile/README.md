# MEDCLUES — Flutter Mobile App

**Package:** `medichain_mobile` · **Version:** `1.0.0+1`  
**Brand:** MEDCLUES · **Tagline:** EMERGENCY | BOOKING | SINCE 2026  
**Display name (Android):** MediChain+ (launcher label in `AndroidManifest.xml`)

Flutter patient app for the MEDCLUES healthcare platform. Full API parity with `fastapi_back/`. Includes a **standalone Emergency module** (works without login).

| Resource | URL |
|----------|-----|
| Production API | `https://medclues.onrender.com` |
| Telegram bot | [@medcluesBot](https://t.me/medcluesBot) |
| API docs (when running locally) | `http://localhost:5000/docs` |
| Monorepo overview | [../README.md](../README.md) |
| Backend deploy guide | [../BACKEND_GITHUB_DEPLOY.md](../BACKEND_GITHUB_DEPLOY.md) |
| Telegram bot (backend) | [../fastapi_back/TELEGRAM_BOT.md](../fastapi_back/TELEGRAM_BOT.md) |

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Environment & API Configuration](#environment--api-configuration)
4. [Run on Device (Android / Web / iOS)](#run-on-device-android--web--ios)
5. [Build Release APK](#build-release-apk)
6. [Project Structure](#project-structure)
7. [Navigation & Routes](#navigation--routes)
8. [Authentication](#authentication)
9. [Onboarding](#onboarding)
10. [Booking & Payments](#booking--payments)
11. [Video Consultation](#video-consultation)
12. [Health Records](#health-records)
13. [Telegram Smart Assistant](#telegram-smart-assistant)
14. [Push Notifications (FCM)](#push-notifications-fcm)
15. [App Deep Links](#app-deep-links)
16. [Hospitals, Labs & Blood Banks](#hospitals-labs--blood-banks)
17. [Emergency Module](#emergency-module)
18. [Themes & Auth UI](#themes--auth-ui)
19. [State Management](#state-management)
20. [Services & API Layer](#services--api-layer)
21. [Assets & Branding](#assets--branding)
22. [Platform Support](#platform-support)
23. [Form Validation](#form-validation)
24. [Multi-Language (i18n)](#multi-language-i18n)
25. [Google Play Store](#google-play-store)
26. [Scripts & Tooling](#scripts--tooling)
27. [Troubleshooting](#troubleshooting)
28. [Related Documentation](#related-documentation)

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Flutter SDK | **3.3+** (Dart `>=3.3.0 <4.0.0`) |
| IDE | VS Code or Android Studio with Flutter extension |
| Backend | FastAPI — local `http://localhost:5000` or production `https://medclues.onrender.com` |
| Android | USB debugging for physical phone, or emulator |
| iOS | **Requires macOS + Xcode** (cannot build iOS from Windows) |
| Web | Chrome recommended |

```bash
flutter doctor
```

Enable **Windows Developer Mode** if `flutter pub get` warns about symlinks:
```powershell
start ms-settings:developers
```

---

## Quick Start

```bash
# 1. Dependencies
cd flutter_mobile
flutter pub get

# 2. Generate launcher icons (from medclues_logo.png)
dart run flutter_launcher_icons

# 3. Configure API (see Environment section)
#    Edit assets/config.env — set API_BASE_URL

# 4. Run (pick one target)
flutter run -d chrome
flutter run -d <android_device_id>
```

**Production backend (no local server needed):** set in `assets/config.env`:
```
API_BASE_URL=https://medclues.onrender.com
API_BASE_URL_WEB=https://medclues.onrender.com
```

---

## Environment & API Configuration

### Config files

| File | Role |
|------|------|
| `assets/config.env` | **Bundled** — used on web, APK, and as fallback on mobile |
| `.env` | Local overrides (optional, not committed) |
| `sync_env.ps1` | Copies `EXPO_PUBLIC_API_URL` from legacy `../mobile/.env` |
| `--dart-define` | Highest priority override at build/run time |

### Load order (`lib/config/api_config.dart`)

1. `--dart-define=API_BASE_URL=...`
2. `assets/config.env` / `.env` (`flutter_dotenv`)
3. Platform defaults (emulator: `10.0.2.2:5000`, web: `localhost:5000`)

### Environment keys

| Key | Purpose |
|-----|---------|
| `API_BASE_URL` | FastAPI URL for Android/iOS |
| `API_BASE_URL_WEB` | API URL for Chrome/web |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth (Firebase Web client ID) |
| `AGORA_APP_ID` | Agora video consult (optional; backend may also provide) |
| `TELEGRAM_BOT_USERNAME` | Bot handle for Connect Telegram (default: `medcluesBot`) |
| `TELEGRAM_BOT_TOKEN` | Optional — not required in app; backend holds the token |

### Platform API defaults

| Target | Recommended `API_BASE_URL` |
|--------|--------------------------|
| **Production APK / phone** | `https://medclues.onrender.com` |
| Android emulator | `http://10.0.2.2:5000` |
| iOS simulator (Mac) | `http://localhost:5000` |
| Physical phone + local backend | `http://<YOUR_PC_LAN_IP>:5000` |
| Chrome (local backend) | `http://localhost:5000` via `API_BASE_URL_WEB` |

> **Never use `localhost` on a physical phone** — the phone cannot reach your PC's localhost. Use LAN IP or the Render production URL.

### Override at build time

```bash
flutter run --dart-define=API_BASE_URL=https://medclues.onrender.com --dart-define=TELEGRAM_BOT_USERNAME=medcluesBot

flutter build apk --release \
  --dart-define=API_BASE_URL=https://medclues.onrender.com \
  --dart-define=TELEGRAM_BOT_USERNAME=medcluesBot
```

> `TELEGRAM_BOT_USERNAME` must match the live bot (`@medcluesBot`) so **Settings → Connect Telegram** opens the correct chat.

---

## Run on Device (Android / Web / iOS)

### Web (Chrome) — works on Windows

```bash
cd flutter_mobile
flutter run -d chrome
# or
.\run_chrome.ps1
```

After changing `web/index.html`, do a **full restart** (not hot reload).

### Android phone via USB (Windows)

1. On phone: **Settings → About → tap Build number 7×** → enable **USB debugging**
2. Connect USB → allow debugging prompt
3. Verify device:
   ```powershell
   flutter devices
   adb devices
   ```
4. Run:
   ```powershell
   .\run_android_phone.ps1
   ```
   Or manually:
   ```powershell
   flutter run --release --dart-define=API_BASE_URL=https://medclues.onrender.com
   ```

### Android emulator

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter run -d emulator-5554
```

### iPhone via USB — **Mac only**

iOS builds **cannot** be produced on Windows. You need:

1. Mac with **Xcode** installed
2. iPhone: **Trust computer** + **Developer Mode** (iOS 16+)
3. Apple ID in Xcode → **Signing & Capabilities**
4. Commands:
   ```bash
   cd flutter_mobile
   flutter pub get
   cd ios && pod install && cd ..
   open ios/Runner.xcworkspace   # set Team + Bundle ID
   flutter devices
   flutter run --release
   ```
5. On iPhone first install: **Settings → General → VPN & Device Management → Trust**

For App Store / TestFlight: `flutter build ios --release` then Archive in Xcode.

---

## Build Release APK

### Standard release APK (production API)

```powershell
cd flutter_mobile
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release \
  --dart-define=API_BASE_URL=https://medclues.onrender.com \
  --dart-define=TELEGRAM_BOT_USERNAME=medcluesBot
```

**Output:** (~85 MB single APK)
```
build/app/outputs/flutter-apk/app-release.apk
```

### Smaller per-CPU APKs

```bash
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://medclues.onrender.com
```

Use `app-arm64-v8a-release.apk` on most modern phones.

### Install APK on connected phone

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Android release notes

| Item | Detail |
|------|--------|
| App ID | `com.medichain.medichain_mobile` |
| Launcher icon | Generated from `assets/images/medclues_logo.png` |
| ProGuard | `android/app/proguard-rules.pro` (Agora R8 rules included) |
| Signing | Debug keystore by default — create release keystore before Play Store |
| Cleartext HTTP | Enabled for local dev (`usesCleartextTraffic`) |
| Core desugaring | Enabled for `flutter_local_notifications` (Java 8+ APIs) |
| Deep link scheme | `mediclues://dashboard` (Telegram bot → app home) |

### Play Store bundle

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://medclues.onrender.com
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Emergency testing in release build

Release builds dial real **108 / 100 / 101**. To block calls while testing a release APK:

```bash
flutter build apk --release --dart-define=EMERGENCY_TESTING=true
```

---

## Project Structure

```
flutter_mobile/
├── lib/
│   ├── main.dart                    # Entry: env, Firebase, MedcluesApp, router
│   ├── firebase_options.dart
│   ├── config/                      # ApiConfig, AppConfig
│   ├── constants/                   # Colors, typography, form_options, profile_options
│   ├── brand/                       # MEDCLUES palette, logo, login transition
│   ├── themes/                      # Light / dark Material 3
│   ├── models/                      # Doctor, appointment, patient, payment, etc.
│   ├── helpers/                     # StorageHelper, TokenHelper, permissions
│   ├── utils/
│   │   ├── validators.dart          # Shared field validation rules
│   │   ├── input_formatters.dart    # Keyboard input restrictions
│   │   └── …                        # Formatters, JSON parser
│   ├── services/                    # Dio API, FCM push, Telegram link, deep links
│   │   ├── telegram_link_service.dart
│   │   ├── push_notification_service.dart
│   │   └── app_deep_link_service.dart
│   ├── repositories/                # Auth, appointment, doctor, patient repos
│   ├── providers/                   # Riverpod state
│   ├── routes/                      # go_router, auth redirect, DashboardShell
│   ├── screens/                     # Auth, dashboard, booking, profile, etc.
│   ├── features/emergency/          # Standalone SOS module (no login required)
│   ├── onboarding/                  # First-run wizard (8 steps)
│   └── widgets/                     # Shared UI, Telegram card, deep link listener
│       ├── settings/telegram_connect_card.dart
│       └── deep_link_listener.dart
├── assets/
│   ├── config.env                   # Bundled API URL (required for web/APK)
│   ├── images/medclues_logo.png     # App icon source (1024×1024)
│   ├── images/specialities/         # Speciality PNG icons
│   ├── videos/opening.mp4           # Splash video
│   └── animations/                  # Lottie files
├── android/                         # google-services.json, ProGuard, manifest
├── ios/                             # GoogleService-Info.plist, Xcode project
├── web/                             # index.html (autofill CSS), PWA manifest
├── sync_env.ps1
├── run_chrome.ps1
├── run_android_phone.ps1
├── get_android_sha.ps1              # Firebase SHA-1 helper
└── pubspec.yaml
```

---

## Navigation & Routes

### Bottom navigation (`DashboardShell`)

| Tab | Route | Screen |
|-----|-------|--------|
| Home | `/dashboard` | Dashboard |
| Appointments | `/appointments` | Upcoming / completed / cancelled |
| Records | `/records` | Health records |
| Profile | `/profile` | Profile hub |

### Auth routes (always light theme — see [Themes & Auth UI](#themes--auth-ui))

| Route | Screen | Auth |
|-------|--------|------|
| `/` | Splash (opening video) | No |
| `/login` | Login | No |
| `/signup` | 4-step registration wizard | No |
| `/forgot-password` | OTP reset | No |

### Emergency routes (no login, always light theme)

| Route | Screen |
|-------|--------|
| `/emergency` | SOS access + countdown |
| `/emergency/settings` | Contacts, medical info, SOS prefs |
| `/emergency/active` | Post-SOS actions |

### Auth redirect rules

- `/emergency*` **always bypass** login
- Logged-in user on `/login` or `/signup` → `/dashboard`
- Guest on protected route → `/login`
- API **401** → clear tokens → `/login`
- Access token expiry → auto **refresh** via `/api/auth/refresh` when refresh token exists

Full route list: `lib/routes/route_names.dart` and `lib/routes/app_router.dart`.

---

## Authentication

### Methods

| Method | Flow |
|--------|------|
| Email/password | `POST /api/user/login` |
| Registration | 4-step wizard → `POST /api/user/register` |
| Google Sign-In | Firebase → `POST /api/user/social-login` |
| Forgot password | Email OTP → reset password |
| Session restore | Secure storage JWT + refresh token rotation |
| Logout | `POST /api/auth/logout` + clear storage |

### Signup wizard (4 steps)

| Step | Fields |
|------|--------|
| 1 — Personal | Full name, **date of birth** (picker), gender |
| 2 — Contact | Email, phone |
| 3 — Security | Password, confirm, terms checkbox |
| 4 — Success | Celebration → dashboard |

- **"Already have an account? Login"** link on all signup steps
- Optional **Google Sign-In** on step 1
- Auth screens use **light theme only** (unaffected by app dark mode)
- Full password/phone/OTP rules defined in `Validators` — see [Form Validation](#form-validation) (signup wiring in progress)

### Token handling

| Item | Detail |
|------|--------|
| Storage | `flutter_secure_storage` |
| Headers | `Authorization: Bearer` + `token:` |
| Access token | Short-lived (~15 min) |
| Refresh token | Rotated via `POST /api/auth/refresh` |
| Expired session | Auto-refresh in `ApiService` interceptor |

### Google Sign-In

| Platform | Method |
|----------|--------|
| Web | Firebase `signInWithPopup` |
| Android/iOS | `google_sign_in` → Firebase credential → backend |

Requires `GOOGLE_WEB_CLIENT_ID` in `config.env` and Firebase config files:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Run `.\get_android_sha.ps1` and add SHA-1 to Firebase Console for Android.

---

## Onboarding

First-login wizard (`lib/onboarding/`) — 8 steps including emergency contact and profile completion.

| Step | Content |
|------|---------|
| Emergency contact | Saves **Contact 1** to backend + local storage (`EmergencyStorageService`) |
| Profile | Patch patient profile |
| Tutorial | In-app feature tour; second emergency contact can be added later in Emergency settings |

Progress synced via `PATCH /api/user/onboarding`.

Permissions (notifications, location, camera) are requested **in context** when needed (booking, emergency, video) — not via a forced full-screen permissions gate on every launch.

---

## Booking & Payments

### Booking flow

```
Doctor Profile → Patient selector (For Me / Others) → Booking screen
  → Slot selection → Symptoms + optional report upload
  → Razorpay (online) or direct book (in-clinic)
  → Success → Confirmation / Receipt → Video consult (if online)
```

### Patient Details form (Book for Someone Else)

**Screen:** `lib/screens/booking/booking_patient_selector_screen.dart`  
**Widgets:** `PremiumPatientFormField`, `PremiumPatientDropdownField`

Validated client-side before Continue (UI styling unchanged — errors show as text below fields):

| Field | Rules |
|-------|-------|
| Patient Name | Required; letters + spaces only; 2–50 chars; auto-trim |
| Age | Required; 0–120 integer; **wheel picker** (no free typing) |
| Gender | Dropdown only — see `FormOptions.genders` |
| Contact Number | Required; exactly 10 digits; must start with 6, 7, 8, or 9 |
| Relationship | Dropdown only — see `FormOptions.relationships` |

- **Continue** button disabled until all fields pass validation
- `inputFormatters` block invalid characters while typing
- Backend validation for `actualPatient` is planned — do not rely on frontend alone

### Payments (Razorpay)

| Item | Detail |
|------|--------|
| Service | `lib/services/payment_service.dart` |
| Create order | `POST /api/payments/create-order` |
| Verify | `POST /api/payments/verify` |
| Confirm (I've paid) | `POST /api/payments/confirm-order` |
| History | `GET /api/payments/history` |
| Hosted checkout | Opens `/api/payments/checkout?token=...` in browser |

Backend stores orders in PostgreSQL (`payment_transactions` table) — survives server restarts.

---

## Video Consultation

| Item | Detail |
|------|--------|
| Route | `/video-consult/:appointmentId` |
| SDK | `agora_rtc_engine` |
| Token | From backend consultation endpoints |
| Permissions | Camera + microphone via `permission_handler` |
| Web | Agora iris script in `web/index.html` |

---

## Health Records

| Item | Detail |
|------|--------|
| Screen | `records/records_screen.dart` (bottom nav) |
| Upload | Multipart to backend → Cloudinary |
| View | PDF/image via view-url or file stream endpoints |
| Upload notify | Backend sends corporate email + Telegram alert when linked |
| Dark mode | Supported (theme-aware skeletons) |

---

## Telegram Smart Assistant

Official patient bot: **[@medcluesBot](https://t.me/medcluesBot)** — friendly menus, inline buttons, and real-time alerts when your account is linked.

### Connect from the app

1. Log in to MEDCLUES
2. **Settings → Connect Telegram**
3. Tap **Connect** — Telegram opens (`tg://` with Play Store fallback)
4. Press **START** in the bot chat — account links without typing a password

| File | Role |
|------|------|
| `lib/services/telegram_link_service.dart` | `POST /api/user/telegram/link-code`, status |
| `lib/widgets/settings/telegram_connect_card.dart` | Settings UI + deep link launcher |
| `lib/utils/telegram_launcher.dart` | Opens Telegram app or `t.me` fallback |

### API endpoints

| Action | Path |
|--------|------|
| Generate link code | `POST /api/user/telegram/link-code` |
| Link status | `GET /api/user/telegram/status` |

### Bot commands (after link)

| Command | Action |
|---------|--------|
| `/start` | Welcome + main menu |
| `/dashboard` | **Open app home** button (`mediclues://dashboard`) |
| `/upcoming` | Next appointments |
| `/records` | Health records list |
| `/profile` | Your profile |
| `/logout` | Unlink Telegram |

### Real-time Telegram messages (backend)

When linked, the bot also sends proactive messages for:

- Appointment booked / cancelled
- New health report uploaded
- Appointment reminders (when scheduler is enabled)

Requires backend `TELEGRAM_BOT_ENABLED=true` on Render (only **one** server may poll the bot token).

### Config

| Key | Default | Purpose |
|-----|---------|---------|
| `TELEGRAM_BOT_USERNAME` | `medcluesBot` | Deep link `https://t.me/medcluesBot?start=link_<code>` |
| `--dart-define=TELEGRAM_BOT_USERNAME=...` | — | Override at APK build time |

---

## Push Notifications (FCM)

Firebase Cloud Messaging for appointment alerts when the app is closed or in background.

| File | Role |
|------|------|
| `lib/services/push_notification_service.dart` | Token register, foreground/background handlers |
| `lib/services/app_permissions_service.dart` | Contextual notification permission |
| `android/app/google-services.json` | Firebase Android config |

| Action | Path |
|--------|------|
| Register FCM token | `POST /api/user/fcm-token` |

Backend sends push on appointment book/cancel. Notification channel: `medclues_appointments`.

---

## App Deep Links

Telegram **🏠 Open App Home** and similar buttons use the custom scheme:

```
mediclues://dashboard          → app home (/dashboard)
mediclues://open/appointments  → appointments tab
mediclues://open/records       → health records
mediclues://open/doctors       → doctor list
mediclues://open/profile       → profile
```

| File | Role |
|------|------|
| `lib/services/app_deep_link_service.dart` | URI → `go_router` navigation (`app_links` package) |
| `lib/widgets/deep_link_listener.dart` | Starts listener at app boot |
| `android/app/src/main/AndroidManifest.xml` | `mediclues` intent filters |

**Test deep link (USB Android):**

```bash
adb shell am start -a android.intent.action.VIEW -d "mediclues://dashboard" com.medichain.medichain_mobile
```

> Deep links open the **native APK only**. Chrome/web does not handle `mediclues://` — use normal navigation in the web build.

---

## Hospitals, Labs & Blood Banks

| Feature | Endpoints |
|---------|-----------|
| Hospitals | List, detail, nearby GPS |
| Labs | `GET /api/lab/list` |
| Blood banks | `GET /api/blood-bank/list` + detail with blood-type availability |

List screens support **dark mode** with theme-aware premium widgets.

---

## Emergency Module

**Location:** `lib/features/emergency/`  
**No login required** — routes bypass auth redirect.  
**Always light theme** — `ForceLightTheme` on emergency screens.

### Access points

`EmergencyHelpButton` on: splash, login, signup, dashboard, profile, settings.

### SOS flow

```
Emergency Access
  ├── Auto-SOS countdown (default 30s, configurable)
  ├── "I Am Critical" → Emergency Active
  ├── "I Can Respond" → symptom picker → severity actions
  └── "Help Someone Else" → helper flow
```

### Severity actions

| Severity | Actions |
|----------|---------|
| Critical | Ambulance 108, WhatsApp relatives, nearby hospitals |
| Moderate | Video doctor, hospitals, WhatsApp |
| Minor | Book normal consultation |

### Emergency settings

| Field | Notes |
|-------|-------|
| 2 relative contacts | Name + phone required together |
| Blood group, allergies, conditions, medications | Optional |
| Auto-SOS timer | 10–120 seconds |
| Voice / triple-tap / shake SOS | Preference toggles |
| Auto location | Default on |

**Storage:** local `SharedPreferences` + **backend sync** when logged in (`emergency_api_service.dart` → `/api/user/emergency-contacts/*`).

**SOS audit:** logged-in SOS events sent to `POST /api/emergency/log-event`.

### Emergency numbers (India)

| Service | Number |
|---------|--------|
| Ambulance | 108 |
| Police | 100 / 112 |
| Fire | 101 |

### Testing mode vs production

| Build | `testingMode` | Emergency calls |
|-------|---------------|-----------------|
| **Debug** (`flutter run`) | `true` | Blocked — toast shown |
| **Release APK** | `false` | Real `tel:` calls to 108/100/101 |
| Release + override | `--dart-define=EMERGENCY_TESTING=true` | Blocked |

Configured in `lib/features/emergency/emergency_constants.dart`.

### Notify relatives

- WhatsApp message with live Google Maps link (`wa.me`)
- Phone call via system dialer
- System share sheet if no contacts saved

---

## Themes & Auth UI

| Area | Theme behavior |
|------|----------------|
| Login, signup, forgot password | **Always light** (`ForceLightTheme` via `LoginScreenShell`) |
| Emergency screens | **Always light** (`ForceLightTheme`) |
| Dashboard, booking, hospitals, labs, profile, settings | **System / light / dark** (user choice in Settings) |

Dark mode uses true-black scaffold (`#000000`) with theme-aware premium colors for hospital/booking flows.

### Settings → Appearance

- System default
- Light
- Dark

Persisted via `themeModeProvider` in `lib/providers/theme_provider.dart`.

---

## State Management

**Riverpod** (`flutter_riverpod`)

| Provider file | Purpose |
|---------------|---------|
| `auth_provider.dart` | Login state, session |
| `theme_provider.dart` | Light / dark / system |
| `booking_state_provider.dart` | Booking draft, patient selection |
| `appointment_provider.dart` | Appointments, slots, tabs |
| `doctor_provider.dart` | Doctors list, detail, filters |
| `payment_provider.dart` | Payment history |
| `health_record_provider.dart` | Health records list |
| `emergency_provider.dart` | SOS session, settings, location |
| `service_providers.dart` | Service + repository DI |

---

## Services & API Layer

### Core services

| Service | Purpose |
|---------|---------|
| `api_service.dart` | Dio client, JWT, refresh, 401 handling |
| `auth_service.dart` | Login, register, social, profile |
| `google_auth_service.dart` | Firebase Google auth |
| `appointment_service.dart` | Book, cancel, list |
| `payment_service.dart` | Razorpay flow |
| `consultation_service.dart` | Agora video |
| `emergency_api_service.dart` | Contact sync + SOS audit log |
| `health_record_service.dart` | Upload / list / view records |
| `hospital_service.dart` | Hospitals + nearby |
| `patient_service.dart` | Profile CRUD |
| `telegram_link_service.dart` | Telegram account linking |
| `push_notification_service.dart` | FCM token + notification taps |
| `app_deep_link_service.dart` | `mediclues://` → router |
| `app_permissions_service.dart` | In-context permission prompts |

### Key API endpoints

| Action | Path |
|--------|------|
| Login | `POST /api/user/login` |
| Register | `POST /api/user/register` |
| Social login | `POST /api/user/social-login` |
| Refresh token | `POST /api/auth/refresh` |
| Logout | `POST /api/auth/logout` |
| Profile | `GET /api/user/get-profile`, `PATCH /api/user/profile` |
| Appointments | `GET /api/user/appointments` |
| Book | `POST /api/user/book-appointment` |
| Payments | `/api/payments/*` |
| Emergency contacts | `/api/user/emergency-contacts/*` |
| Emergency log | `POST /api/emergency/log-event` |
| Health records | `/api/user/health-records/*` |
| Integrations | `GET /api/config/integrations` |
| Telegram link | `POST /api/user/telegram/link-code`, `GET /api/user/telegram/status` |
| FCM token | `POST /api/user/fcm-token` |

---

## Assets & Branding

| Asset | Path |
|-------|------|
| Logo / app icon source | `assets/images/medclues_logo.png` (1024×1024) |
| Launcher icons | Generated to `android/` + `ios/` via `flutter_launcher_icons` |
| Splash video | `assets/videos/opening.mp4` |
| Speciality icons | `assets/images/specialities/*.png` |
| Lottie | `assets/animations/` |
| Bundled env | `assets/config.env` |

Regenerate icons after logo change:
```bash
dart run flutter_launcher_icons
```

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | Primary | APK tested; ProGuard for Agora |
| **Web (Chrome)** | Supported | `config.env` required; autofill CSS in `index.html` |
| **iOS** | Supported | **Mac + Xcode required** to build |
| Windows / macOS / Linux | Scaffolded | Desktop builds possible, not primary target |

### Permissions

| Permission | Used for |
|------------|----------|
| Location | Emergency GPS, nearby hospitals |
| Camera / Mic | Video consultation |
| Internet | All API calls |
| Storage | Health record uploads |
| Notifications | FCM appointment alerts (requested in context) |

Permissions use **native system dialogs** when a feature needs them (Swiggy/Zomato style), not a blocking full-screen gate on every cold start.

---

## Form Validation

Client-side validation layer. **Backend must also validate** — frontend rules are UX only, not security.

### Core files

| File | Purpose |
|------|---------|
| `lib/utils/validators.dart` | All validation functions + `sanitizeText()` |
| `lib/utils/input_formatters.dart` | `FilteringTextInputFormatter`, `maxLength` per field type |
| `lib/constants/form_options.dart` | Shared dropdown enums (gender, relationship) |
| `lib/constants/profile_options.dart` | Profile-specific gender/blood group options |
| `lib/widgets/healthcare/premium_patient_form_field.dart` | Booking form fields with optional `validator` |

### Validation rules (`Validators` class)

| Field | Function | Rules |
|-------|----------|-------|
| Patient name | `patientName()` | Required; `A–Z` + single spaces; 2–50 chars; trim |
| Doctor name | `doctorName()` | Required; `A–Z` + spaces; 3–60 chars; no numbers |
| Age | `age()` | Required; integer 0–120; message: *"Please select a valid age."* |
| Contact (India) | `indianPhone()` | Required (optional flag); exactly 10 digits; starts 6–9 |
| Email | `email()` | Optional or required flag; format check; max 100 chars |
| Password | `password()` | 8–32 chars; 1 upper, 1 lower, 1 number, 1 special |
| Confirm password | `confirmPassword()` | Must match password |
| OTP | `otp()` | Exactly 6 digits |
| Address | `address()` | Max 250; letters, numbers, comma, hyphen, slash |
| Appointment reason | `appointmentReason()` | 5–500 chars; HTML stripped |
| Report title | `reportTitle()` | 3–100 chars |
| Emergency name | `emergencyContactName()` | Letters + spaces; max 50 |
| Emergency phone | `emergencyContactPhone()` | 10-digit Indian mobile |
| DOB vs age | `dobMatchesAge()` | DOB not in future; age must match DOB |

### Input formatters

| Formatter | Used for |
|-----------|----------|
| `InputFormatters.name` | Patient name (letters + space, max 50) |
| `InputFormatters.phone` | Digits only, max 10 |
| `InputFormatters.otp` | Digits only, max 6 |
| `InputFormatters.address` | Allowed address chars, max 250 |
| `InputFormatters.reportTitle` | Max 100 |
| `InputFormatters.appointmentReason` | Max 500 |

### Dropdown enums (`FormOptions`)

**Gender:** Male, Female, Other, Prefer not to say

**Relationship:** Father, Mother, Brother, Sister, Spouse, Son, Daughter, Guardian, Friend, Other

### Screens — validation status

| Screen | Status |
|--------|--------|
| Booking → Patient Details | **Implemented** — full rules + age picker |
| Signup / Login / Forgot password | Shared validators ready; **wiring in progress** |
| Profile / Address | **Pending** |
| Onboarding / Emergency settings | **Pending** |
| Health records upload | **Pending** (title + file size/type) |
| Booking symptoms / notes | **Pending** |

### UI behaviour (no layout/CSS changes)

- Existing field boxes, icons, borders, and themes are unchanged
- Invalid fields show a small error message **below** the input (same secondary text style)
- Submit/Continue disabled until the form is valid
- Validation runs on user interaction (`AutovalidateMode.onUserInteraction`)

### Sanitization

`Validators.sanitizeText()` trims whitespace, strips HTML tags, and enforces max length before API calls. Always pair with backend validation.

---

## Multi-Language (i18n)

**Languages:** English (default), Telugu (`te`), Hindi (`hi`)

| File | Purpose |
|------|---------|
| `l10n.yaml` | Flutter gen-l10n config |
| `lib/l10n/app_en.arb` | English strings (template) |
| `lib/l10n/app_te.arb` | Telugu translations |
| `lib/l10n/app_hi.arb` | Hindi translations |
| `lib/l10n/app_localizations.dart` | Generated — do not edit |
| `lib/providers/locale_provider.dart` | Locale state + SharedPreferences |
| `lib/l10n/l10n_extension.dart` | `context.l10n` shortcut |
| `lib/widgets/common/language_selector.dart` | Language picker UI |

### Language selector locations

- **Login** — top-right (`LanguageSelectorCompact`)
- **Settings** — Language card (`LanguageSelectorCard`)
- **Emergency Settings** — AppBar actions

### Usage in code

```dart
import '../../l10n/l10n_extension.dart';

Text(context.l10n.authSignIn);
validator: (v) => Validators.email(v, context.l10n),
```

### Persist & switch

- Saved key: `@pms/app_locale` in SharedPreferences
- Changing language rebuilds `MaterialApp` immediately — no logout required

### Regenerate after ARB edits

```bash
cd flutter_mobile
flutter gen-l10n
```

### Localization status

| Area | Status |
|------|--------|
| Auth (login, signup, forgot) | Done |
| Settings, profile menu | Done |
| Booking (patient form + full booking flow) | Done |
| Appointments list & detail | Done |
| Doctor search & profile | Done |
| Video consultation | Done |
| Health records | Done |
| Emergency (settings, access, active) | Done |
| Onboarding & tutorial | Done |
| Personal info & address | Done |
| PDF receipt | Done |
| Dashboard & bottom navigation | Done |
| Validators & error messages | Done |

---

## Google Play Store

### Prerequisites

1. [Google Play Console](https://play.google.com/console) account ($25 one-time fee)
2. Privacy policy URL (required for health apps)
3. Production API in `assets/config.env`: `https://medclues.onrender.com`
4. Store assets: 512×512 icon, 1024×500 feature graphic, phone screenshots, support email

### Step 1 — Create release signing key

Play Store rejects debug-signed builds. Current `build.gradle.kts` uses debug signing for release — change before publishing.

```powershell
cd flutter_mobile\android\app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (do **not** commit):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Wire `signingConfigs.release` in `android/app/build.gradle.kts` (see [Flutter Android signing docs](https://docs.flutter.dev/deployment/android#signing-the-app)).

### Step 2 — Build App Bundle (AAB)

```powershell
cd flutter_mobile
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build appbundle --release --dart-define=API_BASE_URL=https://medclues.onrender.com
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

Bump version in `pubspec.yaml` before each upload:

```yaml
version: 1.0.1+2   # versionName + versionCode (code must increase every release)
```

### Step 3 — Firebase SHA-1 for Play builds

Add the **upload keystore** SHA-1 to Firebase (Google Sign-In on Play builds):

```powershell
.\get_android_sha.ps1
# or:
keytool -list -v -keystore android\app\upload-keystore.jks -alias upload
```

### Step 4 — Play Console checklist

| Task | Notes |
|------|-------|
| Store listing | Title, descriptions, icon, feature graphic, screenshots |
| App access | Provide test login if reviewers need an account |
| Content rating | Complete IARC questionnaire |
| Data safety | Declare health, location, contact, payment data |
| Privacy policy | URL required |
| Internal testing | Upload AAB → test → then promote to Production |

### Step 5 — Submit

1. **Release** → **Internal testing** (recommended first) or **Production**
2. Upload `app-release.aab`
3. Complete all policy forms (green checkmarks)
4. **Send for review** — typically 1–7 days

### App identifiers

| Item | Value |
|------|-------|
| Application ID | `com.medichain.medichain_mobile` |
| Display name (launcher) | MediChain+ (`AndroidManifest.xml`) |
| Package name (pubspec) | `medichain_mobile` |

---

## Scripts & Tooling

| Script | Purpose |
|--------|---------|
| `sync_env.ps1` | Sync API URL from legacy Expo `mobile/.env` |
| `run_chrome.ps1` | Sync env + run Chrome |
| `run_android_phone.ps1` | LAN IP detect + run on USB Android |
| `get_android_sha.ps1` | Print SHA-1 for Firebase Console |

```bash
flutter analyze          # Static analysis
flutter test             # Widget tests
dart run flutter_launcher_icons   # Regenerate app icons
```

---

## Troubleshooting

### Cannot reach API from phone

- Use `https://medclues.onrender.com` in `assets/config.env` (not `localhost`)
- For local backend: same Wi‑Fi, `uvicorn --host 0.0.0.0 --port 5000`, PC LAN IP in config
- Rebuild APK after changing `config.env`

### Login/signup fields show grey block on web when focused

- Fixed via `AuthInput` + `web/index.html` autofill CSS
- Do **full restart** after `index.html` changes

### Google Sign-In fails

- Add Android SHA-1 to Firebase (`get_android_sha.ps1`)
- Set `GOOGLE_WEB_CLIENT_ID` in `config.env`
- Verify `google-services.json` / `GoogleService-Info.plist` exist

### Release APK build fails (R8 / Agora)

- `android/app/proguard-rules.pro` includes Agora `-dontwarn` rules
- Run `flutter clean` then rebuild

### Emergency calls don't work

- **Debug build:** calls blocked (`testingMode = true`) — expected
- **Release APK:** calls 108/100/101 work
- Use `--dart-define=EMERGENCY_TESTING=true` to block in release test builds

### iPhone on Windows

- Cannot build iOS on Windows — use a Mac or distribute via TestFlight

### Video consult won't connect

- Set `AGORA_APP_ID` or verify backend Agora config
- Grant camera/microphone permissions
- Check `GET /api/config/integrations`

### Payment stuck after Razorpay

- Tap **"I've paid"** in app → calls `POST /api/payments/confirm-order`
- Backend persists order in `payment_transactions` table

### Dark mode on login page

- Login/signup **always light** — if you still see dark inputs, hot restart the app

### Booking Continue button stays disabled

- Fill all Patient Details fields with valid values
- Age must be selected via the age wheel picker (tap the Age field)
- Contact must be exactly 10 digits starting with 6–9

### Form validation errors not visible

- Errors appear as small text below the field (not inside the input box)
- Hot restart after code changes to `premium_patient_form_field.dart`

### Play Store upload rejected (signing)

- Release builds must use `upload-keystore.jks`, not the debug keystore
- See [Google Play Store](#google-play-store) section

### Connect Telegram shows 404 / Not found

- Backend on Render must be **Live** (check health: `https://medclues.onrender.com/docs`)
- Render env: `JWT_SECRET` ≥ 32 chars, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_USERNAME=medcluesBot`
- Rebuild APK with `--dart-define=TELEGRAM_BOT_USERNAME=medcluesBot`
- Only one server polls the bot — `TELEGRAM_BOT_ENABLED=true` on Render, `false` locally

### Telegram "Open App Home" does nothing

- Install the MEDCLUES APK first (deep links are not for web/Chrome)
- Rebuild APK after `AndroidManifest.xml` deep-link changes
- Test with: `adb shell am start -a android.intent.action.VIEW -d "mediclues://dashboard" com.medichain.medichain_mobile`

### `flutter pub get` symlink warning (Windows)

- Enable **Developer Mode**: `start ms-settings:developers`
- Then run `flutter pub get` again

### OPD slot count not decreasing for second user

- Requires latest backend on Render (slot capacity fix)
- Booking screen refreshes slots every 10s — pull to refresh or re-enter screen

---

## Related Documentation

| Document | Location |
|----------|----------|
| Monorepo overview | [../README.md](../README.md) |
| Backend deploy | [../BACKEND_GITHUB_DEPLOY.md](../BACKEND_GITHUB_DEPLOY.md) |
| Backend security steps | [../fastapi_back/SECURITY_STEP1.md](../fastapi_back/SECURITY_STEP1.md) |
| Agora video | [../fastapi_back/AGORA_VIDEO.md](../fastapi_back/AGORA_VIDEO.md) |
| Telegram bot | [../fastapi_back/TELEGRAM_BOT.md](../fastapi_back/TELEGRAM_BOT.md) |
| Phone API testing | [../fastapi_back/README_PHONE.md](../fastapi_back/README_PHONE.md) |

---

## License

Part of the MEDCLUES healthcare platform. Do not commit `.env`, Firebase keys, or credential files to public repositories.
