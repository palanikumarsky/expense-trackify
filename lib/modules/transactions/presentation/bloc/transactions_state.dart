part of 'transactions_bloc.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {}

class HomeLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<TransactionWithDetails> transactions;
  final DateTimeRange? selectedDateRange;
  final List<TransactionWithDetails> filteredTransactions;

  const TransactionsLoaded({
    required this.transactions,
    this.selectedDateRange,
    required this.filteredTransactions,
  });

  @override
  List<Object?> get props => [transactions, selectedDateRange, filteredTransactions];

  TransactionsLoaded copyWith({
    List<TransactionWithDetails>? transactions,
    DateTimeRange? selectedDateRange,
    bool? isGuest,
    List<TransactionWithDetails>? filteredTransactions,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
    );
  }
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseStatsLoaded extends TransactionsState {
  final Map<String, int> stats;

  const DatabaseStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class DashboardCleared extends TransactionsState {
  const DashboardCleared();
}