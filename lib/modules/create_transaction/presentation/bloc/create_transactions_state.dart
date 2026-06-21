part of 'create_transactions_bloc.dart';

@immutable
abstract class CreateTransactionsState {}

class CreateTransactionsInitial extends CreateTransactionsState {}

class LoadingState extends CreateTransactionsState {}

class LoadedState extends CreateTransactionsState {
  final List<Mode> modes;
  final Mode? selectedMode;
  final List<Category> categories;
  final Category? selectedCategory;
  final List<ExpensesAccount> accounts;
  final String selectedAccount;
  final int selectedAccountId;
  final String currencyCode;
  final DateTime selectedDate;
  LoadedState({
    required this.modes,
    required this.selectedMode,
    required this.categories,
    required this.selectedCategory,
    required this.accounts,
    required this.selectedAccount,
    required this.selectedAccountId,
    required this.currencyCode,
    required this.selectedDate,
  });
}

class NavigateToChooseCategory extends CreateTransactionsState {}

class NavigateToChoosePaymentMode extends CreateTransactionsState {}

class NavigateToChangeAccount extends CreateTransactionsState {
  final String selectedAccount;

  NavigateToChangeAccount({required this.selectedAccount});
}

class TransactionSaved extends CreateTransactionsState {}

class FailureState extends CreateTransactionsState {
  final String errorMessage;
  FailureState({required this.errorMessage});
}

class ValidationErrorState extends CreateTransactionsState {
  final String? errorDescription;
  final String? errorAmount;
  ValidationErrorState({this.errorDescription, this.errorAmount});
}
  