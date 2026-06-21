import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/modules/dao/expense_account_dao.dart';
import 'package:expensetrackify/modules/firebase_models/user_model.dart';
import 'package:expensetrackify/modules/profile/auth_service/auth_service.dart';
import 'package:expensetrackify/modules/profile/auth_service/backup_service.dart';
import 'package:expensetrackify/utils/database_helper.dart';
import 'package:expensetrackify/utils/firebase_utils/firebase_helper.dart';
import 'package:expensetrackify/utils/firebase_utils/userId_helper.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:expensetrackify/utils/user_type_stream.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:meta/meta.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/modules/dao/user_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/utils/sync_event_bus.dart';


part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  late final UserDao _userDao;
  late final SyncService _syncService;
  late final TransactionDao _transactionDao;
  late final CategoryDao _categoryDao;
  late final ModeDao _modeDao;
  late final ExpenseAccountDao expenseAccountDao;

  ProfileBloc() : super(ProfileInitial()) {
    _userDao = UserDao(appDatabase);
    _syncService = SyncService();
    _transactionDao = TransactionDao(appDatabase);
    _categoryDao = CategoryDao(appDatabase);
    _modeDao = ModeDao(appDatabase);
    expenseAccountDao = ExpenseAccountDao(appDatabase);
    on<SignInWithGoogle>(_onSignInWithGoogle);
    on<SignOutTapped>(_onSignOutTapped);
    on<SyncTransactions>(_onSyncTransactions);
    on<ConfirmSync>(_onConfirmSync);
    on<FetchModels>(_onFetchModels);
    on<CreateModel>(_onCreateModel);
    on<ChangeAccountTapped>(_onChangeAccountTapped);
    on<AccountManagementTapped>(_onAccountManagementTapped);
  }
  
  Future<void> _onSignInWithGoogle(
      SignInWithGoogle event,
      Emitter<ProfileState> emit,
      ) async {
    emit(ProfileInitial());
    try {
      final user = await AuthService.loginWithGoogle();
      if (user != null) {
        // Update user state using the stream service
        await userTypeStream.setUserType(AppConstants.loggedUser);

        // Save user data to local database
        try {
          final userCompanion = _userDao.createUserCompanion(
            name: user.displayName ?? 'Unknown User',
            emailId: user.email ?? '',
            photoUrl: user.photoURL,
          );
          
          await _userDao.upsertUser(userCompanion);
          
          // Store user email in preferences for future reference
          if (user.email != null) {
            await Prefs.setUserEmail(user.email!);
          }

          UserModel userdata = UserModel(
            userId: UserIDHelper().generateUserId(),
            name: user.displayName ?? "",
            email: user.email ?? "",
            photoUrl: user.photoURL ?? "",
            isActive: true,
          );
          
          // Create/Update user profile in Firebase Firestore
          await FireStoreService().createOrUpdateFirebaseUserProfile(userdata);
          
          // Initialize default modes and categories for new users
          await DatabaseHelper().initializeDefaultData();
          
          print('User data saved to database and Firebase successfully');
        } catch (dbError) {
          print('Error saving user data to database: $dbError');
          // Continue with login even if database save fails
        }

        await SyncService().syncIfLocalEmptyAndCloudHasData();
        // Fetch the latest model from Firebase and store its name in local db
        final firestore = FirebaseFirestore.instance;
        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final modelsRef = firestore.collection('users').doc(currentUser.uid).collection('expenseModels');
          final modelsSnapshot = await modelsRef.get();
          if (modelsSnapshot.docs.isNotEmpty) {
            // Find the latest model by document ID
            var latestModelDoc = modelsSnapshot.docs.first;
            final List<String> allModelNames = [];
            for (final doc in modelsSnapshot.docs) {
              final data = doc.data();
              final modelName = data['modelName'] ?? doc.id;
              allModelNames.add(modelName);
              await expenseAccountDao.addExpenseAccount(ExpensesAccountsCompanion.insert(name: modelName));
              if (doc.id.compareTo(latestModelDoc.id) > 0) {
                latestModelDoc = doc;
              }
            }
            final data = latestModelDoc.data();
            final modelName = data['modelName'] ?? latestModelDoc.id;
          }
          List<ExpensesAccount> expenseAccountsList = await expenseAccountDao.getExpensesAccounts();
          await Prefs.setSelectedAccount(expenseAccountsList[0].name);
        }
        emit(LoggedInSuccessful(
          userName: user.displayName, 
          email: user.email,
          photoUrl: user.photoURL,
        ));
      } else {
        emit(FailureState(errorMessage: "email not selected"));
      }
    } on firebase_auth.FirebaseAuthException catch (error) {
      print(error);
      emit(FailureState(errorMessage: AppConstants.somethingWentWrong));
    } catch (error) {
      print(error);
      emit(FailureState(errorMessage: AppConstants.somethingWentWrong));
    }
  }

  Future<void> _onSignOutTapped(
      SignOutTapped event,
      Emitter<ProfileState> emit,
      ) async {
    // Get current user info before signing out
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final userUid = currentUser?.uid;
    
    bool isSignedOut = await AuthService.signOut();
    if (isSignedOut) {
      // Update user state using the stream service
      await Prefs.removeUserEmail(); // Clear stored user email
      await userTypeStream.setUserType(AppConstants.guest);

      // Clear all local database data
      await DatabaseHelper().clearLocalDatabaseData();
      
      // Deactivate user profile in Firebase using the stored UID
      if (userUid != null) {
        await FireStoreService().deactivateFirebaseUserProfile(userUid);
      }
      
      // Set a flag to notify home screen to clear dashboard
      await Prefs.setLastSyncTimestamp(); // This will trigger home screen refresh
      
      emit(SignOutSuccess());
    } else {
      emit(FailureState(errorMessage: AppConstants.somethingWentWrong));
    }
  }

  Future<void> _onSyncTransactions(
      SyncTransactions event,
      Emitter<ProfileState> emit,
      ) async {
    try {
      // First, check if local DB is empty and cloud has data
      final cloudFetchResult = await _syncService.syncIfLocalEmptyAndCloudHasData();
      if (cloudFetchResult.success && cloudFetchResult.syncedCount > 0) {
        await Prefs.setLastSyncTimestamp();
        emit(SyncSuccess(
          message: cloudFetchResult.message,
          syncedCount: cloudFetchResult.syncedCount,
        ));
        SyncEventBus().notifySync();
        return;
      } else if (!cloudFetchResult.success) {
        emit(SyncFailure(errorMessage: cloudFetchResult.message));
        return;
      }
      // Get sync info first
      final syncInfo = await _syncService.getSyncInfo();
      if (!syncInfo.success) {
        emit(SyncFailure(errorMessage: syncInfo.message));
        return;
      }
      if (syncInfo.newTransactionsCount == 0) {
        // No new transactions to sync, just download from cloud
        final downloadResult = await _syncService.syncFromFirebase();
        if (downloadResult.success) {
          await Prefs.setLastSyncTimestamp();
          emit(SyncSuccess(
            message: 'No new transactions to upload. Downloaded ${downloadResult.syncedCount} items from cloud.',
            syncedCount: downloadResult.syncedCount,
          ));
          SyncEventBus().notifySync();
        } else {
          emit(SyncFailure(errorMessage: 'Download failed: ${downloadResult.message}'));
        }
      } else {
        // Show sync info to user for confirmation
        emit(SyncInfoLoaded(syncInfo: syncInfo));
      }
    } catch (error) {
      print('Error in sync process: $error');
      emit(SyncFailure(errorMessage: 'Sync failed: $error'));
    }
  }

  Future<void> _onConfirmSync(
      ConfirmSync event,
      Emitter<ProfileState> emit,
      ) async {
    emit(SyncInProgress());
    
    try {
      // Upload the confirmed transactions
      final uploadResult = await _syncService.syncToFirebaseV2();
      
      if (uploadResult.success && uploadResult.syncedCount > 0) {
        // Update isSynced to true for all successfully uploaded transactions
        await _updateTransactionsAsSynced();
      }
      
      // Also download any new data from cloud
      final downloadResult = await _syncService.syncFromFirebase();
      
      final totalSynced = uploadResult.syncedCount + downloadResult.syncedCount;
      
      if (uploadResult.success && downloadResult.success) {
        // Set sync timestamp to trigger refreshes
        await Prefs.setLastSyncTimestamp();
        
        emit(SyncSuccess(
          message: 'Successfully synced $totalSynced items',
          syncedCount: totalSynced,
        ));
        SyncEventBus().notifySync();
      } else {
        emit(SyncFailure(errorMessage: 'Sync failed: ${uploadResult.message}'));
      }
    } catch (error) {
      print('Error in sync process: $error');
      emit(SyncFailure(errorMessage: 'Sync failed: $error'));
    }
  }

  /// Update isSynced field to true for all transactions that are not already synced
  Future<void> _updateTransactionsAsSynced() async {
    try {
      // Get all transactions that are not synced
      final unsyncedTransactions = await _transactionDao.getUnsyncedTransactions();
      
      // Update each transaction to mark as synced
      for (final transaction in unsyncedTransactions) {
        final updatedTransaction = transaction.copyWith(isSynced: true);
        await _transactionDao.updateTransaction(updatedTransaction);
      }
      
      print('Updated ${unsyncedTransactions.length} transactions as synced');
    } catch (error) {
      print('Error updating transactions as synced: $error');
      // Don't throw error to avoid breaking the sync flow
    }
  }

  Future<void> _onFetchModels(
      FetchModels event,
      Emitter<ProfileState> emit,
      ) async {
    emit(ProfileInitial());
    try {
      final expenseAccountDao = ExpenseAccountDao(appDatabase);
      final models = await expenseAccountDao.getExpensesAccounts();
      String? selectedAccount = await Prefs.getSelectedAccount;
      emit(ShowModels(
        modelList: models,
        selectedAccount: selectedAccount ?? "",
      ));
    } catch (error) {
      print('Error getting database stats: $error');
      emit(FailureState(errorMessage: 'Failed to get models. Please try again...!!!'));
    }
  }

  Future<void> _onCreateModel(
      CreateModel event,
      Emitter<ProfileState> emit,
      ) async {
    try {
      final expenseAccountDao = ExpenseAccountDao(appDatabase);
      await expenseAccountDao.addExpenseAccount(ExpensesAccountsCompanion.insert(name: event.modelName));
      final models = await expenseAccountDao.getExpensesAccounts();
      emit(ModelCreateSuccess(modelList: models));
    } catch (error) {
      print('Error creating model: $error');
      emit(FailureState(errorMessage: 'Failed to create model. Please try again...!!!'));
    }
  }

  Future<void> _onChangeAccountTapped(
      ChangeAccountTapped event,
      Emitter<ProfileState> emit,
      ) async {
    try {
      await Prefs.setSelectedAccount(event.selectedAccount);
      SyncEventBus().notifySync();
      emit(SelectAccountSuccess(selectedAccount: event.selectedAccount));
    } catch (error) {
      emit(FailureState(errorMessage: 'Failed to change the Account'));
    }
  }

  Future<void> _onAccountManagementTapped(
      AccountManagementTapped event,
      Emitter<ProfileState> emit,
      ) async {
    try {
      String? selectedAccount = await Prefs.getSelectedAccount;
      emit(NavigateToAccountScreen(selectedAccount: selectedAccount ?? "",));
    } catch (error) {
      emit(FailureState(errorMessage: 'Failed to change the Account'));
    }
  }
}

