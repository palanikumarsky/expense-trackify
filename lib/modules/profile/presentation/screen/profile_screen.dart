import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/profile/presentation/bloc/profile_bloc.dart';
import 'package:expensetrackify/modules/profile/presentation/screen/accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(AppConstants.profile, style: TextStyles.whiteBold20),
        centerTitle: true,
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: BlocProvider<ProfileBloc>(
        create: (context) => ProfileBloc(),
        child: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is FailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is NavigateToAccountScreen) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AccountsScreen(selectedAccount: state.selectedAccount),
                ),
              );
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                children: [
                  // Profile avatar placeholder
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.deepPurpleColor.withOpacity(0.08),
                      child: const Icon(Icons.person,
                          size: 60, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _optionTile(
                      Icons.group,
                      AppConstants.accountManagement,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountsScreen(),
                          ),
                        );
                      },
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

  Widget _optionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.deepPurpleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.deepPurpleColor, size: 22),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyles.blackMedium14),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
