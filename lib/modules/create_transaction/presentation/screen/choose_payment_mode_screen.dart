import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:expensetrackify/config/widgets/custom_input_dialog.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:flutter/material.dart';

class ChoosePaymentModeScreen extends StatefulWidget {
  final List<Mode> paymentModeList;
  const ChoosePaymentModeScreen({super.key, required this.paymentModeList});

  @override
  State<ChoosePaymentModeScreen> createState() => _ChoosePaymentModeScreenState();
}

class _ChoosePaymentModeScreenState extends State<ChoosePaymentModeScreen> {
  final ModeDao _modeDao = ModeDao(appDatabase);
  List<Mode> paymentModeList = [];
  final TextEditingController _newModeController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    paymentModeList = widget.paymentModeList;
  }

  Future<void> saveSelectedPaymentMode(Mode mode) async {
    await Prefs.setSelectedPaymentMode(mode.toJsonString());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppConstants.modes, style: TextStyles.whiteBold20),
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
              itemCount: paymentModeList.length,
              itemBuilder: (context, index) {
                Mode paymentMode = paymentModeList[index];
                return InkWell(
                  onTap: () {
                    saveSelectedPaymentMode(paymentMode);
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
                          Text(paymentMode.name, style: TextStyles.deepPurpleBold16),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
        ],
      ),
    );
  }
}
