import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sandalan'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your money. Your plan. Your freedom.'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get navGuide;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get navMoney;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navContributions.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get navContributions;

  /// No description provided for @navBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get navBills;

  /// No description provided for @navDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get navDebts;

  /// No description provided for @navInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get navInsurance;

  /// No description provided for @navTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get navTaxes;

  /// No description provided for @navCalculators.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get navCalculators;

  /// No description provided for @navPanganayMode.
  ///
  /// In en, this message translates to:
  /// **'Panganay Mode'**
  String get navPanganayMode;

  /// No description provided for @navRetirement.
  ///
  /// In en, this message translates to:
  /// **'Retirement'**
  String get navRetirement;

  /// No description provided for @navRentVsBuy.
  ///
  /// In en, this message translates to:
  /// **'Rent vs Buy'**
  String get navRentVsBuy;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get commonNoResults;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get commonLearnMore;

  /// No description provided for @commonGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get commonGetStarted;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get commonSignIn;

  /// No description provided for @commonSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get commonSignUp;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get commonSignOut;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get commonWarning;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commonType;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get commonNotes;

  /// No description provided for @commonSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commonSelectAll;

  /// No description provided for @commonDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get commonDeselectAll;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your snapshot for today.'**
  String get homeSnapshot;

  /// No description provided for @homeCurrentStage.
  ///
  /// In en, this message translates to:
  /// **'Current Stage'**
  String get homeCurrentStage;

  /// No description provided for @homeBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get homeBalance;

  /// No description provided for @homeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get homeIncome;

  /// No description provided for @homeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get homeExpenses;

  /// No description provided for @homeAdultingGuide.
  ///
  /// In en, this message translates to:
  /// **'Adulting Guide'**
  String get homeAdultingGuide;

  /// No description provided for @homeFinancialDashboard.
  ///
  /// In en, this message translates to:
  /// **'Financial Dashboard'**
  String get homeFinancialDashboard;

  /// No description provided for @homeUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Payments'**
  String get homeUpcomingPayments;

  /// No description provided for @homeNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next Steps'**
  String get homeNextSteps;

  /// No description provided for @homeFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get homeFinancialSummary;

  /// No description provided for @homeCurrentLifeStage.
  ///
  /// In en, this message translates to:
  /// **'Current Life Stage'**
  String get homeCurrentLifeStage;

  /// No description provided for @homeNoUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming payments'**
  String get homeNoUpcomingPayments;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your finances at a glance'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get dashboardHealthScore;

  /// No description provided for @dashboardBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get dashboardBudgetAlerts;

  /// No description provided for @dashboardSpendingInsights.
  ///
  /// In en, this message translates to:
  /// **'Spending Insights'**
  String get dashboardSpendingInsights;

  /// No description provided for @dashboardRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get dashboardRecentTransactions;

  /// No description provided for @dashboardSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get dashboardSavingsRate;

  /// No description provided for @dashboardSafeToSpend.
  ///
  /// In en, this message translates to:
  /// **'Safe to Spend'**
  String get dashboardSafeToSpend;

  /// No description provided for @dashboardEmergencyFund.
  ///
  /// In en, this message translates to:
  /// **'Emergency Fund'**
  String get dashboardEmergencyFund;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactionsAddTransaction;

  /// No description provided for @transactionsIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionsIncome;

  /// No description provided for @transactionsExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionsExpense;

  /// No description provided for @transactionsTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionsTransfer;

  /// No description provided for @transactionsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionsAmount;

  /// No description provided for @transactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transactionsDescription;

  /// No description provided for @transactionsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionsCategory;

  /// No description provided for @transactionsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionsDate;

  /// No description provided for @transactionsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionsAccount;

  /// No description provided for @transactionsImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get transactionsImportCsv;

  /// No description provided for @transactionsNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsNoTransactions;

  /// No description provided for @transactionsAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction to get started'**
  String get transactionsAddFirst;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get accountsAddAccount;

  /// No description provided for @accountsTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get accountsTotalBalance;

  /// No description provided for @accountsNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsNoAccounts;

  /// No description provided for @accountsAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first account to start tracking'**
  String get accountsAddFirst;

  /// No description provided for @accountsCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountsCash;

  /// No description provided for @accountsBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountsBank;

  /// No description provided for @accountsEWallet.
  ///
  /// In en, this message translates to:
  /// **'E-Wallet'**
  String get accountsEWallet;

  /// No description provided for @accountsCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get accountsCreditCard;

  /// No description provided for @accountsInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get accountsInvestment;

  /// No description provided for @accountsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountsOther;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsAddBudget.
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get budgetsAddBudget;

  /// No description provided for @budgetsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetsMonthly;

  /// No description provided for @budgetsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetsWeekly;

  /// No description provided for @budgetsQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get budgetsQuarterly;

  /// No description provided for @budgetsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsSpent;

  /// No description provided for @budgetsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetsRemaining;

  /// No description provided for @budgetsOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budgetsOverBudget;

  /// No description provided for @budgetsOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get budgetsOnTrack;

  /// No description provided for @budgetsNoBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsNoBudgets;

  /// No description provided for @budgetsAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a budget to manage your spending'**
  String get budgetsAddFirst;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsAddGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get goalsAddGoal;

  /// No description provided for @goalsTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get goalsTargetAmount;

  /// No description provided for @goalsCurrentAmount.
  ///
  /// In en, this message translates to:
  /// **'Current Amount'**
  String get goalsCurrentAmount;

  /// No description provided for @goalsDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get goalsDeadline;

  /// No description provided for @goalsProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get goalsProgress;

  /// No description provided for @goalsNoGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get goalsNoGoals;

  /// No description provided for @goalsAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a savings goal to start working towards it'**
  String get goalsAddFirst;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Adulting Journey'**
  String get guideTitle;

  /// No description provided for @guideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Level up through every stage of Filipino adult life.'**
  String get guideSubtitle;

  /// No description provided for @guideOverallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get guideOverallProgress;

  /// No description provided for @guideCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get guideCompleted;

  /// No description provided for @guideStarted.
  ///
  /// In en, this message translates to:
  /// **'started'**
  String get guideStarted;

  /// No description provided for @guideNotStarted.
  ///
  /// In en, this message translates to:
  /// **'not started'**
  String get guideNotStarted;

  /// No description provided for @guideMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as complete'**
  String get guideMarkComplete;

  /// No description provided for @guideMarkIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as incomplete'**
  String get guideMarkIncomplete;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and preferences'**
  String get settingsSubtitle;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Name, avatar, email'**
  String get settingsProfileSub;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSub.
  ///
  /// In en, this message translates to:
  /// **'Theme preferences'**
  String get settingsAppearanceSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageWika.
  ///
  /// In en, this message translates to:
  /// **'Language / Wika'**
  String get settingsLanguageWika;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExportData;

  /// No description provided for @settingsAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get settingsAutomation;

  /// No description provided for @settingsAutomationSub.
  ///
  /// In en, this message translates to:
  /// **'Reminders & auto-generation'**
  String get settingsAutomationSub;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Push notification settings'**
  String get settingsNotificationsSub;

  /// No description provided for @settingsHomePage.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get settingsHomePage;

  /// No description provided for @settingsHomePageSub.
  ///
  /// In en, this message translates to:
  /// **'Customize your Home'**
  String get settingsHomePageSub;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencySub.
  ///
  /// In en, this message translates to:
  /// **'Rates & primary currency'**
  String get settingsCurrencySub;

  /// No description provided for @settingsPrivacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get settingsPrivacyData;

  /// No description provided for @settingsPrivacyDataSub.
  ///
  /// In en, this message translates to:
  /// **'Export, delete, legal'**
  String get settingsPrivacyDataSub;

  /// No description provided for @settingsReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get settingsReportBug;

  /// No description provided for @settingsReportBugSub.
  ///
  /// In en, this message translates to:
  /// **'Report issues'**
  String get settingsReportBugSub;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAccountSubAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign out, tour, sync'**
  String get settingsAccountSubAuth;

  /// No description provided for @settingsAccountSubGuest.
  ///
  /// In en, this message translates to:
  /// **'Tour, create account'**
  String get settingsAccountSubGuest;

  /// No description provided for @settingsCustomizeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Customize how Sandalan looks on your device'**
  String get settingsCustomizeAppearance;

  /// No description provided for @settingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get settingsAccentColor;

  /// No description provided for @settingsAccentColorSub.
  ///
  /// In en, this message translates to:
  /// **'Choose a primary color for buttons, links, and highlights'**
  String get settingsAccentColorSub;

  /// No description provided for @settingsAutomationTitle.
  ///
  /// In en, this message translates to:
  /// **'Automation & Reminders'**
  String get settingsAutomationTitle;

  /// No description provided for @settingsAutomationDesc.
  ///
  /// In en, this message translates to:
  /// **'Control which features run automatically and send you reminders'**
  String get settingsAutomationDesc;

  /// No description provided for @settingsAutoContributions.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate monthly contributions'**
  String get settingsAutoContributions;

  /// No description provided for @settingsAutoContributionsSub.
  ///
  /// In en, this message translates to:
  /// **'Create SSS, PhilHealth, and Pag-IBIG entries each month from your last salary'**
  String get settingsAutoContributionsSub;

  /// No description provided for @settingsBillReminders.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get settingsBillReminders;

  /// No description provided for @settingsBillRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Show upcoming bills on your Home page and send push notifications before due dates'**
  String get settingsBillRemindersSub;

  /// No description provided for @settingsDebtReminders.
  ///
  /// In en, this message translates to:
  /// **'Debt payment reminders'**
  String get settingsDebtReminders;

  /// No description provided for @settingsDebtRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Show upcoming debt payments on your Home page and send push notifications'**
  String get settingsDebtRemindersSub;

  /// No description provided for @settingsInsuranceReminders.
  ///
  /// In en, this message translates to:
  /// **'Insurance premium reminders'**
  String get settingsInsuranceReminders;

  /// No description provided for @settingsInsuranceRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Show upcoming insurance premiums and send push notifications before renewal dates'**
  String get settingsInsuranceRemindersSub;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Push notification preferences (mobile app only)'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications on your phone for upcoming payments and reminders'**
  String get settingsPushNotificationsSub;

  /// No description provided for @settingsMorningSummary.
  ///
  /// In en, this message translates to:
  /// **'Morning summary'**
  String get settingsMorningSummary;

  /// No description provided for @settingsMorningSummarySub.
  ///
  /// In en, this message translates to:
  /// **'Get a daily summary of what\'s due today at 9:00 AM'**
  String get settingsMorningSummarySub;

  /// No description provided for @settingsHomePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get settingsHomePageTitle;

  /// No description provided for @settingsHomePageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections appear on your Home page'**
  String get settingsHomePageDesc;

  /// No description provided for @settingsUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Payments'**
  String get settingsUpcomingPayments;

  /// No description provided for @settingsUpcomingPaymentsSub.
  ///
  /// In en, this message translates to:
  /// **'Show bills, contributions, debts, and insurance due soon'**
  String get settingsUpcomingPaymentsSub;

  /// No description provided for @settingsNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next Steps'**
  String get settingsNextSteps;

  /// No description provided for @settingsNextStepsSub.
  ///
  /// In en, this message translates to:
  /// **'Show suggested next actions from your adulting journey'**
  String get settingsNextStepsSub;

  /// No description provided for @settingsFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get settingsFinancialSummary;

  /// No description provided for @settingsFinancialSummarySub.
  ///
  /// In en, this message translates to:
  /// **'Show balance, income, and expenses at a glance'**
  String get settingsFinancialSummarySub;

  /// No description provided for @settingsCurrentLifeStage.
  ///
  /// In en, this message translates to:
  /// **'Current Life Stage'**
  String get settingsCurrentLifeStage;

  /// No description provided for @settingsCurrentLifeStageSub.
  ///
  /// In en, this message translates to:
  /// **'Show your current adulting journey stage and progress'**
  String get settingsCurrentLifeStageSub;

  /// No description provided for @settingsCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrencyTitle;

  /// No description provided for @settingsCurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your primary currency and manage exchange rates'**
  String get settingsCurrencyDesc;

  /// No description provided for @settingsPrimaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Primary Currency'**
  String get settingsPrimaryCurrency;

  /// No description provided for @settingsSaveCurrency.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSaveCurrency;

  /// No description provided for @settingsCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'All amounts on the dashboard will be converted to this currency'**
  String get settingsCurrencyNote;

  /// No description provided for @settingsExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates (to PHP)'**
  String get settingsExchangeRates;

  /// No description provided for @settingsCustomRates.
  ///
  /// In en, this message translates to:
  /// **'Set custom rates or leave blank to use live market rates'**
  String get settingsCustomRates;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data rights and export options under the Data Privacy Act of 2012'**
  String get settingsPrivacyDesc;

  /// No description provided for @settingsExportYourData.
  ///
  /// In en, this message translates to:
  /// **'Export Your Data'**
  String get settingsExportYourData;

  /// No description provided for @settingsExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Download a full copy of all your data in JSON format — transactions, accounts, budgets, goals, debts, and contributions.'**
  String get settingsExportDesc;

  /// No description provided for @settingsDownloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download My Data'**
  String get settingsDownloadMyData;

  /// No description provided for @settingsLegalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get settingsLegalDocuments;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsPrivacyContact.
  ///
  /// In en, this message translates to:
  /// **'For privacy-related concerns, email privacy@sandalan.com. We will respond within 15 business days.'**
  String get settingsPrivacyContact;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsDangerDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanent and irreversible actions'**
  String get settingsDangerDesc;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes your account and all associated data — transactions, accounts, goals, budgets, debts, and contributions. This cannot be undone.'**
  String get settingsDeleteAccountDesc;

  /// No description provided for @settingsTypeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get settingsTypeDeleteConfirm;

  /// No description provided for @settingsDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account Permanently'**
  String get settingsDeletePermanently;

  /// No description provided for @settingsProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfileTitle;

  /// No description provided for @settingsProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Your personal information and account details'**
  String get settingsProfileDesc;

  /// No description provided for @settingsChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get settingsChangePhoto;

  /// No description provided for @settingsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsRemovePhoto;

  /// No description provided for @settingsPhotoFormat.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or WebP · Max 2 MB'**
  String get settingsPhotoFormat;

  /// No description provided for @settingsEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmailLabel;

  /// No description provided for @settingsEmailCannotChange.
  ///
  /// In en, this message translates to:
  /// **'Your email address cannot be changed'**
  String get settingsEmailCannotChange;

  /// No description provided for @settingsFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get settingsFullNameLabel;

  /// No description provided for @settingsMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String settingsMemberSince(String date);

  /// No description provided for @settingsGuestBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get settingsGuestBannerTitle;

  /// No description provided for @settingsGuestBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Create an account to back up your data and sync across devices.'**
  String get settingsGuestBannerDesc;

  /// No description provided for @settingsCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get settingsCreateAccount;

  /// No description provided for @settingsGuestModeTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re in Guest Mode'**
  String get settingsGuestModeTitle;

  /// No description provided for @settingsGuestModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored only on this device. Create an account to back up your data and sync across devices.'**
  String get settingsGuestModeDesc;

  /// No description provided for @settingsOfflineOutbox.
  ///
  /// In en, this message translates to:
  /// **'Offline Outbox'**
  String get settingsOfflineOutbox;

  /// No description provided for @settingsOfflineOutboxDesc.
  ///
  /// In en, this message translates to:
  /// **'Review queued offline mutations, retry failed items, or clear stale entries.'**
  String get settingsOfflineOutboxDesc;

  /// No description provided for @settingsSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settingsSyncNow;

  /// No description provided for @settingsClearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get settingsClearQueue;

  /// No description provided for @settingsNoQueuedChanges.
  ///
  /// In en, this message translates to:
  /// **'No queued offline changes.'**
  String get settingsNoQueuedChanges;

  /// No description provided for @settingsConflictCenter.
  ///
  /// In en, this message translates to:
  /// **'Conflict Center'**
  String get settingsConflictCenter;

  /// No description provided for @settingsConflictCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'Review sync conflicts and retry or dismiss items after investigation.'**
  String get settingsConflictCenterDesc;

  /// No description provided for @settingsClearConflicts.
  ///
  /// In en, this message translates to:
  /// **'Clear conflicts'**
  String get settingsClearConflicts;

  /// No description provided for @settingsNoConflicts.
  ///
  /// In en, this message translates to:
  /// **'No conflicts detected.'**
  String get settingsNoConflicts;

  /// No description provided for @settingsManageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your account settings'**
  String get settingsManageAccount;

  /// No description provided for @settingsTakeATour.
  ///
  /// In en, this message translates to:
  /// **'Take a Tour'**
  String get settingsTakeATour;

  /// No description provided for @settingsBugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get settingsBugReportTitle;

  /// No description provided for @settingsBugReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Found something broken? Send details and it will appear in the admin dashboard.'**
  String get settingsBugReportDesc;

  /// No description provided for @settingsBugTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get settingsBugTitle;

  /// No description provided for @settingsBugTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of the issue'**
  String get settingsBugTitleHint;

  /// No description provided for @settingsBugSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get settingsBugSeverity;

  /// No description provided for @settingsBugDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get settingsBugDescription;

  /// No description provided for @settingsBugDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? Include steps to reproduce.'**
  String get settingsBugDescriptionHint;

  /// No description provided for @settingsSubmitBugReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Bug Report'**
  String get settingsSubmitBugReport;

  /// No description provided for @settingsSeverityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsSeverityLow;

  /// No description provided for @settingsSeverityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsSeverityMedium;

  /// No description provided for @settingsSeverityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsSeverityHigh;

  /// No description provided for @settingsSeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get settingsSeverityCritical;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Financial trackers and calculators for every stage of adulting.'**
  String get toolsSubtitle;

  /// No description provided for @toolsCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get toolsCompliance;

  /// No description provided for @toolsManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get toolsManagement;

  /// No description provided for @toolsPlanningCalculators.
  ///
  /// In en, this message translates to:
  /// **'Planning & Calculators'**
  String get toolsPlanningCalculators;

  /// No description provided for @toolsGovContributions.
  ///
  /// In en, this message translates to:
  /// **'Gov\'t Contributions'**
  String get toolsGovContributions;

  /// No description provided for @toolsGovContributionsSub.
  ///
  /// In en, this message translates to:
  /// **'SSS, PhilHealth, Pag-IBIG'**
  String get toolsGovContributionsSub;

  /// No description provided for @toolsBirTaxTracker.
  ///
  /// In en, this message translates to:
  /// **'BIR Tax Tracker'**
  String get toolsBirTaxTracker;

  /// No description provided for @toolsBirTaxTrackerSub.
  ///
  /// In en, this message translates to:
  /// **'Income tax & filing'**
  String get toolsBirTaxTrackerSub;

  /// No description provided for @tools13thMonthPay.
  ///
  /// In en, this message translates to:
  /// **'13th Month Pay'**
  String get tools13thMonthPay;

  /// No description provided for @tools13thMonthPaySub.
  ///
  /// In en, this message translates to:
  /// **'Tax exemption calculator'**
  String get tools13thMonthPaySub;

  /// No description provided for @toolsDebtManager.
  ///
  /// In en, this message translates to:
  /// **'Debt Manager'**
  String get toolsDebtManager;

  /// No description provided for @toolsDebtManagerSub.
  ///
  /// In en, this message translates to:
  /// **'Loans & payoff strategies'**
  String get toolsDebtManagerSub;

  /// No description provided for @toolsBillsSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Bills & Subscriptions'**
  String get toolsBillsSubscriptions;

  /// No description provided for @toolsBillsSubscriptionsSub.
  ///
  /// In en, this message translates to:
  /// **'Track recurring payments'**
  String get toolsBillsSubscriptionsSub;

  /// No description provided for @toolsInsuranceTracker.
  ///
  /// In en, this message translates to:
  /// **'Insurance Tracker'**
  String get toolsInsuranceTracker;

  /// No description provided for @toolsInsuranceTrackerSub.
  ///
  /// In en, this message translates to:
  /// **'Policies & renewals'**
  String get toolsInsuranceTrackerSub;

  /// No description provided for @toolsRetirementProjection.
  ///
  /// In en, this message translates to:
  /// **'Retirement Projection'**
  String get toolsRetirementProjection;

  /// No description provided for @toolsRetirementProjectionSub.
  ///
  /// In en, this message translates to:
  /// **'SSS pension & savings gap'**
  String get toolsRetirementProjectionSub;

  /// No description provided for @toolsRentVsBuy.
  ///
  /// In en, this message translates to:
  /// **'Rent vs Buy'**
  String get toolsRentVsBuy;

  /// No description provided for @toolsRentVsBuySub.
  ///
  /// In en, this message translates to:
  /// **'Housing cost comparison'**
  String get toolsRentVsBuySub;

  /// No description provided for @toolsPanganayMode.
  ///
  /// In en, this message translates to:
  /// **'Panganay Mode'**
  String get toolsPanganayMode;

  /// No description provided for @toolsPanganayModeSub.
  ///
  /// In en, this message translates to:
  /// **'Family support budgeting'**
  String get toolsPanganayModeSub;

  /// No description provided for @toolsFinancialCalculators.
  ///
  /// In en, this message translates to:
  /// **'Financial Calculators'**
  String get toolsFinancialCalculators;

  /// No description provided for @toolsFinancialCalculatorsSub.
  ///
  /// In en, this message translates to:
  /// **'Interest, loans & FIRE'**
  String get toolsFinancialCalculatorsSub;

  /// No description provided for @contributionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Contributions'**
  String get contributionsTitle;

  /// No description provided for @contributionsSss.
  ///
  /// In en, this message translates to:
  /// **'SSS'**
  String get contributionsSss;

  /// No description provided for @contributionsPhilHealth.
  ///
  /// In en, this message translates to:
  /// **'PhilHealth'**
  String get contributionsPhilHealth;

  /// No description provided for @contributionsPagIbig.
  ///
  /// In en, this message translates to:
  /// **'Pag-IBIG'**
  String get contributionsPagIbig;

  /// No description provided for @contributionsMonthlyContribution.
  ///
  /// In en, this message translates to:
  /// **'Monthly Contribution'**
  String get contributionsMonthlyContribution;

  /// No description provided for @contributionsEmployeeShare.
  ///
  /// In en, this message translates to:
  /// **'Employee Share'**
  String get contributionsEmployeeShare;

  /// No description provided for @contributionsEmployerShare.
  ///
  /// In en, this message translates to:
  /// **'Employer Share'**
  String get contributionsEmployerShare;

  /// No description provided for @contributionsTotalContribution.
  ///
  /// In en, this message translates to:
  /// **'Total Contribution'**
  String get contributionsTotalContribution;

  /// No description provided for @contributionsSalaryBasis.
  ///
  /// In en, this message translates to:
  /// **'Salary Basis'**
  String get contributionsSalaryBasis;

  /// No description provided for @debtTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt Manager'**
  String get debtTitle;

  /// No description provided for @debtAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get debtAddDebt;

  /// No description provided for @debtTotalOwed.
  ///
  /// In en, this message translates to:
  /// **'Total Owed'**
  String get debtTotalOwed;

  /// No description provided for @debtMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment'**
  String get debtMonthlyPayment;

  /// No description provided for @debtInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get debtInterestRate;

  /// No description provided for @debtMinimumPayment.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payment'**
  String get debtMinimumPayment;

  /// No description provided for @debtRemainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get debtRemainingBalance;

  /// No description provided for @debtPayoffDate.
  ///
  /// In en, this message translates to:
  /// **'Payoff Date'**
  String get debtPayoffDate;

  /// No description provided for @debtNoDebts.
  ///
  /// In en, this message translates to:
  /// **'No debts tracked'**
  String get debtNoDebts;

  /// No description provided for @billsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bills & Subscriptions'**
  String get billsTitle;

  /// No description provided for @billsAddBill.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get billsAddBill;

  /// No description provided for @billsDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get billsDueDate;

  /// No description provided for @billsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get billsFrequency;

  /// No description provided for @billsNoBills.
  ///
  /// In en, this message translates to:
  /// **'No bills tracked'**
  String get billsNoBills;

  /// No description provided for @insuranceTitle.
  ///
  /// In en, this message translates to:
  /// **'Insurance Tracker'**
  String get insuranceTitle;

  /// No description provided for @insuranceAddPolicy.
  ///
  /// In en, this message translates to:
  /// **'Add Policy'**
  String get insuranceAddPolicy;

  /// No description provided for @insurancePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get insurancePremium;

  /// No description provided for @insuranceCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get insuranceCoverage;

  /// No description provided for @insuranceRenewalDate.
  ///
  /// In en, this message translates to:
  /// **'Renewal Date'**
  String get insuranceRenewalDate;

  /// No description provided for @insuranceNoInsurance.
  ///
  /// In en, this message translates to:
  /// **'No insurance policies tracked'**
  String get insuranceNoInsurance;

  /// No description provided for @taxTitle.
  ///
  /// In en, this message translates to:
  /// **'BIR Tax Tracker'**
  String get taxTitle;

  /// No description provided for @taxAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get taxAnnualIncome;

  /// No description provided for @taxTaxableIncome.
  ///
  /// In en, this message translates to:
  /// **'Taxable Income'**
  String get taxTaxableIncome;

  /// No description provided for @taxIncomeTax.
  ///
  /// In en, this message translates to:
  /// **'Income Tax'**
  String get taxIncomeTax;

  /// No description provided for @taxEffectiveRate.
  ///
  /// In en, this message translates to:
  /// **'Effective Rate'**
  String get taxEffectiveRate;

  /// No description provided for @taxFilingDeadline.
  ///
  /// In en, this message translates to:
  /// **'Filing Deadline'**
  String get taxFilingDeadline;

  /// No description provided for @thirteenthMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'13th Month Pay'**
  String get thirteenthMonthTitle;

  /// No description provided for @thirteenthMonthBasicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic Monthly Salary'**
  String get thirteenthMonthBasicSalary;

  /// No description provided for @thirteenthMonthMonthsWorked.
  ///
  /// In en, this message translates to:
  /// **'Months Worked'**
  String get thirteenthMonthMonthsWorked;

  /// No description provided for @thirteenthMonthAmount.
  ///
  /// In en, this message translates to:
  /// **'13th Month Pay Amount'**
  String get thirteenthMonthAmount;

  /// No description provided for @thirteenthMonthTaxExempt.
  ///
  /// In en, this message translates to:
  /// **'Tax Exempt (up to ₱90,000)'**
  String get thirteenthMonthTaxExempt;

  /// No description provided for @retirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Retirement Projection'**
  String get retirementTitle;

  /// No description provided for @retirementCurrentAge.
  ///
  /// In en, this message translates to:
  /// **'Current Age'**
  String get retirementCurrentAge;

  /// No description provided for @retirementTargetAge.
  ///
  /// In en, this message translates to:
  /// **'Target Retirement Age'**
  String get retirementTargetAge;

  /// No description provided for @retirementMonthlySavings.
  ///
  /// In en, this message translates to:
  /// **'Monthly Savings'**
  String get retirementMonthlySavings;

  /// No description provided for @retirementProjectedFund.
  ///
  /// In en, this message translates to:
  /// **'Projected Fund'**
  String get retirementProjectedFund;

  /// No description provided for @retirementSssPension.
  ///
  /// In en, this message translates to:
  /// **'SSS Pension'**
  String get retirementSssPension;

  /// No description provided for @retirementSavingsGap.
  ///
  /// In en, this message translates to:
  /// **'Savings Gap'**
  String get retirementSavingsGap;

  /// No description provided for @rentVsBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Rent vs Buy'**
  String get rentVsBuyTitle;

  /// No description provided for @rentVsBuyMonthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent'**
  String get rentVsBuyMonthlyRent;

  /// No description provided for @rentVsBuyPropertyPrice.
  ///
  /// In en, this message translates to:
  /// **'Property Price'**
  String get rentVsBuyPropertyPrice;

  /// No description provided for @rentVsBuyDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down Payment'**
  String get rentVsBuyDownPayment;

  /// No description provided for @rentVsBuyLoanTerm.
  ///
  /// In en, this message translates to:
  /// **'Loan Term'**
  String get rentVsBuyLoanTerm;

  /// No description provided for @rentVsBuyInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get rentVsBuyInterestRate;

  /// No description provided for @rentVsBuyMonthlyMortgage.
  ///
  /// In en, this message translates to:
  /// **'Monthly Mortgage'**
  String get rentVsBuyMonthlyMortgage;

  /// No description provided for @rentVsBuyVerdict.
  ///
  /// In en, this message translates to:
  /// **'Verdict'**
  String get rentVsBuyVerdict;

  /// No description provided for @panganayTitle.
  ///
  /// In en, this message translates to:
  /// **'Panganay Mode'**
  String get panganayTitle;

  /// No description provided for @panganaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Family support budgeting'**
  String get panganaySubtitle;

  /// No description provided for @panganayFamilySupport.
  ///
  /// In en, this message translates to:
  /// **'Family Support'**
  String get panganayFamilySupport;

  /// No description provided for @panganayMonthlySupport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Support'**
  String get panganayMonthlySupport;

  /// No description provided for @panganayPercentageOfIncome.
  ///
  /// In en, this message translates to:
  /// **'Percentage of Income'**
  String get panganayPercentageOfIncome;

  /// No description provided for @calculatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Calculators'**
  String get calculatorsTitle;

  /// No description provided for @calculatorsCompoundInterest.
  ///
  /// In en, this message translates to:
  /// **'Compound Interest'**
  String get calculatorsCompoundInterest;

  /// No description provided for @calculatorsLoanAmortization.
  ///
  /// In en, this message translates to:
  /// **'Loan Amortization'**
  String get calculatorsLoanAmortization;

  /// No description provided for @calculatorsFireNumber.
  ///
  /// In en, this message translates to:
  /// **'FIRE Number'**
  String get calculatorsFireNumber;

  /// No description provided for @calculatorsEmergencyFund.
  ///
  /// In en, this message translates to:
  /// **'Emergency Fund'**
  String get calculatorsEmergencyFund;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sandalan'**
  String get onboardingWelcome;

  /// No description provided for @onboardingWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Your all-in-one Filipino adulting companion'**
  String get onboardingWelcomeSub;

  /// No description provided for @onboardingChooseStage.
  ///
  /// In en, this message translates to:
  /// **'What stage of life are you in?'**
  String get onboardingChooseStage;

  /// No description provided for @onboardingChooseFocus.
  ///
  /// In en, this message translates to:
  /// **'What do you want to focus on?'**
  String get onboardingChooseFocus;

  /// No description provided for @onboardingSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get onboardingSelectAll;

  /// No description provided for @onboardingAddAccounts.
  ///
  /// In en, this message translates to:
  /// **'Add your accounts'**
  String get onboardingAddAccounts;

  /// No description provided for @onboardingAddAccountsSub.
  ///
  /// In en, this message translates to:
  /// **'We\'ll track your balances across all your money spots'**
  String get onboardingAddAccountsSub;

  /// No description provided for @onboardingSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkipForNow;

  /// No description provided for @onboardingAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get onboardingAccountName;

  /// No description provided for @onboardingAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get onboardingAccountType;

  /// No description provided for @onboardingInitialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get onboardingInitialBalance;

  /// No description provided for @onboardingAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingAllSet;

  /// No description provided for @onboardingAllSetSub.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start your adulting journey'**
  String get onboardingAllSetSub;

  /// No description provided for @onboardingContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get onboardingContinueAsGuest;

  /// No description provided for @onboardingGuestNote.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device only'**
  String get onboardingGuestNote;

  /// No description provided for @stageUnangHakbang.
  ///
  /// In en, this message translates to:
  /// **'Unang Hakbang'**
  String get stageUnangHakbang;

  /// No description provided for @stageUnangHakbangSub.
  ///
  /// In en, this message translates to:
  /// **'Fresh grad / First job'**
  String get stageUnangHakbangSub;

  /// No description provided for @stageUnangHakbangDesc.
  ///
  /// In en, this message translates to:
  /// **'Getting IDs, first payslip, learning the basics'**
  String get stageUnangHakbangDesc;

  /// No description provided for @stagePundasyon.
  ///
  /// In en, this message translates to:
  /// **'Pundasyon'**
  String get stagePundasyon;

  /// No description provided for @stagePundasySub.
  ///
  /// In en, this message translates to:
  /// **'Building foundations'**
  String get stagePundasySub;

  /// No description provided for @stagePundasyonDesc.
  ///
  /// In en, this message translates to:
  /// **'Saving, budgeting, building credit'**
  String get stagePundasyonDesc;

  /// No description provided for @stageTahanan.
  ///
  /// In en, this message translates to:
  /// **'Tahanan'**
  String get stageTahanan;

  /// No description provided for @stageTahananSub.
  ///
  /// In en, this message translates to:
  /// **'Establishing a home'**
  String get stageTahananSub;

  /// No description provided for @stageTahananDesc.
  ///
  /// In en, this message translates to:
  /// **'Renting, buying property, starting a family'**
  String get stageTahananDesc;

  /// No description provided for @stageTugatog.
  ///
  /// In en, this message translates to:
  /// **'Tugatog'**
  String get stageTugatog;

  /// No description provided for @stageTugatogSub.
  ///
  /// In en, this message translates to:
  /// **'Career peak'**
  String get stageTugatogSub;

  /// No description provided for @stageTugatogDesc.
  ///
  /// In en, this message translates to:
  /// **'Growing wealth, investments, insurance'**
  String get stageTugatogDesc;

  /// No description provided for @stagePaghahanda.
  ///
  /// In en, this message translates to:
  /// **'Paghahanda'**
  String get stagePaghahanda;

  /// No description provided for @stagePaghahandaSub.
  ///
  /// In en, this message translates to:
  /// **'Pre-retirement'**
  String get stagePaghahandaSub;

  /// No description provided for @stagePaghahandaDesc.
  ///
  /// In en, this message translates to:
  /// **'Estate planning, retirement prep'**
  String get stagePaghahandaDesc;

  /// No description provided for @stageGintongTaon.
  ///
  /// In en, this message translates to:
  /// **'Gintong Taon'**
  String get stageGintongTaon;

  /// No description provided for @stageGintongTaonSub.
  ///
  /// In en, this message translates to:
  /// **'Golden years'**
  String get stageGintongTaonSub;

  /// No description provided for @stageGintongTaonDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoying retirement, legacy planning'**
  String get stageGintongTaonDesc;

  /// No description provided for @focusTrackExpenses.
  ///
  /// In en, this message translates to:
  /// **'Track my daily expenses'**
  String get focusTrackExpenses;

  /// No description provided for @focusBudgetSalary.
  ///
  /// In en, this message translates to:
  /// **'Budget my salary'**
  String get focusBudgetSalary;

  /// No description provided for @focusPayOffDebt.
  ///
  /// In en, this message translates to:
  /// **'Pay off debt'**
  String get focusPayOffDebt;

  /// No description provided for @focusBuildEmergency.
  ///
  /// In en, this message translates to:
  /// **'Build an emergency fund'**
  String get focusBuildEmergency;

  /// No description provided for @focusSaveForGoal.
  ///
  /// In en, this message translates to:
  /// **'Save for a big purchase'**
  String get focusSaveForGoal;

  /// No description provided for @focusGrowWealth.
  ///
  /// In en, this message translates to:
  /// **'Grow my wealth'**
  String get focusGrowWealth;

  /// No description provided for @focusGetIds.
  ///
  /// In en, this message translates to:
  /// **'Get my government IDs'**
  String get focusGetIds;

  /// No description provided for @focusUnderstandBenefits.
  ///
  /// In en, this message translates to:
  /// **'Understand my benefits & contributions'**
  String get focusUnderstandBenefits;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your financial journey'**
  String get authSignInSubtitle;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authDontHaveAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOrContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or continue with email'**
  String get authOrContinueWithEmail;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get authFillAllFields;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get authPasswordMismatch;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get authWeakPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get authInvalidEmail;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use'**
  String get authEmailInUse;

  /// No description provided for @authAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get authAccountNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get authWrongPassword;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a reset link'**
  String get authCheckEmail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
