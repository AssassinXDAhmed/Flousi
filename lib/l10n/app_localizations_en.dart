// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flousi';

  @override
  String get trackSpending => 'Track your expenses wisely';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign up';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordDescription =>
      'Enter your email address and we will send you a link to recover your account.';

  @override
  String get cancel => 'Cancel';

  @override
  String get sendLink => 'Send Link';

  @override
  String get passwordResetSent => 'Password reset link sent to your email!';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinCommunity => 'Join our community of wise spenders';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get transactions => 'Transactions';

  @override
  String get reports => 'Reports';

  @override
  String get budget => 'Budget';

  @override
  String get debts => 'Debts';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get profile => 'Profile';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note (Optional)';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get lyd => 'LYD';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get seeAll => 'See all';

  @override
  String get spent => 'Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String setLimit(Object period) {
    return 'Set $period Limit';
  }

  @override
  String periodLimit(Object period) {
    return '$period Limit';
  }

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get allTransactions => 'All Transactions';

  @override
  String spentColon(Object amount) {
    return 'Spent: $amount LYD';
  }

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get transfer => 'Transfer';

  @override
  String todayAt(Object time) {
    return 'Today, $time';
  }

  @override
  String yesterdayAt(Object time) {
    return 'Yesterday, $time';
  }

  @override
  String get expense => 'Expense';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get addIncome => 'Add Income';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get arabicScan => 'Arabic Scan';

  @override
  String get latinScan => 'Latin Scan';

  @override
  String get aiExtract => 'AI Extract';

  @override
  String get descriptionHint => 'Description or notes...';

  @override
  String get updateTransaction => 'Update Transaction';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get deleteConfirmation =>
      'Are you sure you want to delete this transaction?';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get transactionUpdated => 'Transaction updated';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get noTextFound => 'No text found in image';

  @override
  String get noArabicTextFound => 'No Arabic text found in image';

  @override
  String ocrError(Object error) {
    return 'OCR Error: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Error saving transaction: $error';
  }

  @override
  String errorDeleting(Object error) {
    return 'Error deleting transaction: $error';
  }

  @override
  String get totalSaved => 'Total Saved';

  @override
  String get activeGoals => 'Active Goals';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get userName => 'User Name';

  @override
  String get debtsAndLoans => 'Debts & Loans';

  @override
  String get recentDebts => 'Recent Debts';

  @override
  String get noDebtsYet => 'No debts tracked yet';

  @override
  String get iOwe => 'I Owe';

  @override
  String get owedToMe => 'Owed to Me';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get markAsUnpaid => 'Mark as Unpaid';

  @override
  String amountLyd(Object amount) {
    return '$amount LYD';
  }

  @override
  String get yourSubscriptions => 'Your Subscriptions';

  @override
  String get noSubscriptionsYet => 'No subscriptions yet';

  @override
  String get totalMonthlyEst => 'Total Monthly Est.';

  @override
  String get active => 'Active';

  @override
  String nextBilling(Object date) {
    return 'Next: $date';
  }

  @override
  String get oneTime => 'One-time';

  @override
  String get monthlyBudgets => 'Monthly Budgets';

  @override
  String get totalMonthlyBudget => 'Total Monthly Budget';

  @override
  String get setMonthlyBudget => 'Set Monthly Budget';

  @override
  String get budgetLimitLyd => 'Budget Limit (LYD)';

  @override
  String setCategoryLimit(Object category) {
    return 'Set $category Limit';
  }

  @override
  String categoryBudgetLyd(Object category) {
    return '$category Budget (LYD)';
  }

  @override
  String get categories => 'Categories';

  @override
  String get used => 'used';

  @override
  String get overBudget => 'Over budget';

  @override
  String get left => 'left';

  @override
  String get aiInsightTitle => 'AI Predictive Insight';

  @override
  String get projectedMonthly => 'Projected Monthly';

  @override
  String get spentThisWeek => 'Spent this week';

  @override
  String get newSubscription => 'New Subscription';

  @override
  String get serviceName => 'Service Name';

  @override
  String get serviceNameHint => 'e.g. Netflix, Spotify';

  @override
  String get billingAmount => 'Billing Amount';

  @override
  String get recurring => 'Recurring';

  @override
  String get autoRenewalEnabled => 'Auto-renewal enabled';

  @override
  String get frequency => 'Frequency';

  @override
  String get currency => 'Currency';

  @override
  String get nextBillingDate => 'Next Billing Date';

  @override
  String get addSubscription => 'Add Subscription';

  @override
  String get pleaseEnterServiceName => 'Please enter a service name';

  @override
  String get addNewDebt => 'Add New Debt';

  @override
  String get whoDoYouOwe => 'Who do you owe?';

  @override
  String get whoOwesYou => 'Who owes you?';

  @override
  String get amountLydLabel => 'Amount (LYD)';

  @override
  String get notes => 'Notes';

  @override
  String get reminderDate => 'Reminder Date';

  @override
  String get notSet => 'Not set';

  @override
  String get saveDebt => 'Save Debt';

  @override
  String get pleaseEnterValidPersonAndAmount =>
      'Please enter a valid person/place and amount';

  @override
  String errorOccurred(Object error) {
    return 'Error: $error';
  }

  @override
  String get security => 'Security';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get biometricLoginDesc =>
      'Require fingerprint or face verification when opening the app';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not set up on this device';

  @override
  String get biometricEnableFailed =>
      'Could not enable biometric login. Please try again.';

  @override
  String get biometricAuthFailed => 'Authentication failed. Please try again.';

  @override
  String get unlockApp => 'Unlock App';

  @override
  String get unlockAppDesc => 'Verify your identity to continue';

  @override
  String get usePasswordInstead => 'Use password instead';

  @override
  String get spendingOverview => 'Spending Overview';

  @override
  String get showFullSpendingReports => 'Show full spending reports';

  @override
  String get viewFullReports => 'View Full Reports';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get total => 'Total';

  @override
  String get language => 'Language';

  @override
  String get languageDesc => 'Choose your preferred language';

  @override
  String get generateInsight => 'Generate Insight';

  @override
  String get generatingInsight => 'Generating insight...';

  @override
  String get aiInsightEmpty =>
      'Analyze your recent spending and get an AI prediction for next week.';
}
