# Progress Tracker — Architecture & Implementation Plan

> **Scope**: High-level technical plan following Clean Architecture for offline-first habit/task tracking with Supabase and Google Sign-In.

---

## 1. System Architecture

The application strictly adheres to **Clean Architecture** (Separation of Concerns, unidirectional data flow, Dependency Inversion):

```
lib/
├── core/
│   ├── network/          # Network connectivity checker
│   ├── error/            # Failures & Exceptions
│   └── database/         # Local DB client & sync coordinator
└── features/
    ├── auth/             # Google Sign-In & session management
    │   ├── data/         # Supabase Auth data source & user model
    │   ├── domain/       # User entity & Auth repository interface
    │   └── presentation/ # Splash & unified Sign-In page (Bloc)
    └── tasks/            # Tasks, entries & contribution grids
        ├── data/         # Local & Remote (Supabase) data sources, repos
        ├── domain/       # Task & TaskEntry entities, use cases
        └── presentation/ # Task list, green grid widget, morning review (Bloc)
```

---

## 2. Core Flows & UI Specifications

### A. Authentication & Splash
- **Splash Screen**: Checks active session via `Supabase.instance.client.auth.currentSession`.
  - Authenticated → Route to Task List.
  - Unauthenticated → Route to Auth Screen.
- **Unified Sign-In / Sign-Up Screen**:
  - Single screen with one primary action: **"Continue with Google"** (`google_sign_in` + Supabase OAuth `signInWithIdToken`).
  - No email/password forms or separate registration screens.

### B. Task Creation & Setup Wizard (Step-by-Step Question Sequence)
A dedicated, distraction-free onboarding sequence (`PageView` with spring animations and progress indicator) where each screen asks a single focused question before creating the task:

1. **Page 1: Task Identity & Meaning**
   - *"What habit or goal are you committing to?"*
   - Clean, large typography input (e.g., *"Read 20 pages"*, *"Morning Workout"*, *"Deep Work 1 hr"*).
   - Optional quick-preset suggestions (Health, Learning, Mindfulness, Fitness).

2. **Page 2: Repetition & Frequency Cadence**
   - *"How often do you want to perform this?"*
   - Three distinct repetition modes:
     - **Daily (Multiple Days Selection)**:
       - User selects any combination of days of the week (1 = Mon ... 7 = Sun).
       - Presets: *Every Day* (all 7 days), *Weekdays* (Mon–Fri), *Weekends* (Sat–Sun), or *Custom* (interactive M/T/W/T/F/S/S pill toggle).
     - **Weekly (Once a Week)**:
       - User selects exactly **one day of the week** (e.g., *Every Sunday*, *Every Saturday*).
       - The grid tracks weekly completion milestone markers.
     - **Monthly (Day Number or Start/End)**:
       - User selects one of three monthly schedule rules:
         - **Specific Day Number**: A numeric day of the month (1 through 31, e.g., the 15th of every month).
         - **Start of the Month**: Evaluates on the 1st of each month.
         - **End of the Month**: Automatically evaluates on the last day of each month (handling 28, 29, 30, and 31).

3. **Page 3: Start Time & Daily Window**
   - *"When is your ideal time to do this?"*
   - Quick time buckets: Morning (08:00), Afternoon (13:00), Evening (19:00), or Custom time picker.
   - Optional expected duration (e.g., 15m, 30m, 1h) to frame intentionality.

4. **Page 4: Notification Budget & Accountability Reminders**
   - *"How many nudges do you need before checking in?"*
   - Options:
     - **0 — Silent Mode**: No push notifications (self-motivated/manual check-in).
     - **1 — Single Reminder**: One notification at the chosen start time.
     - **2 — Gentle Follow-up**: One reminder at start time + one evening check-in before bed.
     - **3 — High Accountability**: Morning kickoff + midday reminder + final evening warning before streak breaks.

5. **Page 5: Grid Aesthetics & Custom Color Palette**
   - *"Choose the color for your contribution grid"*
   - Live interactive mini-grid preview updating in real-time as the user selects:
     - **Classic Emerald** (`#22C55E` — default brand green).
     - **Cyber Mint** (`#86EFAC` — light, energetic).
     - **Neon Jade** (`#10B981` — deep tech green).
     - **Royal Violet** (`#8B5CF6` — high-focus purple).
     - **Sunset Amber** (`#F59E0B` — warmth & energy).
     - **Electric Cyan** (`#06B6D4` — calm focus).

6. **Page 6: Review & Final Confirmation**
   - *"Accountability Rules"*
   - Toggle: **Include in Morning Review?** (Prompt every morning for yesterday's status).
   - Summary card with live preview of the task card and configured grid color.
   - Primary action: **"Create Habit & Start Grid"**.

### C. Tasks & The Green Grid
- **Minimalist Task Row**: Displays only the task name and its historical contribution grid in its configured color.
- **Green Grid (Heatmap)**:
  - Renders a horizontal matrix of cells representing past days/months.
  - **Active cell (custom color)**: Task status = `'done'`.
  - **Muted/Grey cell**: Task status = `'missed'` or uncompleted.
  - Visual density shows consistency at a glance.

### D. Morning Review Workflow
- At the start of the day (or first app open in the morning), prompt user for pending task entries from the previous cycle.
- Simple binary actions: Mark **Done** (custom color) or **Missed** (grey).

### E. Offline-First Storage & Synchronization
- **Local-First Writes**: All additions and status updates are saved immediately to local storage (e.g. SQLite / Drift / Hive) with a `sync_status` flag (`synced` vs `pending`).
- **Background Sync**:
  - When network is connected, push `pending` records to Supabase (`tasks` and `task_entries`).
  - Pull remote changes using `entry_date` and `answered_at` timestamps to resolve state.

---

## 3. Database Schema Mapping

### Supabase Tables
1. **`public.tasks`**:
   - `id` (uuid, PK)
   - `user_id` (uuid, FK auth.users)
   - `name` (text, 1-100 chars)
   - `frequency_type` (`daily` | `weekly` | `monthly`, default: `'daily'`)
   - `days_of_week` (smallint[], default: `'{1,2,3,4,5,6,7}'` — 1=Mon .. 7=Sun)
     - *Daily mode*: contains all chosen active days (e.g. `[1,2,3,4,5]`).
     - *Weekly mode*: contains exactly one day (e.g. `[7]` for Sunday).
   - `monthly_rule` (varchar(20), default: NULL)
     - *Monthly mode*: `'start'`, `'end'`, or specific day number `'1'` through `'31'`.
   - `start_time` (time without time zone, optional, e.g. `'08:00:00'`)
   - `reminder_count` (smallint, 0 to 3, default: 1)
   - `grid_color` (varchar(10), default: `'#22C55E'`)
   - `include_in_morning_review` (boolean, default: true)
   - `archived` (boolean, default: false)
   - `created_at` (timestamptz, default: `now()`)

2. **`public.task_entries`**:
   - `id` (uuid, PK)
   - `task_id` (uuid, FK tasks)
   - `user_id` (uuid, FK auth.users)
   - `entry_date` (date)
   - `status` (`done` | `missed`)
   - `answered_at` (timestamptz)

### SQL Migration Script (Supabase SQL Editor)
Run this migration in your Supabase Dashboard to update your existing `public.tasks` table:

```sql
-- Migration: Add wizard fields and enhanced repetition support to tasks
ALTER TABLE public.tasks 
  ADD COLUMN IF NOT EXISTS frequency_type VARCHAR(20) DEFAULT 'daily',
  ADD COLUMN IF NOT EXISTS days_of_week SMALLINT[] DEFAULT '{1,2,3,4,5,6,7}',
  ADD COLUMN IF NOT EXISTS monthly_rule VARCHAR(20) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS start_time TIME WITHOUT TIME ZONE DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS reminder_count SMALLINT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS grid_color VARCHAR(10) DEFAULT '#22C55E',
  ADD COLUMN IF NOT EXISTS include_in_morning_review BOOLEAN DEFAULT TRUE;

-- Comment definitions for clarity
COMMENT ON COLUMN public.tasks.frequency_type IS 'daily (multi-day), weekly (single-day), or monthly';
COMMENT ON COLUMN public.tasks.days_of_week IS 'Array of days: 1=Mon, 2=Tue, ..., 7=Sun';
COMMENT ON COLUMN public.tasks.monthly_rule IS 'start, end, or specific day 1..31 for monthly frequency';
```

### Local Storage Schema
- Mirror the Supabase tables exactly, adding:
  - `is_dirty`: `bool` (indicates local mutation awaiting sync)
  - `updated_at`: `datetime` (for conflict resolution)

---

## 4. Implementation Steps

### Step 1: Package Dependencies
Add required packages to `pubspec.yaml`:
- `supabase_flutter`: Backend auth, database, and real-time.
- `google_sign_in`: Native Google authentication.
- `flutter_bloc`: State management.
- `get_it`: Service locator (DI).
- `sqflite` (or `drift`): Local persistent offline storage.
- `connectivity_plus`: Network status monitoring for auto-sync.

### Step 2: Supabase & Dependency Injection Setup
1. Initialize `Supabase` in `lib/main.dart` with project URL and Anon key.
2. In `lib/injection.dart`, register:
   - Supabase client, local DB, and network info (singletons).
   - Data sources (local and remote) and repositories.
   - Use cases and BLoCs (factories).

### Step 3: Auth Feature (Splash & Google Login)
1. **Domain**: `AuthRepository` (`signInWithGoogle`, `signOut`, `getCurrentUser`).
2. **Data**: `AuthRemoteDataSource` wrapping `GoogleSignIn` and `supabase.auth.signInWithIdToken`.
3. **Presentation**:
   - `SplashPage`: Plays animated logo while checking session via `AuthBloc` on startup.
   - `SignInPage`: Single button UI calling `AuthBloc.add(SignInWithGoogleRequested())`.

### Step 4: Local Storage & Sync Engine
1. Implement local database tables for `tasks` and `task_entries`.
2. Create `SyncCoordinator`:
   - Listens to connectivity changes via `connectivity_plus`.
   - On online event: queries unsynced rows from local DB, performs batch upsert to Supabase, and clears the dirty flag.

### Step 5: Multi-Page Task Setup Wizard (`TaskSetupWizardPage`)
1. Implement a 6-step animated `PageView` with smooth step indicators:
   - **Step 1 (Name):** Habit name input & category suggestions.
   - **Step 2 (Repetition):** Cadence selector:
     - *Daily*: Multi-day toggle (e.g. Mon–Sun, Mon–Fri, custom days).
     - *Weekly*: Single-day picker (e.g. Every Sunday).
     - *Monthly*: Day of month (1..31), start of month, or end of month.
   - **Step 3 (Start Time):** Time of day picker (Morning, Afternoon, Evening, Custom).
   - **Step 4 (Notifications):** Nudge budget (0 = Silent, 1 = Single, 2 = Gentle, 3 = High Accountability).
   - **Step 5 (Grid Color):** Interactive color palette picker with live preview.
   - **Step 6 (Accountability):** Morning review inclusion toggle & final habit summary card.
2. Form validation preventing advancement until required fields are valid.
3. Wire submit action to `TasksBloc.add(AddTaskSubmitted(...))`.

### Step 6: Tasks & Contribution Grid Feature
1. **Domain**:
   - Entities: `TaskEntity` (enhanced with frequency, time, reminders, color), `TaskEntryEntity`.
   - Use cases: `GetTasksWithHistory`, `CreateTask`, `RecordDailyEntry`.
2. **Data**:
   - `TaskRepositoryImpl`: Reads from local DB first; triggers background sync from Supabase.
3. **Presentation**:
   - `TasksBloc`: Manages tasks and historical entries state.
   - `TaskCard`: Minimalist card showing task title and custom-colored `ContributionGrid`.
   - `ContributionGrid`: Custom-painted or flex grid rendering custom-color boxes for `'done'` status across historical dates.

### Step 7: Morning Review Dialog / BottomSheet
1. Check for tasks with no entry for yesterday / today morning that have `include_in_morning_review == true`.
2. Display quick-action prompt for each pending task:
   - **Done** (records status: `'done'`, entry_date: target date).
   - **Missed** (records status: `'missed'`, entry_date: target date).

