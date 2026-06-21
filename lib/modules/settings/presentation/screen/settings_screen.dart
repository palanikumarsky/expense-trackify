import 'package:expensetrackify/modules/dao/category_dao.dart';
import 'package:expensetrackify/modules/dao/mode_dao.dart';
import 'package:expensetrackify/modules/dao/transaction_dao.dart';
import 'package:expensetrackify/modules/profile/presentation/screen/accounts_screen.dart';
import 'package:expensetrackify/modules/profile/presentation/screen/profile_screen.dart';
import 'package:expensetrackify/modules/settings/presentation/screen/currency_screen.dart';
import 'package:expensetrackify/modules/settings/presentation/screen/pdf_viewer_screen.dart';
import 'package:expensetrackify/utils/date_time_helper.dart';
import 'package:expensetrackify/utils/pref.dart';
import 'package:flutter/material.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:expensetrackify/constants/styles.dart';
import 'package:expensetrackify/modules/settings/presentation/screen/modes_screen.dart';
import 'package:expensetrackify/modules/settings/presentation/screen/categories_screen.dart';
import 'package:expensetrackify/config/database_config/database_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:expensetrackify/utils/transaction_helper.dart';
import 'package:expensetrackify/modules/dao/user_dao.dart';
import 'package:expensetrackify/utils/sync_event_bus.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ModeDao _modeDao = ModeDao(appDatabase);
  final CategoryDao _categoryDao = CategoryDao(appDatabase);
  final TransactionDao _transactionDao = TransactionDao(appDatabase);
  final UserDao _userDao = UserDao(appDatabase);
  List<dynamic> _modes = [];
  List<dynamic> _categories = [];
  StreamSubscription? _syncSubscription;
  String buildNumber = "";
  String versionNumber = "";

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSyncListener();
  }

  void _setupSyncListener() {
    _syncSubscription = SyncEventBus().onSync.listen((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final modes = await _modeDao.getModes();
    final categories = await _categoryDao.getCategories();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;
    setState(() {
      _modes = modes;
      _categories = categories;
      versionNumber = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  Future<Uint8List> _generatePdf(
    List<TransactionWithDetails> transactions,
  ) async {
    // Fetch user info for invoice header
    String userName = 'User';
    String userEmail = '';
    try {
      final email = await Prefs.getUserEmail;
      if (email != null && email.isNotEmpty) {
        final user = await _userDao.getUserByEmail(email);
        if (user != null) {
          userName = user.name;
          userEmail = user.emailId;
        }
      }
    } catch (_) {}

    final totalAmount = transactions.fold<double>(0.0, (sum, tx) => sum + tx.transaction.amount);
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Invoice Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppConstants.expenseTrackifyInvoice, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(AppConstants.generatedFor, style: pw.TextStyle(fontSize: 12)),
                      pw.Text(userName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      if (userEmail.isNotEmpty) pw.Text(userEmail, style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("${AppConstants.date}:${DateFormat('yyyy-MM-dd').format(DateTime.now())}", style: pw.TextStyle(fontSize: 12)),
                      pw.Text(AppConstants.invoice + DateTime.now().millisecondsSinceEpoch.toString(), style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),
              // Table
              pw.Table.fromTextArray(
                headers: [
                  AppConstants.date,
                  AppConstants.mode,
                  AppConstants.category,
                  AppConstants.description,
                  AppConstants.amount,
                ],
                data: transactions.map((tx) => [
                  DateTimeHelper().formatDate(DateTime.parse(tx.transaction.date)),
                  tx.mode?.name ?? '',
                  tx.category?.name ?? '',
                  tx.transaction.description,
                  tx.transaction.amount.toStringAsFixed(2),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: pw.TextStyle(fontSize: 11),
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              ),
              pw.SizedBox(height: 16),
              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(AppConstants.total, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                        pw.Text(totalAmount.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _clearAllData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Use the centralized database service to clear all data
      await DatabaseService.clearAllData();
      
      // Clear sync timestamp
      await Prefs.clearLastSyncTimestamp();
      
      // Initialize default data after clearing
      await _initializeDefaultData();
      
      // Reload data after clearing
      await _loadData();
      
      // Notify other parts of the app about data clearing
      SyncEventBus().notifySync();
      
      // Close loading dialog and show success message
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.allDataClearedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      // Close loading dialog and show error message
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      print('Error clearing data: $error');
    }
  }

  Future<void> _initializeDefaultData() async {
    try {
      // Initialize default payment modes
      await _initializeDefaultModes();
      
      // Initialize default categories
      await _initializeDefaultCategories();
      
    } catch (error) {
      print('Error initializing default data: $error');
    }
  }

  Future<void> _initializeDefaultModes() async {
    try {
      // Get existing modes
      final existingModes = await _modeDao.getModes();
      
      // Define default modes
      final defaultModes = AppConstants.defaultModes;
      
      // Check which default modes are missing
      final existingModeNames = existingModes.map((mode) => mode.name).toList();
      final missingModes = defaultModes.where((mode) => !existingModeNames.contains(mode)).toList();
      
      // Add missing modes
      for (final modeName in missingModes) {
        await _modeDao.createMode(ModesCompanion.insert(name: modeName));
        print('Added default mode: $modeName');
      }
      
      if (missingModes.isNotEmpty) {
        print('Initialized ${missingModes.length} default payment modes');
      }
    } catch (error) {
      print('Error initializing default modes: $error');
    }
  }

  Future<void> _initializeDefaultCategories() async {
    try {
      // Get existing categories
      final existingCategories = await _categoryDao.getCategories();
      
      // Define default categories
      final defaultCategories = AppConstants.defaultCategories;
      
      // Check which default categories are missing
      final existingCategoryNames = existingCategories.map((category) => category.name).toList();
      final missingCategories = defaultCategories.where((category) => !existingCategoryNames.contains(category)).toList();
      
      // Add missing categories
      for (final categoryName in missingCategories) {
        await _categoryDao.createCategory(CategoriesCompanion.insert(name: categoryName));
        print('Added default category: $categoryName');
      }
      
      if (missingCategories.isNotEmpty) {
        print('Initialized ${missingCategories.length} default categories');
      }
    } catch (error) {
      print('Error initializing default categories: $error');
    }
  }

  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        } else {
          return true; // fallback to app-specific dir
        }
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(AppConstants.storagePermissionRequired),
                  content: Text(
                    AppConstants.storagePermissionDeniedMessage,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(AppConstants.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(AppConstants.openSettings),
                    ),
                  ],
                ),
          );
          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
          return false;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppConstants.storagePermissionNeeded,
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return false;
        }
      }
    } else {
      return true;
    }
  }

  String _formatSmartDateRange(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final sameMonth = start.year == end.year && start.month == end.month;
    final sameYear = start.year == end.year;
    if (sameDay) {
      return DateFormat('MMMM d, yyyy').format(start);
    } else if (sameMonth) {
      return '${DateFormat('MMMM d').format(start)}–${DateFormat('d, yyyy').format(end)}';
    } else if (sameYear) {
      return '${DateFormat('MMMM d').format(start)} – ${DateFormat('MMMM d, yyyy').format(end)}';
    } else {
      return '${DateFormat('MMM d, yyyy').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
    }
  }

  void _showDateRangeDownloadSheet(BuildContext parentContext) async {
    final modes = await _modeDao.getModes();
    String? selectedModeId; // null = ALL payment modes
    String selectedDuration = AppConstants.last30Days;
    DateTimeRange? customRange;
    DateTime? singleDay;
    String fileFormat = AppConstants.pdf;
    final durationOptions = [
      AppConstants.last30Days,
      AppConstants.thisWeek,
      AppConstants.thisMonth,
      AppConstants.thisYear,
      AppConstants.singleDay,
      AppConstants.customRange,
    ];
    final fileFormatOptions = [AppConstants.pdf, AppConstants.csv];
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickSingleDay() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setModalState(() {
                    singleDay = picked;
                  });
                }
              }

              Future<void> pickCustomRange() async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  initialDateRange:
                      customRange ??
                      DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 7)),
                        end: DateTime.now(),
                      ),
                );
                if (picked != null) {
                  setModalState(() {
                    customRange = picked;
                  });
                }
              }

              DateTimeRange? getSelectedRange() {
                final now = DateTime.now();
                switch (selectedDuration) {
                  case AppConstants.last30Days:
                    return DateTimeRange(
                      start: now.subtract(const Duration(days: 29)),
                      end: now,
                    );
                  case AppConstants.thisWeek:
                    final start = now.subtract(Duration(days: now.weekday - 1));
                    final end = start.add(const Duration(days: 6));
                    return DateTimeRange(start: start, end: end);
                  case AppConstants.thisMonth:
                    final start = DateTime(now.year, now.month, 1);
                    final end = DateTime(now.year, now.month + 1, 0);
                    return DateTimeRange(start: start, end: end);
                  case AppConstants.thisYear:
                    final start = DateTime(now.year, 1, 1);
                    final end = DateTime(now.year, 12, 31);
                    return DateTimeRange(start: start, end: end);
                  case AppConstants.singleDay:
                    if (singleDay != null) {
                      return DateTimeRange(start: singleDay!, end: singleDay!);
                    }
                    return null;
                  case AppConstants.customRange:
                    return customRange;
                  default:
                    return null;
                }
              }

              final selectedRange = getSelectedRange();
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            AppConstants.downloadTransactionsTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.mode,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedModeId,
                          isExpanded: true,
                          hint: Text(AppConstants.selectMode),
                          items: [
                            // Add "ALL" option at the top
                            DropdownMenuItem<String>(
                              value: null, // null value means "ALL"
                              child: Text(
                                AppConstants.allModes,
                              ),
                            ),
                            // Add existing modes
                            ...modes.map<DropdownMenuItem<String>>((mode) {
                              return DropdownMenuItem<String>(
                                value: mode.id.toString(),
                                child: Text(mode.name),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              selectedModeId = val;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.duration,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedDuration,
                          isExpanded: true,
                          items:
                              durationOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedDuration = val!;
                              // Reset pickers if switching
                              if (val == AppConstants.singleDay) singleDay = null;
                              if (val == AppConstants.customRange) customRange = null;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (selectedDuration == AppConstants.singleDay)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.today,
                                color: Colors.deepPurple,
                              ),
                              label: Text(
                                singleDay == null
                                    ? AppConstants.pickADay
                                    : DateFormat(
                                      'MMMM d, yyyy',
                                    ).format(singleDay!),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.deepPurple,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: pickSingleDay,
                            ),
                          ),
                        if (selectedDuration == AppConstants.customRange)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.date_range,
                                color: Colors.deepPurple,
                              ),
                              label: Text(
                                customRange == null
                                    ? AppConstants.pickDateRange
                                    : _formatSmartDateRange(customRange!),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.deepPurple,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: pickCustomRange,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (selectedRange != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatSmartDateRange(selectedRange),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Text(AppConstants.fileFormat, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: fileFormatOptions.map((format) {
                            return Expanded(
                              child: RadioListTile<String>(
                                value: format,
                                groupValue: fileFormat,
                                title: Text(format),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (val) {
                                  setModalState(() {
                                    fileFormat = val!;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.deepPurple),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  AppConstants.cancel,
                                  style: const TextStyle(color: Colors.deepPurple),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    (selectedRange != null && (selectedDuration != AppConstants.singleDay || singleDay != null) && (selectedDuration != AppConstants.customRange || customRange != null))
                                        ? () async {
                                            Navigator.of(context).pop();
                                            await _downloadWithFormat(parentContext, selectedRange, selectedModeId, fileFormat);
                                          }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.deepPurpleColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(AppConstants.download),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _downloadWithFormat(BuildContext parentContext, DateTimeRange range, String? modeId, String fileFormat) async {
    if (fileFormat == AppConstants.pdf) {
      await _downloadPdfWithRange(parentContext, range, modeId);
    } else if (fileFormat == AppConstants.csv) {
      await _downloadCsvWithRange(parentContext, range, modeId);
    }
  }

  Future<void> _downloadPdfWithRange(
    BuildContext parentContext,
    DateTimeRange range,
    String? modeId,
  ) async {
    try {
      if (!await _requestStoragePermission(parentContext)) {
        return;
      }
      final allTransactions = await _transactionDao.getTransactions();
      final filtered =
          allTransactions.where((tx) {
            final date = DateTime.parse(tx.transaction.date);
            final modeMatch =
                modeId == null || tx.mode?.id.toString() == modeId;
            return !date.isBefore(range.start) &&
                !date.isAfter(range.end) &&
                modeMatch;
          }).toList();
      if (filtered.isEmpty) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text(AppConstants.noTransactionsFoundInSelectedRange),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final pdfData = await _generatePdf(filtered);
      String downloadPath = '';
      bool useDownloadsFolder = false;
      if (!kIsWeb && Platform.isAndroid) {
        final manageStorageStatus =
            await Permission.manageExternalStorage.status;
        if (manageStorageStatus.isGranted) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final downloadsPath =
                '${externalDir.path.split('Android')[0]}Download';
            final appDir = Directory('$downloadsPath/ExpenseTrackify');
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
            downloadPath = appDir.path;
            useDownloadsFolder = true;
          }
        }
        if (downloadPath == '') {
          final appDir = await getApplicationDocumentsDirectory();
          final expenseDir = Directory('${appDir.path}/ExpenseTrackify');
          if (!await expenseDir.exists()) {
            await expenseDir.create(recursive: true);
          }
          downloadPath = expenseDir.path;
          useDownloadsFolder = false;
        }
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        downloadPath = documentsDir.path;
        useDownloadsFolder = false;
      }
      if (downloadPath.isEmpty) {
        throw Exception(AppConstants.couldNotGetDownloadDirectory);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'transactions_$timestamp.pdf';
      final file = File('$downloadPath/$fileName');
      await file.writeAsBytes(pdfData);
      final locationMessage =
          useDownloadsFolder
              ? AppConstants.pdfSavedToDownloads
              : AppConstants.pdfSavedToAppDirectory;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('$locationMessage: $fileName'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: AppConstants.open,
            onPressed: () {
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(filePath: file.path),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.errorDownloadingPDF}$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadCsvWithRange(BuildContext parentContext, DateTimeRange range, String? modeId) async {
    try {
      if (!await _requestStoragePermission(parentContext)) {
        return;
      }
      final allTransactions = await _transactionDao.getTransactions();
      final filtered = allTransactions.where((tx) {
        final date = DateTime.parse(tx.transaction.date);
        final modeMatch = modeId == null || tx.mode?.id.toString() == modeId;
        return !date.isBefore(range.start) && !date.isAfter(range.end) && modeMatch;
      }).toList();
      if (filtered.isEmpty) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text(AppConstants.noTransactionsFoundInSelectedRange),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Date,Mode,Category,Description,Amount');
      for (final tx in filtered) {
        csvBuffer.writeln('"${DateTimeHelper().formatDate(DateTime.parse(tx.transaction.date))}","${tx.mode?.name ?? ''}","${tx.category?.name ?? ''}","${tx.transaction.description}","${tx.transaction.amount.toStringAsFixed(2)}"');
      }
      String downloadPath = '';
      bool useDownloadsFolder = false;
      if (!kIsWeb && Platform.isAndroid) {
        final manageStorageStatus = await Permission.manageExternalStorage.status;
        if (manageStorageStatus.isGranted) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final downloadsPath = '${externalDir.path.split('Android')[0]}Download';
            final appDir = Directory('$downloadsPath/ExpenseTrackify');
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
            downloadPath = appDir.path;
            useDownloadsFolder = true;
          }
        }
        if (downloadPath == '') {
          final appDir = await getApplicationDocumentsDirectory();
          final expenseDir = Directory('${appDir.path}/ExpenseTrackify');
          if (!await expenseDir.exists()) {
            await expenseDir.create(recursive: true);
          }
          downloadPath = expenseDir.path;
          useDownloadsFolder = false;
        }
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        downloadPath = documentsDir.path;
        useDownloadsFolder = false;
      }
      if (downloadPath.isEmpty) {
        throw Exception(AppConstants.couldNotGetDownloadDirectory);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'transactions_$timestamp.csv';
      final file = File('$downloadPath/$fileName');
      await file.writeAsString(csvBuffer.toString());
      final locationMessage = useDownloadsFolder
          ? AppConstants.csvSavedToDownloads
          : AppConstants.csvSavedToAppDirectory;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('$locationMessage: $fileName'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: AppConstants.open,
            onPressed: () async {
              await Share.shareXFiles([XFile(file.path)], text: AppConstants.transactionReport);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('${AppConstants.errorDownloadingCSV}$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.settings, style: TextStyles.whiteBold20),
        centerTitle: true,
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            title: AppConstants.accountManagement,
            children: [
              _buildSettingsTile(
                icon: Icons.person,
                title: AppConstants.profile,
                subtitle: AppConstants.manageProfilePreferences,
                onTap: () {
                  // TODO: Navigate to notifications settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.manage_accounts,
                title: AppConstants.account,
                subtitle: AppConstants.manageAccountPreferences,
                onTap: () {
                  // TODO: Navigate to notifications settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const AccountsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: AppConstants.dataManagement,
            children: [
              _buildSettingsTile(
                icon: Icons.download,
                title: AppConstants.downloadTransactions,
                subtitle: AppConstants.exportAllTransactions,
                onTap: () async {
                  final allTransactions = await _transactionDao.getTransactions();
                  if (allTransactions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppConstants.noTransactionsAvailableToDownload),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    _showDateRangeDownloadSheet(context);
                  }
                },
              ),
              _buildSettingsTile(
                icon: Icons.account_balance_wallet,
                title: AppConstants.paymentModesTitle,
                subtitle: '${_modes.length} ${AppConstants.modesConfigured}',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModesScreen(),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
              _buildSettingsTile(
                icon: Icons.category,
                title: AppConstants.categoriesTitle,
                // subtitle: "",
                subtitle: '${_categories.length} ${AppConstants.categoriesConfigured}',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: Prefs.currencyCodeNotifier,
                builder: (context, currencyCode, _) {
                  final currencySymbol = TransactionHelper.getCurrencySymbol(currencyCode);
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.deepPurpleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.attach_money, color: AppColors.deepPurpleColor, size: 20),
                    ),
                    title: Text(AppConstants.currency, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    subtitle: Text('$currencySymbol  ($currencyCode)'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CurrencyScreen()),
                      );
                      if (result != null) {
                        // No need to reload, ValueListenableBuilder will update
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // _buildSettingsSection(
          //   title: AppConstants.general,
          //   children: [
          //     _buildSettingsTile(
          //       icon: Icons.notifications,
          //       title: AppConstants.notifications,
          //       subtitle: AppConstants.manageNotificationPreferences,
          //       onTap: () {
          //         // TODO: Navigate to notifications settings
          //       },
          //     ),
          //     ValueListenableBuilder<ThemeMode>(
          //       valueListenable: Prefs.themeModeNotifier,
          //       builder: (context, themeMode, _) {
          //         final isDark = themeMode == ThemeMode.dark;
          //         return ListTile(
          //           leading: Container(
          //             padding: const EdgeInsets.all(8),
          //             decoration: BoxDecoration(
          //               color: AppColors.deepPurpleColor.withOpacity(0.1),
          //               borderRadius: BorderRadius.circular(8),
          //             ),
          //             child: Icon(
          //               isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
          //               color: AppColors.deepPurpleColor,
          //               size: 20,
          //             ),
          //           ),
          //           title: Text(
          //             AppConstants.darkTheme,
          //             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          //           ),
          //           subtitle: Text(
          //             isDark
          //               ? AppConstants.willAlwaysUseDarkTheme
          //               : AppConstants.willNeverTurnOnAutomatically,
          //             style: TextStyle(color: Colors.grey[600]),
          //           ),
          //           trailing: Switch(
          //             value: isDark,
          //             activeColor: AppColors.deepPurpleColor,
          //             onChanged: (val) {
          //               Prefs.setTheme(val ? ThemeMode.dark : ThemeMode.light);
          //             },
          //           ),
          //         );
          //       },
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),
          _buildSettingsSection(
            title: AppConstants.dataAndPrivacy,
            children: [
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: AppConstants.clearData,
                subtitle: AppConstants.deleteAllAppData,
                onTap: () {
                  _showClearDataDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingsSection(
            title: AppConstants.general,
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: AppConstants.appVersion,
                subtitle: "$versionNumber ($buildNumber)",
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyles.deepPurpleSemiBold16,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.deepPurpleColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.deepPurpleColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyles.blackMedium16,
        // style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyles.greyMedium14,
        // style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing:
          onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey[400])
              : null,
      onTap: onTap,
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
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
                Text(
                  "Are you sure?",
                  style: TextStyles.blackBold18
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.clearAllDataConfirmation,
                  style: TextStyles.greyMedium14,
                ),
                const SizedBox(height: 30),

                /// Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black26),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppConstants.cancel,
                          style: TextStyles.blackBold12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _clearAllData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepPurpleColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppConstants.clear,
                          style: TextStyles.whiteBold12,),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
