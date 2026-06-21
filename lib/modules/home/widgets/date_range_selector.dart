import 'package:expensetrackify/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangeType { week, month, year, custom }

class DateRangeSelector extends StatefulWidget {
  final Function(DateTimeRange) onDateRangeChanged;

  const DateRangeSelector({super.key, required this.onDateRangeChanged});

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  DateRangeType _selectedType = DateRangeType.month;
  DateTime _currentDate = DateTime.now();
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDateRange();
    });
  }

  void _updateDateRange() {
    DateTimeRange newRange;
    switch (_selectedType) {
      case DateRangeType.week:
        final startOfWeek =
            _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        newRange = DateTimeRange(start: startOfWeek, end: endOfWeek);
        break;
      case DateRangeType.month:
        final startOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
        final endOfMonth =
            DateTime(_currentDate.year, _currentDate.month + 1, 0);
        newRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
        break;
      case DateRangeType.year:
        final startOfYear = DateTime(_currentDate.year, 1, 1);
        final endOfYear = DateTime(_currentDate.year, 12, 31);
        newRange = DateTimeRange(start: startOfYear, end: endOfYear);
        break;
      case DateRangeType.custom:
        _showCustomDateRangePicker();
        return;
    }
    widget.onDateRangeChanged(newRange);
  }

  void _changeDate(int amount) {
    setState(() {
      switch (_selectedType) {
        case DateRangeType.week:
          _currentDate = _currentDate.add(Duration(days: 7 * amount));
          break;
        case DateRangeType.month:
          _currentDate = DateTime(
              _currentDate.year, _currentDate.month + amount, _currentDate.day);
          break;
        case DateRangeType.year:
          _currentDate = DateTime(
              _currentDate.year + amount, _currentDate.month, _currentDate.day);
          break;
        case DateRangeType.custom:
          break;
      }
      _updateDateRange();
    });
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      widget.onDateRangeChanged(picked);
      setState(() {
        _selectedType = DateRangeType.custom;
        _customDateRange = picked;
      });
    }
  }

  String _getDisplayDate() {
    switch (_selectedType) {
      case DateRangeType.week:
        final startOfWeek =
            _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat.yMMMd().format(startOfWeek)} - ${DateFormat.yMMMd().format(endOfWeek)}';
      case DateRangeType.month:
        return DateFormat('MMMM yyyy').format(_currentDate);
      case DateRangeType.year:
        return DateFormat('yyyy').format(_currentDate);
      case DateRangeType.custom:
        if (_customDateRange != null) {
          return '${DateFormat.yMMMd().format(_customDateRange!.start)} - ${DateFormat.yMMMd().format(_customDateRange!.end)}';
        }
        return 'Select Custom Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.deepPurpleColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: DateRangeType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  if (type == DateRangeType.custom) {
                    _showCustomDateRangePicker();
                  } else {
                    setState(() {
                      _selectedType = type;
                      _currentDate = DateTime.now();
                      _updateDateRange();
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    toBeginningOfSentenceCase(
                            type.toString().split('.').last) ??
                        '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _selectedType == DateRangeType.custom
                  ? const SizedBox(width: 48.0)
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.whiteColor),
                      onPressed: () => _changeDate(-1),
                    ),
              Expanded(
                child: Center(
                  child: Text(
                    _getDisplayDate(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _selectedType == DateRangeType.custom
                  ? const SizedBox(width: 48.0)
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          color: AppColors.whiteColor),
                      onPressed: () => _changeDate(1),
                    ),
            ],
          ),
        ],
      ),
    );
  }
} 