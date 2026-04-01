# Sandalan QA Test Cases

## How to Use This Document

- **P0** = Blocker — app is broken, cannot ship
- **P1** = Critical — major flow broken, must fix before release
- **P2** = Major — feature doesn't work correctly, fix soon
- **P3** = Minor — cosmetic or edge case, fix when possible

**Status tracking:** Copy this to a spreadsheet or Notion. Mark each test as PASS / FAIL / BLOCKED / SKIPPED.

---

## TC-1: AUTHENTICATION

### TC-1.1: Email Signup

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 1.1.1 | Signup with valid credentials | Enter name, valid email, password (8+ chars) → tap Sign Up | Account created, navigates to onboarding | P0 |
| 1.1.2 | Signup with empty fields | Leave all fields blank → tap Sign Up | Shows "Please fill in all fields" error | P1 |
| 1.1.3 | Signup with invalid email | Enter "notanemail" → tap Sign Up | Shows email validation error | P1 |
| 1.1.4 | Signup with short password | Enter password < 6 chars → tap Sign Up | Shows password too short error | P1 |
| 1.1.5 | Signup with existing email | Use an email that already has an account | Shows appropriate error (duplicate email) | P1 |
| 1.1.6 | Signup activates 30-day trial | Complete signup → finish onboarding → reach home | Trial welcome dialog shows, header badge shows "30d" | P0 |
| 1.1.7 | Trial welcome shows AFTER onboarding | Signup → verify dialog does NOT show before onboarding | Dialog appears only on first home screen load | P1 |
| 1.1.8 | Signup as former guest | Use app as guest → create transactions → sign up | Local data preserved, migrated to new account | P1 |
| 1.1.9 | Network error during signup | Turn off wifi → attempt signup | Shows network error, doesn't crash | P2 |

### TC-1.2: Email Login

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 1.2.1 | Login with valid credentials | Enter registered email + password → tap Sign In | Logged in, navigates to home | P0 |
| 1.2.2 | Login with wrong password | Enter valid email + wrong password | Shows "Invalid email or password" | P1 |
| 1.2.3 | Login with empty fields | Leave blank → tap Sign In | Shows "Please fill in all fields" | P1 |
| 1.2.4 | Login with unregistered email | Enter new email + any password | Shows "Invalid email or password" | P1 |
| 1.2.5 | Quick login card | Login once → close app → reopen → go to login screen | Shows quick-login card with email, tap to re-enter | P2 |
| 1.2.6 | Login does NOT re-trigger trial | Login with existing account (trial already used) | No trial welcome dialog, header shows current status | P1 |
| 1.2.7 | Rate limiting | Attempt 10+ rapid failed logins | Shows "Too many attempts. Please try again later." | P2 |

### TC-1.3: Google Sign-In

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 1.3.1 | First-time Google sign-in | Tap "Continue with Google" → select account | Account created, trial activated, onboarding shown | P0 |
| 1.3.2 | Returning Google sign-in | Tap "Continue with Google" → select existing account | Logged in, navigates to home (no onboarding) | P0 |
| 1.3.3 | Cancel Google sign-in | Tap Google → dismiss the picker | No error shown, stays on login screen | P2 |
| 1.3.4 | Google sign-in as guest | Use as guest → tap Google sign-in | Guest data migrated, trial activated | P1 |

### TC-1.4: Guest Mode

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 1.4.1 | Enter guest mode | Tap "Continue without an account" | Navigates to home, app works offline | P0 |
| 1.4.2 | Guest data persists | Add transactions as guest → close and reopen app | All data still there | P1 |
| 1.4.3 | Guest sees free tier limits | As guest → try adding 3rd account | Blocked by premium gate (2 account limit) | P1 |
| 1.4.4 | Guest cannot access premium | As guest → tap Bills in More screen | Shows premium gate with paywall | P0 |
| 1.4.5 | Guest prompted to create account | Go to Settings → Account | Shows guest banner with "Create Account" button | P2 |

### TC-1.5: Logout

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 1.5.1 | Sign out | Settings → Account → Sign Out | Signed out, navigates to login | P0 |
| 1.5.2 | Data not lost after logout | Sign out → sign back in → check data | All transactions/accounts present | P1 |
| 1.5.3 | Sync before logout | Add transaction → sign out → sign in on another device | Transaction synced and visible on other device | P1 |

---

## TC-2: ONBOARDING

### TC-2.1: Onboarding Flow

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 2.1.1 | Complete full onboarding | Welcome → Life Stage → User Type → Focus Areas → Create Account → Done | All selections saved, navigates to guide/home | P0 |
| 2.1.2 | Skip all optional steps | Tap Next on each step without selecting anything | Onboarding completes, navigates to home | P1 |
| 2.1.3 | Select life stage | Choose "Unang Hakbang" → continue | Saved to profile, used for guide recommendations | P1 |
| 2.1.4 | Select user type | Choose "Employee" → continue | Saved to profile, used for guide recommendations | P1 |
| 2.1.5 | Select focus areas | Check "Track expenses" + "Budget salary" | Corresponding features auto-enabled in visibility | P2 |
| 2.1.6 | Create account during onboarding | Add "GCash" e-wallet account with ₱5,000 balance | Account created, opening balance transaction recorded | P1 |
| 2.1.7 | Create multiple accounts | Add Cash + GCash + BDO during onboarding | All 3 accounts created with correct balances | P2 |
| 2.1.8 | Back navigation in onboarding | Go to Step 3 → tap Back twice → verify on Step 1 | Navigation works, selections preserved | P2 |
| 2.1.9 | Progress indicator | Navigate through steps | Progress bar and "X/4" text update correctly | P3 |

---

## TC-3: ACCOUNTS

### TC-3.1: Create Account

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 3.1.1 | Create cash account | Name: "Cash", Type: Cash, Balance: 1000 → Add | Account created, balance shows ₱1,000 | P0 |
| 3.1.2 | Create bank account | Name: "BDO", Type: Bank Account, Balance: 50000 | Account created with correct type | P1 |
| 3.1.3 | Create e-wallet | Name: "GCash", Type: E-Wallet, Balance: 2500 | Account created | P1 |
| 3.1.4 | Create credit card | Name: "BPI CC", Type: Credit Card, Balance: -15000 | Negative balance allowed | P1 |
| 3.1.5 | Create custom type | Type: Custom → enter "Piggy Bank" → Add | Custom type saved, shows wallet icon | P2 |
| 3.1.6 | Duplicate name rejected | Create "GCash" → try creating another "GCash" | Shows "An account with this name already exists" | P1 |
| 3.1.7 | Empty name rejected | Leave name blank → tap Add | Button disabled or name error shown | P1 |
| 3.1.8 | Quick add preset | Tap "GCash" preset → verify name and type auto-fill | Name = "GCash", Type = "E-Wallet" | P2 |
| 3.1.9 | Currency selection | Change currency from PHP to USD → Add | Account saved with USD currency | P2 |
| 3.1.10 | Free tier: 2 account limit | Create 2 accounts → try creating 3rd | Premium gate shown (free users limited to 2) | P0 |
| 3.1.11 | Premium: unlimited accounts | As premium user → create 3+ accounts | No limit enforced | P0 |

### TC-3.2: Account Operations

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 3.2.1 | Delete account | Swipe to delete → confirm | Account removed from list | P1 |
| 3.2.2 | Transfer between accounts | Transfer ₱500 from Cash to GCash | Cash -500, GCash +500, transfer transaction created | P1 |
| 3.2.3 | Archive account | Archive an account → verify hidden from selectors | Archived account not shown in transaction dropdowns | P2 |

---

## TC-4: TRANSACTIONS

### TC-4.1: Create Transaction

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 4.1.1 | Create expense | Amount: 250, Category: Food, Account: Cash | Transaction saved, balance deducted by ₱250 | P0 |
| 4.1.2 | Create income | Tap Income tab → Amount: 25000, Category: Salary | Transaction saved, balance increased by ₱25,000 | P0 |
| 4.1.3 | Zero amount rejected | Enter 0 → tap Save | Shows "Enter a valid amount" error | P1 |
| 4.1.4 | Negative amount rejected | Enter -500 → tap Save | Shows validation error | P1 |
| 4.1.5 | No account selected | Remove account selection → Save | Shows "Select an account" error | P1 |
| 4.1.6 | Custom category | Select "Other" → type "Angkas" → Save | Transaction saved with custom category | P2 |
| 4.1.7 | Auto-categorization | Type "Jollibee" in description | Category auto-suggests "Food" | P2 |
| 4.1.8 | Date selection | Tap date → select yesterday → Save | Transaction date shows yesterday | P2 |
| 4.1.9 | Insufficient balance | Expense ₱100,000 from account with ₱5,000 | Shows "Insufficient balance" error | P1 |
| 4.1.10 | Credit card no balance check | Expense from credit card account | No insufficient balance error (credit cards exempt) | P2 |
| 4.1.11 | Amount with commas | Enter "1,234.56" | Parsed correctly as 1234.56 | P1 |
| 4.1.12 | Max amount | Enter 999,999,999 | Accepted | P2 |
| 4.1.13 | Over max amount | Enter 1,000,000,000 | Rejected with error | P2 |
| 4.1.14 | Tags | Enter "groceries, weekly" in tags field | Tags saved as array | P3 |
| 4.1.15 | Milestone celebration | Create 1st, 10th, 50th, 100th transaction | Milestone dialog appears at thresholds | P3 |

### TC-4.2: Edit Transaction

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 4.2.1 | Edit amount | Open existing transaction → change amount → Save | Amount updated, balance recalculated | P1 |
| 4.2.2 | Edit category | Change category from Food to Transport | Category updated | P2 |
| 4.2.3 | Edit account | Move transaction to different account | Old account balance restored, new account deducted | P1 |

### TC-4.3: Delete Transaction

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 4.3.1 | Delete transaction | Swipe or delete button → confirm | Transaction removed, balance restored | P1 |
| 4.3.2 | Delete income | Delete a salary income transaction | Balance reduced by income amount | P1 |

### TC-4.4: CSV Import (Premium)

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 4.4.1 | Free user blocked | As free user → tap Import CSV | Premium gate shown | P0 |
| 4.4.2 | Import GCash CSV | Upload GCash export CSV | Transactions parsed and previewed | P1 |
| 4.4.3 | Import BDO CSV | Upload BDO export CSV | Transactions parsed correctly | P2 |
| 4.4.4 | Import invalid file | Upload a non-CSV file | Error message shown | P2 |

### TC-4.5: Receipt Scanner (Premium)

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 4.5.1 | Free user blocked | As free user → tap Scan Receipt | Premium gate shown | P0 |
| 4.5.2 | Scan grocery receipt | Take photo of SM/Puregold receipt | Store name, total, date extracted | P1 |
| 4.5.3 | Scan GCash screenshot | Take photo of GCash transaction | Detected as digital wallet, amount extracted | P1 |
| 4.5.4 | Scan ATM receipt | Take photo of ATM withdrawal slip | Detected as ATM, bank and amount extracted | P2 |
| 4.5.5 | Reference number not read as amount | Scan receipt with long ref number | Amount is the actual total, not the ref number | P1 |
| 4.5.6 | Empty/unreadable image | Scan blank paper | Shows "Could not read the receipt" error | P2 |
| 4.5.7 | Gallery pick | Choose from gallery instead of camera | Image processed same as camera | P2 |
| 4.5.8 | Edit parsed fields | Scan → change amount and category → Save | Edited values saved (not OCR values) | P1 |

---

## TC-5: BUDGETS

### TC-5.1: Create Budget

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 5.1.1 | Create monthly budget | Category: Food, Amount: 5000, Period: Monthly | Budget created, shows on budgets screen | P0 |
| 5.1.2 | Quick preset amount | Tap "₱3,000" preset → Save | Amount filled as 3000 | P2 |
| 5.1.3 | Duplicate category rejected | Create Food budget → try creating another Food budget | Shows "A budget for Food already exists" | P1 |
| 5.1.4 | Custom category | Select "Other" → type "Pets" → Save | Budget created with custom category | P2 |
| 5.1.5 | Free tier: 3 budget limit | Create 3 budgets → try creating 4th | Premium gate shown | P0 |
| 5.1.6 | Premium: unlimited budgets | As premium → create 4+ budgets | No limit enforced | P0 |
| 5.1.7 | Budget spending tracking | Create Food ₱5000 budget → add ₱250 Food expense | Budget shows ₱250 spent of ₱5,000 | P1 |
| 5.1.8 | Case-insensitive matching | Budget category "food" matches transaction "Food" | Spending correctly calculated | P1 |

### TC-5.2: Delete Budget

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 5.2.1 | Swipe to delete | Swipe budget card left → confirm | Budget deleted, snackbar shown | P1 |
| 5.2.2 | Cancel delete | Swipe → tap Cancel in dialog | Budget not deleted | P2 |

---

## TC-6: GOALS

### TC-6.1: Create Goal

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 6.1.1 | Create savings goal | Name: "Emergency Fund", Target: 50000, Category: Emergency Fund | Goal created, shows on goals screen | P0 |
| 6.1.2 | Goal with deadline | Set deadline 6 months from now | Deadline displayed on goal card | P2 |
| 6.1.3 | Goal with initial savings | Set "Currently Saved" to 10000 | Progress bar shows 10K/50K | P2 |
| 6.1.4 | Free tier: 2 goal limit | Create 2 goals → try creating 3rd | Premium gate shown | P0 |
| 6.1.5 | Premium: unlimited goals | As premium → create 3+ goals | No limit enforced | P0 |

### TC-6.2: Fund Goal

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 6.2.1 | Add funds to goal | Tap goal → Add Funds → ₱5,000 from Cash account | Goal balance +5000, account balance -5000 | P1 |
| 6.2.2 | Complete goal | Fund goal to reach target amount | Goal marked as completed, celebration shown | P2 |

---

## TC-7: BILLS (Premium)

### TC-7.1: Create Bill

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 7.1.1 | Free user blocked | As free user → tap Bills & Payments | Premium gate shown | P0 |
| 7.1.2 | Create monthly bill | Name: "Meralco", Amount: 3500, Cycle: Monthly, Due: 15 | Bill created | P1 |
| 7.1.3 | Create quarterly bill | Cycle: Quarterly | Bill shows with quarterly badge | P2 |
| 7.1.4 | Empty name rejected | Leave name blank → Save | Shows "Name is required" | P1 |
| 7.1.5 | Due day validation | Enter day 31 → Save | Accepted (clamped to month's last day) | P2 |

### TC-7.2: Mark Bill Paid

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 7.2.1 | Mark as paid | Tap check icon on bill | last_paid_date updated, success snackbar shown | P1 |
| 7.2.2 | Bill due soon indicator | Bill with due day within 7 days of today | Shows "Due soon" badge in orange | P2 |

---

## TC-8: DEBTS (Premium)

### TC-8.1: Create Debt

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 8.1.1 | Free user blocked | As free user → tap Debts | Premium gate shown | P0 |
| 8.1.2 | Create personal loan | Name: "Car Loan", Balance: 500000, Rate: 12%, Min: 15000 | Debt created | P1 |
| 8.1.3 | Create credit card debt | Type: Credit Card, Balance: 50000, Rate: 24% | Debt created with CC type | P2 |
| 8.1.4 | Zero balance rejected | Enter 0 balance → Save | Shows validation error | P1 |
| 8.1.5 | Interest rate over 300% | Enter 350% → Save | Shows "must be between 0% and 300%" | P2 |

### TC-8.2: Debt Payment

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 8.2.1 | Record payment | Confirm pending debt payment from account | Debt balance reduced, account deducted | P1 |
| 8.2.2 | Insufficient balance check | Try paying from account with less balance | Shows "Insufficient balance" error | P1 |
| 8.2.3 | Pay off debt completely | Payment equals remaining balance | Debt marked as paid off | P2 |

---

## TC-9: PREMIUM & BILLING

### TC-9.1: Free Tier Limits

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 9.1.1 | 2 account limit | Create 2 accounts → try 3rd | Premium gate shown | P0 |
| 9.1.2 | 3 budget limit | Create 3 budgets → try 4th | Premium gate shown | P0 |
| 9.1.3 | 2 goal limit | Create 2 goals → try 3rd | Premium gate shown | P0 |
| 9.1.4 | All manage items gated | Tap each: Bills, Debts, Insurance, Investments, Split Bills, Salary Allocation | All show premium gate | P0 |
| 9.1.5 | All tools gated | Tap each: Contributions, Tax, 13th Month, Retirement, Rent vs Buy, Panganay, Calculators, Currency | All show premium gate | P0 |
| 9.1.6 | App items gated | Tap each: Reports, AI Chat, Scan Receipt, Document Vault | All show premium gate | P0 |
| 9.1.7 | Dashboard tabs gated | Tap Trends/Planning/Health/Insights tabs | Premium gate shown | P1 |
| 9.1.8 | Home quick links gated | Tap AI Chat and Reports quick links | Premium gate shown | P1 |
| 9.1.9 | FAB scanner gated | Tap + → Scan | Premium gate shown | P1 |
| 9.1.10 | PRO badge visible | Check header bar | Shows purple "PRO" pill linking to paywall | P1 |
| 9.1.11 | More screen shows lock icons | Check premium items in More | Shows PRO badge + lock icon + dimmed text | P2 |

### TC-9.2: Premium Purchase

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 9.2.1 | Open paywall | Tap PRO badge in header | Paywall screen opens with plan options | P0 |
| 9.2.2 | Select monthly plan | Tap Monthly → Subscribe | Google Play purchase sheet appears with ₱79 | P0 |
| 9.2.3 | Select yearly plan | Tap Yearly → Subscribe | Google Play purchase sheet appears with ₱649 | P0 |
| 9.2.4 | Complete purchase | Finish Google Play purchase flow | "Welcome to Sandalan Premium!" snackbar, all features unlocked | P0 |
| 9.2.5 | Cancel purchase | Start purchase → cancel in Google Play | Returns to paywall, no charge | P1 |
| 9.2.6 | Restore purchase | Tap "Restore Purchase" with active subscription | Premium restored, success snackbar | P1 |
| 9.2.7 | Restore with no purchase | Tap "Restore Purchase" with no history | Shows "No previous purchase found" | P2 |

### TC-9.3: Signup Trial

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 9.3.1 | Trial activates on signup | Create new account → complete onboarding | Trial welcome dialog, 30d badge in header | P0 |
| 9.3.2 | Trial unlocks all features | During trial → access every premium feature | All features work without paywall | P0 |
| 9.3.3 | Trial does not reset on re-login | Logout → login again | No new trial dialog, same days remaining | P1 |
| 9.3.4 | Trial expiry reverts to free | Set device date 31 days ahead → reopen app | Premium features blocked, badge gone | P1 |
| 9.3.5 | Header shows trial days | During active trial | Yellow clock badge shows remaining days | P2 |
| 9.3.6 | Subscription status in settings | Settings → About → Subscription | Shows "Free Trial — X days left" with subscribe CTA | P2 |

### TC-9.4: Streak Reward

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 9.4.1 | 90-day streak unlocks premium | Reach 90-day streak | 1 month free premium activated | P1 |
| 9.4.2 | Streak reward shows in header | During active streak reward | Orange flame badge with days remaining | P2 |
| 9.4.3 | Streak reward expires | Wait for 30 days after reward | Reverts to free tier | P2 |

### TC-9.5: Premium Bypass Prevention

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 9.5.1 | Direct URL bypass | Deep link to /investments as free user | Redirected to /home | P0 |
| 9.5.2 | Search bypass | Search "retirement" → tap result | Premium gate shown (router blocks) | P0 |
| 9.5.3 | Guide link bypass | Read a guide → tap "Related Tool" link to premium route | Router redirects to /home | P1 |
| 9.5.4 | Checklist link bypass | Checklist item with app link to premium route | Router redirects to /home | P1 |

---

## TC-10: NAVIGATION

### TC-10.1: Back Button Behavior

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 10.1.1 | Home → exit | Press back on home screen | Shows "Press back again to exit" | P1 |
| 10.1.2 | Home → double back → exit | Press back twice within 2 seconds on home | App closes | P1 |
| 10.1.3 | Goals → dashboard | Press back on goals screen | Goes to /dashboard | P1 |
| 10.1.4 | Bills → more | Press back on bills screen | Goes to /more | P1 |
| 10.1.5 | Settings → more | Press back on settings | Goes to /more | P1 |
| 10.1.6 | Dashboard → home | Press back on dashboard/money | Goes to /home | P1 |
| 10.1.7 | More → home | Press back on more screen | Goes to /home | P1 |
| 10.1.8 | Guide article → stage | Press back on article screen | Goes to stage detail | P2 |
| 10.1.9 | Checklist → stage | Press back on checklist detail | Goes to stage detail | P2 |
| 10.1.10 | Monthly report → reports | Press back on monthly report | Goes to /reports | P2 |

### TC-10.2: Tab Highlighting

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 10.2.1 | Home tab active | Navigate to /home | Home tab highlighted | P2 |
| 10.2.2 | Guide tab active | Navigate to /guide | Guide tab highlighted | P2 |
| 10.2.3 | Money tab active | Navigate to /dashboard | Money tab highlighted | P2 |
| 10.2.4 | More tab active | Navigate to /more or any child | More tab highlighted | P2 |
| 10.2.5 | Goals highlights Money | Navigate to /goals | Money tab highlighted | P2 |

---

## TC-11: CROSS-DEVICE SYNC

### TC-11.1: Data Sync

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 11.1.1 | Transaction syncs to cloud | Create transaction on Device A → wait 30s | Transaction appears on Device B after pull | P0 |
| 11.1.2 | Account syncs | Create account on Device A | Account appears on Device B | P1 |
| 11.1.3 | Budget syncs | Create budget on Device A | Budget appears on Device B | P1 |
| 11.1.4 | Goal syncs | Create goal on Device A | Goal appears on Device B | P1 |
| 11.1.5 | Delete syncs | Delete transaction on Device A | Removed from Device B (may take up to 7 days for incremental) | P2 |
| 11.1.6 | Offline → online | Add transactions offline → turn on wifi | Data pushes to Supabase within seconds | P1 |
| 11.1.7 | Sync on app resume | Background app → modify data on web → resume app | New data pulled within 30 seconds | P2 |

---

## TC-12: OFFLINE MODE

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 12.1 | App works offline | Turn off wifi → open app | All screens load from local data | P0 |
| 12.2 | Create transaction offline | Offline → add expense | Transaction saved locally, sync_status = pending | P0 |
| 12.3 | Sync indicator shows | Offline with pending data | Sync indicator shows pending state | P2 |
| 12.4 | Reconnect syncs | Go offline → add data → reconnect | Pending data pushes automatically | P1 |

---

## TC-13: SETTINGS

### TC-13.1: Feature Visibility

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 13.1.1 | Hide a feature | Settings → Feature Visibility → toggle off Bills | Bills removed from More screen | P2 |
| 13.1.2 | Show a hidden feature | Toggle Bills back on | Bills reappears in More screen | P2 |
| 13.1.3 | Hidden count | Hide 3 features → check More screen | Shows "3 features hidden" at bottom | P3 |

### TC-13.2: Send Feedback

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 13.2.1 | Submit bug report | Settings → Send Feedback → type: Bug → describe → Submit | Saved to bug_reports table, success snackbar | P1 |
| 13.2.2 | Submit suggestion | Type: Suggestion → describe → Submit | Saved with [suggestion] prefix | P1 |
| 13.2.3 | Submit with rating | Select 4 stars → type message → Submit | Saved with ⭐⭐⭐⭐ in title | P2 |
| 13.2.4 | Submit empty blocked | Leave message blank and no rating → Submit | Button disabled | P2 |
| 13.2.5 | Discord notification | Submit any feedback | Discord webhook fires (if configured) | P2 |

### TC-13.3: App Lock

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 13.3.1 | Enable biometric lock | Settings → Privacy → toggle App Lock | Lock screen shown on next app open | P2 |
| 13.3.2 | Unlock with fingerprint | Open locked app → authenticate | App unlocks | P2 |
| 13.3.3 | PIN fallback | Biometric fails → enter PIN | App unlocks | P2 |

---

## TC-14: GUIDE & CHECKLIST

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 14.1 | Browse life stages | Open Guide tab | 6 stages displayed | P1 |
| 14.2 | Read article | Tap stage → tap article | Article content shown | P1 |
| 14.3 | Mark checklist done | Tap checklist item → Mark as Done | Checkmark shown, snackbar "Marked as done!" | P1 |
| 14.4 | Skip checklist item | Tap Skip | Item skipped, snackbar "Skipped for now" | P2 |
| 14.5 | Undo checklist | Mark done → Undo | Item unchecked, snackbar "Unmarked" | P2 |
| 14.6 | Recommended for you | User with type "student" → open Unang Hakbang | "Recommended for you" section shows relevant guides | P2 |
| 14.7 | Recommendation fallback | User with NO type set → open any stage | Recommendations inferred from stage slug | P2 |

---

## TC-15: STREAK & ACHIEVEMENTS

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 15.1 | First visit sets streak to 1 | Open app for the first time | Streak badge shows "1" | P2 |
| 15.2 | Consecutive day increments | Open app next day | Streak increments to 2 | P2 |
| 15.3 | Same day no change | Open app again same day | Streak stays the same | P2 |
| 15.4 | Gap resets streak | Skip 2+ days → open app | Streak resets to 1 | P2 |
| 15.5 | Pahinha saves streak | Miss 1 day with token → open app | Streak continues, token consumed | P3 |
| 15.6 | Achievements visible | More → Achievements | Achievements screen loads with badges | P2 |

---

## TC-16: HOME SCREEN

| # | Test Case | Steps | Expected Result | Priority |
|---|-----------|-------|-----------------|:--------:|
| 16.1 | Financial summary cards | Open home | Balance, Income, Expenses cards shown | P1 |
| 16.2 | Hide balances | Tap eye icon | All amounts show "••••" | P2 |
| 16.3 | Recent transactions | Have 5+ transactions | Shows last 5 with "See all" link | P2 |
| 16.4 | Upcoming payments | Have a bill due within 7 days | Shows in upcoming payments section | P2 |
| 16.5 | Upcoming payment tap gated | As free user → tap upcoming bill | Premium gate shown (bills is premium) | P1 |
| 16.6 | Smart suggestions | Use app normally | AI-generated suggestions appear | P3 |
| 16.7 | Weekly recap card | Open app on Sunday-Tuesday | Weekly recap card shown | P3 |
| 16.8 | Tip of the day | Open app on Wednesday-Saturday | Daily tip shown | P3 |
| 16.9 | Premium badge in header | Check header bar at all times | PRO badge visible, tappable | P1 |

---

## Test Execution Checklist

### Pre-Release (Every Build)
Run all P0 tests. Any P0 failure = do not ship.

### Weekly Regression
Run all P0 + P1 tests.

### Full QA (Before Major Release)
Run all tests P0 through P3.

### Test Environments
- [ ] Fresh install (new device, no data)
- [ ] Upgrade from previous version
- [ ] Guest mode user
- [ ] Free tier authenticated user
- [ ] Premium subscriber (test purchase)
- [ ] Trial user (30-day trial active)
- [ ] Expired trial user
- [ ] Offline mode
- [ ] Low-end device (2GB RAM)
