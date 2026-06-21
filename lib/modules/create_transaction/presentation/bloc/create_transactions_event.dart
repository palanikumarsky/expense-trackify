part of 'create_transactions_bloc.dart';

@immutable
abstract class CreateTransactionsEvent {}

class FetchModesCategories extends CreateTransactionsEvent {}

class ChooseCategory extends CreateTransactionsEvent {
  final List<Category> categoryList;

  ChooseCategory(this.categoryList);
}

class ChoosePaymentMode extends CreateTransactionsEvent {
  final List<Mode> paymentModeList;

  ChoosePaymentMode(this.paymentModeList);
}

class ChangeAccountTapped extends CreateTransactionsEvent {}

class SaveTransaction extends CreateTransactionsEvent {
  final String description;
  final String amount;
  final Mode selectedMode;
  final Category selectedCategory;
  final DateTime selectedDate;
  final String currencyCode;
  final int selectedAccountId;

  SaveTransaction({
    required this.description,
    required this.amount,
    required this.selectedMode,
    required this.selectedCategory,
    required this.selectedDate,
    required this.currencyCode,
    required this.selectedAccountId,
  });
}


