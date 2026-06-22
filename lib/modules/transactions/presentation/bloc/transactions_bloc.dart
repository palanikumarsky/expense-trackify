import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart' show CategoryDao;
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:flutter/material.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionDao _transactionDao;
  final ModeDao _modeDao;
  final CategoryDao _categoryDao;
  final ExpenseAccountDao expenseAccountDao;
  TransactionsBloc() : _transactionDao = TransactionDao(DatabaseService.instance),
        _modeDao = ModeDao(DatabaseService.instance),
        _categoryDao = CategoryDao(DatabaseService.instance),
        expenseAccountDao = ExpenseAccountDao(DatabaseService.instance),
        super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<RefreshTransactions>(_onRefreshTransactions);
    on<ClearDashboardData>(_onClearDashboardData);
    on<UpdateDateRange>(_onUpdateDateRange);
    on<GetDatabaseStats>(_onGetDatabaseStats);
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event,
      Emitter<TransactionsState> emit,
      ) async {
    try {
      emit(HomeLoading());

      String? selectedAccount = await Prefs.getSelectedAccount;
      final accounts = await expenseAccountDao.getExpensesAccounts();
      int accountId = 0;

      if (accounts.isNotEmpty) {
        if (selectedAccount != null) {
          accountId = accounts.firstWhere((a) => a.name == selectedAccount).id;
        }

        List<TransactionWithDetails> transactions =  await _transactionDao.getTransactions(selectedAccountId: accountId);

        // List<TransactionWithDetails> transactions =  await _transactionDao.getTransactions();
        List<TransactionWithDetails> filteredTransactions = _filterTransactions(transactions, null);

        emit(TransactionsLoaded(
          transactions: transactions,
          selectedDateRange: null,
          filteredTransactions: filteredTransactions,
        ));
      } else {
        emit(TransactionsLoaded(
          transactions: [],
          selectedDateRange: null,
          filteredTransactions: [],
        ));
      }
    } catch (error) {
      emit(TransactionsError('Failed to load transactions: $error'));
    }
  }

  Future<void> _onRefreshTransactions(
      RefreshTransactions event,
      Emitter<TransactionsState> emit,
      ) async {
    try {
      String? selectedAccount = await Prefs.getSelectedAccount;
      final accounts = await expenseAccountDao.getExpensesAccounts();
      int accountId = 0;

      if (selectedAccount != null) {
        accountId = accounts.firstWhere((a) => a.name == selectedAccount).id;
      }

      final transactions = await _transactionDao.getTransactions(selectedAccountId: accountId);

      if (state is TransactionsLoaded) {
        final currentState = state as TransactionsLoaded;
        final filteredTransactions = _filterTransactions(transactions, currentState.selectedDateRange);

        emit(currentState.copyWith(
          transactions: transactions,
          filteredTransactions: filteredTransactions,
        ));
      } else {
        final filteredTransactions = _filterTransactions(transactions, null);
        emit(TransactionsLoaded(
          transactions: transactions,
          selectedDateRange: null,
          filteredTransactions: filteredTransactions,
        ));
      }
    } catch (error) {
      emit(TransactionsError('Failed to refresh transactions: $error'));
    }
  }

  Future<void> _onClearDashboardData(
      ClearDashboardData event,
      Emitter<TransactionsState> emit,
      ) async {
    try {
      // Use the centralized database service to clear all data
      await DatabaseService.clearAllData();

      // Clear sync timestamp
      await Prefs.clearLastSyncTimestamp();

      emit(const DashboardCleared());
      add(LoadTransactions());
    } catch (error) {
      emit(TransactionsError('Failed to clear dashboard data: $error'));
    }
  }

  Future<void> _onUpdateDateRange(
      UpdateDateRange event,
      Emitter<TransactionsState> emit,
      ) async {
    if (state is TransactionsLoaded) {
      final currentState = state as TransactionsLoaded;
      final filteredTransactions = _filterTransactions(currentState.transactions, event.dateRange);

      emit(currentState.copyWith(
        selectedDateRange: event.dateRange,
        filteredTransactions: filteredTransactions,
      ));
    }
  }

  Future<void> _onGetDatabaseStats(
      GetDatabaseStats event,
      Emitter<TransactionsState> emit,
      ) async {
    try {
      final stats = await DatabaseService.getDatabaseStats();
      emit(DatabaseStatsLoaded(stats: stats));
    } catch (error) {
      emit(TransactionsError('Failed to get database statistics: $error'));
    }
  }

  List<TransactionWithDetails> _filterTransactions(
      List<TransactionWithDetails> transactions,
      DateTimeRange? dateRange,
      ) {
    if (transactions.isEmpty) {
      return [];
    }

    if (dateRange == null) {
      // return transactions;
      if (dateRange == null) {
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        dateRange = DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
      }
    }

    return transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction.transaction.date);
      return (transactionDate.isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(dateRange.end.add(const Duration(days: 1))));
    }).toList();
  }
}
