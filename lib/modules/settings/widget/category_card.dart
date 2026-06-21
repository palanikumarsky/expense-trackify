import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.deepPurpleColor.withOpacity(0.1),
          child: Icon(Icons.category, color: AppColors.deepPurpleColor),
        ),
        title: Row(
          children: [
            Text(category.name, style: TextStyles.deepPurpleBold16),
            const Spacer(),
            if (isDefault) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.orange),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case AppConstants.edit:
                onEdit();
                break;
              case AppConstants.delete:
                onDelete();
                break;
              case 'set_default':
                onSetDefault();
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: AppConstants.edit,
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.deepPurpleColor),
                      const SizedBox(width: 8),
                      Text(AppConstants.edit),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: AppConstants.delete,
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        AppConstants.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'set_default',
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(AppConstants.setAsDefault),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
