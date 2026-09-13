import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/utils/transaction_change_notifier.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';


class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  final _newModeController = TextEditingController();
  final _newCategoryController = TextEditingController();

  final ModeDao _modeDao = ModeDao(appDatabase);
  final CategoryDao _categoryDao = CategoryDao(appDatabase);
  final TransactionDao _transactionDao = TransactionDao(appDatabase);
  List<Mode> _modes = [];
  Mode? _selectedMode;
  List<Category> _categories = [];
  Category? _selectedCategory;
  late DateTime _selectedDate;

  String? errorDescription;
  String? errorAmount;
  String _currencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _selectedDate = DateTime.parse(widget.transaction.date);
    _loadModes();
    _loadCategories();
    _loadCurrency();
  }

  Future<void> _loadModes() async {
    final modes = await _modeDao.getModes();
    setState(() {
      _modes = modes;
      if (modes.isNotEmpty) {
        _selectedMode = modes.firstWhere((m) => m.id == widget.transaction.modeId, orElse: () => modes.first);
      }
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryDao.getCategories();
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) {
        _selectedCategory = categories.firstWhere((c) => c.id == widget.transaction.categoryId, orElse: () => categories.first);
      }
    });
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencyCode = prefs.getString('currency_code') ?? 'USD';
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _newModeController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _updateTransaction() async {
    setState(() {
      errorDescription = null;
      errorAmount = null;
    });

    final description = _descriptionController.text;
    final amount = _amountController.text;
    bool hasError = false;

    if (description.isEmpty) {
      setState(() {
        errorDescription = AppConstants.pleaseEnterDescription;
      });
      hasError = true;
    }

    if (amount.isEmpty) {
      setState(() {
        errorAmount = AppConstants.pleaseEnterAmount;
      });
      hasError = true;
    } else if (double.tryParse(amount) == null) {
      setState(() {
        errorAmount = AppConstants.pleaseEnterValidNumber;
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    if (_selectedMode == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.selectModeAndCategory),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updatedTransaction = widget.transaction.copyWith(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        modeId: _selectedMode!.id,
        categoryId: _selectedCategory!.id,
        date: _selectedDate.toIso8601String(),
      );

      await _transactionDao.updateTransaction(updatedTransaction);
      notifyTransactionChange();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(updatedTransaction);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating transaction: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addNewMode(String modeName) async {
    if (modeName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.modeNameCannotBeEmpty),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final modeId = await _modeDao.createMode(ModesCompanion.insert(
        name: modeName.trim(),
      ));
      final allModes = await _modeDao.getModes();
      final newMode = allModes.firstWhere((mode) => mode.id == modeId);
      setState(() {
        _modes.add(newMode);
        _selectedMode = newMode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.newModeAddedSuccessfully.replaceAll('{0}', modeName.trim())),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding mode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addNewCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.categoryNameCannotBeEmpty),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final categoryId = await _categoryDao.createCategory(CategoriesCompanion.insert(
        name: categoryName.trim(),
      ));
      final allCategories = await _categoryDao.getCategories();
      final newCategory = allCategories.firstWhere((cat) => cat.id == categoryId);
      setState(() {
        _categories.add(newCategory);
        _selectedCategory = newCategory;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.newCategoryAddedSuccessfully.replaceAll('{0}', categoryName.trim())),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showModeSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  AppConstants.paymentMode,
                  style: TextStyles.deepPurpleBold18,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _modes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payment_outlined,
                                  size: 64,
                                  color: AppColors.deepPurpleColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppConstants.noPaymentModesAvailable,
                                  style: TextStyles.deepPurpleMedium16,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppConstants.tapPlusButtonToAddFirstMode,
                                  style: TextStyles.blackRegular14.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _modes.length,
                            itemBuilder: (context, index) {
                              final mode = _modes[index];
                              final isSelected = _selectedMode?.id == mode.id;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isSelected
                                      ? BorderSide(color: AppColors.deepPurpleColor, width: 2)
                                      : BorderSide.none,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.deepPurpleColor
                                        : AppColors.deepPurpleColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.payment,
                                      color: isSelected ? Colors.white : AppColors.deepPurpleColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    mode.name,
                                    style: TextStyles.deepPurpleMedium16.copyWith(
                                      color: isSelected ? AppColors.deepPurpleColor : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.deepPurpleColor,
                                          size: 24,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedMode = mode;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.deepPurpleColor.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.deepPurpleColor.withOpacity(0.1),
                          child: Icon(
                            Icons.add,
                            color: AppColors.deepPurpleColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          AppConstants.addNewMode,
                          style: TextStyles.deepPurpleMedium16.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Create a new payment mode',
                          style: TextStyles.blackRegular12.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddModeDialog();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20,),
          ],
        ),
      ),
    );
  }

  void _showAddModeDialog() {
    _newModeController.clear();
    showDialog(
      context: context,
      builder: (_) => CustomInputDialog(
        controller: _newModeController,
        title: AppConstants.addNewMode,
        hintText: AppConstants.enterModeName,
        onConfirm: (newModeName) async {
          if (newModeName.isNotEmpty) {
            _addNewMode(newModeName);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showCategorySelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  AppConstants.category,
                  style: TextStyles.deepPurpleBold18,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _categories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 64,
                                  color: AppColors.deepPurpleColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppConstants.noCategoriesAvailable,
                                  style: TextStyles.deepPurpleMedium16,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppConstants.tapPlusButtonToAddFirstCategory,
                                  style: TextStyles.blackRegular14.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory?.id == category.id;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isSelected
                                      ? BorderSide(color: AppColors.deepPurpleColor, width: 2)
                                      : BorderSide.none,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.deepPurpleColor
                                        : AppColors.deepPurpleColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.category,
                                      color: isSelected ? Colors.white : AppColors.deepPurpleColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: TextStyles.deepPurpleMedium16.copyWith(
                                      color: isSelected ? AppColors.deepPurpleColor : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.deepPurpleColor,
                                          size: 24,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.deepPurpleColor.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.deepPurpleColor.withOpacity(0.1),
                          child: Icon(
                            Icons.add,
                            color: AppColors.deepPurpleColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          AppConstants.addNewCategory,
                          style: TextStyles.deepPurpleMedium16.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Create a new category',
                          style: TextStyles.blackRegular12.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20,),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.category, color: AppColors.deepPurpleColor, size: 24),
            const SizedBox(width: 12),
            Text(AppConstants.addNewCategory),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newCategoryController,
              decoration: InputDecoration(
                labelText: AppConstants.enterCategoryName,
                prefixIcon: Icon(Icons.category, color: AppColors.deepPurpleColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.deepPurpleColor,
                    width: 2,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addNewCategory(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newCategoryController.clear();
              Navigator.pop(context);
            },
            child: Text(AppConstants.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newCategoryController.text.trim().isNotEmpty) {
                _addNewCategory(_newCategoryController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurpleColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppConstants.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.editTransaction, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.transaction.isSynced)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_sync, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Synced',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ListTile(
              title: Text(AppConstants.date),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null && pickedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(AppConstants.paymentMode, style: TextStyles.deepPurpleBold16),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  side: BorderSide(color: AppColors.deepPurpleColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerLeft,
                ),
                icon: Icon(Icons.payment, color: AppColors.deepPurpleColor),
                label: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedMode?.name ?? AppConstants.selectMode,
                        style: TextStyle(
                          color: _selectedMode != null 
                              ? AppColors.deepPurpleColor 
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.deepPurpleColor,
                    ),
                  ],
                ),
                onPressed: _showModeSelectionModal,
              ),
            ),
            const SizedBox(height: 18),
            Text(AppConstants.category, style: TextStyles.deepPurpleBold16),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  side: BorderSide(color: AppColors.deepPurpleColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerLeft,
                ),
                icon: Icon(Icons.category, color: AppColors.deepPurpleColor),
                label: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategory?.name ?? AppConstants.selectCategory,
                        style: TextStyle(
                          color: _selectedCategory != null 
                              ? AppColors.deepPurpleColor 
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.deepPurpleColor,
                    ),
                  ],
                ),
                onPressed: _showCategorySelectionModal,
              ),
            ),
            const SizedBox(height: 18),
            Text(AppConstants.description, style: TextStyles.deepPurpleBold16),
            const SizedBox(height: 18),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppConstants.description,
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorDescription != null ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorDescription != null ? Colors.red : AppColors.deepPurpleColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorDescription != null ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
              child: Padding(
                padding: const EdgeInsets.only(left: 0, right: 0),
                child: Text(
                  errorDescription ?? '',
                  style: TextStyles.blackRegular14.copyWith(fontSize: 10, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(AppConstants.amount, style: TextStyles.deepPurpleBold16),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: AppConstants.amount,
                prefixIcon: SizedBox(width: 20, child: Center(child: Text(TransactionHelper.getCurrencySymbol(_currencyCode), style: TextStyle(fontSize: 24),)),),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorAmount != null ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorAmount != null ? Colors.red : AppColors.deepPurpleColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorAmount != null ? Colors.red : Colors.grey,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(
              height: 20,
              child: Padding(
                padding: const EdgeInsets.only(left: 0, right: 0),
                child: Text(
                  errorAmount ?? '',
                  style: TextStyles.blackRegular14.copyWith(fontSize: 10, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _updateTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepPurpleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(AppConstants.saveTransaction, style: TextStyles.whiteBold16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 