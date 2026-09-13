import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/modules/settings/widget/category_card.dart';
import 'package:expensetrackify/config/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/default_settings.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryDao _categoryDao = CategoryDao(appDatabase);
  List<Category> _categories = [];
  String? _defaultCategoryName;
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryDao.getCategories();
    final defaultCategory = await DefaultSettings.getDefaultMode();
    setState(() {
      _categories = categories;
      _defaultCategoryName = defaultCategory;
    });
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    _editCategoryController.dispose();
    super.dispose();
  }

  void _addNewCategory() {
    showDialog(
      context: context,
      builder: (_) => CustomInputDialog(
        controller: _newCategoryController,
        title: AppConstants.addNewCategory,
        hintText: AppConstants.enterCategoryName,
        onConfirm: (newCategoryName) async {
          if (newCategoryName.isNotEmpty) {
            await _categoryDao.createCategory(
              CategoriesCompanion.insert(name: newCategoryName),
            );
            _loadCategories();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.newCategoryAddedSuccessfully.replaceAll(
                    '{0}',
                    newCategoryName,
                  ),
                ),
                backgroundColor: AppColors.deepPurpleColor,
              ),
            );
          }
        },
      ),
    );
  }

  void _editCategory(Category category) {
    _editCategoryController.text = category.name;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppConstants.editCategory,
            style: TextStyles.deepPurpleBold18,
          ),
          content: TextField(
            controller: _editCategoryController,
            decoration: InputDecoration(
              hintText: AppConstants.enterCategoryName,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editCategoryController.clear();
              },
              child: Text(
                AppConstants.cancel,
                style: TextStyles.deepPurpleBold16,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCategoryName = _editCategoryController.text.trim();
                if (newCategoryName.isNotEmpty &&
                    newCategoryName != category.name) {
                  await _categoryDao.updateCategory(
                    category.copyWith(name: newCategoryName),
                  );
                  _loadCategories();
                  Navigator.of(context).pop();
                  _editCategoryController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppConstants.categoryUpdatedSuccessfully
                            .replaceAll('{0}', category.name)
                            .replaceAll('{1}', newCategoryName),
                      ),
                      backgroundColor: AppColors.deepPurpleColor,
                    ),
                  );
                } else if (newCategoryName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppConstants.categoryNameCannotBeEmpty),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                  _editCategoryController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurpleColor,
                foregroundColor: Colors.white,
              ),
              child: Text(AppConstants.save),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppConstants.deleteCategory,
            style: TextStyles.deepPurpleBold18,
          ),
          content: Text(
            AppConstants.deleteCategoryConfirmation.replaceAll(
              '{0}',
              category.name,
            ),
            style: TextStyles.deepPurpleMedium16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppConstants.cancel,
                style: TextStyles.deepPurpleBold16,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _categoryDao.deleteCategory(category.id);
                _loadCategories();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppConstants.categoryDeletedSuccessfully.replaceAll(
                        '{0}',
                        category.name,
                      ),
                    ),
                    backgroundColor: AppColors.deepPurpleColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppConstants.delete),
            ),
          ],
        );
      },
    );
  }

  void _setDefaultCategory(Category category) async {
    await DefaultSettings.setDefaultCategory(category.name);
    if (mounted) {
      setState(() {
        _defaultCategoryName = category.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${category.name}" set as default category.'),
          backgroundColor: AppColors.deepPurpleColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppConstants.categories, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                _addNewCategory();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  child: Text("Add", style: TextStyles.whiteMedium12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _categories.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.label_outline,
                        title: 'No categories yet',
                        subtitle: 'Tap the + button to add your first category',
                      )
                    : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isDefault = category.name == _defaultCategoryName;
                        return CategoryCard(
                          category: category,
                          isDefault: isDefault,
                          onEdit: () => _editCategory(category),
                          onDelete: () => _deleteCategory(category),
                          onSetDefault: () => _setDefaultCategory(category),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
