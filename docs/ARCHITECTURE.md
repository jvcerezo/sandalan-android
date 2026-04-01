# Sandalan Architecture

## Overview

Sandalan is a local-first Flutter app with cloud sync. All reads and writes hit the local Drift (SQLite) database immediately. Background sync pushes pending changes to Supabase and pulls remote changes periodically.

```
┌─────────────┐     ┌───────────┐     ┌──────────┐
│  Flutter UI  │────>│  Drift DB │<───>│ Supabase │
│  (Riverpod)  │<────│  (SQLite) │     │  (Cloud) │
└─────────────┘     └───────────┘     └──────────┘
     reads              source           backup +
     writes             of truth         cross-device
```

## Data Flow

### Write Path
```
User taps "Add Expense"
  → AddTransactionDialog validates input
  → LocalTransactionRepository.createTransaction()
    → Drift DB upsert (sync_status = 'pending')
    → Account balance updated locally
    → SyncService.pushAfterWrite() fires (5s debounce)
      → Supabase upsert (marks 'synced' on success)
  → UI refreshes via Riverpod provider invalidation
```

### Read Path
```
Screen builds
  → Riverpod provider watches data
  → Provider calls repository method
  → Repository queries Drift SQLite
  → Returns Dart model objects
  → UI renders immediately (no network wait)
```

### Sync Path
```
App startup     → fullSync() (pull then push)
App resume      → pullIfStale() (if >30s since last sync)
App background  → fullSync() (push pending before sleep)
After write     → pushAfterWrite() (5s debounced)
Connectivity    → syncIfDailyDue() (when network restored)
```

## Layer Architecture

```
┌──────────────────────────────────────────────┐
│                  UI Layer                      │
│  features/*/screens/    features/*/widgets/    │
│  (StatefulWidget, ConsumerWidget)              │
├──────────────────────────────────────────────┤
│                Provider Layer                  │
│  features/*/providers/   (Riverpod)            │
│  FutureProvider, StateProvider, etc.           │
├──────────────────────────────────────────────┤
│              Repository Layer                  │
│  data/repositories/local_*_repository.dart     │
│  (validates, sanitizes, writes to Drift,       │
│   triggers sync)                               │
├──────────────────────────────────────────────┤
│               Service Layer                    │
│  core/services/                                │
│  (business logic, sync, billing, streak,       │
│   premium, OCR, notifications)                 │
├──────────────────────────────────────────────┤
│                Data Layer                      │
│  data/local/app_database.dart  (Drift SQLite)  │
│  Supabase client (cloud)                       │
└──────────────────────────────────────────────┘
```

## Navigation System

### GoRouter with Shell

```
GoRouter
├── /login              (full-screen, no nav)
├── /signup             (full-screen, no nav)
├── /onboarding         (full-screen, no nav)
├── /guide/:slug        (full-screen, SafeBackWrapper)
├── /guide/:slug/:guide (full-screen, SafeBackWrapper)
├── /guide/:slug/checklist/:id (full-screen, SafeBackWrapper)
│
└── ShellRoute (AppScaffold — bottom nav + header)
    ├── /home           (Tab 0: Home)
    ├── /guide          (Tab 1: Guide)
    ├── /dashboard      (Tab 3: Money — 4 sub-tabs)
    ├── /more           (Tab 4: More)
    ├── /goals          (Tab 3 highlight)
    ├── /settings       (Tab 4 highlight)
    ├── /achievements   (Tab 4 highlight)
    ├── /tools/*        (Tab 4 highlight, premium-gated)
    ├── /investments    (Tab 4 highlight, premium-gated)
    ├── /split-bills    (Tab 4 highlight, premium-gated)
    ├── /vault          (Tab 4 highlight, premium-gated)
    ├── /chat           (Tab 4 highlight, premium-gated)
    ├── /reports        (Tab 4 highlight, premium-gated)
    └── /reports/:y/:m  (Tab 4 highlight, premium-gated)
```

### Router Redirect Chain

Every navigation goes through this sequence:
1. **Auth check**: Not logged in and not guest → redirect to `/login`
2. **Guest guard**: Guest trying to access `/login` → redirect to `/signup`
3. **Session guard**: Logged in on `/signup` → redirect to `/home`
4. **Premium guard**: `blockedByPremium(path)` → redirect to `/home` if blocked

### Back Button Behavior

```
/home           → double-press exits app
/dashboard      → /home
/goals          → /dashboard
/transactions   → /dashboard
/accounts       → /dashboard
/budgets        → /dashboard
/more           → /home
/settings       → /more
/tools/*        → /more
/investments    → /more
/split-bills    → /more
/vault          → /more
/chat           → /more
/reports        → /more
/reports/:y/:m  → /reports
```

## Premium System

See [PREMIUM.md](PREMIUM.md) for full details.

**Quick summary**: 17 routes are premium-gated at the router level. The `blockedByPremium()` function in `premium_route_guard.dart` is the single source of truth — no matter how a user reaches a premium route (tap, search, deep link, guide link), the redirect fires.

## State Management

### Riverpod Providers

- `FutureProvider` for async data (transactions, accounts, budgets, goals)
- `StateProvider` for simple UI state (selected month, period, hide balances)
- `StateNotifierProvider` for complex state (feature visibility)
- Providers are invalidated after writes to trigger UI refresh

### Singleton Services

Services use the singleton pattern for app-wide state:
- `PremiumService.instance` — premium status, trial, streak reward
- `BillingService.instance` — Google Play purchases
- `SyncService.instance` — background sync (nullable, set after auth)
- `StreakService.instance` — daily streak tracking
- `AppDatabase.instance` — Drift SQLite database

## Database Schema

### Local Tables (Drift SQLite)

| Table | Fields | sync_status |
|-------|--------|:-----------:|
| local_transactions | id, user_id, amount, category, description, date, currency, account_id, tags, status | Yes |
| local_accounts | id, user_id, name, type, currency, balance, is_archived | Yes |
| local_budgets | id, user_id, category, amount, month, period, rollover | Yes |
| local_goals | id, user_id, name, target_amount, current_amount, deadline, category, account_id, is_completed | Yes |
| local_bills | id, user_id, name, category, amount, billing_cycle, due_day, provider, last_paid_date, is_active, account_id | Yes |
| local_debts | id, user_id, name, type, current_balance, original_amount, interest_rate, minimum_payment, lender, due_day, is_paid_off, account_id | Yes |
| local_insurance | id, user_id, name, type, provider, policy_number, premium_amount, premium_frequency, renewal_date, is_active | Yes |
| local_investments | id, user_id, name, type, amount_invested, current_value, date_started | Yes |
| local_contributions | id, user_id, type, period, monthly_salary, employee_share, employer_share, total_contribution, is_paid, employment_type | Yes |

### sync_status Lifecycle

```
Write (create/update) → 'pending'
Push success          → 'synced'
Push network error    → 'failed' (retry up to 3x)
Push validation error → 'failed_permanent' (no retry)
Pull from remote      → 'synced'
```

## Key Patterns

### Input Validation
All user input is validated and sanitized at the repository layer via `InputValidator` and `InputSanitizer`. The UI can have bugs — the data layer catches them.

### Fire-and-Forget
Non-critical operations (sync push, budget threshold checks, milestone celebrations, Discord webhooks) use fire-and-forget patterns — they run asynchronously without blocking the UI or failing the main operation.

### Anti-Tamper
Trial and streak reward expiry checks use server time from worldtimeapi.org (with Google fallback) instead of device `DateTime.now()`. This prevents users from extending trials by changing their device clock.
