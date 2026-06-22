import 'dart:io';
import 'package:expensetrackify/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const loadingDialogKey = "loadingDialogKey";
const loadingDialogWillPopKey = "loadingDialogWillPopKey";

class CustomProgressBar {
  final BuildContext context;

  CustomProgressBar(this.context);

  static bool progressbarStatus = false;

  void showLoadingIndicator() {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: const LoadingIndicator(),
          );
        },
      );
      progressbarStatus = true;
    }
  }

  void hideLoadingIndicator() {
    if (progressbarStatus == true) {
      Navigator.of(context).pop();
      progressbarStatus = false;
    }
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      key: const Key(loadingDialogWillPopKey),
      onWillPop: () async => false,
      child: Center(
        key: const Key(loadingDialogKey),
        child:
            Platform.isAndroid
                ? CircularProgressIndicator(color: AppColors.deepPurpleColor)
                : CupertinoActivityIndicator(
                  color: AppColors.deepPurpleColor,
                  radius: 20,
                  animating: true,
                ),
      ),
    );
  }
}
