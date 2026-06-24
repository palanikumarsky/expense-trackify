import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:intl/intl.dart';

class CalendarDayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CalendarDayDetailScreen({super.key, required this.selectedDate});

  @override
  State<CalendarDayDetailScreen> createState() =>
      _CalendarDayDetailScreenState();
}

class _CalendarDayDetailScreenState extends State<CalendarDayDetailScreen> {
  List<TransactionWithDetails> _transactions = [];
  bool _isLoading = true;
  final TransactionDao _transactionDao = TransactionDao(appDatabase);

  @override
  void initState() {
    super.initState();
    _loadTransactionsForDay();
  }

  Future<void> _loadTransactionsForDay() async {
    try {
      final allTransactions = await _transactionDao.getTransactions();
      final dayTransactions = <TransactionWithDetails>[];

      for (final transactionWithDetails in allTransactions) {
        final date = DateTime.parse(transactionWithDetails.transaction.date);
        final transactionDate = DateTime(date.year, date.month, date.day);
        final selectedDate = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
        );

        if (transactionDate.isAtSameMomentAs(selectedDate)) {
          dayTransactions.add(transactionWithDetails);
        }
      }

      // Sort transactions by time in descending order (latest first)
      dayTransactions.sort((a, b) {
        final dateA = DateTime.parse(a.transaction.date);
        final dateB = DateTime.parse(b.transaction.date);
        return dateB.compareTo(dateA); // descending
      });

      setState(() {
        _transactions = dayTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getTotalAmount() {
    return _transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.transaction.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          DateFormat('MMM d, yyyy').format(widget.selectedDate),
          style: TextStyles.whiteBold18,
        ),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Summary Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepPurpleColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Total Spent',
                                style: TextStyles.whiteMedium14,
                              ),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<String>(
                                valueListenable: Prefs.currencyCodeNotifier,
                                builder: (context, currencyCode, _) {
                                  final symbol =
                                      TransactionHelper.getCurrencySymbol(
                                        currencyCode,
                                      );
                                  return Text(
                                    '$symbol${_getTotalAmount().toStringAsFixed(2)}',
                                    style: TextStyles.whiteBold20,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Transactions',
                                style: TextStyles.whiteMedium14,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_transactions.length}',
                                style: TextStyles.whiteBold20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transactions List
                  Expanded(
                    child:
                        _transactions.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: AppColors.deepPurpleColor
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${AppConstants.noTransactionsFor} ${DateFormat('MMM d, yyyy').format(widget.selectedDate)}',
                                    style: TextStyles.deepPurpleMedium16,
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transactionWithDetails =
                                    _transactions[index];
                                final transaction =
                                    transactionWithDetails.transaction;
                                final modeName =
                                    transactionWithDetails.mode?.name ??
                                    AppConstants.unknown;
                                final categoryName =
                                    transactionWithDetails.category?.name ??
                                    AppConstants.unknown;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              transaction.description,
                                              style:
                                                  TextStyles.deepPurpleBold16,
                                            ),
                                            Text(
                                              '$modeName • $categoryName',
                                              style: TextStyles.greyMedium12,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.2,
                                        // height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            ValueListenableBuilder<String>(
                                              valueListenable:
                                                  Prefs.currencyCodeNotifier,
                                              builder: (
                                                context,
                                                currencyCode,
                                                _,
                                              ) {
                                                final symbol =
                                                    TransactionHelper.getCurrencySymbol(
                                                      currencyCode,
                                                    );
                                                return Text(
                                                  '$symbol${transaction.amount.toStringAsFixed(2)}',
                                                  style:
                                                      TextStyles
                                                          .deepPurpleBold16,
                                                );
                                              },
                                            ),
                                            Text(
                                              DateFormat('hh:mm a').format(
                                                DateTime.parse(
                                                  transaction.date,
                                                ),
                                              ),
                                              style: TextStyles.greyMedium12,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(height: 10),
                            ),
                  ),
                ],
              ),
    );
  }
}
