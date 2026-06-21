part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<TransactionWithDetails> transactions;
  final DateTimeRange? selectedDateRange;
  final List<TransactionWithDetails> filteredTransactions;

  const HomeLoaded({
    required this.transactions,
    this.selectedDateRange,
    required this.filteredTransactions,
  });

  @override
  List<Object?> get props => [transactions, selectedDateRange, filteredTransactions];

  HomeLoaded copyWith({
    List<TransactionWithDetails>? transactions,
    DateTimeRange? selectedDateRange,
    bool? isGuest,
    List<TransactionWithDetails>? filteredTransactions,
  }) {
    return HomeLoaded(
      transactions: transactions ?? this.transactions,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class DashboardCleared extends HomeState {
  const DashboardCleared();
}

class DatabaseStatsLoaded extends HomeState {
  final Map<String, int> stats;

  const DatabaseStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}
