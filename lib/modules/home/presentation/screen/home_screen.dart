import 'dart:async';

import 'package:expensetrackify/utils/sync_event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/home/presentation/bloc/home_bloc.dart';
import 'package:expensetrackify/modules/home/widgets/date_range_selector.dart';
import 'package:expensetrackify/utils/user_type_stream.dart';
import 'package:expensetrackify/modules/home/presentation/screen/summary_view.dart';

import 'package:expensetrackify/modules/ads/widgets/interstitial_ad_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionWithDetails> transactions = [];
  HomeBloc? _homeBloc;
  bool _isVisible = false;

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
    // Mark as visible initially
    _isVisible = true;
    // Initialize user type monitoring
    _initializeUserTypeMonitoring();
    // Listen for sync events and refresh transactions
    _syncSubscription = SyncEventBus().onSync.listen((_) {
      if (_homeBloc != null) {
        _homeBloc!.add(const LoadTransactions());
      }
    });
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _userTypeSubscription?.cancel();
    _userTypeChangeSubscription?.cancel();
    _syncSubscription?.cancel();

    super.dispose();
  }


  /// Initialize user type monitoring streams
  void _initializeUserTypeMonitoring() {
    // Initialize with current values
    _currentUserType = userTypeStream.currentUserType;


    // Listen to user type changes
    _userTypeSubscription = userTypeStream.listenToUserTypeChanges((userType) {
      setState(() {
        _currentUserType = userType;
        _isGuest = userType == AppConstants.guest;
      });
      _handleUserTypeChange(userType);
    });

    _userTypeChangeSubscription = userTypeStream.listenToUserTypeChangesDetailed((
      change,
    ) {
      setState(() {
        _lastUserTypeChange = change;
      });
      _showUserTypeChangeNotification(change);
    });
  }

  /// Handle user type changes
  void _handleUserTypeChange(String newUserType) {
    if (_homeBloc != null) {
      if (newUserType == AppConstants.guest) {
        _homeBloc!.add(const ClearDashboardData());
      } else if (newUserType == AppConstants.loggedUser) {
        _homeBloc!.add(const LoadTransactions());
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
        _homeBloc = HomeBloc();
        return _homeBloc!..add(const LoadTransactions());
      },
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded) {
            transactions = state.filteredTransactions;
          } else if (state is DashboardCleared) {

          } else if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    AppConstants.appName,
                    style: TextStyles.whiteBold20,
                  ),
                  centerTitle: true,
                  backgroundColor: AppColors.deepPurpleColor,
                  foregroundColor: AppColors.whiteColor,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        // Track action and potentially show interstitial ad
                        await InterstitialAdHelper().trackActionAndShowAd(
                          actionName: 'refresh_transactions',
                          onAdShown: () {
                            // Continue with refresh after ad is shown
                            _homeBloc!.add(const RefreshTransactions());
                          },
                          onAdFailed: () {
                            // Continue with refresh even if ad fails
                            _homeBloc!.add(const RefreshTransactions());
                          },
                        );
                        
                        // If no ad was shown, refresh immediately
                        if (InterstitialAdHelper().actionCount > 0) {
                          _homeBloc!.add(const RefreshTransactions());
                        }
                      },
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    DateRangeSelector(
                      onDateRangeChanged: (dateRange) {
                        _homeBloc!.add(UpdateDateRange(dateRange));
                      },
                    ),
                    const SizedBox(height: 10,),
                    // Summary View (no more tabs needed)
                    Expanded(child: SummaryView(transactions: transactions,),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
