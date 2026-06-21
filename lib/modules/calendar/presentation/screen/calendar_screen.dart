import 'dart:async';

import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_progress_bar.dart';
import 'package:expensetrackify/modules/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/calendar/presentation/screen/calendar_day_detail_screen.dart';
import 'package:expensetrackify/modules/calendar/widget/month_calendar_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TransactionWithDetails>> _events = {};

  void _onDayDoubleTapped(BuildContext context, DateTime selectedDay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CalendarDayDetailScreen(selectedDate: selectedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarBloc>(
      create: (context) => CalendarBloc()..add(LoadCalendarEvents()),
      child: BlocListener<CalendarBloc, CalendarState>(
        listener: (context, state) {
          // TODO: implement listener
          if (state is CalendarLoaded) {
            CustomProgressBar(context).hideLoadingIndicator();
            _events = state.events;
            _focusedDay = state.focusedDay;
            _selectedDay = state.selectedDay;
          } else if (state is NavigateToDetailsScreen) {
            CustomProgressBar(context).hideLoadingIndicator();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CalendarDayDetailScreen(
                  selectedDate: state.selectedDay,
                ),
              ),
            );
          } else if (state is CalendarLoading) {
            CustomProgressBar(context).showLoadingIndicator();
          } else if (state is CalendarInitial) {
            CustomProgressBar(context).showLoadingIndicator();
          }
        },
        child: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppConstants.calendar,
                  style: TextStyles.whiteBold20,
                ),
                centerTitle: true,
                backgroundColor: AppColors.deepPurpleColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed:
                        () => context.read<CalendarBloc>().add(
                      RefreshCalendarEvents(),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: MonthCalendarWidget(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        events: _events,
                        onDaySelected: (selectedDay, focusedDay) {
                          BlocProvider.of<CalendarBloc>(context).add(
                            DaySelected(
                              selectedDay: selectedDay,
                              focusedDay: focusedDay,
                            ),
                          );
                        },
                        onDayDoubleTapped: (day) {
                          BlocProvider.of<CalendarBloc>(
                            context,
                          ).add(DayDoubleTapped(selectedDay: day));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

// @override
// Widget build(BuildContext context) {
//   return BlocProvider(
//     create: (_) => CalendarBloc()..add(LoadCalendarEvents()),
//     child: Scaffold(
//       appBar: AppBar(
//         title: Text(AppConstants.calendar, style: TextStyles.whiteBold20),
//         centerTitle: true,
//         backgroundColor: AppColors.deepPurpleColor,
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => context.read<CalendarBloc>().add(RefreshCalendarEvents()),
//           ),
//         ],
//       ),
//       body: BlocBuilder<CalendarBloc, CalendarState>(
//         builder: (context, state) {
//           if (state is CalendarLoading) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (state is CalendarLoaded) {
//             return Column(
//               children: [
//                 Flexible(
//                   child: Container(
//                     margin: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: MonthCalendarWidget(
//                       focusedDay: state.focusedDay,
//                       selectedDay: state.selectedDay,
//                       events: state.events,
//                       onDaySelected: (selectedDay, focusedDay) {
//                         context.read<CalendarBloc>().add(
//                           DaySelected(
//                             selectedDay: selectedDay,
//                             focusedDay: focusedDay,
//                           ),
//                         );
//                       },
//                       onDayDoubleTapped: (day) => _onDayDoubleTapped(context, day),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           } else if (state is CalendarFailure) {
//             return Center(child: Text(state.errorMessage));
//           }
//           return const SizedBox.shrink();
//         },
//       ),
//     ),
//   );
// }
}
