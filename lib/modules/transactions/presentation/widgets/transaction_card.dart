import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/utils/date_time_helper.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String? mode;
  final String? category;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.mode,
    this.category,
    this.onTap,
  });

  // IconData getIcon() {
  //   switch ((category ?? '').toLowerCase()) {
  //     case 'shopping':
  //       return Icons.shopping_cart;
  //     case 'electricity':
  //       return Icons.lightbulb_outline;
  //     case 'restaurant delivery':
  //       return Icons.room_service;
  //     default:
  //       return Icons.category;
  //   }
  // }

  IconData getIcon() {
    switch ((category ?? '').toLowerCase()) {
      case 'food & dining':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_bus;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'bills & utilities':
        return Icons.receipt_long;
      case 'travel':
        return Icons.flight;
      case 'gifts':
        return Icons.card_giftcard;
      case 'other':
        return Icons.category;
      default:
        return Icons.category; // fallback
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDefaultCategory = AppConstants.defaultCategories
        .map((c) => c.toLowerCase())
        .contains(category?.toLowerCase());
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            width: 33,
            height: 33,
            child: Center(
              child: isDefaultCategory
                  ? Icon(
                getIcon(),
                color: Colors.white,
                size: 26,
              )
                  : Text(
                (category?.isNotEmpty ?? false)
                    ? category![0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyles.blackSemiBold14,
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              mode ?? '',
              style: TextStyles.greyMedium12,
            ),
            const SizedBox(width: 5,),
            Container(
              width: 6, // circle diameter
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.black, // circle color
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4), // space between circle and time
            Text(
              DateTimeHelper().getHourMin(transaction.date),
              style: TextStyles.greyMedium12,
            ),
          ],
        ),
        trailing: ValueListenableBuilder<String>(
          valueListenable: Prefs.currencyCodeNotifier,
          builder: (context, currency, _) {
            final isNegative = transaction.amount < 0;
            final amountStr = transaction.amount.abs().toStringAsFixed(2);
            final symbol = TransactionHelper.getCurrencySymbol(currency);
            return Text(
              '${isNegative ? '-' : ''}$symbol$amountStr',
              style: TextStyles.greyMedium14.copyWith(
                color: Colors.redAccent.shade700,
              ),
              // style: TextStyle(
              //   color: Colors.blue.shade700,
              //   fontSize: 14,
              //   fontWeight: FontWeight.w600,
              // ),
            );
          },
        ),
      ),
    );
  }
}
