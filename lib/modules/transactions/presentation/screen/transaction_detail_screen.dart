import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/transactions/presentation/screen/edit_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:expensetrackify/constants/app_constants.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Transaction _transaction;
  final TransactionDao _transactionDao = TransactionDao(appDatabase);
  final ModeDao _modeDao = ModeDao(appDatabase);
  final CategoryDao _categoryDao = CategoryDao(appDatabase);
  String? _modeName;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _loadModeAndCategoryNames();
  }

  Future<void> _loadModeAndCategoryNames() async {
    final modes = await _modeDao.getModes();
    final categories = await _categoryDao.getCategories();

    final mode = modes.firstWhere(
      (m) => m.id == _transaction.modeId,
      orElse: () => Mode(id: 0, name: AppConstants.unknown),
    );
    final category = categories.firstWhere(
      (c) => c.id == _transaction.categoryId,
      orElse: () => Category(id: 0, name: AppConstants.unknown),
    );

    setState(() {
      _modeName = mode.name;
      _categoryName = category.name;
    });
  }

  void _editTransaction(BuildContext context) async {
    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: _transaction),
      ),
    );

    if (updatedTransaction != null) {
      setState(() {
        _transaction = updatedTransaction;
      });
    }
  }

  void _deleteTransaction(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: AppConstants.areYouSure,
          content: AppConstants.deleteTransactionConfirmation,
          cancelText: AppConstants.cancel,
          confirmText: AppConstants.delete,
          onConfirm: () async {
            try {
              await _transactionDao.deleteTransaction(_transaction.id);

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.of(context).pop();
            } catch (error) {
              // Close the dialog
              Navigator.of(context).pop();

              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting transaction: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          confirmButtonColor: Colors.red,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.transactionDetails,
          style: TextStyles.whiteBold20,
        ),
        centerTitle: true,
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: Colors.white,
        actions: [
          if (_transaction.isSynced)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // color: Colors.green.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                // border: Border.all(color: Colors.green, width: 1),
              ),
              child: Icon(
                Icons.cloud_sync,
                color: AppColors.darkGreenColor,
                size: 20,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      AppConstants.descriptionLabel,
                      _transaction.description,
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: Prefs.currencyCodeNotifier,
                      builder: (context, currencyCode, _) {
                        final symbol = TransactionHelper.getCurrencySymbol(
                          currencyCode,
                        );
                        return _buildDetailRow(
                          AppConstants.amountLabel,
                          '$symbol${_transaction.amount.toStringAsFixed(2)}',
                        );
                      },
                    ),
                    _buildDetailRow(
                      AppConstants.paymentModeLabel,
                      _modeName ?? AppConstants.loading,
                    ),
                    _buildDetailRow(
                      AppConstants.categoryLabel,
                      _categoryName ?? AppConstants.loading,
                    ),
                    _buildDetailRow(
                      AppConstants.dateLabel,
                      DateFormat.yMMMd().format(
                        DateTime.parse(_transaction.date),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editTransaction(context),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: Text(
                        AppConstants.edit,
                        style: TextStyles.whiteSemiBold16,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepPurpleColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteTransaction(context),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        AppConstants.delete,
                        style: TextStyles.whiteSemiBold16,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.deepPurpleBold16.copyWith(
              color: AppColors.deepPurpleColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyles.deepPurpleMedium16,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
