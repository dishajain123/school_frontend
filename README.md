# Gurukul Mobile App (`sms_app`)

Flutter application for school stakeholders: principals, trustees, teachers, students, and parents.

## Project Overview

Gurukul is a role-based School Management System mobile app that connects academic, operational, and communication workflows in one client.  
It is built for day-to-day school operations and self-service access by different user roles, while `STAFF_ADMIN` users are redirected to use the web admin console flow.

## Tech Stack

- **Framework**: Flutter
- **Dart SDK constraint**: `>=3.3.0 <4.0.0` (from `pubspec.yaml`)
- **State management**: `flutter_riverpod` (Notifier/AsyncNotifier/FutureProvider/StateNotifier patterns)
- **Routing**: `go_router` with `ShellRoute`
- **Networking**: `dio`
- **Storage**:
  - `flutter_secure_storage` for tokens
  - `shared_preferences` for cached user/session metadata and app prefs
- **Realtime**: `web_socket_channel` (chat)
- **UI/Utilities**: `google_fonts`, `cached_network_image`, `shimmer`, `intl`, `file_picker`, `image_picker`, `permission_handler`, `url_launcher`, `syncfusion_flutter_pdfviewer`, `pdfx`

## Project Setup

```bash
flutter pub get
flutter run
flutter analyze
flutter build apk
flutter build web
```

## Folder Structure (`lib/`)

```text
lib/
├── app.dart                         # MaterialApp.router bootstrap
├── main.dart                        # app init + orientation + SharedPreferences override
├── core/
│   ├── auth/                        # auth logout event bus
│   ├── constants/                   # API paths, storage keys, app constants
│   ├── errors/                      # app exception/failure mapping
│   ├── network/                     # Dio client + interceptors
│   │   └── interceptors/            # auth, envelope, error handling
│   ├── router/                      # GoRouter + route names
│   ├── storage/                     # secure/local storage wrappers
│   ├── theme/                       # colors, typography, dimensions, decorations
│   └── utils/                       # validators, date/file/media/url helpers, extensions
├── data/
│   ├── models/                      # typed API models (auth, attendance, fees, etc.)
│   └── repositories/                # API access layer per domain
├── presentation/
│   ├── academic_year/
│   ├── announcements/
│   ├── assignments/
│   ├── attendance/
│   ├── audit/
│   ├── auth/
│   ├── behaviour/
│   ├── chat/
│   ├── common/                      # shared widgets, shell, bottom nav
│   ├── complaints/
│   ├── dashboard/
│   ├── diary/
│   ├── documents/
│   ├── enrollment/
│   ├── exam_schedule/
│   ├── fees/
│   ├── gallery/
│   ├── homework/
│   ├── leave/
│   ├── masters/
│   ├── my_class/
│   ├── notifications/
│   ├── parents/
│   ├── profile/
│   ├── reports/
│   ├── results/
│   ├── settings/
│   ├── students/
│   ├── superadmin/
│   ├── teacher_schedule/
│   ├── teachers/
│   └── timetable/
└── providers/                       # Riverpod providers/notifiers per domain
```

## Architecture Overview

Primary flow:

`UI (presentation/screens)` → `Provider/Notifier (lib/providers)` → `Repository (lib/data/repositories)` → `DioClient + Interceptors` → `Backend API`

Key characteristics:

- Clear separation between UI, state, and data access.
- Providers own UI-facing state and orchestration.
- Repositories encapsulate endpoint calls and model parsing.
- Interceptors standardize auth headers, response envelopes, and error mapping.

## Authentication Flow

- Login via `AuthRepository.login` (`/auth/login`) and fetch profile via `/auth/me`.
- Access + refresh tokens stored in **SecureStorage**.
- Backup token copies also stored in **SharedPreferences** for restart resiliency.
- User profile + role + permissions cached in local storage.
- On app startup, `AuthNotifier.initialize()` restores session from cached user/token, then refreshes from `/auth/me`.
- Router redirects:
  - Unauthenticated users to `/login`.
  - `STAFF_ADMIN` users to `/staff-use-web-console`.
  - Users with `enrollment_pending && !profile_created` to `/enrollment-pending`.
- Logout clears secure + local auth data.

## API Layer

- `dioClientProvider` builds `Dio` with base URL + `/api/v1` prefix.
- Base URL resolution supports:
  - Android emulator host fix (`10.0.2.2`)
  - web host-aware local base
  - optional compile-time env overrides (`API_BASE_URL`, `WS_BASE_URL`)
- Interceptors:
  - **AuthInterceptor**:
    - injects `Bearer` token
    - excludes auth/public endpoints
    - retries once on `401` using refresh token flow
  - **EnvelopeInterceptor**:
    - unwraps `{ success, data, message, error }` responses
  - **ErrorInterceptor**:
    - maps Dio/network/http failures to typed app exceptions
    - retries local-host failures across host fallbacks (`localhost`, `127.0.0.1`, `10.0.2.2`, `host.docker.internal`)

## Features (`lib/presentation`)

Implemented feature modules include:

- Authentication
- Dashboard (role-based variants)
- Notifications
- Announcements
- Academic Year + rollover
- Masters (standards, subjects, grades)
- Teachers
- Students
- Parents
- Attendance
- Assignments + submissions
- Homework
- Diary
- Timetable + upload + exam schedule
- Results + report card + distribution
- Fees + payments + receipts
- Chat (conversation + room + file send + reactions)
- Leave
- Gallery
- Documents
- Complaints
- Behaviour logs
- Enrollment / reenrollment / academic history
- Reports
- School settings
- Audit logs
- Teacher schedule
- My Class
- Common shell/navigation/widgets

## State Management Strategy

Patterns in use:

- `StateNotifierProvider` for auth and some form workflows.
- `NotifierProvider` / `AsyncNotifierProvider` for domain state with mutations.
- `FutureProvider` / `FutureProvider.family` for request-based reads.
- `autoDispose` used in multiple places for scoped lifecycle/caching.
- Providers inject repositories through Riverpod (`ref.read(repositoryProvider)`).
- Some providers explicitly watch current user to scope cache by session and avoid cross-user leakage.

## Constraints / Design Decisions

- App is backend-dependent; API schema/permissions drive visible behavior.
- Role-driven shell tabs and navigation behavior are built into routing/shell config.
- Mobile behavior differs for `STAFF_ADMIN`: app shows “use web console” screen.
- Orientation is locked to portrait in `main.dart`.
- Session resilience uses secure token storage plus shared-preferences backups.
- Presigned URL downloads (documents/timetable-like flows) are treated as short-lived and fetched fresh.

## Development Guidelines (from existing patterns)

- Add domain models in `lib/data/models/<domain>/`.
- Add API calls in `lib/data/repositories/<domain>_repository.dart`.
- Expose UI state through `lib/providers/<domain>_provider.dart`.
- Keep screens/widgets under `lib/presentation/<domain>/`.
- Use `ApiConstants` for endpoints; avoid hardcoded paths.
- Keep auth/session concerns inside auth/storage/interceptor layers.
- Use provider injection for dependencies instead of direct object creation in UI.
- For role-aware navigation, update `RouteNames`, `app_router`, and `role_shell_config` together.

## Known Limitations (visible in code)

- Periodic polling exists in some flows (for example document status every 10s, auto-refresh timers in certain screens).
- Some UI actions remain marked as TODO (example: announcement attachment download/open path).
- Presigned download URLs are intentionally not cached long-term.
- Local backend connectivity can require host mapping depending on platform/environment.
