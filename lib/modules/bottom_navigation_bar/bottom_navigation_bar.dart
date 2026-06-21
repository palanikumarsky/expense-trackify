import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_add_account_alert.dart';
import 'package:expensetrackify/modules/calendar/presentation/screen/calender_screen1.dart';
import 'package:expensetrackify/modules/transactions/presentation/screen/transactions_screen.dart';
import 'package:expensetrackify/modules/create_transaction/presentation/screen/create_transaction_screen.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/modules/home/presentation/screen/home_screen.dart';
import 'package:expensetrackify/modules/calendar/presentation/screen/calendar_screen.dart';
import 'package:expensetrackify/modules/settings/presentation/screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/modules/ads/widgets/banner_ad_widget.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final bool isHomeRefreshNeeded;

  const CustomBottomNavigationBar({
    super.key,
    this.selectedIndex = 0,
    this.isHomeRefreshNeeded = false,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 0;
  List<String> models = [];
  List<ExpensesAccount> expenseAccountsList = [];

  final List<Widget> _screens = [
    HomeScreen(key: UniqueKey()),
    // const CalendarScreen(),
    const CalendarScreen(),
    CreateTransactionScreen(key: UniqueKey()),
    const TransactionsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    fetchAccountDetails();
  }

  Future<void> fetchAccountDetails() async {
    final expenseAccountDao = ExpenseAccountDao(appDatabase);
    expenseAccountsList = await expenseAccountDao.getExpensesAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          // Banner Ad at the bottom
          const BannerAdWidget(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            showBorder: true,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            fetchAccountDetails();
            if (expenseAccountsList.isEmpty && index == 2) {
              customAddAccountAlertDialog(context: context);
            } else {
              setState(() {
                _currentIndex = index;
                if (index == 2) {
                  _screens[2] = CreateTransactionScreen(key: UniqueKey());
                // } else if (index == 0 && widget.isHomeRefreshNeeded) {
                //   // Force refresh of home screen when navigating to it
                //   _screens[0] = HomeScreen(key: UniqueKey());
                }
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.deepPurpleColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppConstants.dashboard,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: AppConstants.calendar,
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.deepPurpleColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              label: "",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              activeIcon: Icon(Icons.receipt_long),
              label: AppConstants.txn,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: AppConstants.settings,
            ),
          ],
        ),
      ),
    );
  }
}
