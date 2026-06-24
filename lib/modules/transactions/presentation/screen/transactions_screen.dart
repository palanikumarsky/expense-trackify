import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/home/widgets/date_range_selector.dart';
import 'package:expensetrackify/modules/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:expensetrackify/modules/transactions/presentation/screen/detailed_transactions.dart';
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
