part of 'profile_bloc.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class FailureState extends ProfileState {
  final String errorMessage;
  FailureState({required this.errorMessage});
}

class ShowModels extends ProfileState {
  final List<ExpensesAccount> modelList;
  final String selectedAccount;
  ShowModels({required this.modelList, required this.selectedAccount});
}

class ModelCreateSuccess extends ProfileState {
  final List<ExpensesAccount> modelList;
  ModelCreateSuccess({required this.modelList});
}

class NavigateToAccountScreen extends ProfileState {
  final String selectedAccount;
  NavigateToAccountScreen({required this.selectedAccount});
}

class SelectAccountSuccess extends ProfileState {
  final String selectedAccount;
  SelectAccountSuccess({required this.selectedAccount});
}
