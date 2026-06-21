import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/user_type_stream.dart';
import 'package:flutter/material.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TransactionDao _transactionDao;
  final ModeDao _modeDao;
  final CategoryDao _categoryDao;
  final ExpenseAccountDao expenseAccountDao;
  
  HomeBloc() : _transactionDao = TransactionDao(DatabaseService.instance), 
                _modeDao = ModeDao(DatabaseService.instance), 
                _categoryDao = CategoryDao(DatabaseService.instance),
                expenseAccountDao = ExpenseAccountDao(DatabaseService.instance),
                super(HomeInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<RefreshTransactions>(_onRefreshTransactions);
    on<UpdateDateRange>(_onUpdateDateRange);
    on<ClearDashboardData>(_onClearDashboardData);
    on<InitializeDefaultData>(_onInitializeDefaultData);
    on<GetDatabaseStats>(_onGetDatabaseStats);
    
    // Initialize default modes and categories when bloc is created
    _initializeDefaultData();
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading());
      final userType = userTypeStream.currentUserType;
      String? selectedAccount = await Prefs.getSelectedAccount;
      final accounts = await expenseAccountDao.getExpensesAccounts();
      int accountId = 0;


      if (accounts.isNotEmpty) {
        if (selectedAccount != null) {
          accountId = accounts.firstWhere((a) => a.name == selectedAccount).id;
        }


        List<TransactionWithDetails> transactions =  await _transactionDao.getTransactions(selectedAccountId: accountId);

        List<TransactionWithDetails> filteredTransactions = _filterTransactions(transactions, null);

        emit(HomeLoaded(
          transactions: transactions,
          selectedDateRange: null,
          filteredTransactions: filteredTransactions,
        ));
      } else {
        emit(HomeLoaded(
          transactions: [],
          selectedDateRange: null,
          filteredTransactions: [],
        ));
      }
    } catch (error) {
      emit(HomeError('Failed to load transactions: $error'));
    }
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactions event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final transactions = await _transactionDao.getTransactions();
      
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        final filteredTransactions = _filterTransactions(transactions, currentState.selectedDateRange);
        
        emit(currentState.copyWith(
          transactions: transactions,
          filteredTransactions: filteredTransactions,
        ));
      } else {
        final filteredTransactions = _filterTransactions(transactions, null);
        emit(HomeLoaded(
          transactions: transactions,
          selectedDateRange: null,
          filteredTransactions: filteredTransactions,
        ));
      }
    } catch (error) {
      emit(HomeError('Failed to refresh transactions: $error'));
    }
  }

  Future<void> _onUpdateDateRange(
    UpdateDateRange event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final filteredTransactions = _filterTransactions(currentState.transactions, event.dateRange);
      
      emit(currentState.copyWith(
        selectedDateRange: event.dateRange,
        filteredTransactions: filteredTransactions,
      ));
    }
  }

  Future<void> _onClearDashboardData(
    ClearDashboardData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Use the centralized database service to clear all data
      await DatabaseService.clearAllData();
      
      // Clear sync timestamp
      await Prefs.clearLastSyncTimestamp();
      
      emit(const DashboardCleared());
      add(InitializeDefaultData());
    } catch (error) {
      print('Error clearing dashboard data: $error');
      emit(HomeError('Failed to clear dashboard data: $error'));
    }
  }

  Future<void> _onInitializeDefaultData(
    InitializeDefaultData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _initializeDefaultData();
      // Optionally refresh transactions after initialization
      add(const RefreshTransactions());
    } catch (error) {
      emit(HomeError('Failed to initialize default data: $error'));
    }
  }

  Future<void> _onGetDatabaseStats(
    GetDatabaseStats event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final stats = await DatabaseService.getDatabaseStats();
      emit(DatabaseStatsLoaded(stats: stats));
    } catch (error) {
      print('Error getting database stats: $error');
      emit(HomeError('Failed to get database statistics: $error'));
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

  Future<void> _initializeDefaultData() async {
    try {
      // Initialize default payment modes
      await _initializeDefaultModes();
      
      // Initialize default categories
      await _initializeDefaultCategories();
      
    } catch (error) {
      print('Error initializing default data: $error');
    }
  }

  Future<void> _initializeDefaultModes() async {
    try {
      // Get existing modes
      final existingModes = await _modeDao.getModes();
      
      // Define default modes
      final defaultModes = AppConstants.defaultModes;;
      
      // Check which default modes are missing
      final existingModeNames = existingModes.map((mode) => mode.name).toList();
      final missingModes = defaultModes.where((mode) => !existingModeNames.contains(mode)).toList();
      
      // Add missing modes
      for (final modeName in missingModes) {
        await _modeDao.createMode(ModesCompanion.insert(name: modeName));
        print('Added default mode: $modeName');
      }
      
      if (missingModes.isNotEmpty) {
        print('Initialized ${missingModes.length} default payment modes');
      }
    } catch (error) {
      print('Error initializing default modes: $error');
    }
  }

  Future<void> _initializeDefaultCategories() async {
    try {
      // Get existing categories
      final existingCategories = await _categoryDao.getCategories();
      
      // Define default categories
      final defaultCategories = AppConstants.defaultCategories;
      
      // Check which default categories are missing
      final existingCategoryNames = existingCategories.map((category) => category.name).toList();
      final missingCategories = defaultCategories.where((category) => !existingCategoryNames.contains(category)).toList();
      
      // Add missing categories
      for (final categoryName in missingCategories) {
        await _categoryDao.createCategory(CategoriesCompanion.insert(name: categoryName));
        print('Added default category: $categoryName');
      }
      
      if (missingCategories.isNotEmpty) {
        print('Initialized ${missingCategories.length} default categories');
      }
    } catch (error) {
      print('Error initializing default categories: $error');
    }
  }
}
