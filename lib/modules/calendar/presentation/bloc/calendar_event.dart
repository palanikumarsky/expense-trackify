part of 'calendar_bloc.dart';

@immutable
abstract class CalendarEvent {}

class LoadCalendarEvents extends CalendarEvent {}

class RefreshCalendarEvents extends CalendarEvent {}

class DaySelected extends CalendarEvent {
  final DateTime selectedDay;
  final DateTime focusedDay;

  DaySelected({required this.selectedDay, required this.focusedDay});
}

class DayDoubleTapped extends CalendarEvent {
  final DateTime selectedDay;

  DayDoubleTapped({required this.selectedDay});
}
