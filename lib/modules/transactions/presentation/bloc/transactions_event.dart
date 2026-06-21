part of 'transactions_bloc.dart';


abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  const LoadTransactions();
}

class RefreshTransactions extends TransactionsEvent {
  const RefreshTransactions();
}

class UpdateDateRange extends TransactionsEvent {
  final DateTimeRange? dateRange;

  const UpdateDateRange(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class ClearDashboardData extends TransactionsEvent {
  const ClearDashboardData();
}

class InitializeDefaultData extends TransactionsEvent {
  const InitializeDefaultData();
}

class GetDatabaseStats extends TransactionsEvent {
  const GetDatabaseStats();
}
