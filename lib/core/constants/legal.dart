/// Legal documents for Sandalan.
/// Privacy Policy compliant with RA 10173 (Data Privacy Act of 2012).

const String kLastUpdatedLegal = 'March 21, 2026';

const String kPrivacyPolicy = '''
PRIVACY POLICY

Last updated: $kLastUpdatedLegal

This Privacy Policy explains how Sandalan ("we," "our," or "us") collects, uses, stores, and protects your personal information in accordance with Republic Act No. 10173, also known as the Data Privacy Act of 2012 of the Philippines, and its implementing rules and regulations.


1. WHO WE ARE (DATA CONTROLLER)

Sandalan is a personal finance and adulting guide application designed for individuals in the Philippines, developed by Jet Timothy Cerezo. We act as the Personal Information Controller for the data you provide when using our services.

Contact: privacy@sandalan.com


2. INFORMATION WE COLLECT

We collect only the information necessary to provide the app's features:

Account Information:
- Email address (for authentication and communication)
- Full name (for personalization)
- Profile photo / avatar (optional, for account personalization)

Financial Data (all manually entered by you):
- Transactions (income and expenses)
- Accounts and balances
- Budgets
- Financial goals
- Debts
- Bills
- Insurance policies
- Government contributions (SSS, PhilHealth, Pag-IBIG)
- Tax records

Usage Data:
- Life stage selection
- Checklist progress (adulting journey milestones)
- Feature usage patterns

Device Information:
- Device token (for push notifications only)

We do NOT collect bank account numbers, credit card numbers, government ID numbers (TIN, SSS number, PhilHealth number), or any payment credentials. All financial figures are manually entered by you.


3. LEGAL BASIS FOR PROCESSING

We process your personal data based on your freely given, specific, informed, and unambiguous consent, provided when you create an account and agree to this Privacy Policy. You may withdraw your consent at any time by deleting your account.


4. HOW WE USE YOUR INFORMATION

- To provide, maintain, and improve the core service (financial tracking, budgeting, adulting guides)
- To generate personalized insights and recommendations
- To send notifications and reminders (bill due dates, contribution schedules, etc.)
- To improve the app experience
- To authenticate your identity and secure your account
- To respond to bug reports and support requests

We do NOT sell, rent, or share your personal data with third parties for marketing purposes. We do not use your data for profiling, behavioral advertising, or any purpose beyond operating the app. No advertising trackers are used.


5. DATA STORAGE

Cloud Storage:
Your data is stored on Supabase, hosted on Amazon Web Services (AWS) in the Singapore region. Supabase is SOC 2 Type II certified and ISO 27001 compliant.

Local Storage:
A cached copy of your data is stored locally on your device using SQLite to enable offline access and faster load times. This data remains on your device and is not shared with any third party.

Guest Mode:
When using the app in guest mode, all data is stored locally on your device only. No data is uploaded to our servers. Guest mode data is never synced to the cloud unless you create an account.


6. DATA RETENTION

We retain your personal data for as long as your account is active. When you delete your account, all associated data — including transactions, accounts, goals, debts, budgets, contributions, bills, insurance records, and tax records — is permanently deleted from our systems within 30 days. Backups may retain data for up to 30 additional days before being overwritten.


7. DATA SHARING

We do NOT sell or share your personal data with third parties. The only third-party services used are:

- Supabase (supabase.com): Database and authentication infrastructure. All user data is stored on Supabase servers. Data may be stored in servers outside the Philippines.
- Google Sign-In (optional): If you sign in with Google, we receive your name, email, and profile photo. We do not access your Google Drive, Gmail, contacts, or any other Google service data.
- ExchangeRate-API (open.er-api.com): Currency exchange rates. No personal data is sent.


8. YOUR RIGHTS UNDER RA 10173

As a data subject, you have the following rights:

Right to be Informed:
Know what data we collect and why — this Privacy Policy fulfills that obligation.

Right to Access:
Request a copy of all personal data we hold about you via the Data Export feature in Settings > Privacy & Data.

Right to Object:
Object to processing by withdrawing consent (deleting your account).

Right to Erasure:
Delete your account and all associated data permanently via Settings > Privacy & Data > Delete Account.

Right to Data Portability:
Export all your data in JSON format via Settings > Privacy & Data > Download My Data.

Right to Rectification:
Correct inaccurate data directly within the app at any time (edit your profile, transactions, accounts, etc.).

Right to File a Complaint:
If you believe your rights under RA 10173 have been violated, you may file a complaint with the National Privacy Commission at www.privacy.gov.ph.

To exercise any right not available in-app, email us at privacy@sandalan.com. We will respond within 15 business days.


9. DATA SECURITY

We implement the following security measures to protect your data:
- All data is encrypted in transit using TLS (HTTPS)
- All data is encrypted at rest using AES-256 on Supabase infrastructure
- Row-Level Security (RLS) ensures users can only access their own data
- Passwords are hashed using bcrypt via Supabase Auth — we never store plaintext passwords
- Local database on your device is protected by the operating system's app sandbox
- Administrative access is limited and does not include individual financial figures


10. DATA BREACH NOTIFICATION

In the event of a personal data breach that is likely to result in harm to affected individuals, we will notify the National Privacy Commission (NPC) within 72 hours of becoming aware of the breach, and notify affected users within a reasonable period, in accordance with NPC Circular No. 16-03.


11. CHILDREN'S PRIVACY

Sandalan is not intended for individuals under 13 years of age. We do not knowingly collect personal information from children. If you believe a child has created an account, please contact us and we will delete the account promptly.


12. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of material changes by posting a notice within the app. Your continued use of Sandalan after changes take effect constitutes acceptance of the revised policy.


13. CONTACT

For privacy-related concerns, contact us at:
Email: privacy@sandalan.com

If you believe your rights under RA 10173 have been violated, you may file a complaint with the National Privacy Commission at www.privacy.gov.ph.
''';

const String kTermsOfService = '''
TERMS OF SERVICE

Last updated: $kLastUpdatedLegal

Please read these Terms of Service carefully before using Sandalan. By creating an account, you agree to be bound by these terms.


1. ACCEPTANCE OF TERMS

By accessing or using Sandalan, you agree to these Terms of Service and our Privacy Policy. If you do not agree, do not use the app. We reserve the right to update these terms at any time. Continued use after changes constitutes acceptance.


2. DESCRIPTION OF SERVICE

Sandalan is a personal finance and adulting guide application available on the web and as a mobile application on the Google Play Store. It helps you record and monitor your income, expenses, accounts, budgets, goals, debts, insurance policies, tax records, government contributions, and life milestones through the adulting checklist. Sandalan is a tracking tool only — it does not hold money, process payments, provide financial advice, or act as a bank, lending institution, or financial intermediary.


3. ELIGIBILITY

You must be at least 18 years old to use Sandalan. By using the app, you represent that you meet this requirement.


4. ACCOUNT REGISTRATION AND RESPONSIBILITIES

You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account. You agree to provide accurate and complete information during registration. Notify us immediately at support@sandalan.com if you suspect unauthorized access. We are not liable for losses caused by unauthorized use of your account.


5. PROHIBITED USES

You agree not to:
- Use the app for any unlawful purpose or in violation of Philippine law
- Attempt to gain unauthorized access to other users' accounts or data
- Reverse engineer, decompile, or attempt to extract the app's source code
- Use automated tools to scrape, crawl, or extract data from the app
- Introduce malicious code, viruses, or disruptive components
- Misrepresent your identity or impersonate any person or entity
- Use the app to launder money or facilitate any illegal financial activity


6. FINANCIAL DISCLAIMER

Sandalan provides tools to help you track your personal finances. NOTHING IN THIS APP CONSTITUTES FINANCIAL, INVESTMENT, TAX, OR LEGAL ADVICE. The calculations shown (including government contributions, tax estimates, and net worth) are for informational purposes only and may not reflect the latest rates or regulations. Always consult a qualified professional (accountant, financial advisor, lawyer) for financial decisions. We are not responsible for any financial losses resulting from reliance on information displayed in the app.


7. DATA AND PRIVACY

Your use of Sandalan is also governed by our Privacy Policy, which is incorporated into these Terms by reference. You retain ownership of all financial data you enter into the app. We do not claim any rights to your data.


8. INTELLECTUAL PROPERTY

All content, design, branding, logos, and code that make up Sandalan are owned by us and protected under Philippine intellectual property law. You may not copy, modify, distribute, or create derivative works from any part of the app without our written consent. Your financial data remains yours — we claim no ownership over content you enter into the app.


9. PRICING

Sandalan is currently free to use. We reserve the right to introduce paid features, subscription plans, or pricing changes in the future. If we do, existing features at the time of any pricing change will remain accessible, and we will provide advance notice before any changes take effect.


10. SERVICE AVAILABILITY

We strive to maintain high availability but do not guarantee uninterrupted access. We may perform maintenance, updates, or experience outages. We are not liable for losses resulting from service unavailability.


11. OFFLINE FUNCTIONALITY

Sandalan supports limited offline access through on-device caching. Data entered while offline is stored locally and synced when connectivity is restored. We are not responsible for data loss caused by clearing app data, uninstalling the app, or device failure while data is pending synchronization.


12. LIMITATION OF LIABILITY

To the maximum extent permitted by Philippine law, Sandalan and its operators shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app, including but not limited to financial decisions made based on information displayed in the app. Our total liability for any claim arising from or related to these Terms shall not exceed the amount you have paid us in the 12 months preceding the claim, or PHP 1,000, whichever is lower.


13. TERMINATION

You may terminate your account at any time through Settings > Privacy & Data. We reserve the right to suspend or terminate accounts that violate these Terms without prior notice. Upon termination, your data will be deleted in accordance with our Privacy Policy.


14. GOVERNING LAW

These Terms are governed by the laws of the Republic of the Philippines. Any disputes shall be subject to the exclusive jurisdiction of the courts of the Philippines.


15. DISPUTE RESOLUTION

Before filing a formal legal claim, you agree to first contact us at support@sandalan.com to attempt to resolve the dispute informally. We will endeavor to resolve any dispute within 30 days. If the dispute cannot be resolved informally, it shall be submitted to the appropriate courts of the Philippines.


16. CONTACT

For questions about these Terms, contact us at:
Email: support@sandalan.com

For privacy-related concerns: privacy@sandalan.com
''';
