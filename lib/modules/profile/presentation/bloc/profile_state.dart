part of 'profile_bloc.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class LoggedInSuccessful extends ProfileState {
  final String? providerName;
  final String? userName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;

  LoggedInSuccessful({
    this.providerName,
    this.userName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
  });
}

class FailureState extends ProfileState {
  final String errorMessage;

  FailureState({required this.errorMessage});
}

class SignOutSuccess extends ProfileState {}

class SyncInProgress extends ProfileState {}

class SyncSuccess extends ProfileState {
  final String message;
  final int syncedCount;

  SyncSuccess({required this.message, required this.syncedCount});
}

class SyncFailure extends ProfileState {
  final String errorMessage;

  SyncFailure({required this.errorMessage});
}

class SyncInfoLoaded extends ProfileState {
  final SyncInfo syncInfo;

  SyncInfoLoaded({required this.syncInfo});
}

class ShowModels extends ProfileState {
  final List<ExpensesAccount> modelList;
  final String selectedAccount;

  ShowModels({
    required this.modelList,
    required this.selectedAccount
  });
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
