part of 'profile_bloc.dart';

@immutable
abstract class ProfileEvent {}

class SignInWithGoogle extends ProfileEvent {}

class SignOutTapped extends ProfileEvent {}

class SyncTransactions extends ProfileEvent {}

class ConfirmSync extends ProfileEvent {
  final List<dynamic> newTransactions;
  
  ConfirmSync({required this.newTransactions});
}

class FetchModels extends ProfileEvent {}

class CreateModel extends ProfileEvent {
  final String modelName;

  CreateModel({required this.modelName});
}

class ChangeAccountTapped extends ProfileEvent {
  final String selectedAccount;

  ChangeAccountTapped({required this.selectedAccount});
}

class AccountManagementTapped extends ProfileEvent {}
