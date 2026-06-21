part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends HomeEvent {
  const LoadTransactions();
}

class RefreshTransactions extends HomeEvent {
  const RefreshTransactions();
}

class UpdateDateRange extends HomeEvent {
  final DateTimeRange? dateRange;
  
  const UpdateDateRange(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class ClearDashboardData extends HomeEvent {
  const ClearDashboardData();
}

class InitializeDefaultData extends HomeEvent {
  const InitializeDefaultData();
}

class GetDatabaseStats extends HomeEvent {
  const GetDatabaseStats();
}
