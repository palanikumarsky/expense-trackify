part of 'calendar_bloc.dart';

@immutable
abstract class CalendarState {}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class NavigateToDetailsScreen extends CalendarState {
  final DateTime selectedDay;

  NavigateToDetailsScreen({required this.selectedDay});
}

class CalendarLoaded extends CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<TransactionWithDetails>> events;

  CalendarLoaded({
    required this.focusedDay,
    this.selectedDay,
    required this.events,
  });

  CalendarLoaded copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<DateTime, List<TransactionWithDetails>>? events,
  }) {
    return CalendarLoaded(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      events: events ?? this.events,
    );
  }
}

class CalendarFailure extends CalendarState {
  final String errorMessage;

  CalendarFailure({required this.errorMessage});
}
