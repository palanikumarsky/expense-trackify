import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/modules/home/widgets/category_pie_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:expensetrackify/utils/pref.dart';

class SummaryView extends StatefulWidget {
  final List<TransactionWithDetails> transactions;
  const SummaryView({required this.transactions, super.key});

  @override
  State<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  List<String> _allModes = [];
  final ModeDao _modeDao = ModeDao(appDatabase);
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final GlobalKey _gridViewRepaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchModes();
  }

  Future<void> _fetchModes() async {
    final modes = await _modeDao.getModes();
    setState(() {
      _allModes = modes.map((m) => m.name).toList();
    });
  }



  Future<void> _shareSpendingByModeCard(BuildContext context) async {
    // Capture the context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Wait for the widget to be fully rendered and ensure proper layout
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check if the widget is mounted and has a valid context
      if (!mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Widget not mounted')),
        );
        return;
      }
      
      // Ensure the RepaintBoundary key has a valid context
      if (_gridViewRepaintBoundaryKey.currentContext == null) {
        // Try to rebuild the widget and wait a bit more
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (_gridViewRepaintBoundaryKey.currentContext == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('GridView not ready for capture. Please try again.')),
          );
          return;
        }
      }
      
      // Find the render object for the GridView
      final RenderObject? renderObject = _gridViewRepaintBoundaryKey.currentContext!.findRenderObject();
      
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Unable to capture GridView')),
        );
        return;
      }
      
      // Wait for any pending paint operations to complete
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Capture the GridView as image
          ui.Image image = await renderObject.toImage(pixelRatio: 2.0);
          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          
          if (byteData == null) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Failed to capture image')),
            );
            return;
          }

          // Get temporary directory and save image
          final directory = await getTemporaryDirectory();
          final imagePath = '${directory.path}/payment_modes_grid_${DateTime.now().millisecondsSinceEpoch}.png';
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(byteData.buffer.asUint8List());

          // Share the image
          await Share.shareXFiles([XFile(imagePath)], text: 'My Payment Modes Grid');
          
          // Clean up the temporary file
          await imageFile.delete();
          
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error sharing image: $e')),
          );
        }
      });
      
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error sharing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = widget.transactions;
    if (transactions.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.summarize,
            size: 80,
            color: AppColors.deepPurpleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noTransactionsFound,
            style: TextStyles.deepPurpleBold18,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              AppConstants.addTransactionToSeeSummary,
              style: TextStyles.deepPurpleMedium16.copyWith(
                color: AppColors.deepPurpleColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final totalSpend = transactions.fold(0.0, (sum, tx) => sum + tx.transaction.amount);
    final modeTotals = _modeTotals(transactions);

    return ValueListenableBuilder<String>(
      valueListenable: Prefs.currencyCodeNotifier,
      builder: (context, currencyCode, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20,),
              // Total Spend Card
              Container(
                width: MediaQuery.of(context).size.width * 0.75,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF6A11CB), // purple
                      Color(0xFF2575FC), // blue
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurpleColor,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Spending',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${TransactionHelper.getCurrencySymbol(currencyCode)}${totalSpend.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Spending by Mode Card
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.deepPurpleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.payment,
                                    color: AppColors.deepPurpleColor,
                                    size: 20,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  'Spending by Mode',
                                  style: TextStyles.deepPurpleBold14.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.deepPurpleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.share, color: AppColors.deepPurpleColor),
                                tooltip: 'Share Grid as Image',
                                onPressed: () => _shareSpendingByModeCard(context),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      if (_allModes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payment,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'No payment modes available.',
                                style: TextStyles.deepPurpleMedium14.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Mode cards in a grid layout
                      RepaintBoundary(
                        key: _gridViewRepaintBoundaryKey,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 40,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.0,
                          ),
                          itemCount: _allModes.length,
                          itemBuilder: (context, index) {
                          final mode = _allModes[index];
                          final amount = modeTotals[mode] ?? 0.0;
                          final totalModeSpending = modeTotals.values.fold(0.0, (sum, val) => sum + val);
                          final percentage = totalModeSpending > 0 ? (amount / totalModeSpending * 100) : 0.0;
                          
                          // Generate different colors for each mode
                          final colors = [
                            [Colors.blue[600]!, Colors.blue[700]!],
                            [Colors.red[600]!, Colors.red[700]!],
                            [Colors.green[600]!, Colors.green[700]!],
                            [Colors.orange[600]!, Colors.orange[700]!],
                            [Colors.purple[600]!, Colors.purple[700]!],
                            [Colors.teal[600]!, Colors.teal[700]!],
                            [Colors.indigo[600]!, Colors.indigo[700]!],
                            [Colors.pink[600]!, Colors.pink[700]!],
                          ];
                          
                          final colorPair = colors[index % colors.length];
                          
                          return Container(
                            // height: 100,
                            decoration: BoxDecoration(
                              // color: AppColors.deepPurpleColor.withOpacity(0.6),
                              // gradient: LinearGradient(
                              //   // colors: colorPair,
                              //   colors: [
                              //     AppColors.deepPurpleColor,
                              //     AppColors.deepPurpleColor.withOpacity(0.8),
                              //   ],
                              //   begin: Alignment.topLeft,
                              //   end: Alignment.bottomRight,
                              // ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorPair[1]
                              )
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: AppColors.deepPurpleColor.withOpacity(0.8),
                              //     blurRadius: 8,
                              //     offset: const Offset(0, 4),
                              //   ),
                              // ],
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Mode name
                                    Text(
                                      mode,
                                      style: TextStyle(
                                        color:  Colors.black54 ,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // Amount
                                    Text(
                                      '${TransactionHelper.getCurrencySymbol(currencyCode)}${amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: (amount>0) ? colorPair[0] : Colors.black54 ,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // // Percentage (small text)
                                    // if (percentage > 0)
                                    //   Text(
                                    //     '${percentage.toStringAsFixed(1)}%',
                                    //     style: TextStyle(
                                    //       color: Colors.white.withOpacity(0.8),
                                    //       fontSize: 12,
                                    //       fontWeight: FontWeight.w500,
                                    //     ),
                                    //   ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ),
                    ],
                  ),
                ),
              ),
              // Spending by Category Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending by Category',
                        style: TextStyles.deepPurpleBold14,
                      ),
                      const SizedBox(height: 8),
                      ..._categoryTotals(transactions).entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyles.deepPurpleBold12,
                              ),
                              Text(
                                '${TransactionHelper.getCurrencySymbol(currencyCode)}${entry.value.toStringAsFixed(2)}',
                                style: TextStyles.deepPurpleBold12,
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CategoryPieChart(transactions: transactions),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Map<String, double> _categoryTotals(List<TransactionWithDetails> transactions) {
  final Map<String, double> totals = {};
  for (final tx in transactions) {
    final categoryName = tx.category?.name ?? 'Unknown';
    totals.update(
      categoryName,
      (value) => value + tx.transaction.amount,
      ifAbsent: () => tx.transaction.amount,
    );
  }
  return totals;
}

  Map<String, double> _modeTotals(List<TransactionWithDetails> transactions) {
    final Map<String, double> totals = {};
    for (final tx in transactions) {
      final modeName = tx.mode?.name ?? 'Unknown';
      totals.update(
        modeName,
        (value) => value + tx.transaction.amount,
        ifAbsent: () => tx.transaction.amount,
      );
    }
    return totals;
  }

  IconData _getModeIcon(String modeName) {
    switch (modeName.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'credit card':
      case 'creditcard':
        return Icons.credit_card;
      case 'debit card':
      case 'debitcard':
        return Icons.credit_card;
      case 'upi':
        return Icons.phone_android;
      case 'netbanking':
      case 'net banking':
        return Icons.account_balance;
      case 'paypal':
        return Icons.payment;
      case 'apple pay':
        return Icons.apple;
      case 'google pay':
        return Icons.g_mobiledata;
      case 'phonepe':
        return Icons.phone_android;
      case 'paytm':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }
