import 'dart:async';

import 'package:expensetrackify/config/widgets/custom_progress_bar.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/profile/presentation/bloc/profile_bloc.dart';
import 'package:expensetrackify/modules/profile/presentation/screen/login_screen.dart';
import 'package:expensetrackify/modules/profile/presentation/screen/accounts_screen.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/modules/dao/user_dao.dart';
import 'package:expensetrackify/modules/profile/auth_service/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expensetrackify/utils/user_type_stream.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isGuest = true;
  String? userName;
  String? userEmail;
  String? userPhotoUrl;
  late UserDao _userDao;
  StreamSubscription<String>? _userTypeSubscription;

  @override
  void initState() {
    super.initState();
    _userDao = UserDao(appDatabase);
    // Listen to user type changes
    _userTypeSubscription = userTypeStream.userTypeStream.listen((
      userType,
    ) async {
      bool isGuestUser = (userType.isEmpty || userType == AppConstants.guest);
      if (mounted) {
        setState(() {
          isGuest = isGuestUser;
        });
        if (!isGuestUser) {
          await loadUserDataFromDatabase();
        } else {
          setState(() {
            userName = null;
            userEmail = null;
            userPhotoUrl = null;
          });
        }
      }
    });
    // Initialize with current user type
    userTypeStream.getCurrentUserType().then((userType) async {
      bool isGuestUser = (userType.isEmpty || userType == AppConstants.guest);
      if (mounted) {
        setState(() {
          isGuest = isGuestUser;
        });
        if (!isGuestUser) {
          await loadUserDataFromDatabase();
        }
      }
    });
  }

  @override
  void dispose() {
    _userTypeSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadUserDataFromDatabase() async {
    try {
      // Get the current user's email from preferences
      final storedEmail = await Prefs.getUserEmail;
      if (storedEmail!.isNotEmpty) {
        final user = await _userDao.getUserByEmail(storedEmail);
        if (user != null) {
          setState(() {
            userName = user.name;
            userEmail = user.emailId;
            userPhotoUrl = user.photoUrl;
          });
        }
      } else {
        // Fallback: get the first user from database if no email is stored
        final users = await _userDao.getAllUsers();
        if (users.isNotEmpty) {
          final user = users.first; // Get the most recent user
          setState(() {
            userName = user.name;
            userEmail = user.emailId;
            userPhotoUrl = user.photoUrl;
          });
        }
      }
    } catch (error) {
    }
  }

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
            if (state is LoggedInSuccessful) {
              CustomProgressBar(context).hideLoadingIndicator();
              setState(() {
                isGuest = false;
                userName = state.userName;
                userEmail = state.email;
                userPhotoUrl = state.photoUrl;
              });
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppConstants.welcomeUser.replaceAll(
                      '{0}',
                      state.userName ?? AppConstants.user,
                    ),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is FailureState) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SignOutSuccess) {
              setState(() {
                isGuest = true;
                userName = null;
                userEmail = null;
                userPhotoUrl = null;
              });
              // Show logout success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppConstants.loggedOutSuccessfully),
                  backgroundColor: Colors.blue,
                ),
              );
            } else if (state is NavigateToAccountScreen) {
              CustomProgressBar(context).hideLoadingIndicator();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AccountsScreen(selectedAccount: state.selectedAccount,),
                ),
              );
            } else if (state is SyncInfoLoaded) {
              CustomProgressBar(context).hideLoadingIndicator();
              _showSyncConfirmationDialog(context, state.syncInfo);
            } else if (state is SyncInProgress) {
              CustomProgressBar(context).hideLoadingIndicator();
              // Show sync in progress
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(AppConstants.syncingTransactions),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is SyncSuccess) {
              CustomProgressBar(context).hideLoadingIndicator();
              // Show sync success
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate back to home screen to refresh the data
              // Navigator.pop(context);
            } else if (state is SyncFailure) {
              CustomProgressBar(context).hideLoadingIndicator();
              // Show sync failure
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProfileInitial) {
              CustomProgressBar(context).showLoadingIndicator();
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  // child: isGuest ? _buildGuestCard(context) : _buildProfileContent(context),
                  child: Column(
                    children: [
                      isGuest
                          ? _buildGuestCard(context)
                          : _buildProfile(context),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _optionTile(
                              Icons.group,
                              AppConstants.accountManagement,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AccountsScreen(),
                                  ),
                                );
                              },
                            ),
                            _optionTile(Icons.sync, AppConstants.syncNow, () {
                              // Start sync directly
                              BlocProvider.of<ProfileBloc>(
                                context,
                              ).add(SyncTransactions());
                            }, isLocked: isGuest),
                            _optionTile(
                              Icons.delete_outline,
                              AppConstants.deleteProfile,
                              () {},
                              isLocked: isGuest,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Logout Button for guest (if needed)
                      Visibility(
                        visible: !isGuest,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.deepPurpleColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              BlocProvider.of<ProfileBloc>(
                                context,
                              ).add(SignOutTapped());
                            },
                            child: Text(
                              AppConstants.logout,
                              style: TextStyles.deepPurpleBold16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.deepPurpleColor.withOpacity(0.08),
                child: const Icon(Icons.person, size: 48, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(AppConstants.hiGuest, style: TextStyles.deepPurpleBold18),
              const SizedBox(height: 8),
              Text(
                AppConstants.loginOrSignupToTrackExpenses,
                style: TextStyles.blackMedium14.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepPurpleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => LoginScreen(isFromProfilePage: true),
                      ),
                    );
                  },
                  child: Text(
                    AppConstants.loginOrSignup,
                    style: TextStyles.whiteBold16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Avatar with Edit Icon
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 75,
                backgroundImage:
                    userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                        ? NetworkImage(userPhotoUrl!)
                        : null,
                backgroundColor: AppColors.deepPurpleColor.withOpacity(0.08),
                child:
                    (userPhotoUrl == null || userPhotoUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 75, color: Colors.grey)
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepPurpleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    color: Colors.white,
                    onPressed: () {
                      // TODO: Change profile picture
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Name and Username
        Text(
          (userName ?? AppConstants.user),
          style: TextStyles.deepPurpleBold18,
        ),
        (!isGuest && userEmail != null)
            ? Text(
              userEmail!,
              style: TextStyles.blackMedium14.copyWith(color: Colors.grey[600]),
            )
            : const SizedBox.shrink(),
        const SizedBox(height: 16),
        // Edit Profile Button
        SizedBox(
          width: 160,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurpleColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              // TODO: Edit profile
            },
            child: Text(
              AppConstants.editProfile,
              style: TextStyles.whiteBold16,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _optionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
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
            Text(
              title,
              style:
                  isLocked ? TextStyles.greyMedium14 : TextStyles.blackMedium14,
            ),
            const Spacer(),
            Icon(
              isLocked ? Icons.lock : Icons.chevron_right,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  void _showSyncConfirmationDialog(BuildContext context, SyncInfo syncInfo) {
    // Capture the ProfileBloc instance before creating the bottom sheet
    final profileBloc = BlocProvider.of<ProfileBloc>(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                child: Row(
                  children: [
                    Icon(
                      Icons.sync,
                      color: AppColors.deepPurpleColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppConstants.syncConfirmation,
                      style: TextStyles.deepPurpleBold18,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.foundNewTransactionsToUpload.replaceAll(
                          '{0}',
                          syncInfo.newTransactionsCount.toString(),
                        ),
                        style: TextStyles.blackMedium14,
                      ),
                      const SizedBox(height: 16),
                      if (syncInfo.newTransactionsCount > 0) ...[
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView(
                              children:
                                  syncInfo.newTransactions
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        final index = entry.key;
                                        final transaction = entry.value;
                                        final transactionData =
                                            transaction.transaction;
                                        final category = transaction.category;
                                        final mode = transaction.mode;

                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors
                                                .deepPurpleColor
                                                .withOpacity(0.1),
                                            child: Text(
                                              '${index + 1}',
                                              style:
                                                  TextStyles.deepPurpleBold16,
                                            ),
                                          ),
                                          title: Text(
                                            transactionData.description,
                                            style: TextStyles.blackMedium12,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            '${category?.name ?? 'Unknown'} • ${mode?.name ?? 'Unknown'}',
                                            style: TextStyles.blackRegular10,
                                          ),
                                          trailing: Text(
                                            '\$${transactionData.amount.toStringAsFixed(2)}',
                                            style: TextStyles.deepPurpleBold16,
                                          ),
                                        );
                                      })
                                      .toList(),
                            ),
                          ),
                        ),
                        if (syncInfo.newTransactionsCount > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              AppConstants.andMoreTransactions.replaceAll(
                                '{0}',
                                (syncInfo.newTransactionsCount - 5).toString(),
                              ),
                              style: TextStyles.blackRegular12.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.doYouWantToUploadTransactions,
                        style: TextStyles.blackMedium14,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Show message that sync was cancelled
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppConstants.syncCancelledByUser),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.deepPurpleColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          AppConstants.no,
                          style: TextStyles.deepPurpleBold16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Confirm sync with the new transactions using the captured bloc instance
                          profileBloc.add(
                            ConfirmSync(
                              newTransactions: syncInfo.newTransactions,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepPurpleColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          AppConstants.yes,
                          style: TextStyles.whiteBold16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
