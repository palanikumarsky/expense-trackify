import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/ads/widgets/banner_ad_widget.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/utils/pref.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  List<Map<String, String>> currencies = [];

  String? _selectedCurrencyCode;

  @override
  void initState() {
    super.initState();
    currencies = AppConstants.currencyMap;
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    await Prefs.loadCurrency();
    setState(() {
      _selectedCurrencyCode = Prefs.currencyCodeNotifier.value;
    });
  }

  Future<void> _setCurrency(String code) async {
    await Prefs.setCurrency(code);
    setState(() {
      _selectedCurrencyCode = code;
    });
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.selectCurrency, style: TextStyles.whiteBold20),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      // appBar: AppBar(
      //   title: Text(AppConstants.selectCurrency),
      // ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: currencies.map((currency) {
                return RadioListTile<String>(
                  value: currency['code']!,
                  groupValue: _selectedCurrencyCode,
                  title: Text('${currency['code']}', style: TextStyles.blackBold16),
                  subtitle: Text(currency['name']!),
                  onChanged: (val) => _setCurrency(val!),
                  secondary: Text(TransactionHelper.getCurrencySymbol(currency['code']!), style: TextStyles.blackBold16),
                );
              }).toList(),
            ),
          ),
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