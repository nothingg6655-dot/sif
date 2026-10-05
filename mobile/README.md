# SIF Mobile (Flutter)

A production-quality Flutter mobile application connecting directly to the shared Node.js backend for Specialized Investment Funds (SIF) and mutual funds analytics.

---

## 1. Flutter Requirements

- **Flutter SDK**: `^3.13.4` or later (tested on Flutter `3.47.5`, Dart `3.13.4`)
- **Android Studio / Android SDK**: Platform API 34+
- **Xcode** (macOS only, for iOS development): 15+
- **Node.js**: v20+ (for local backend)
- **PostgreSQL**: v15+ (with database `dynasif_moneycontrol`)

---

## 2. Project Architecture

The application follows a clean, feature-oriented layered architecture:

```text
mobile/
├── android/              # Native Android configuration (cleartext enabled for dev)
├── ios/                  # Native iOS configuration
├── lib/
│   ├── main.dart         # App entry point, dependency injection, environment validation
│   ├── app/
│   │   ├── app.dart      # Navigation shell, bottom bar, route generator
│   │   └── theme.dart    # Material 3 theme system (deep navy brand palette)
│   ├── core/
│   │   ├── config/
│   │   │   └── api_config.dart # Environment-driven API base URL resolution
│   │   ├── network/
│   │   │   └── api_client.dart # Centralized HTTP client, headers, error wrapping
│   │   └── widgets/
│   │       └── states.dart     # Common UI widgets (StatusView, Fact, Section, formatting)
│   └── features/
│       ├── admin/
│       │   ├── admin_screen.dart      # Protected administration screen
│       │   ├── import_repository.dart # Excel parsing analysis & commit API
│       │   └── import_screen.dart     # Multi-step Excel ingestion UI
│       ├── auth/
│       │   └── session.dart           # Secure key storage & admin authentication state
│       ├── calculator/
│       │   └── cost_calculator.dart   # Fee compounding investment calculator
│       ├── compare/
│       │   └── compare_screen.dart    # Peer comparison and performance explorer
│       ├── funds/
│       │   ├── data/
│       │   │   ├── fund_repository.dart # Funds, details, analytics, comparison APIs
│       │   │   └── models.dart          # Typed Dart data models with null-safety
│       │   ├── presentation/
│       │   │   ├── analytics_panel.dart # Returns, risk, monthly heat tables, drawdowns
│       │   │   ├── detail_screen.dart   # Comprehensive fund factsheet
│       │   │   ├── discover_screen.dart # Fund discovery, search, and category filters
│       │   │   ├── fund_tile.dart       # Reusable fund card
│       │   │   └── series_chart.dart    # FLChart interactive NAV / drawdown timeline
│       │   └── fund_controller.dart     # Provider-based fund state management
│       └── tracker/
│           └── tracker_screen.dart      # Active schemes, Live NFO, and upcoming launches
├── test/                 # Comprehensive unit, repository, and widget tests
│   ├── api_test.dart
│   ├── calculator_test.dart
│   ├── controller_test.dart
│   ├── live_api_test.dart
│   ├── navigation_test.dart
│   └── session_test.dart
└── pubspec.yaml
```

---

## 3. Setup and Dependencies

Install Flutter dependencies:

```bash
cd mobile
flutter pub get
```

Key dependencies used:
- `http`: Centralized networking and multipart uploads
- `provider`: Consistent state management
- `flutter_secure_storage`: Keystore/Keychain credential persistence for admin key
- `file_picker`: Native file selection for Excel workbooks
- `fl_chart`: Interactive performance and drawdown visualizations
- `flutter_lints`: Clean static analysis enforcement

---

## 4. Backend Setup

The mobile application connects to the single existing Fastify/Node.js backend in `/backend`.

1. Ensure PostgreSQL is running and has the schema loaded:
   ```bash
   psql -U postgres -d dynasif_moneycontrol -f backend/dynasif_moneycontrol_postgres.sql
   ```
2. Verify environment configuration in `backend/.env`:
   ```env
   NODE_ENV=development
   PORT=3000
   DATABASE_URL=postgresql://postgres:Shri%401927@localhost:5432/dynasif_moneycontrol
   ADMIN_API_KEY=dynasif-admin-local
   ```
3. Start the backend:
   ```bash
   cd backend
   npm run dev
   ```
   The backend will listen on `0.0.0.0:3000`.

---

## 5. Local Networking & Environment Variables

The mobile app relies on `--dart-define=API_BASE_URL=...` to set the API endpoint at runtime.

### Android Emulator
Android Emulators cannot access the host machine via `localhost`. Use `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```
*(Default fallback on Android if not specified is `http://10.0.2.2:3000`)*

### iOS Simulator
iOS Simulators share the host network:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```
*(Default fallback on iOS/Desktop is `http://localhost:3000`)*

### Physical Android or iOS Device
When testing on a physical phone connected over Wi-Fi, point to your host computer's local LAN IP:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.XX:3000
```

---

## 6. Authentication & Roles

- **Public Features**: Scheme discovery, searching, category filters, factsheets, NAV history, analytics, returns, comparisons, and fee calculator do not require authentication.
- **Administrator Role**: Admin data operations (`/api/admin/ingestion-runs`, `/api/admin/import/excel/*`) require an administrator key (`x-admin-key: dynasif-admin-local`).
- **Session Management**:
  - Securely persisted using `flutter_secure_storage`.
  - Automatically restored on app launch.
  - Automatically invalidated on HTTP 401.
  - No plaintext credentials stored.

---

## 7. Quality Assurance & Testing

Run analyzer:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

All unit, integration, and UI widget tests validate:
- URL validation and release HTTPS requirements
- Repository query params and pagination
- Compounding math in Cost Calculator
- Admin session lifecycle and secure storage
- Safe error mapping (no raw server stack traces)
- Debounced search state
- Multi-fund comparison caps
- Factsheet rendering and chart generation

---

## 8. Build Commands

### Android APK (Debug):
```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### Android APK (Release):
Release mode enforces HTTPS endpoints:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com
```

---

## 9. Known Limitations

- Excel import commits support NAV history sheets; additional dataset types (e.g. quarterly portfolios) are parsed and classified, with full backend ingestion endpoints ready.
- Live NFO and Upcoming launch tabs display informative placeholder states reflecting currently available AMFI database records.
