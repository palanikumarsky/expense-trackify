import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.pdfViewer),
        backgroundColor: AppColors.deepPurpleColor,
        foregroundColor: Colors.white,
      ),
      body: PdfView(
        controller: _pdfController,
      ),
    );
  }
}
