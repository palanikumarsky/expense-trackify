import 'package:expensetrackify/modules/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:expensetrackify/utils/transaction_change_notifier.dart';
import 'package:expensetrackify/modules/create_transaction/presentation/screen/change_account_screen.dart';
import 'package:expensetrackify/modules/create_transaction/presentation/screen/choose_category_screen.dart';
import 'package:expensetrackify/modules/create_transaction/presentation/screen/choose_payment_mode_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expensetrackify/modules/create_transaction/presentation/bloc/create_transactions_bloc.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';

class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  final TransactionDao _transactionDao = TransactionDao(appDatabase);
  List<Mode> modeList = [];
  List<Category> categoryList = [];
  List<ExpensesAccount> accountList = [];
  Mode? selectedMode;
  Category? selectedCategory;
  String? selectedAccount;
  int selectedAccountId = 0;
  String currencyCode = 'USD';
  String? errorDescription;
  String? errorAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppConstants.addTransaction, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: Colors.white,
      ),
      body: BlocProvider(
        create: (_) => CreateTransactionsBloc()..add(FetchModesCategories()),
        child: BlocListener<CreateTransactionsBloc, CreateTransactionsState>(
          listener: (context, state) {
            if (state is TransactionSaved) {
              notifyTransactionChange();
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction saved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate to home screen with index 0 to force refresh
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CustomBottomNavigationBar(
                        selectedIndex: 3,
                        isHomeRefreshNeeded: true,
                      ),
                ),
              );
            } else if (state is LoadedState) {
              modeList = state.modes;
              categoryList = state.categories;
              accountList = state.accounts;
              selectedMode = state.selectedMode;
              selectedCategory = state.selectedCategory;
              selectedAccount = state.selectedAccount;
              selectedAccountId = state.selectedAccountId;
              currencyCode = state.currencyCode;
            } else if (state is NavigateToChooseCategory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ChooseCategoryScreen(categoryList: categoryList),
                ),
              ).then((value) {
                if (value != null && value) {
                  BlocProvider.of<CreateTransactionsBloc>(
                    context,
                  ).add(FetchModesCategories());
                }
              });
            } else if (state is NavigateToChangeAccount) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChangeAccountScreen(accountList: accountList, selectedAccount: selectedAccount ?? '',),
                ),
              ).then((value) {
                if (value != null && value) {
                  BlocProvider.of<CreateTransactionsBloc>(
                    context,
                  ).add(FetchModesCategories());
                }
              });
            } else if (state is NavigateToChoosePaymentMode) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ChoosePaymentModeScreen(paymentModeList: modeList),
                ),
              ).then((value) {
                if (value != null && value) {
                  BlocProvider.of<CreateTransactionsBloc>(
                    context,
                  ).add(FetchModesCategories());
                }
              });
            } else if (state is ValidationErrorState) {
              errorAmount = state.errorAmount;
              errorDescription = state.errorDescription;
            } else if (state is FailureState) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
            }
          },
          child: BlocBuilder<CreateTransactionsBloc, CreateTransactionsState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              buildHeader(AppConstants.account),
                              const Spacer(),
                              InkWell(
                                onTap: (){
                                  BlocProvider.of<CreateTransactionsBloc>(
                                    context,
                                  ).add(ChangeAccountTapped());
                                  // showChangeAccountAlert(context);
                                },
                                child: Text(
                                    AppConstants.change,
                                    style: TextStyles.deepPurpleMedium12.copyWith(
                                      decoration: TextDecoration.underline
                                    ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100,
                                border: Border.all(
                                  color: AppColors.deepPurpleColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance, // or any icon you prefer
                                    color: AppColors.deepPurpleColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedAccount ?? "",
                                      style: const TextStyle(
                                        color: AppColors.deepPurpleColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          buildHeader(AppConstants.date),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                side: BorderSide(
                                  color: AppColors.deepPurpleColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              icon: Icon(
                                Icons.calendar_today,
                                color: AppColors.deepPurpleColor,
                              ),
                              label: Row(
                                children: [
                                  Text(
                                    DateFormat.yMMMd().format(selectedDate),
                                    style: TextStyle(
                                      color: AppColors.deepPurpleColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEE').format(selectedDate),
                                    style: TextStyle(
                                      color: AppColors.deepPurpleColor
                                          .withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null &&
                                    pickedDate != selectedDate) {
                                  setState(() {
                                    selectedDate = pickedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildHeader(AppConstants.paymentMode),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                side: BorderSide(
                                  color: AppColors.deepPurpleColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              icon: Icon(
                                Icons.payment,
                                color: AppColors.deepPurpleColor,
                              ),
                              label: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedMode?.name ??
                                          AppConstants.selectMode,
                                      style: TextStyle(
                                        color:
                                            selectedMode != null
                                                ? AppColors.deepPurpleColor
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: AppColors.deepPurpleColor,
                                  ),
                                ],
                              ),
                              onPressed: () {
                                BlocProvider.of<CreateTransactionsBloc>(
                                  context,
                                ).add(ChoosePaymentMode(modeList));
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildHeader(AppConstants.category),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                side: BorderSide(
                                  color: AppColors.deepPurpleColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              icon: Icon(
                                Icons.category,
                                color: AppColors.deepPurpleColor,
                              ),
                              label: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedCategory?.name ??
                                          AppConstants.selectCategory,
                                      style: TextStyle(
                                        color:
                                            selectedCategory != null
                                                ? AppColors.deepPurpleColor
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: AppColors.deepPurpleColor,
                                  ),
                                ],
                              ),
                              onPressed: () {
                                BlocProvider.of<CreateTransactionsBloc>(
                                  context,
                                ).add(ChooseCategory(categoryList));
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildHeader(AppConstants.description),
                          const SizedBox(height: 8),
                          TextFormField(
                            textCapitalization: TextCapitalization.sentences,
                            controller: descriptionController,
                            style: TextStyles.deepPurpleSemiBold14,
                            decoration: InputDecoration(
                              hintText: AppConstants.description,
                              hintStyle: TextStyles.deepPurpleSemiBold14,
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: AppColors.deepPurpleColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      errorDescription != null
                                          ? Colors.red
                                          : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      errorDescription != null
                                          ? Colors.red
                                          : Colors.deepPurple,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 2,
                                  color:
                                      errorDescription != null
                                          ? Colors.red
                                          : Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 16,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0, right: 0),
                              child: Text(
                                errorDescription ?? '',
                                style: TextStyles.blackRegular14.copyWith(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          buildHeader(AppConstants.amount),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: amountController,
                            style: TextStyles.deepPurpleSemiBold14,
                            decoration: InputDecoration(
                              hintText: AppConstants.amount,
                              hintStyle: TextStyles.deepPurpleSemiBold14,
                              prefixIcon: SizedBox(
                                width: 20,
                                child: Center(
                                  child: Text(
                                    TransactionHelper.getCurrencySymbol(
                                      currencyCode,
                                    ),
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: AppColors.deepPurpleColor,
                                    ),
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      errorAmount != null
                                          ? Colors.red
                                          : AppColors.deepPurpleColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      errorAmount != null
                                          ? Colors.red
                                          : Colors.deepPurple,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 2,
                                  color:
                                      errorAmount != null
                                          ? Colors.red
                                          : AppColors.deepPurpleColor
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(
                            height: 20,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0, right: 0),
                              child: Text(
                                errorAmount ?? '',
                                style: TextStyles.blackRegular14.copyWith(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Validate form fields here if needed

                                BlocProvider.of<CreateTransactionsBloc>(
                                  context,
                                ).add(
                                  SaveTransaction(
                                    description: descriptionController.text,
                                    amount: amountController.text,
                                    selectedMode: selectedMode!,
                                    selectedCategory: selectedCategory!,
                                    selectedDate: selectedDate,
                                    currencyCode: currencyCode,
                                    selectedAccountId: selectedAccountId,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepPurpleColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.save),
                              label: Text(
                                AppConstants.saveTransaction,
                                style: TextStyles.whiteBold16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildHeader(String title) {
    return Text(title, style: TextStyles.deepPurpleBold12);
  }
}
