import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/home/presentation/bloc/home_bloc.dart';
import 'package:expensetrackify/modules/home/widgets/date_range_selector.dart';
import 'package:expensetrackify/modules/home/presentation/screen/summary_view.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionWithDetails> transactions = [];
  HomeBloc? _homeBloc;
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
                      onPressed: () {
                        _homeBloc!.add(const RefreshTransactions());
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
