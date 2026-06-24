part of 'profile_bloc.dart';

@immutable
abstract class ProfileEvent {}

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
