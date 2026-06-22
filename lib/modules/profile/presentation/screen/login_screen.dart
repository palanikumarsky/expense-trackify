import 'package:expensetrackify/config/widgets/custom_progress_bar.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/asset_path.dart';
import 'package:expensetrackify/modules/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromProfilePage;
  const LoginScreen({super.key, this.isFromProfilePage = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final double topContainerHeight = MediaQuery.of(context).size.height * 0.35;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.deepPurpleColor,
        automaticallyImplyLeading: false,
        actions: [
          if (widget.isFromProfilePage)
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 25),
                child: Text(AppConstants.skip, style: TextStyles.whiteBold16),
              ),
            ),
        ],
      ),
      body: BlocProvider<ProfileBloc>(
        create: (context) => ProfileBloc(),
        child: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is LoggedInSuccessful) {
              CustomProgressBar(context).hideLoadingIndicator();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => CustomBottomNavigationBar(
                    selectedIndex: widget.isFromProfilePage ? 4 : 0,
                  ),
                ),
              );
            } else if (state is FailureState) {
              CustomProgressBar(context).hideLoadingIndicator();
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProfileInitial) {
              CustomProgressBar(context).showLoadingIndicator();
              // Handle initial state if needed
              // For now, we'll keep the current guest state
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: topContainerHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(100),
                              bottomRight: Radius.circular(100),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                PngAssets.appIconPng,
                                height:
                                    MediaQuery.of(context).size.height * 0.18,
                                width: MediaQuery.of(context).size.width * 0.5,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                AppConstants.appName,
                                style: TextStyles.whiteBold20.copyWith(
                                  fontSize: 32,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppConstants.personalizedTrackerForYourExpenses,
                                style: TextStyles.whiteMedium14.copyWith(
                                  fontSize: 16,
                                  color: Colors.grey[100],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  AppConstants.unlockAllFeatures,
                                  style: TextStyles.deepPurpleBold18.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _benefitRow(
                                Icons.download,
                                AppConstants.downloadYourTransactions,
                              ),
                              _benefitRow(
                                Icons.backup,
                                AppConstants.backupAndSyncYourData,
                              ),
                              _benefitRow(
                                Icons.devices,
                                AppConstants.accessOnMultipleDevices,
                              ),
                              // _benefitRow(Icons.block, AppConstants.adFreeEnvironment),
                              const SizedBox(height: 36),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    BlocProvider.of<ProfileBloc>(
                                      context,
                                    ).add(SignInWithGoogle());
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        PngAssets.googlePng,
                                        height: 28,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        AppConstants.signInWithGoogle,
                                        style: TextStyles.whiteBold18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Visibility(
                                visible: !widget.isFromProfilePage,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const CustomBottomNavigationBar(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppConstants.continueAsGuest,
                                    style: TextStyles.deepPurpleBold16.copyWith(
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.deepPurpleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.deepPurpleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyles.blackMedium14)),
        ],
      ),
    );
  }
}
