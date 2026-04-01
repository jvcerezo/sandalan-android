# Sandalan Premium System

## Tier Breakdown

### Free Tier (forever free)

| Feature | Limit |
|---------|-------|
| Transaction tracking | Unlimited history |
| Accounts | Up to 2 |
| Budgets | Up to 3, monthly only |
| Goals | Up to 2 |
| Life stage guide | Full access (6 stages, 57+ articles, checklists) |
| Basic dashboard | Net worth, income/expense summary, recent transactions |
| Streak & achievements | Full access |
| Android home widget | Full access |
| Dark/light theme, offline, EN/FIL, app lock | Full access |

### Premium (₱79/month or ₱649/year)

Everything in Free, plus:

| Category | Features |
|----------|----------|
| Finance Management | Bills & due dates, debt payoff (avalanche/snowball), insurance & renewal alerts |
| Investments | Portfolio tracker (MP2, UITF, stocks, bonds, time deposits) |
| Dashboard | Health score, spending trends, planning tab, AI insights |
| Reports | Monthly reports with charts and category deep-dives |
| Calculators | Retirement planner, rent vs buy, FIRE, loan amortization, compound interest |
| Tax & Gov't | Ongoing BIR tax tracker, SSS/PhilHealth/Pag-IBIG contribution tracker |
| AI & Scanning | Taglish chat assistant, receipt OCR, bank CSV import |
| Tools | Currency converter, document vault, split bills, salary allocation, panganay mode |
| Limits | Unlimited accounts, budgets (weekly/quarterly/rollover), goals |

## Ways to Get Premium

| Method | Duration | Repeatable |
|--------|----------|:----------:|
| Monthly subscription | 1 month (auto-renew) | Yes |
| Yearly subscription | 1 year (auto-renew) | Yes |
| Signup trial | 30 days (one-time) | No |
| 90-day streak reward | 30 days | Yes |

## How Gating Works

### Three layers of protection

**Layer 1: UI gates** — `showPremiumGateWithPaywall()` called on tap handlers in More screen, home screen, dashboard tabs. Shows a bottom sheet with feature list and "See Plans & Pricing" button.

**Layer 2: Router redirect** — `blockedByPremium()` in `premium_route_guard.dart` checks every navigation. If a free user somehow reaches a premium route (deep link, search, guide link), they're redirected to `/home`.

**Layer 3: Feature limits** — Account, budget, and goal creation checks count against limits before showing the create dialog.

### Premium Route Map

```dart
const premiumRoutes = {
  '/tools/bills':        PremiumFeature.billsTracker,
  '/tools/debts':        PremiumFeature.debtManager,
  '/tools/insurance':    PremiumFeature.insuranceTracker,
  '/tools/contributions': PremiumFeature.contributionTracker,
  '/tools/taxes':        PremiumFeature.taxTracker,
  '/tools/13th-month':   PremiumFeature.advancedCalculators,
  '/tools/retirement':   PremiumFeature.advancedCalculators,
  '/tools/rent-vs-buy':  PremiumFeature.advancedCalculators,
  '/tools/panganay':     PremiumFeature.panganayMode,
  '/tools/calculators':  PremiumFeature.advancedCalculators,
  '/tools/currency':     PremiumFeature.exchangeRates,
  '/tools':              PremiumFeature.advancedCalculators,
  '/investments':        PremiumFeature.investments,
  '/split-bills':        PremiumFeature.splitBills,
  '/salary-allocation':  PremiumFeature.salaryAllocation,
  '/vault':              PremiumFeature.documentVault,
  '/chat':               PremiumFeature.aiChat,
  '/reports':            PremiumFeature.advancedReports,
};
```

### Access Check Priority

```dart
bool hasAccess(PremiumFeature feature) {
  if (_isBetaPeriod) return true;        // 1. Beta override
  if (_isPremium) return true;           // 2. Paid subscriber
  if (hasActiveSignupTrial) return true; // 3. 30-day trial
  if (hasActiveStreakReward) return true; // 4. 90-day streak reward
  return false;                          // 5. Free user
}
```

## Google Play Billing

### Product IDs

| ID | Type | Price |
|----|------|-------|
| `sandalan_premium_monthly` | Subscription (auto-renewing) | ₱79/month |
| `sandalan_premium_yearly` | Subscription (auto-renewing) | ₱649/year |

### Purchase Flow

```
User taps "Subscribe" in PaywallScreen
  → BillingService.purchase(product)
  → InAppPurchase.buyNonConsumable()
  → Google Play purchase sheet appears
  → User completes payment
  → purchaseStream fires with PurchaseStatus.purchased
  → _verifyAndDeliver():
    → PremiumService.setPremium(true)
    → Purchase token saved to SharedPreferences
    → InAppPurchase.completePurchase() acknowledges
  → onPremiumStatusChanged callback fires
  → PaywallScreen shows success and closes
```

### Restore Flow

```
User taps "Restore Purchase"
  → BillingService.restorePurchases()
  → InAppPurchase.restorePurchases()
  → purchaseStream fires with PurchaseStatus.restored
  → Same _verifyAndDeliver() flow
```

## Signup Trial

### Activation

```
User signs up (email or Google)
  → PremiumService.activateSignupTrial()
    → Checks SharedPreferences for existing trial
    → If none: sets expiry = now + 30 days, returns true
    → If exists: returns false (one-time only)
  → If granted: saves pending_trial_welcome = true
  → After onboarding: home screen shows trial welcome dialog
```

### Expiry Check

```dart
bool get hasActiveSignupTrial {
  if (_signupTrialExpiry == null) return false;
  final now = _lastVerifiedServerTime ?? DateTime.now();
  return now.isBefore(_signupTrialExpiry!);
}
```

Uses server time when available to prevent clock manipulation.

## Anti-Tamper

| Attack | Protection |
|--------|-----------|
| Set device clock back to extend trial | Expiry checked against server time (worldtimeapi.org) |
| Set clock forward to fake streak days | Streak service resets if clock >48h ahead of server |
| Sign out + sign in for new trial | Trial key persists in SharedPreferences (not cleared on logout) |
| Reinstall for new trial | Possible but acceptable (forces re-onboarding, loses all data) |
| Edit SharedPreferences (rooted) | Would need server-side verification to fully prevent |

## Header Badge

The `_PremiumBadge` widget in `app_scaffold.dart` shows in the header bar at all times:

| State | Badge | Tap |
|-------|-------|-----|
| Free user | Purple solid `PRO` pill | Opens paywall |
| Trial active | Yellow clock + `Xd` | Opens paywall |
| Streak reward | Orange flame + `Xd` | Opens paywall |
| Premium | Purple `PRO` badge | No action |

## More Screen Visual Treatment

Premium items show:
- **PRO** badge next to title
- Lock icon instead of chevron
- Dimmed icon, title, and subtitle
- Tapping still shows premium gate with paywall
