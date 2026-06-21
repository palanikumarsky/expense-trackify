import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final VoidCallback onConfirm;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelText = "Cancel",
    this.confirmText = "Confirm",
    this.confirmButtonColor,
    this.cancelButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Container(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyles.blackBold18),
            const SizedBox(height: 10),
            Text(content, style: TextStyles.greyMedium14),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cancelButtonColor ?? Colors.black87,
                      side: BorderSide(color: Colors.black26),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(cancelText, style: TextStyles.blackBold12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      confirmButtonColor ?? AppColors.deepPurpleColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                    Text(confirmText, style: TextStyles.whiteBold12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
