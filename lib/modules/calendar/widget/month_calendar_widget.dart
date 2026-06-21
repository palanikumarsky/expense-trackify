import 'package:expensetrackify/modules/calendar/widget/calendar_helper.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:intl/intl.dart';

class MonthCalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<dynamic>> events;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime)? onDayDoubleTapped;

  const MonthCalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    this.onDayDoubleTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isAtCurrentMonth =
        focusedDay.year == DateTime.now().year &&
            focusedDay.month == DateTime.now().month;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Month and Year Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final newFocusedDay = CalendarHelper.getPreviousMonth(
                    focusedDay,
                  );
                  onDaySelected(selectedDay ?? focusedDay, newFocusedDay);
                },
                icon: const Icon(Icons.chevron_left),
                color: AppColors.deepPurpleColor,
              ),
              Text(
                DateFormat('MMMM yyyy').format(focusedDay),
                style: TextStyles.deepPurpleBold18,
              ),
              IconButton(
                onPressed: isAtCurrentMonth
                    ? null // 🚫 disables the button completely
                    : () {
                  final nextMonth = CalendarHelper.getNextMonth(focusedDay);
                  onDaySelected(selectedDay ?? focusedDay, nextMonth);
                },
                icon: const Icon(Icons.chevron_right),
                color: isAtCurrentMonth ? Colors.grey : AppColors.deepPurpleColor,
              ),

            ],
          ),
          const SizedBox(height: 16),

          // Days of Week Header
          Row(
            children: CalendarHelper.getDaysOfWeek()
                .map(
                  (day) => Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyles.deepPurpleMedium14,
                ),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          ..._buildCalendarDays(context),
        ],
      ),
    );
  }

  double _getTotalForDay(DateTime date) {
    final dayEvents = events[date] ?? [];
    double total = 0.0;

    for (final event in dayEvents) {
      if (event is TransactionWithDetails) {
        total += event.transaction.amount;
      }
    }

    return total;
  }

  Widget _buildAmountText(
      DateTime date,
      bool isSelected,
      bool hasEvents,
      double totalAmount,
      ) {
    if (!hasEvents || totalAmount <= 0) {
      return const SizedBox(height: 12);
    }

    return ValueListenableBuilder<String>(
      valueListenable: Prefs.currencyCodeNotifier,
      builder: (context, currencyCode, _) {
        final symbol = TransactionHelper.getCurrencySymbol(currencyCode);
        return Text(
          '$symbol${totalAmount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isSelected
                ? Colors.white.withOpacity(0.9)
                : AppColors.deepPurpleColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  List<Widget> _buildCalendarDays(BuildContext context) {
    final days = <Widget>[];
    final lastDayOfMonth = CalendarHelper.getLastDayOfMonth(focusedDay);
    final firstWeekday = CalendarHelper.getFirstWeekdayOfMonth(focusedDay);

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(const Expanded(child: SizedBox()));
    }

    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(focusedDay.year, focusedDay.month, day);
      final isSelected =
          selectedDay != null && CalendarHelper.isSameDay(selectedDay!, date);
      final isToday = CalendarHelper.isToday(date);
      final isFuture = date.isAfter(DateTime.now()); // 🚫 Restrict future
      final hasEvents = events[date]?.isNotEmpty ?? false;
      final totalAmount = _getTotalForDay(date);

      days.add(
        Expanded(
          child: GestureDetector(
            onTap: isFuture ? null : () => onDaySelected(date, focusedDay),
            onDoubleTap: isFuture || onDayDoubleTapped == null
                ? null
                : () => onDayDoubleTapped!(date),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.085,
              width: 100,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.deepPurpleColor
                    : isToday
                    ? AppColors.deepPurpleColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: AppColors.deepPurpleColor, width: 1)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day number
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.035,
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isFuture
                              ? Colors.grey // 🚫 Grey out future days
                              : isSelected
                              ? Colors.white
                              : isToday
                              ? AppColors.deepPurpleColor
                              : Colors.black87,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Total amount
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.04,
                    child: Center(
                      child: isFuture
                          ? const SizedBox() // 🚫 No amounts for future
                          : _buildAmountText(
                        date,
                        isSelected,
                        hasEvents,
                        totalAmount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Group days into weeks
    final weeks = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      final weekDays = days.skip(i).take(7).toList();
      // Pad with empty cells if needed
      while (weekDays.length < 7) {
        weekDays.add(const Expanded(child: SizedBox()));
      }
      weeks.add(Row(children: weekDays));
    }

    return weeks;
  }
}
