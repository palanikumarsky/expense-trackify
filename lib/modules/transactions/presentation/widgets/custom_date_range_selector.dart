import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum CustomDateRangeType { week, month, year, custom }

class CustomDateRangeSelector extends StatefulWidget {
  final Function(DateTimeRange) onDateRangeChanged;
  final DateTimeRange? initialDateRange;

  const CustomDateRangeSelector({
    super.key, 
    required this.onDateRangeChanged,
    this.initialDateRange,
  });

  @override
  State<CustomDateRangeSelector> createState() => _CustomDateRangeSelectorState();
}

class _CustomDateRangeSelectorState extends State<CustomDateRangeSelector> {
  CustomDateRangeType _selectedType = CustomDateRangeType.month;
  DateTime _currentDate = DateTime.now();
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateRange != null) {
      _customDateRange = widget.initialDateRange;
      _selectedType = CustomDateRangeType.custom;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDateRange();
    });
  }

  void _updateDateRange() {
    DateTimeRange newRange;
    switch (_selectedType) {
      case CustomDateRangeType.week:
        final startOfWeek =
            _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        newRange = DateTimeRange(start: startOfWeek, end: endOfWeek);
        break;
      case CustomDateRangeType.month:
        final startOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
        final endOfMonth =
            DateTime(_currentDate.year, _currentDate.month + 1, 0);
        newRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
        break;
      case CustomDateRangeType.year:
        final startOfYear = DateTime(_currentDate.year, 1, 1);
        final endOfYear = DateTime(_currentDate.year, 12, 31);
        newRange = DateTimeRange(start: startOfYear, end: endOfYear);
        break;
      case CustomDateRangeType.custom:
        if (_customDateRange != null) {
          newRange = _customDateRange!;
        } else {
          final startOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
          final endOfMonth =
              DateTime(_currentDate.year, _currentDate.month + 1, 0);
          newRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
        }
        break;
    }
    widget.onDateRangeChanged(newRange);
  }

  void _changeDate(int amount) {
    setState(() {
      switch (_selectedType) {
        case CustomDateRangeType.week:
          _currentDate = _currentDate.add(Duration(days: 7 * amount));
          break;
        case CustomDateRangeType.month:
          _currentDate = DateTime(
              _currentDate.year, _currentDate.month + amount, _currentDate.day);
          break;
        case CustomDateRangeType.year:
          _currentDate = DateTime(
              _currentDate.year + amount, _currentDate.month, _currentDate.day);
          break;
        case CustomDateRangeType.custom:
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
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedType = CustomDateRangeType.custom;
        _customDateRange = picked;
      });
      widget.onDateRangeChanged(picked);
    }
  }

  String _getDisplayDate() {
    switch (_selectedType) {
      case CustomDateRangeType.week:
        final startOfWeek =
            _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat.yMMMd().format(startOfWeek)} - ${DateFormat.yMMMd().format(endOfWeek)}';
      case CustomDateRangeType.month:
        return DateFormat('MMMM yyyy').format(_currentDate);
      case CustomDateRangeType.year:
        return DateFormat('yyyy').format(_currentDate);
      case CustomDateRangeType.custom:
        if (_customDateRange != null) {
          return '${DateFormat.yMMMd().format(_customDateRange!.start)} - ${DateFormat.yMMMd().format(_customDateRange!.end)}';
        }
        return 'Select Custom Range';
    }
  }

  void _showDateTypeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Date Range Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...CustomDateRangeType.values.map((type) {
                final isSelected = _selectedType == type;
                return ListTile(
                  leading: Icon(
                    type == CustomDateRangeType.week
                        ? Icons.view_week
                        : type == CustomDateRangeType.month
                            ? Icons.calendar_month
                            : type == CustomDateRangeType.year
                                ? Icons.calendar_today
                                : Icons.date_range,
                    color: isSelected ? AppColors.deepPurpleColor : Colors.grey,
                  ),
                  title: Text(
                    toBeginningOfSentenceCase(
                            type.toString().split('.').last) ??
                        '',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.deepPurpleColor : Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (type == CustomDateRangeType.custom) {
                      _showCustomDateRangePicker();
                    } else {
                      setState(() {
                        _selectedType = type;
                        _currentDate = DateTime.now();
                        _updateDateRange();
                      });
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showDateTypeSelector,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      _getDisplayDate(),
                      style: TextStyles.whiteSemiBold16,
                    ),
                  ),
                ),
              ),
            ),
            // if (_selectedType != CustomDateRangeType.custom) ...[
            //   IconButton(
            //     icon: Icon(
            //       Icons.arrow_back_ios,
            //       color: Colors.grey.shade700,
            //       size: 16,
            //     ),
            //     onPressed: () => _changeDate(-1),
            //     padding: EdgeInsets.zero,
            //     constraints: const BoxConstraints(),
            //   ),
            //   IconButton(
            //     icon: Icon(
            //       Icons.arrow_forward_ios,
            //       color: Colors.grey.shade700,
            //       size: 16,
            //     ),
            //     onPressed: () => _changeDate(1),
            //     padding: EdgeInsets.zero,
            //     constraints: const BoxConstraints(),
            //   ),
            // ],
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
