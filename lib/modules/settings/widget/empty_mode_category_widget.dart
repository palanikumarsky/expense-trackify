import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:flutter/material.dart';

class EmptyModeCategoryWidget extends StatelessWidget {
  final String screenType;
  const EmptyModeCategoryWidget({
    super.key,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 80,
            color: AppColors.deepPurpleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noPaymentModesAvailable,
            style: TextStyles.deepPurpleBold18,
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.tapPlusButtonToAddFirstMode,
            style: TextStyles.deepPurpleBold16.copyWith(
              color: AppColors.deepPurpleColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
