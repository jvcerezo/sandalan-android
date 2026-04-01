# Sandalan

Your Filipino adulting companion. Track money, bills, goals, and life milestones.

## Tech Stack

- **Flutter** 3.29+ / Dart 3.7+
- **Drift** (SQLite) — local-first offline database
- **Supabase** — auth, cloud sync, admin functions
- **Google Play Billing** — in-app subscriptions
- **Google ML Kit** — receipt OCR text recognition
- **Riverpod** — state management
- **GoRouter** — declarative routing with premium guards
- **Envied** — compile-time environment variables

## Getting Started

### Prerequisites

- Flutter SDK (3.29+) — installed at `C:\flutter\flutter`
- Android Studio with Android SDK
- A `.env` file in the project root (see below)

### Environment Setup

Create a `.env` file in the project root:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_WEB_CLIENT_ID=your-google-client-id
GROQ_API_KEY=your-groq-api-key
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your-webhook
```

### Install & Run

```bash
# Install dependencies
flutter pub get

# Generate env file + Drift code
dart run build_runner build --delete-conflicting-outputs

# Run on connected device
flutter run

# Run tests
flutter test --reporter expanded
```

### Build Release AAB

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Project Structure

```
lib/
  app.dart                    # Root app widget, theme, providers
  main.dart                   # Entry point, service initialization
  core/
    config/env.dart           # Environment variables (envied)
    constants/                # Rates, categories, currencies, legal text
    math/                     # Pure calculation modules
      ph_math.dart            #   SSS, PhilHealth, Pag-IBIG, tax
      debt_math.dart          #   Avalanche/snowball payoff
      retirement_math.dart    #   Pension projection
      housing_math.dart       #   Rent vs buy, amortization
      due_dates.dart          #   Bill/debt due date logic
    providers/                # Feature visibility, theme
    router/
      app_router.dart         # All routes, auth + premium guards
      premium_route_guard.dart # Premium route blocking logic
    services/                 # Business logic services
      premium_service.dart    #   Premium access, trial, streak
      billing_service.dart    #   Google Play purchases
      sync_service.dart       #   Supabase push/pull sync
      streak_service.dart     #   Daily streak + pahinha tokens
      receipt_parser.dart     #   OCR text → structured data
      ...40+ services
    utils/                    # Validators, sanitizers, formatters
  data/
    local/app_database.dart   # Drift SQLite schema + queries
    models/                   # Data classes (Account, Transaction, etc.)
    repositories/             # Local-first repos (8 entities)
    guide/                    # Life stage content + recommendations
    merchants/                # Merchant category database
  features/                   # Feature modules (screen + widgets + providers)
    auth/                     #   Login, signup, onboarding
    home/                     #   Home screen, smart suggestions, streak
    dashboard/                #   Money overview, trends, health, insights
    transactions/             #   Transaction list, add/edit, import, scanner
    accounts/                 #   Account list, add dialog, transfer
    budgets/                  #   Budget list, add dialog, rollover
    goals/                    #   Goal list, add dialog, funding
    guide/                    #   Life stages, articles, checklists
    tools/                    #   Bills, debts, insurance, contributions, etc.
    investments/              #   Portfolio tracker
    splits/                   #   Split bills with friends
    settings/                 #   Settings, paywall, feedback
    reports/                  #   Monthly financial reports
    achievements/             #   Badges and milestones
    vault/                    #   Document vault
    chat/                     #   AI chat assistant
    more/                     #   More screen (feature hub)
    money/                    #   Money tab container
  shared/
    widgets/                  # Reusable widgets (scaffold, snackbar, loading)
    utils/                    # Snackbar helper
  providers/                  # Global providers (theme, query)
test/
  core/math/                  # Calculator tests (ph_math, debt, retirement, housing, due_dates)
  core/utils/                 # Input validator tests
  core/services/              # Premium, streak, receipt parser, sync tests
  core/router/                # Premium route guard tests
  integration/                # Cross-cutting flow tests (transaction→balance, trial→routes)
docs/
  QA_TEST_CASES.md            # 180+ manual QA test cases
  ARCHITECTURE.md             # System architecture
  PREMIUM.md                  # Premium/free tier system
  SYNC.md                     # Cross-device sync
  DEPLOYMENT.md               # Build & release guide
```

## Key Concepts

- **Local-first**: All data written to Drift SQLite immediately, synced to Supabase in background
- **Premium gating**: Router-level redirect prevents access to premium routes regardless of entry point
- **30-day trial**: Activated on first account signup, shown after onboarding
- **Anti-tamper**: Trial/streak expiry checked against server time (worldtimeapi.org)

## Tests

210+ automated tests covering:
- Government calculator math (SSS, PhilHealth, Pag-IBIG, TRAIN tax, 13th month)
- Debt payoff strategies (avalanche, snowball, PMT)
- Input validation and sanitization
- Receipt OCR text parsing
- Premium access logic and trial system
- Route guards for all 17 premium routes
- Streak service logic
- Sync data mapping
- Integration flows (transaction→balance, trial→routes, free tier limits)

```bash
flutter test --reporter expanded
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — data flow, folder structure, patterns
- [Premium System](docs/PREMIUM.md) — free/premium tiers, billing, trial
- [Sync System](docs/SYNC.md) — cross-device sync, conflict resolution
- [Deployment](docs/DEPLOYMENT.md) — build, sign, upload, Play Console
- [QA Test Cases](docs/QA_TEST_CASES.md) — 180+ manual test scenarios

## License

Proprietary. All rights reserved.
