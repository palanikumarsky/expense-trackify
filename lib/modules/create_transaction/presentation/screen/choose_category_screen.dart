import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/ads/widgets/banner_ad_widget.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/sync_event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChooseCategoryScreen extends StatefulWidget {
  final List<Category> categoryList;
  const ChooseCategoryScreen({super.key, required this.categoryList});

  @override
  State<ChooseCategoryScreen> createState() => _ChooseCategoryScreenState();
}

class _ChooseCategoryScreenState extends State<ChooseCategoryScreen> {
  List<Category> categoryList = [];
  final CategoryDao _categoryDao = CategoryDao(appDatabase);
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    categoryList = widget.categoryList;
  }

  Future<void> saveSelectedCategory(Category category) async {
    await Prefs.setSelectedCategory(category.toJsonString());
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryDao.getCategories();
    print("Loading Categories");
    setState(() {
      categoryList = categories;
    });
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
            // Notify other screens about the data change
            SyncEventBus().notifySync();
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
          const SizedBox(height: 20,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Where did the money go?",
                style: TextStyles.deepPurpleBold18.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                "Let’s tag it right!",
                style: TextStyles.greyMedium16.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20,),
          Expanded(
            child: ListView.separated(
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                Category category = categoryList[index];
                return InkWell(
                  onTap: () {
                    saveSelectedCategory(category);
                    Navigator.pop(context, true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        border: Border.all(
                          color: Colors.deepPurple.shade100,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16,),
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.category, color: AppColors.deepPurpleColor),
                          ),
                          const SizedBox(width: 16,),
                          Text(category.name, style: TextStyles.deepPurpleBold16),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
          // Banner Ad at the bottom
          const BannerAdWidget(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            showBorder: true,
          ),
        ],
      ),
    );
  }
}
