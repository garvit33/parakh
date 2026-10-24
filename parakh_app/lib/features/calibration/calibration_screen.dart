import 'package:flutter/material.dart';

import '../../core/models/calibration_record.dart';
import '../../core/storage/calibration_storage.dart';
import '../../core/theme/parakh_colors.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final CalibrationStorage _storage = CalibrationStorage();

  List<CalibrationRecord> _records = [];
  bool _isLoading = true;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    final records = await _storage.getRecords();

    if (!mounted) return;

    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Calibration records', 'कैलिब्रेशन रिकॉर्ड'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ParakhColors.forestGreen,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: _records.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                            itemCount: _records.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildRecordCard(_records[index]);
                            },
                          ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.science_outlined, size: 68, color: Color(0xFF9BA79E)),
        const SizedBox(height: 18),
        Text(
          _text(
            'No calibration records yet',
            'अभी कोई कैलिब्रेशन रिकॉर्ड नहीं है',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF26372D),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _text(
            'Complete an NIR scan to create a pending record.',
            'लंबित रिकॉर्ड बनाने के लिए NIR स्कैन पूरा करें।',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7A847D), height: 1.4),
        ),
      ],
    );
  }

  Widget _labValueField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: '%',
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final parsed = double.tryParse(value?.trim() ?? '');

          if (parsed == null || parsed < 0 || parsed > 100) {
            return _text(
              'Enter a value from 0 to 100',
              '0 से 100 तक मान दर्ज करें',
            );
          }

          return null;
        },
      ),
    );
  }

  Future<void> _openLabEntry(CalibrationRecord record) async {
    final existing = record.referenceValues;
    final formKey = GlobalKey<FormState>();

    final laboratoryController = TextEditingController(
      text: record.laboratoryName ?? '',
    );
    final moistureController = TextEditingController(
      text: existing?.moisture.toString() ?? '',
    );
    final proteinController = TextEditingController(
      text: existing?.protein.toString() ?? '',
    );
    final fiberController = TextEditingController(
      text: existing?.fiber.toString() ?? '',
    );
    final fatController = TextEditingController(
      text: existing?.fat.toString() ?? '',
    );
    final ashController = TextEditingController(
      text: existing?.ash.toString() ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _text('Enter laboratory result', 'प्रयोगशाला परिणाम दर्ज करें'),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: laboratoryController,
                      decoration: InputDecoration(
                        labelText: _text(
                          'Laboratory name',
                          'प्रयोगशाला का नाम',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _text(
                            'Laboratory name is required',
                            'प्रयोगशाला का नाम आवश्यक है',
                          );
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _labValueField(
                      controller: moistureController,
                      label: _text('Moisture', 'नमी'),
                    ),
                    _labValueField(
                      controller: proteinController,
                      label: _text('Protein', 'प्रोटीन'),
                    ),
                    _labValueField(
                      controller: fiberController,
                      label: _text('Fibre', 'फाइबर'),
                    ),
                    _labValueField(
                      controller: fatController,
                      label: _text('Fat', 'वसा'),
                    ),
                    _labValueField(
                      controller: ashController,
                      label: _text('Ash', 'राख'),
                    ),
                    Text(
                      _text(
                        'Enter values exactly as reported by the reference laboratory.',
                        'मान संदर्भ प्रयोगशाला की रिपोर्ट के अनुसार ही दर्ज करें।',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF7A847D),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(_text('Cancel', 'रद्द करें')),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: ParakhColors.forestGreen,
              ),
              child: Text(_text('Save result', 'परिणाम सहेजें')),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      final updatedRecord = CalibrationRecord(
        id: record.id,
        reading: record.reading,
        referenceValues: NutritionValues(
          moisture: double.parse(moistureController.text.trim()),
          protein: double.parse(proteinController.text.trim()),
          fiber: double.parse(fiberController.text.trim()),
          fat: double.parse(fatController.text.trim()),
          ash: double.parse(ashController.text.trim()),
        ),
        calibrationVersion: record.calibrationVersion,
        status: CalibrationRecord.validatedStatus,
        laboratoryName: laboratoryController.text.trim(),
        createdAt: record.createdAt,
        validatedAt: DateTime.now(),
        notes: record.notes,
      );

      await _storage.saveRecord(updatedRecord);

      if (mounted) {
        await _loadRecords();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _text(
                  'Laboratory result saved.',
                  'प्रयोगशाला परिणाम सहेजा गया।',
                ),
              ),
              backgroundColor: ParakhColors.forestGreen,
            ),
          );
        }
      }
    }

    laboratoryController.dispose();
    moistureController.dispose();
    proteinController.dispose();
    fiberController.dispose();
    fatController.dispose();
    ashController.dispose();
  }

  Widget _comparisonRow({
    required String label,
    required double predicted,
    required double reference,
    required double errorPercent,
    bool isHeader = false,
  }) {
    final style = TextStyle(
      color: isHeader ? const Color(0xFF526159) : const Color(0xFF26372D),
      fontSize: isHeader ? 10 : 11,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: style)),
          Expanded(
            flex: 2,
            child: Text(
              isHeader
                  ? _text('Sensor', 'सेंसर')
                  : predicted.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isHeader ? _text('Lab', 'लैब') : reference.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isHeader
                  ? _text('Error', 'त्रुटि')
                  : '${errorPercent.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: style.copyWith(
                color: !isHeader && errorPercent > 10
                    ? const Color(0xFFB54435)
                    : style.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(CalibrationRecord record) {
    final reference = record.referenceValues;

    if (reference == null) {
      return const SizedBox.shrink();
    }

    final predicted = record.predictedValues;
    final errors = record.percentageErrors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        children: [
          _comparisonRow(
            label: _text('Nutrient', 'पोषक तत्व'),
            predicted: 0,
            reference: 0,
            errorPercent: 0,
            isHeader: true,
          ),
          const Divider(height: 12),
          _comparisonRow(
            label: _text('Moisture', 'नमी'),
            predicted: predicted.moisture,
            reference: reference.moisture,
            errorPercent: errors['moisture']!,
          ),
          _comparisonRow(
            label: _text('Protein', 'प्रोटीन'),
            predicted: predicted.protein,
            reference: reference.protein,
            errorPercent: errors['protein']!,
          ),
          _comparisonRow(
            label: _text('Fibre', 'फाइबर'),
            predicted: predicted.fiber,
            reference: reference.fiber,
            errorPercent: errors['fiber']!,
          ),
          _comparisonRow(
            label: _text('Fat', 'वसा'),
            predicted: predicted.fat,
            reference: reference.fat,
            errorPercent: errors['fat']!,
          ),
          _comparisonRow(
            label: _text('Ash', 'राख'),
            predicted: predicted.ash,
            reference: reference.ash,
            errorPercent: errors['ash']!,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(CalibrationRecord record) {
    final validated = record.isValidated;

    final statusColor = validated
        ? const Color(0xFF2F7650)
        : const Color(0xFF9A6815);

    final statusBackground = validated
        ? const Color(0xFFE3F1E6)
        : const Color(0xFFFFF1CF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.reading.sampleId,
                  style: const TextStyle(
                    color: Color(0xFF26372D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  validated
                      ? _text('Validated', 'सत्यापित')
                      : _text('Pending lab result', 'लैब परिणाम लंबित'),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.reading.feedType,
            style: const TextStyle(
              color: Color(0xFF4F5D53),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailChip(Icons.memory_rounded, record.reading.device),
              _detailChip(
                Icons.model_training_rounded,
                record.calibrationVersion,
              ),
              _detailChip(
                Icons.schedule_rounded,
                _formatDate(record.reading.receivedAt),
              ),
            ],
          ),
          if (record.isValidated) ...[
            const SizedBox(height: 14),
            _buildComparisonTable(record),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openLabEntry(record),
              icon: Icon(
                record.isValidated
                    ? Icons.edit_rounded
                    : Icons.add_chart_rounded,
              ),
              label: Text(
                record.isValidated
                    ? _text(
                        'Update laboratory result',
                        'प्रयोगशाला परिणाम अपडेट करें',
                      )
                    : _text(
                        'Add laboratory result',
                        'प्रयोगशाला परिणाम जोड़ें',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF607067)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607067),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
