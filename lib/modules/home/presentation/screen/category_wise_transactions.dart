import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/transactions/presentation/screen/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/modules/transactions/presentation/widgets/transaction_card.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:intl/intl.dart';


class CategoryWiseTransactions extends StatelessWidget {
  final String category;
  final List<TransactionWithDetails> transactions;
  
  const CategoryWiseTransactions({
    required this.category,
    required this.transactions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<TransactionWithDetails>> groupedTransactions = {};
    for (var transaction in transactions) {
      final date = DateTime.parse(transaction.transaction.date);
      final groupedDate = DateTime(date.year, date.month, date.day);
      if (groupedTransactions[groupedDate] == null) {
        groupedTransactions[groupedDate] = [];
      }
      groupedTransactions[groupedDate]!.add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final sortedGroupedTransactions = {
      for (var date in sortedDates)
        date: (groupedTransactions[date]!..sort((a, b) => b.transaction.date.compareTo(a.transaction.date)))
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(category, style: TextStyles.whiteBold20),
        centerTitle: true,
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        // automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: sortedGroupedTransactions.length,
        itemBuilder: (context, index) {
          final date = sortedGroupedTransactions.keys.elementAt(index);
          final transactions = sortedGroupedTransactions[date]!;
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
              ...transactions.map((transaction) {
                return TransactionCard(
                  transaction: transaction.transaction,
                  mode: transaction.mode?.name,
                  category: transaction.category?.name,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(
                          transaction: transaction.transaction,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
