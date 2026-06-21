import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/transactions/presentation/screen/transaction_detail_screen.dart';
import 'package:expensetrackify/modules/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/modules/transactions/presentation/widgets/transaction_card.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:expensetrackify/constants/app_constants.dart';

class DetailedTransactions extends StatelessWidget {
  final List<TransactionWithDetails> allTransactions;
  final TransactionsBloc transactionsBloc;

  const DetailedTransactions({
    required this.allTransactions,
    required this.transactionsBloc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          allTransactions.isEmpty
              ? buildNoTransaction()
              : buildAllTransaction(),
    );
  }

  Widget buildNoTransaction() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: AppColors.deepPurpleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noTransactionsFound,
            style: TextStyles.deepPurpleBold18,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              AppConstants.tapPlusButtonToAddFirstTransaction,
              style: TextStyles.deepPurpleMedium16.copyWith(
                color: AppColors.deepPurpleColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAllTransaction() {
    final Map<DateTime, List<TransactionWithDetails>> groupedTransactions = {};
    for (var transaction in allTransactions) {
      final date = DateTime.parse(transaction.transaction.date);
      final groupedDate = DateTime(date.year, date.month, date.day);
      if (groupedTransactions[groupedDate] == null) {
        groupedTransactions[groupedDate] = [];
      }
      groupedTransactions[groupedDate]!.add(transaction);
    }

    final sortedDates =
        groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedGroupedTransactions = {
      for (var date in sortedDates)
        date:
            (groupedTransactions[date]!..sort(
              (a, b) => b.transaction.date.compareTo(a.transaction.date),
            )),
    };
    return ListView.builder(
      itemCount: sortedGroupedTransactions.length,
      itemBuilder: (context, index) {
        final date = sortedGroupedTransactions.keys.elementAt(index);
        final dateWiseTransactions = sortedGroupedTransactions[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                DateFormat.yMMMd().format(date),
                style: TextStyles.deepPurpleBold16,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.separated(
                itemCount: dateWiseTransactions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final transaction = dateWiseTransactions[index];
                  return TransactionCard(
                    transaction: transaction.transaction,
                    mode: transaction.mode?.name,
                    category: transaction.category?.name,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => TransactionDetailScreen(
                                transaction: transaction.transaction,
                              ),
                        ),
                      );
                      transactionsBloc.add(const RefreshTransactions());
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
