# Sandalan Sync System

## Overview

Sandalan uses a local-first architecture with background cloud sync. All data is stored in Drift (SQLite) and synced to Supabase for cross-device access and backup.

## When Sync Happens

| Trigger | What runs | Direction |
|---------|-----------|-----------|
| App startup | `fullSync()` | Pull then push |
| App resume (after >30s) | `fullSync()` | Pull then push |
| App backgrounds | `fullSync()` | Push then pull |
| After any write | `pushAfterWrite()` (5s debounce) | Push only |
| Connectivity restored | `syncIfDailyDue()` | Pull then push (once/day) |
| Manual "Sync Now" | `fullSync(forceFullPull: true)` | Full pull + push |
| Before logout | `flushPending()` | Push only (best-effort) |

## Rate Limiting

- **Full sync**: Max once per 15 seconds
- **Push after write**: 5-second debounce (batches rapid writes)
- **Stale check on resume**: Skips if synced within last 30 seconds
- **Daily sync**: Once per calendar day

## Sync Tables

| Local Table | Remote Table | Synced Fields |
|-------------|-------------|---------------|
| local_transactions | transactions | amount, category, description, date, currency, account_id, tags |
| local_accounts | accounts | name, type, currency, balance, is_archived |
| local_budgets | budgets | category, amount, month, period, rollover |
| local_goals | goals | name, target_amount, current_amount, deadline, category, account_id, is_completed |
| local_bills | bills | name, category, amount, billing_cycle, due_day, provider, last_paid_date, is_active, account_id |
| local_debts | debts | name, type, current_balance, original_amount, interest_rate, minimum_payment, lender, due_day, is_paid_off, account_id |
| local_insurance | insurance_policies | name, type, provider, policy_number, premium_amount, premium_frequency, renewal_date, is_active |
| local_investments | investments | name, type, amount_invested, current_value, date_started |
| local_contributions | contributions | type, period, monthly_salary, employee_share, employer_share, total_contribution, is_paid, employment_type |

**Not synced**: local_bill_splits (local-only feature)

## sync_status Field

Every local table row has a `sync_status` field:

```
'pending'          → Created/modified locally, not yet pushed
'synced'           → Successfully pushed to Supabase (or pulled from remote)
'failed'           → Push failed (network error), will retry (up to 3x)
'failed_permanent' → Push failed (validation error), won't retry
```

### Lifecycle

```
Create/Update → 'pending'
                    │
              Push attempt
                    │
            ┌───────┴───────┐
            │               │
        Success          Failure
            │               │
        'synced'     ┌──────┴──────┐
                     │             │
                 Network       Validation
                 error          error
                     │             │
                 'failed'    'failed_permanent'
                 (retry)      (no retry)
                     │
              Retry (max 3)
                     │
            ┌────────┴────────┐
            │                 │
        Success        Max retries
            │                 │
        'synced'     'failed_permanent'
```

## Pull Strategy

### Incremental Pull (default)

- Fetches rows WHERE `updated_at > last_pull_timestamp`
- Skips delete detection (can't distinguish "not updated" from "deleted")
- Saves ~90% bandwidth after first sync
- Timestamp persisted per-table in SharedPreferences

### Full Pull (weekly + first sync)

- Fetches ALL rows for the user
- Detects and removes locally-synced rows that no longer exist remotely
- Runs on first-ever sync and once per 7 days
- Can be forced via `fullSync(forceFullPull: true)`

## Conflict Resolution

**Strategy: Last-write-wins based on `updated_at` timestamp**

When pulling a remote row:
1. If local row has `sync_status = 'pending'` → **skip** (preserve local changes)
2. If local `updated_at` > remote `updated_at` → **skip** (local is newer)
3. Otherwise → **overwrite** local with remote data

## Data Mapping

### Remote → Local (`remoteToLocal`)

- Sets `sync_status = 'synced'`
- Converts booleans to integers (SQLite doesn't have bool)
- Encodes tags List to JSON string (for transactions)
- Adds `updated_at` if missing

### Local → Remote (`localToRemote`)

- Removes `sync_status`, `failure_reason`, `status` (local-only fields)
- Converts integer `is_*` and `rollover` columns back to booleans
- Decodes tags JSON string back to List

## Progress Sync (Checklist/Guide)

Separate from the main sync system. Uses **union merge** — never loses progress.

```
App startup
  → ProgressSyncService.pullAndMerge()
    → Fetch cloud checklist_done, checklist_skipped, guides_read
    → Union with local SharedPreferences values
    → Push merged result back to Supabase profile
```

## Failure Handling

### Retry Logic

- Network errors retry up to 3 times
- Retry count tracked in `failure_reason` field: `"retry:2 Network error: ..."`
- After 3 retries → marked `'failed_permanent'`

### Validation Errors (No Retry)

Detected by checking error message for:
- `violates check constraint`
- HTTP 400
- `not-null`
- `invalid input`

These are marked `'failed_permanent'` immediately.

### User-Facing

- **Sync indicator** in header shows syncing/synced/failed state
- **Settings → Account → Offline Outbox** shows pending/failed/synced counts
- "Sync Now" button for manual retry
- "Clear Queue" button to discard permanently failed rows

## Known Limitations

1. **Delete propagation**: Deleted rows only detected on full pulls (weekly). Incremental pulls can't distinguish "not updated" from "deleted."
2. **No realtime**: No Supabase Realtime channels. Sync is poll-based.
3. **SharedPreferences timestamps**: Per-table pull timestamps are device-wide, not per-user. Cleared on logout to prevent cross-user pollution.
4. **Concurrent edits**: If two devices edit the same row, last-write-wins. No merge or conflict UI.
