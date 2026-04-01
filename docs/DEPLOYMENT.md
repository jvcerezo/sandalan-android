# Sandalan Deployment Guide

## Prerequisites

- Flutter SDK 3.29+ at `C:\flutter\flutter`
- Android Studio with Android SDK
- Java JDK 17
- Google Play Console access
- Supabase project access
- Release keystore (`android/app/keystore.jks`)

## Environment Setup

### 1. .env File

```
SUPABASE_URL=https://oinnvvvqqpdffhkhdyyo.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_WEB_CLIENT_ID=your-google-client-id
GROQ_API_KEY=your-groq-api-key
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your-webhook
```

### 2. Signing Key

`android/app/key.properties`:
```
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-alias
storeFile=keystore.jks
```

### 3. Regenerate Env

After any `.env` change:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Version Bumping

Edit `pubspec.yaml`:
```yaml
version: 1.2.0+35
#        ^     ^
#        |     build number (increment every build)
#        version name (semver)
```

**Always increment version before pushing.** Build number must be higher than last uploaded AAB.

## Build Release AAB

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Upload to Google Play

1. Go to [Google Play Console](https://play.google.com/console)
2. Select "Sandalan" app
3. Go to **Release** → **Testing** → **Closed testing**
4. **Create new release**
5. Upload `app-release.aab`
6. Add release notes
7. **Review and roll out**

## Supabase Migrations

Run these in **Supabase SQL Editor** when deploying new features:

| Migration | When to run |
|-----------|-------------|
| `supabase/schema.sql` | Initial setup (already done) |
| `supabase/adulting_tables.sql` | If adulting tables missing |
| `supabase/subscriptions.sql` | For premium billing (already done) |

### Verify Tables Exist

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected: accounts, admin_users, bills, budgets, bug_reports, contributions, debts, exchange_rates, goal_fundings, goals, insurance_policies, investments, market_rates, profiles, subscriptions, tax_records, transactions

## Google Play Products

### Subscriptions

| Product ID | Type | Price | Base Plan |
|-----------|------|-------|-----------|
| `sandalan_premium_monthly` | Subscription | ₱79/month | `monthly-autorenew` |
| `sandalan_premium_yearly` | Subscription | ₱649/year | `yearly-autorenew` |

### License Testing

- Play Console → Settings → License testing
- Add tester emails to "Initial Testers" list
- Test purchases are free and auto-renew on shortened cycle (5min for monthly, 30min for yearly)

## Discord Webhook

For real-time feedback notifications:

1. Add `DISCORD_WEBHOOK_URL` to `.env`
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Rebuild app

Feedback from the app sends Discord embeds with type (bug/suggestion/praise), message, rating, and user name.

## Checklist Before Each Release

- [ ] Version bumped in `pubspec.yaml`
- [ ] `dart run build_runner build --delete-conflicting-outputs` (if env changed)
- [ ] `flutter test` passes (210+ tests)
- [ ] `flutter build appbundle --release` succeeds
- [ ] Tested on real device (P0 test cases from QA_TEST_CASES.md)
- [ ] Any new Supabase migrations run in production
- [ ] Release notes written
- [ ] AAB uploaded to closed testing track
