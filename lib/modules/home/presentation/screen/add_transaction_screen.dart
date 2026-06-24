import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/utils/date_time_helper.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _newModeController = TextEditingController();
  final _newCategoryController = TextEditingController();

  String? errorDescription;
  String? errorAmount;

  DateTime _selectedDate = DateTime.now();

  final TransactionDao _transactionDao = TransactionDao(appDatabase);
  List<Mode> _modes = [];
  Mode? _selectedMode;
  List<Category> _categories = [];
  Category? _selectedCategory;
  String _currencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _loadModesAndDefaults();
    _loadCategoriesAndDefaults();
    errorDescription = null;
    errorAmount = null;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _newModeController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencyCode = prefs.getString('currency_code') ?? 'USD';
    });
  }

  Future<void> _loadModesAndDefaults() async {
    final modes = await ModeDao(appDatabase).getModes();
    setState(() {
      _modes = modes;
      if (modes.isNotEmpty) {
        _selectedMode = modes.first;
      }
    });
  }

  Future<void> _loadCategoriesAndDefaults() async {
    final categories = await CategoryDao(appDatabase).getCategories();
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
      }
    });
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
      final modeId = await ModeDao(appDatabase).createMode(ModesCompanion.insert(
        name: modeName.trim(),
      ));
      final allModes = await ModeDao(appDatabase).getModes();
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
      // Don't pop here - let the dialog handle navigation
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
      final categoryId = await CategoryDao(appDatabase).createCategory(CategoriesCompanion.insert(
        name: categoryName.trim(),
      ));
      final allCategories = await CategoryDao(appDatabase).getCategories();
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
      // Don't pop here - let the dialog handle navigation
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveTransaction() async {
    setState(() {
      errorDescription = null;
      errorAmount = null;
    });
    bool hasError = false;
    if (_descriptionController.text.isEmpty) {
      errorDescription = AppConstants.pleaseEnterDescription;
      hasError = true;
    }
    if (_amountController.text.isEmpty) {
      errorAmount = AppConstants.pleaseEnterAmount;
      hasError = true;
    } else if (double.tryParse(_amountController.text) == null) {
      errorAmount = AppConstants.pleaseEnterValidNumber;
      hasError = true;
    }
    setState(() {});
    if (hasError) return;
    if (_selectedMode == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.selectModeAndCategory),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _transactionDao.createTransaction(TransactionsCompanion.insert(
      id: DateTimeHelper().generateTransactionsId(DateTime.now().toIso8601String()),
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      modeId: _selectedMode!.id,
      categoryId: _selectedCategory!.id,
      date: _selectedDate.toIso8601String(),
    ));
    // Navigator.of(context).pop(true); // Return true to indicate data may have changed
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
            // Modes list with Add New Mode option
            Expanded(
              child: Column(
                children: [
                  // Existing modes list
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: AppColors.deepPurpleColor, size: 24),
            const SizedBox(width: 12),
            Text(AppConstants.addNewMode),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newModeController,
              decoration: InputDecoration(
                labelText: AppConstants.enterModeName,
                prefixIcon: Icon(Icons.payment, color: AppColors.deepPurpleColor),
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
                  _addNewMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newModeController.clear();
              Navigator.pop(context);
            },
            child: Text(AppConstants.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newModeController.text.trim().isNotEmpty) {
                _addNewMode(_newModeController.text);
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
                  // Add New Category container
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
            Text(AppConstants.addNewCategory, style: TextStyles.deepPurpleBold16),
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
        centerTitle: true,
        title: Text(AppConstants.addTransaction, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(AppConstants.date),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        side: BorderSide(color: AppColors.deepPurpleColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                      ),
                      icon: Icon(Icons.calendar_today, color: AppColors.deepPurpleColor),
                      label: Row(
                        children: [
                          Text(
                            DateFormat.yMMMd().format(_selectedDate),
                            style: TextStyle(color: AppColors.deepPurpleColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEE').format(_selectedDate),
                            style: TextStyle(color: AppColors.deepPurpleColor.withOpacity(0.7), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null && pickedDate != _selectedDate) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text(AppConstants.paymentMode, style: TextStyles.deepPurpleBold16),
                  buildHeader(AppConstants.paymentMode),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  // Text(AppConstants.category, style: TextStyles.deepPurpleBold16),
                  buildHeader(AppConstants.category),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  // Text(AppConstants.description, style: TextStyles.deepPurpleBold16),
                  buildHeader(AppConstants.description),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyles.deepPurpleSemiBold14,
                    decoration: InputDecoration(
                      labelText: AppConstants.description,
                      labelStyle: TextStyles.deepPurpleSemiBold14,
                      prefixIcon: Icon(Icons.description_outlined,color: AppColors.deepPurpleColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorDescription != null ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorDescription != null ? Colors.red : Colors.deepPurple,
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
                    height: 16,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0, right: 0),
                      child: Text(
                        errorDescription ?? '',
                        style: TextStyles.blackRegular14.copyWith(fontSize: 10, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Text(AppConstants.amount, style: TextStyles.deepPurpleBold16),
                  buildHeader(AppConstants.amount),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    style: TextStyles.deepPurpleSemiBold14,
                    decoration: InputDecoration(
                      labelText: AppConstants.amount,
                      labelStyle: TextStyles.deepPurpleSemiBold14,
                      prefixIcon: SizedBox(width: 20, child: Center(child: Text(TransactionHelper.getCurrencySymbol(_currencyCode), style: TextStyle(fontSize: 24, color: AppColors.deepPurpleColor),)),),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorDescription != null ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorDescription != null ? Colors.red : Colors.deepPurple,
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepPurpleColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.save),
                      label: Text(AppConstants.saveTransaction, style: TextStyles.whiteBold16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader(String title) {
    return Text(title, style: TextStyles.deepPurpleBold12) ;
  }
}
