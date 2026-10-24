import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/feed_test_result.dart';

class TestReportService {
  Future<Uint8List> buildReport(FeedTestResult result) async {
    final document = pw.Document(
      title: 'Parakh Feed Screening Report',
      author: 'Parakh',
      subject: 'Feed and silage screening result',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFF2F7650),
                width: 2,
              ),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PARAKH',
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF174D35),
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Feed Screening Report',
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF566158),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 20),
          pw.Text(
            result.feedType,
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF1B2B21),
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${result.testType} | ${_formatDate(result.createdAt)}',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _riskBackground(result.riskLevel),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Suitability score',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      '${result.score}/100',
                      style: pw.TextStyle(
                        fontSize: 27,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  '${result.riskLevel} RISK',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Sample and animal context'),
          _detailsTable([
            ['Report ID', result.id],
            ['Sample ID', result.sampleId],
            ['Batch ID', result.batchId],
            ['Feed type', result.feedType],
            ['Animal', '${result.animalType} - ${result.animalBreed}'],
            ['Production goal', result.productionGoal],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Screening result'),
          _detailsTable([
            ['Estimated pH', result.phValue.toStringAsFixed(1)],
            ['Nutrition status', result.nutritionStatus],
            ['Impurity status', result.impurityStatus],
            if (result.moisture != null)
              ['Moisture', '${result.moisture!.toStringAsFixed(1)}%'],
            if (result.protein != null)
              ['Protein', '${result.protein!.toStringAsFixed(1)}%'],
            if (result.fiber != null)
              ['Fibre', '${result.fiber!.toStringAsFixed(1)}%'],
            if (result.fat != null)
              ['Fat', '${result.fat!.toStringAsFixed(1)}%'],
            if (result.ash != null)
              ['Ash', '${result.ash!.toStringAsFixed(1)}%'],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Traceability'),
          _detailsTable([
            ['Data source', result.dataSource],
            ['Device', result.deviceId],
            ['Firmware', result.firmwareVersion],
            ['Calibration/model', result.calibrationVersion],
            [
              'Validation',
              result.isLaboratoryValidated
                  ? 'Laboratory validated'
                  : 'Screening only',
            ],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Recommendation'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF7DF),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              result.recommendationEnglish,
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF735B2E),
                fontSize: 11,
                lineSpacing: 3,
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFBE8E4),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              result.disclaimerEnglish,
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xFF8F352C),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<void> shareReport(FeedTestResult result) async {
    final bytes = await buildReport(result);
    final safeId = result.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'parakh_report_$safeId.pdf',
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: const PdfColor.fromInt(0xFF174D35),
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _detailsTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(9),
              color: PdfColors.grey100,
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(9),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        );
      }).toList(),
    );
  }

  PdfColor _riskBackground(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
        return const PdfColor.fromInt(0xFFFBE8E4);
      case 'MEDIUM':
        return const PdfColor.fromInt(0xFFFFF1CF);
      default:
        return const PdfColor.fromInt(0xFFE3F1E6);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }
}
