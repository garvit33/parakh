import 'package:flutter/material.dart';

import '../../core/models/feed_test_result.dart';
import '../../core/storage/test_history_storage.dart';
import '../../core/theme/parakh_colors.dart';
import '../../core/services/test_report_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TestHistoryStorage _storage = TestHistoryStorage();
  final TestReportService _reportService = TestReportService();

  bool _isLoading = true;
  List<FeedTestResult> _results = [];

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final results = await _storage.getResults();

    if (!mounted) return;

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  Future<void> _deleteResult(FeedTestResult result) async {
    await _storage.deleteResult(result.id);
    await _loadResults();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_text('Test deleted', 'जाँच हटाई गई'))),
    );
  }

  Future<void> _confirmClearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_text('Clear history?', 'इतिहास हटाएँ?')),
          content: Text(
            _text(
              'All saved offline test results will be removed.',
              'सभी सुरक्षित ऑफलाइन जाँच परिणाम हटा दिए जाएँगे।',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_text('Cancel', 'रद्द करें')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB75B4A),
              ),
              child: Text(_text('Clear', 'हटाएँ')),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await _storage.clearHistory();
    await _loadResults();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Test History', 'जाँच इतिहास'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              tooltip: _text('Clear history', 'इतिहास हटाएँ'),
              onPressed: _confirmClearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ParakhColors.forestGreen),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyHistory();
    }

    return RefreshIndicator(
      onRefresh: _loadResults,
      color: ParakhColors.forestGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        itemCount: _results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 13),
        itemBuilder: (context, index) {
          return _buildResultCard(_results[index]);
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: const BoxDecoration(
                color: Color(0xFFE3EEE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 49,
                color: ParakhColors.forestGreen,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _text('No saved tests yet', 'अभी कोई सुरक्षित जाँच नहीं है'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B2B21),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _text(
                'Complete a feed test and save it offline to view it here.',
                'चारे की जाँच पूरी करके उसे ऑफलाइन सुरक्षित करें। वह यहाँ दिखाई देगी।',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF768078),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(FeedTestResult result) {
    final isLowRisk = result.riskLevel == 'LOW';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: () => _showResultDetails(result),
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE0E8DD)),
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLowRisk
                      ? const Color(0xFFE3F1E6)
                      : const Color(0xFFFFECE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${result.score}',
                  style: TextStyle(
                    color: isLowRisk
                        ? const Color(0xFF32834C)
                        : const Color(0xFFB75B4A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.feedType,
                      style: const TextStyle(
                        color: Color(0xFF26342B),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(result.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF7B847D),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${result.testType} • ${result.riskLevel} RISK',
                      style: TextStyle(
                        color: isLowRisk
                            ? const Color(0xFF32834C)
                            : const Color(0xFFB75B4A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _text('Delete', 'हटाएँ'),
                onPressed: () => _deleteResult(result),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF9A6A60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareReport(FeedTestResult result) async {
    try {
      await _reportService.shareReport(result);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Could not create the PDF report.',
              'PDF रिपोर्ट नहीं बनाई जा सकी।',
            ),
          ),
          backgroundColor: const Color(0xFFB75B4A),
        ),
      );
    }
  }

  void _showResultDetails(FeedTestResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6CEC7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    result.feedType,
                    style: const TextStyle(
                      color: Color(0xFF1B2B21),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(result.createdAt),
                    style: const TextStyle(color: Color(0xFF768078)),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(
                    _text('FeedGuard score', 'फीडगार्ड स्कोर'),
                    '${result.score}/100',
                  ),
                  _detailRow(
                    _text('Risk level', 'जोखिम स्तर'),
                    result.riskLevel,
                  ),
                  _detailRow(
                    _text('Estimated pH', 'अनुमानित pH'),
                    result.phValue.toStringAsFixed(1),
                  ),
                  _detailRow(
                    _text('Nutrition', 'पोषण'),
                    result.nutritionStatus,
                  ),
                  _detailRow(
                    _text('Impurities', 'अशुद्धियाँ'),
                    result.impurityStatus,
                  ),
                  _detailRow(_text('Sample ID', 'नमूना आईडी'), result.sampleId),
                  _detailRow(
                    _text('Animal', 'पशु'),
                    '${result.animalType} • ${result.animalBreed}',
                  ),
                  _detailRow(
                    _text('Production goal', 'उत्पादन लक्ष्य'),
                    result.productionGoal,
                  ),
                  _detailRow(
                    _text('Data source', 'डेटा स्रोत'),
                    result.dataSource,
                  ),
                  _detailRow(_text('Device', 'डिवाइस'), result.deviceId),
                  _detailRow(
                    _text('Calibration', 'कैलिब्रेशन'),
                    result.calibrationVersion,
                  ),
                  _detailRow(
                    _text('Validation', 'सत्यापन'),
                    result.isLaboratoryValidated
                        ? _text(
                            'Laboratory validated',
                            'प्रयोगशाला द्वारा सत्यापित',
                          )
                        : _text('Screening only', 'केवल स्क्रीनिंग'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => _shareReport(result),
                      style: FilledButton.styleFrom(
                        backgroundColor: ParakhColors.forestGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(
                        _text('Share PDF report', 'PDF रिपोर्ट साझा करें'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7DF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.isHindi
                          ? result.recommendationHindi
                          : result.recommendationEnglish,
                      style: const TextStyle(
                        color: Color(0xFF735B2E),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667169),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF26342B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
