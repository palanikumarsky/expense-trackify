import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/config/widgets/empty_state_widget.dart';
import 'package:expensetrackify/config/widgets/custom_progress_bar.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/modules/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsScreen extends StatefulWidget {
  final String selectedAccount;
  const AccountsScreen({super.key, this.selectedAccount = ""});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<ExpensesAccount> accountList = [];
  String selectedAccount = "";
  final TextEditingController accountController = TextEditingController();
  final ExpenseAccountDao _accountDao = ExpenseAccountDao(appDatabase);

  @override
  void dispose() {
    selectedAccount = widget.selectedAccount;
    accountController.dispose();
    super.dispose();
  }

  // void addNewModel(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext contex) {
  //       return AlertDialog(
  //         title: Text(
  //           AppConstants.addNewAccount,
  //           style: TextStyles.deepPurpleBold16,
  //         ),
  //         content: TextField(
  //           controller: accountController,
  //           decoration: InputDecoration(
  //             hintText: AppConstants.enterAccountName,
  //             border: OutlineInputBorder(),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               accountController.clear();
  //             },
  //             child: Text(
  //               AppConstants.cancel,
  //               style: TextStyles.deepPurpleBold16,
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               final newAccountName = accountController.text.trim();
  //               if (newAccountName.isNotEmpty) {
  //                 BlocProvider.of<ProfileBloc>(
  //                   context,
  //                 ).add(CreateModel(modelName: newAccountName));
  //                 Navigator.of(context).pop();
  //                 accountController.clear();
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.deepPurpleColor,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: Text(AppConstants.save),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void addNewModel(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomInputDialog(
        controller: accountController,
        title: AppConstants.addNewAccount,
        hintText: AppConstants.enterAccountName,
        onConfirm: (newAccountName) {
          BlocProvider.of<ProfileBloc>(context)
              .add(CreateModel(modelName: newAccountName));
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Accounts', style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: BlocProvider<ProfileBloc>(
        create: (context) => ProfileBloc()..add(FetchModels()),
        child: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            // TODO: implement listener
            if (state is ShowModels) {
              CustomProgressBar(context).hideLoadingIndicator();
              accountList = state.modelList;
              selectedAccount =
                  state.selectedAccount.isNotEmpty
                      ? state.selectedAccount
                      : accountList.isNotEmpty ? accountList[0].name : '';
            } else if (state is SelectAccountSuccess) {
              CustomProgressBar(context).hideLoadingIndicator();
              selectedAccount = state.selectedAccount;
            } else if (state is FailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ModelCreateSuccess) {
              accountList = state.modelList;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppConstants.newAccountAddedSuccessfully.replaceAll(
                      '{0}',
                      accountController.text.trim(),
                    ),
                  ),
                  backgroundColor: AppColors.deepPurpleColor,
                ),
              );
            } else if (state is ProfileInitial) {
              CustomProgressBar(context).showLoadingIndicator();
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child:
                        accountList.isEmpty
                            ? buildEmptyModelWidget()
                            : buildModelWidget(),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      addNewModel(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: AppColors.deepPurpleColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Add New Account",
                            style: TextStyles.whiteBold14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildEmptyModelWidget() {
    return const EmptyStateWidget(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No accounts yet',
      subtitle: 'Add an account to start organising your expenses',
    );
  }

  Widget buildModelWidget() {
    return Column(
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
              final modelName = accountList[index].name;
              bool isSelected = selectedAccount == modelName;
              return InkWell(
                onTap: () {
                  BlocProvider.of<ProfileBloc>(
                    context,
                  ).add(ChangeAccountTapped(selectedAccount: modelName));
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
                      modelName,
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
      ],
    );
  }
}
