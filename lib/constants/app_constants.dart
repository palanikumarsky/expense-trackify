class AppConstants {
  // App
  static const String appName = 'ExpenseTrackify';
  static const String expenseTracker = 'Your Personal Expense Tracker';

  // Home/DashBoard
  static const String summary = 'Summary';
  static const String detailedView = 'DetailedView';
  
  // Bottom Navigation
  static const String dashboard = 'Dashboard';
  static const String modes = 'Modes';
  static const String categories = 'Categories';
  static const String analytics = 'Analytics';
  static const String txn = 'Txn';
  static const String calendar = 'Calendar';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String about = 'About';
  
  // Summary
  static const String totalSpend = 'Total Spend';
  static const String allDates = 'All Dates';
  static const String selectPeriod = 'Select Period';
  static const String categoryWiseTransactionChart = 'Category-wise Transaction Chart';
  static const String categoryWiseTransactionVennDiagram = 'Category-wise Transaction Venn Diagram';
  static const String spendingByMode = 'Spending by Mode';
  static const String spendingByCategory = 'Spending by Category';
  static const String addTransactionToSeeSummary = 'Add a transaction to see your summary!';
  
  // Add/Edit Transaction
  static const String addTransaction = 'Add Transaction';
  static const String editTransaction = 'Edit Transaction';
  static const String enterDetailsForYourNewTransaction = 'Enter details for your new transaction';
  static const String description = 'Description';
  static const String account = 'Account';
  static const String amount = 'Amount';
  static const String category = 'Category';
  static const String date = 'Date';
  static const String pleaseEnterDescription = 'Please enter a description';
  static const String pleaseEnterAmount = 'Please enter an amount';
  static const String pleaseEnterValidNumber = 'Please enter a valid number';
  static const String saveTransaction = 'Save Transaction';
  static const String selectModeAndCategory = 'Please select a mode and category';
  static const String selectCategory = 'Select Category';
  
  // Modes Screen
  static const String paymentModes = 'Payment Modes';
  static const String addNewMode = 'Add New Mode';
  static const String editMode = 'Edit Mode';
  static const String deleteMode = 'Delete Mode';
  static const String enterModeName = 'Enter mode name';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String undo = 'Undo';
  static const String noPaymentModesAvailable = 'No payment modes available.';
  static const String tapPlusButtonToAddFirstMode = 'Tap the + button to add your first payment mode!';
  static const String paymentMode = 'Payment Mode';
  static const String newModeAddedSuccessfully = 'New mode "{0}" added successfully!';
  static const String modeUpdatedSuccessfully = 'Mode updated from "{0}" to "{1}"!';
  static const String modeDeletedSuccessfully = 'Mode "{0}" deleted successfully!';
  static const String modeNameCannotBeEmpty = 'Mode name cannot be empty!';
  static const String deleteModeConfirmation = 'Are you sure you want to delete "{0}"? This action cannot be undone.';
  static const String setAsDefault = 'Set as Default';

  // Categories Screen
  static const String addNewCategory = 'Add New Category';
  static const String editCategory = 'Edit Category';
  static const String deleteCategory = 'Delete Category';
  static const String enterCategoryName = 'Enter category name';
  static const String noCategoriesAvailable = 'No categories available.';
  static const String tapPlusButtonToAddFirstCategory = 'Tap the + button to add your first category!';
  static const String newCategoryAddedSuccessfully = 'New category "{0}" added successfully!';
  static const String categoryUpdatedSuccessfully = 'Category updated from "{0}" to "{1}"!';
  static const String categoryDeletedSuccessfully = 'Category "{0}" deleted successfully!';
  static const String categoryNameCannotBeEmpty = 'Category name cannot be empty!';
  static const String deleteCategoryConfirmation = 'Are you sure you want to delete "{0}"?\n\nThis action cannot be undone.';
  static const String noTransactionsFound = 'No transactions found.';
  static const String tapPlusButtonToAddFirstTransaction = 'Tap the + button to add your first transaction!';
  static const String defaultModeLabel = 'Default';

  // Transaction Detail Screen
  static const String transactionDetails = 'Transaction Details';
  static const String deleteTransaction = 'Delete Transaction';
  static const String deleteTransactionConfirmation = 'Are you sure you want to delete this transaction?\n\nThis action cannot be undone.';
  static const String transactionDeletedSuccessfully = 'Transaction deleted successfully!';
  static const String paymentModeLabel = 'Payment Mode:';
  static const String categoryLabel = 'Category:';
  static const String dateLabel = 'Date:';
  static const String descriptionLabel = 'Description:';
  static const String amountLabel = 'Amount:';
  static const String loading = 'Loading...';
  static const String unknown = 'Unknown';

  // Detailed View
  static const String cannotAddTransaction = 'Cannot Add Transaction';
  static const String needModeAndCategory = 'You need at least one payment mode and one category to add a transaction.';
  static const String ok = 'OK';

  // Currency Screen
  static const String selectCurrency = 'Select Currency';

  // Create Transactions Screen
  static const String selectedCategory = 'Select Category';
  static const String selectedPaymentMode = 'Select Payment Mode';
  static const String change = 'change';
  static const String openAccountScreen = 'Would you like to open the account screen now?';

  // Login Screen
  static const String continueAsGuest = 'Continue As Guest';
  static const String signInWithGoogle = 'SignIn with Google';
  static const String skip = 'Skip';
  static const String unlockAllFeatures = 'Unlock all features';
  static const String downloadYourTransactions = 'Download your transactions';
  static const String backupAndSyncYourData = 'Backup & sync your data';
  static const String accessOnMultipleDevices = 'Access on multiple devices';
  static const String adFreeEnvironment = 'Ad free environment';
  static const String personalizedTrackerForYourExpenses = 'Personalized tracker for \nyour expenses.';

  // Profile Screen
  static const String hiGuest = 'Hi Guest!';
  static const String loginOrSignupToTrackExpenses = 'Login or Signup to track your expenses and unlock all features.';
  static const String loginOrSignup = 'Login or Signup';
  static const String guest = 'Guest User';
  static const String user = 'User';
  static const String editProfile = 'Edit Profile';
  static const String accountManagement = 'Account Management';
  static const String syncNow = 'Sync Now';
  static const String deleteProfile = 'Delete Profile';
  static const String logout = 'Logout';
  static const String welcomeUser = 'Welcome {0}!';
  static const String loggedOutSuccessfully = 'Logged out successfully...!!!';
  static const String syncingTransactions = 'Syncing transactions...';
  static const String foundCollections = 'Found {0} collections';
  static const String syncConfirmation = 'Sync Confirmation';
  static const String foundNewTransactionsToUpload = 'Found {0} new transactions to upload to cloud:';
  static const String andMoreTransactions = '... and {0} more transactions';
  static const String doYouWantToUploadTransactions = 'Do you want to upload these transactions to the cloud?';
  static const String no = 'NO';
  static const String yes = 'YES';
  static const String syncCancelledByUser = 'Sync cancelled by user';

  // Settings Screen
  static const String exportData = 'Export Data';
  static const String dataManagement = 'Data Management';
  static const String general = 'General';
  static const String dataAndPrivacy = 'Data & Privacy';
  static const String downloadTransactions = 'Download Transactions';
  static const String exportAllTransactions = 'Export all transactions';
  static const String paymentModesTitle = 'Payment Modes';
  static const String categoriesTitle = 'Categories';
  static const String modesConfigured = 'modes configured';
  static const String categoriesConfigured = 'categories configured';
  static const String currency = 'Currency';
  static const String notifications = 'Notifications';
  static const String manageNotificationPreferences = 'Manage notification preferences';
  static const String manageProfilePreferences = 'Manage profile, sync & backup transactions';
  static const String manageAccountPreferences = 'Manage expense accounts';
  static const String language = 'Language';
  static const String english = 'English';
  static const String darkTheme = 'Dark theme';
  static const String willAlwaysUseDarkTheme = 'Will always use dark theme';
  static const String willNeverTurnOnAutomatically = 'Will never turn on automatically';
  static const String backupAndRestore = 'Backup & Restore';
  static const String backupYourDataToCloud = 'Backup your data to cloud';
  static const String privacy = 'Privacy';
  static const String manageYourPrivacySettings = 'Manage your privacy settings';
  static const String clearData = 'Clear Data';
  static const String areYouSure = 'Are you sure?';
  static const String deleteAllAppData = 'Delete all app data';
  static const String clearAllData = 'Clear All Data';
  static const String clearAllDataConfirmation = 'Are you sure you want to delete all your transaction data? This action cannot be undone.';
  static const String allDataClearedSuccessfully = 'All data cleared successfully';
  static const String clear = 'Clear';
  static const String appVersion = "App Version";

  // Settings Screen Additional
  static const String expenseTrackifyInvoice = 'ExpenseTrackify Invoice';
  static const String generatedFor = 'Generated for:';
  static const String invoice = 'Invoice #: ';
  static const String total = 'Total: ';
  static const String pdfViewer = 'PDF Viewer';

  // Download Modal
  static const String downloadTransactionsTitle = 'Download Transactions';
  static const String mode = 'Mode';
  static const String selectMode = 'Select Mode';
  static const String allModes = 'ALL';
  static const String duration = 'Duration';
  static const String fileFormat = 'File Format';
  static const String download = 'Download';
  static const String pickADay = 'Pick a Day';
  static const String pickDateRange = 'Pick Date Range';
  static const String noTransactionsAvailableToDownload = 'No transactions available to download.';
  static const String noTransactionsFoundInSelectedRange = 'No transactions found in selected range.';
  static const String errorDownloadingPDF = 'Error downloading PDF: ';
  static const String errorDownloadingCSV = 'Error downloading CSV: ';
  static const String storagePermissionRequired = 'Storage Permission Required';
  static const String storagePermissionDeniedMessage = 'Storage permission is permanently denied. To save PDF files to your Downloads folder, please enable storage permission in app settings.';
  static const String openSettings = 'Open Settings';
  static const String storagePermissionNeeded = 'Storage permission needed to save PDF to Downloads folder.';
  static const String couldNotGetDownloadDirectory = 'Could not get download directory';
  static const String pdfSavedToDownloads = 'PDF saved to Downloads/ExpenseTrackify folder';
  static const String pdfSavedToAppDirectory = 'PDF saved to app directory';
  static const String csvSavedToDownloads = 'CSV saved to Downloads/ExpenseTrackify folder';
  static const String csvSavedToAppDirectory = 'CSV saved to app directory';
  static const String open = 'Open';
  static const String transactionReport = 'Transaction Report';

  // Duration Options
  static const String last30Days = 'Last 30 Days';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String thisYear = 'This Year';
  static const String singleDay = 'Single Day';
  static const String customRange = 'Custom Range';

  // File Format Options
  static const String pdf = 'PDF';
  static const String csv = 'CSV';

  // PDF/CSV Headers
  static const String transactions = 'Transactions';
  static const String dateHeader = 'Date';
  static const String modeHeader = 'Mode';
  static const String categoryHeader = 'Category';
  static const String descriptionHeader = 'Description';
  static const String amountHeader = 'Amount';

  // Currency Screen
  static const List<Map<String, String>> currencyMap = [
    {'code': 'USD', 'symbol': ' 24', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': ' 0AC', 'name': 'Euro'},
    {'code': 'INR', 'symbol': ' 0B9', 'name': 'Indian Rupee'},
    {'code': 'GBP', 'symbol': ' A3', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': ' A5', 'name': 'Japanese Yen'},
    {'code': 'AUD', 'symbol': ' 24', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': ' 24', 'name': 'Canadian Dollar'},
    {'code': 'SGD', 'symbol': ' 24', 'name': 'Singapore Dollar'},
    {'code': 'CNY', 'symbol': ' A5', 'name': 'Chinese Yuan'},
  ];

  // Calendar
  static const String selectDateToViewTransactions = 'Select a date to view transactions';
  static const String noTransactionsFor = 'No transactions for';

  // Common
  static const String somethingWentWrong = "Something Went Wrong";
  static const String isGuestUser = "Is_Guest_User";
  static const String userType = "User_Type";
  static const String guestUser = "Guest_User";
  static const String loggedUser = "Logged_User";

  // Accounts Screen
  static const String selectedAccount = "Selected_Account";
  static const String addNewAccount = 'Add New Account';
  static const String enterAccountName = 'Enter account name';
  static const String newAccountAddedSuccessfully = 'New account "{0}" added successfully!';
  static const String accountUpdatedSuccessfully = 'Account updated from "{0}" to "{1}"!';
  static const String accountDeletedSuccessfully = 'Account "{0}" deleted successfully!';
  static const String accountNameCannotBeEmpty = 'Account name cannot be empty!';
  static const String deleteAccountConfirmation = 'Are you sure you want to delete "{0}"?\n\nThis action cannot be undone.';

  // Default Data
  static const List<String> defaultCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Education',
    'Bills & Utilities',
    'Travel',
    'Gifts',
    'Other'
  ];
  static const List<String> defaultModes = ['NetBanking', 'UPI', 'Credit Card', 'Cash'];
}