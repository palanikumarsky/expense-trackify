import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  late final TransactionDao _transactionDao;

  CalendarBloc() : super(CalendarInitial()) {
    _transactionDao = TransactionDao(appDatabase);

    on<LoadCalendarEvents>(_onLoadCalendarEvents);
    on<RefreshCalendarEvents>(_onLoadCalendarEvents);
    on<DaySelected>(_onDaySelected);
    on<DayDoubleTapped>(_onDayDoubleTapped);
  }

  Future<void> _onLoadCalendarEvents(
      CalendarEvent event,
      Emitter<CalendarState> emit,
      ) async {
    emit(CalendarLoading());

    try {
      final transactions = await _transactionDao.getTransactions();
      final events = <DateTime, List<TransactionWithDetails>>{};

      for (final tx in transactions) {
        final date = DateTime.parse(tx.transaction.date);
        final key = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(key, () => []);
        events[key]!.add(tx);
      }

      emit(CalendarLoaded(
        focusedDay: DateTime.now(),
        selectedDay: DateTime.now(),
        events: events,
      ));
    } catch (e) {
      emit(CalendarFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onDaySelected(
      DaySelected event,
      Emitter<CalendarState> emit,
      ) async {
    if (state is CalendarLoaded) {
      final current = state as CalendarLoaded;
      emit(current.copyWith(
        selectedDay: event.selectedDay,
        focusedDay: event.focusedDay,
      ));
    }
  }

  Future<void> _onDayDoubleTapped(
      DayDoubleTapped event,
      Emitter<CalendarState> emit,
      ) async {
    emit(CalendarInitial());
    emit(NavigateToDetailsScreen(selectedDay: event.selectedDay));
  }
}
