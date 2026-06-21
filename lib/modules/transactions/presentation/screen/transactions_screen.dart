import 'dart:async';

import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/home/widgets/date_range_selector.dart';
import 'package:expensetrackify/modules/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:expensetrackify/modules/transactions/presentation/screen/detailed_transactions.dart';
import 'package:expensetrackify/utils/sync_event_bus.dart';
import 'package:expensetrackify/utils/user_type_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionWithDetails> transactions = [];
  TransactionsBloc? _transactionsBloc;
  // Stream subscriptions for user type monitoring
  StreamSubscription<String>? _userTypeSubscription;
  StreamSubscription<UserTypeChange>? _userTypeChangeSubscription;
  StreamSubscription? _syncSubscription;
  // Current user state
  String _currentUserType = AppConstants.guest;
  bool _isGuest = true;
  UserTypeChange? _lastUserTypeChange;

  @override
  void initState() {
    super.initState();
    _initializeUserTypeMonitoring();
    // Listen for sync events and refresh transactions
    _syncSubscription = SyncEventBus().onSync.listen((_) {
      if (_transactionsBloc != null) {
        _transactionsBloc!.add(const LoadTransactions());
      }
    });
  }

  @override
  void dispose() {
    _userTypeSubscription?.cancel();
    _userTypeChangeSubscription?.cancel();
    _syncSubscription?.cancel();

    super.dispose();
  }

  /// Initialize user type monitoring streams
  void _initializeUserTypeMonitoring() {
    // Initialize with current values
    _currentUserType = userTypeStream.currentUserType;

    debugPrint(
      'HomeScreen: Initial user type: $_currentUserType, isGuest: $_isGuest',
    );

    // Listen to user type changes
    _userTypeSubscription = userTypeStream.listenToUserTypeChanges((userType) {
      setState(() {
        _currentUserType = userType;
        _isGuest = userType == AppConstants.guest;
      });
      _handleUserTypeChange(userType);
    });

    _userTypeChangeSubscription = userTypeStream
        .listenToUserTypeChangesDetailed((change) {
          setState(() {
            _lastUserTypeChange = change;
          });
          _showUserTypeChangeNotification(change);
        });
  }

  /// Handle user type changes
  void _handleUserTypeChange(String newUserType) {
    if (_transactionsBloc != null) {
      if (newUserType == AppConstants.guest) {
        _transactionsBloc!.add(const ClearDashboardData());
      } else if (newUserType == AppConstants.loggedUser) {
        _transactionsBloc!.add(const LoadTransactions());
      }
    }
  }

  /// Show notification for user type changes
  void _showUserTypeChangeNotification(UserTypeChange change) {
    _handleUserTypeChange(change.currentUserType);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        _transactionsBloc = TransactionsBloc();
        return _transactionsBloc!..add(const LoadTransactions());
      },
      child: BlocListener<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionsLoaded) {
            transactions = state.filteredTransactions;
          } else if (state is DashboardCleared) {
          } else if (state is TransactionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppConstants.transactions,
                  style: TextStyles.whiteBold20,
                ),
                centerTitle: true,
                backgroundColor: AppColors.deepPurpleColor,
                foregroundColor: AppColors.whiteColor,
                elevation: 0,
                automaticallyImplyLeading: false,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DateRangeSelector(
                    onDateRangeChanged: (dateRange) {
                      _transactionsBloc!.add(UpdateDateRange(dateRange));
                    },
                  ),
                  const SizedBox(height: 10),
                  // Summary View (no more tabs needed)
                  Expanded(
                    child: DetailedTransactions(
                      allTransactions: transactions,
                      transactionsBloc: _transactionsBloc!,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
