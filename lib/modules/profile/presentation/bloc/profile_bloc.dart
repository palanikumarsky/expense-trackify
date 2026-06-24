import 'package:bloc/bloc.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:meta/meta.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  late final ExpenseAccountDao _expenseAccountDao;

  ProfileBloc() : super(ProfileInitial()) {
    _expenseAccountDao = ExpenseAccountDao(appDatabase);
    on<FetchModels>(_onFetchModels);
    on<CreateModel>(_onCreateModel);
    on<ChangeAccountTapped>(_onChangeAccountTapped);
    on<AccountManagementTapped>(_onAccountManagementTapped);
  }

  Future<void> _onFetchModels(
    FetchModels event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final models = await _expenseAccountDao.getExpensesAccounts();
      final selectedAccount = await Prefs.getSelectedAccount;
      emit(ShowModels(modelList: models, selectedAccount: selectedAccount ?? ''));
    } catch (_) {
      emit(FailureState(errorMessage: 'Failed to get accounts. Please try again.'));
    }
  }

  Future<void> _onCreateModel(
    CreateModel event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _expenseAccountDao.addExpenseAccount(
        ExpensesAccountsCompanion.insert(name: event.modelName),
      );
      final models = await _expenseAccountDao.getExpensesAccounts();
      emit(ModelCreateSuccess(modelList: models));
    } catch (_) {
      emit(FailureState(errorMessage: 'Failed to create account. Please try again.'));
    }
  }

  Future<void> _onChangeAccountTapped(
    ChangeAccountTapped event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await Prefs.setSelectedAccount(event.selectedAccount);
      emit(SelectAccountSuccess(selectedAccount: event.selectedAccount));
    } catch (_) {
      emit(FailureState(errorMessage: 'Failed to change the account.'));
    }
  }

  Future<void> _onAccountManagementTapped(
    AccountManagementTapped event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final selectedAccount = await Prefs.getSelectedAccount;
      emit(NavigateToAccountScreen(selectedAccount: selectedAccount ?? ''));
    } catch (_) {
      emit(FailureState(errorMessage: 'Failed to open account screen.'));
    }
  }
}
