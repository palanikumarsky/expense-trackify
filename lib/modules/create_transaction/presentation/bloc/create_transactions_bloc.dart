import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:meta/meta.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetrackify/utils/date_time_helper.dart';

part 'create_transactions_event.dart';
part 'create_transactions_state.dart';

class CreateTransactionsBloc
    extends Bloc<CreateTransactionsEvent, CreateTransactionsState> {
  final ModeDao _modeDao = ModeDao(appDatabase);
  final CategoryDao _categoryDao = CategoryDao(appDatabase);
  final TransactionDao _transactionDao = TransactionDao(appDatabase);
  final expenseAccountDao = ExpenseAccountDao(appDatabase);

  CreateTransactionsBloc() : super(CreateTransactionsInitial()) {
    on<FetchModesCategories>(_onFetchModesCategories);
    on<ChooseCategory>(_onChooseCategory);
    on<ChoosePaymentMode>(_onChoosePaymentMode);
    on<SaveTransaction>(_onSaveTransaction);
    on<ChangeAccountTapped>(_onChangeAccountTapped);
  }

  Future<void> _onFetchModesCategories(
      FetchModesCategories event,
    Emitter<CreateTransactionsState> emit,
  ) async {
    emit(LoadingState());
    final modes = await _modeDao.getModes();
    String? selectedPaymentModePref = await Prefs.getSelectedPaymentMode;
    Mode? selectedPaymentMode = modes.isNotEmpty ? modes.first : null;
    if (selectedPaymentModePref != null && selectedPaymentModePref.isNotEmpty ) {
      Map<String, dynamic> jsonMap = json.decode(selectedPaymentModePref);
      selectedPaymentMode = Mode.fromJson(jsonMap);
    }
    final categories = await _categoryDao.getCategories();
    String? selectedCategoryPref = await Prefs.getSelectedCategory;
    Category? selectedCategory = categories.isNotEmpty ? categories.first : null;
    if (selectedCategoryPref != null && selectedCategoryPref.isNotEmpty ) {
      Map<String, dynamic> jsonMap = json.decode(selectedCategoryPref);
      selectedCategory = Category.fromJson(jsonMap);
    }

    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('currency_code') ?? 'USD';

    final accounts = await expenseAccountDao.getExpensesAccounts();
    String? selectedAccount = await Prefs.getSelectedAccount;
    int selectedAccountId = accounts.firstWhere((a) => a.name == selectedAccount).id;

    emit(
      LoadedState(
        modes: modes,
        selectedMode: selectedPaymentMode,
        categories: categories,
        selectedCategory: selectedCategory,
        accounts: accounts,
        selectedAccount: selectedAccount ?? "",
        selectedAccountId: selectedAccountId,
        currencyCode: currencyCode,
        selectedDate: DateTime.now(),
      ),
    );
  }

  Future<void> _onChooseCategory(
      ChooseCategory event,
      Emitter<CreateTransactionsState> emit,
      ) async {
    emit(NavigateToChooseCategory());
  }

  Future<void> _onChoosePaymentMode(
      ChoosePaymentMode event,
      Emitter<CreateTransactionsState> emit,
      ) async {
    emit(NavigateToChoosePaymentMode());
  }

  Future<void> _onChangeAccountTapped(
      ChangeAccountTapped event,
      Emitter<CreateTransactionsState> emit,
      ) async {
    String? selectedAccount = await Prefs.getSelectedAccount;
    emit(NavigateToChangeAccount(selectedAccount: selectedAccount ?? ""));
  }

  Future<void> _onSaveTransaction(
    SaveTransaction event,
    Emitter<CreateTransactionsState> emit,
  ) async {
    String? errorDescription;
    String? errorAmount;
    bool hasError = false;
    if (event.description.isEmpty) {
      errorDescription = 'Please enter description';
      hasError = true;
    }
    if (event.amount.isEmpty) {
      errorAmount = 'Please enter amount';
      hasError = true;
    } else if (double.tryParse(event.amount) == null) {
      errorAmount = 'Please enter a valid amount';
      hasError = true;
    }
    if (hasError) {
      emit(
        ValidationErrorState(
          errorDescription: errorDescription,
          errorAmount: errorAmount,
        ),
      );
      return;
    }
    try {
      await _transactionDao.createTransaction(
        TransactionsCompanion.insert(
          id: DateTimeHelper().generateTransactionsId(
            DateTime.now().toIso8601String(),
          ),
          description: event.description,
          amount: double.parse(event.amount),
          modeId: event.selectedMode.id,
          categoryId: event.selectedCategory.id,
          date: event.selectedDate.toIso8601String(),
          expensesAccountId: Value(event.selectedAccountId),
        ),
      );
      emit(TransactionSaved());
    } catch (e) {
      emit(FailureState(errorMessage: 'Error saving transaction: $e'));
    }
  }
}
