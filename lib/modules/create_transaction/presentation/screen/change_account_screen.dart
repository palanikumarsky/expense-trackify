import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/ads/widgets/banner_ad_widget.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/sync_event_bus.dart';
import 'package:flutter/material.dart';

class ChangeAccountScreen extends StatefulWidget {
  final List<ExpensesAccount> accountList;
  final String selectedAccount;
  const ChangeAccountScreen({
    super.key,
    required this.accountList,
    required this.selectedAccount,
  });

  @override
  State<ChangeAccountScreen> createState() => _ChangeAccountScreenState();
}

class _ChangeAccountScreenState extends State<ChangeAccountScreen> {
  List<ExpensesAccount> accountList = [];
  String selectedAccount = "";
  final TextEditingController accountController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    accountList = widget.accountList;
    selectedAccount = widget.selectedAccount;
  }

  Future<void> saveSelectedAccount(String selectedAccount) async {
    await Prefs.setSelectedAccount(selectedAccount);
  }

  void addNewModel(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomInputDialog(
        controller: accountController,
        title: AppConstants.addNewAccount,
        hintText: AppConstants.enterAccountName,
        onConfirm: (newAccountName) async {
          if (newAccountName.isNotEmpty) {
            final expenseAccountDao = ExpenseAccountDao(appDatabase);
            await expenseAccountDao.addExpenseAccount(ExpensesAccountsCompanion.insert(name: newAccountName));
            // Notify other screens about the data change
            SyncEventBus().notifySync();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.newAccountAddedSuccessfully.replaceAll(
                    '{0}',
                    newAccountName,
                  ),
                ),
                backgroundColor: AppColors.deepPurpleColor,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppConstants.account, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                addNewModel(context);
                // _addNewCategory();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  child: Text("Add", style: TextStyles.whiteMedium12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepPurpleColor.withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.deepPurpleColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Switch Your Expense Account',
                        style: TextStyles.deepPurpleBold16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an account below to manage your expenses. All new transactions will be created in the selected account, helping you organize your finances better.',
                  style: TextStyles.blackRegular14.copyWith(
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.deepPurpleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${accountList.length} Account${accountList.length == 1 ? '' : 's'} Available',
                    style: TextStyles.deepPurpleBold12,
                  ),
                ),
              ],
            ),
          ),
          // List of models as selectable radio list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: accountList.length,
              itemBuilder: (context, index) {
                String accountName = accountList[index].name;
                bool isSelected = selectedAccount == accountName;
                return InkWell(
                  onTap: () {
                    saveSelectedAccount(accountName);
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.deepPurpleColor
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
                      child: Text(
                        accountName,
                        style:
                            isSelected
                                ? TextStyles.whiteSemiBold16
                                : TextStyles.blackSemiBold16,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
          // Banner Ad at the bottom
          const BannerAdWidget(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            showBorder: true,
          ),
        ],
      ),
    );
  }
}
