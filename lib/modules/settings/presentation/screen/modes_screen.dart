import 'package:expensetrackify/config/widgets/custom_alert_dialog.dart';
import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/modules/ads/widgets/banner_ad_widget.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/modules/settings/widget/empty_mode_category_widget.dart';
import 'package:expensetrackify/modules/settings/widget/payment_mode_card.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/default_settings.dart';
import 'package:expensetrackify/utils/sync_event_bus.dart';

class ModesScreen extends StatefulWidget {
  const ModesScreen({super.key});

  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen> {
  final ModeDao _modeDao = ModeDao(appDatabase);
  List<Mode> _modes = [];
  String? _defaultModeName;
  final TextEditingController _newModeController = TextEditingController();
  final TextEditingController _editModeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModesAndDefault();
  }

  Future<void> _loadModesAndDefault() async {
    final modes = await _modeDao.getModes();
    final defaultMode = await DefaultSettings.getDefaultMode();
    setState(() {
      _modes = modes;
      _defaultModeName = defaultMode;
    });
  }

  @override
  void dispose() {
    _newModeController.dispose();
    _editModeController.dispose();
    super.dispose();
  }

  void _addNewMode() {
    showDialog(
      context: context,
      builder: (_) => CustomInputDialog(
        controller: _newModeController,
        title: AppConstants.addNewMode,
        hintText: AppConstants.enterModeName,
        onConfirm: (newModeName) async {
          if (newModeName.isNotEmpty) {
            await _modeDao.createMode(
              ModesCompanion.insert(name: newModeName),
            );
            _loadModesAndDefault();
            // Notify other screens about the data change
            SyncEventBus().notifySync();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.newModeAddedSuccessfully.replaceAll(
                    '{0}',
                    newModeName,
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

  void _editMode(Mode mode) {
    _editModeController.text = mode.name;

    showDialog(
      context: context,
      builder: (_) => CustomInputDialog(
        controller: _editModeController,
        title: AppConstants.editMode,
        hintText: AppConstants.enterModeName,
        onConfirm: (newModeName) async {
          if (newModeName.isNotEmpty && newModeName != mode.name) {
            await _modeDao.updateMode(mode.copyWith(name: newModeName));
            _loadModesAndDefault();
            // Notify other screens about the data change
            SyncEventBus().notifySync();
            Navigator.of(context).pop();
            _editModeController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.modeUpdatedSuccessfully
                      .replaceAll('{0}', mode.name)
                      .replaceAll('{1}', newModeName),
                ),
                backgroundColor: AppColors.deepPurpleColor,
              ),
            );
          } else if (newModeName.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppConstants.modeNameCannotBeEmpty),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteMode(Mode mode) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: AppConstants.areYouSure,
          content: AppConstants.deleteModeConfirmation.replaceAll('{0}', mode.name),
          cancelText: AppConstants.cancel,
          confirmText: AppConstants.delete,
          onConfirm: () async {
            Navigator.pop(context);
            await _modeDao.deleteMode(mode.id);
            _loadModesAndDefault();
            // Notify other screens about the data change
            SyncEventBus().notifySync();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.modeDeletedSuccessfully.replaceAll(
                    '{0}',
                    mode.name,
                  ),
                ),
                backgroundColor: AppColors.deepPurpleColor,
              ),
            );
          },
          confirmButtonColor: Colors.red,
        );
      },
    );
  }

  void _setDefaultMode(Mode mode) async {
    await DefaultSettings.setDefaultMode(mode.name);
    if (mounted) {
      setState(() {
        _defaultModeName = mode.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${mode.name}" set as default payment mode.'),
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
        title: Text(AppConstants.paymentModes, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                _addNewMode();
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
                _modes.isEmpty
                    ? EmptyModeCategoryWidget(screenType: AppConstants.mode,)
                    : ListView.builder(
                      itemCount: _modes.length,
                      itemBuilder: (context, index) {
                        final mode = _modes[index];
                        final isDefault = mode.name == _defaultModeName;
                        return PaymentModeCard(
                          mode: mode,
                          isDefault: isDefault,
                          onEdit: () => _editMode(mode),
                          onDelete: () => _deleteMode(mode),
                          onSetDefault: () => _setDefaultMode(mode),
                        );
                      },
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
