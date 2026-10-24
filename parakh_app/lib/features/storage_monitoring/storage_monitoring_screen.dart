import 'package:flutter/material.dart';

import '../../core/theme/parakh_colors.dart';

class StorageMonitoringScreen extends StatefulWidget {
  const StorageMonitoringScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<StorageMonitoringScreen> createState() =>
      _StorageMonitoringScreenState();
}

class _StorageMonitoringScreenState extends State<StorageMonitoringScreen> {
  final _batchController = TextEditingController();
  final _moistureController = TextEditingController(text: '66');
  final _phController = TextEditingController(text: '4.2');
  final _temperatureController = TextEditingController(text: '27');
  final _storageDaysController = TextEditingController(text: '7');

  String _selectedFeed = 'Maize Silage';
  bool _visibleMould = false;
  bool _unusualSmell = false;
  bool _heatingObserved = false;
  bool _showResult = false;

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  @override
  void dispose() {
    _batchController.dispose();
    _moistureController.dispose();
    _phController.dispose();
    _temperatureController.dispose();
    _storageDaysController.dispose();
    super.dispose();
  }

  void _analyseStorage() {
    final moisture = double.tryParse(_moistureController.text.trim());
    final ph = double.tryParse(_phController.text.trim());
    final temperature = double.tryParse(_temperatureController.text.trim());
    final storageDays = int.tryParse(_storageDaysController.text.trim());

    if (moisture == null ||
        ph == null ||
        temperature == null ||
        storageDays == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Enter valid values in every measurement field.',
              'सभी माप फ़ील्ड में सही मान दर्ज करें।',
            ),
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _showResult = true;
    });
  }

  int _riskLevel() {
    final moisture = double.tryParse(_moistureController.text.trim()) ?? 0;
    final ph = double.tryParse(_phController.text.trim()) ?? 0;
    final temperature =
        double.tryParse(_temperatureController.text.trim()) ?? 0;

    if (_visibleMould ||
        _unusualSmell ||
        temperature >= 35 ||
        ph > 5.0 ||
        moisture < 55 ||
        moisture > 75) {
      return 2;
    }

    if (_heatingObserved ||
        temperature >= 30 ||
        ph > 4.5 ||
        moisture < 60 ||
        moisture > 72) {
      return 1;
    }

    return 0;
  }

  Widget _measurementField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (_) {
        if (_showResult) {
          setState(() {
            _showResult = false;
          });
        }
      },
    );
  }

  Widget _observationSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: const Color(0xFF8A6418)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF26372D),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF748078), fontSize: 12),
      ),
      value: value,
      activeTrackColor: const Color(0xFFB54435),
      onChanged: (enabled) {
        onChanged(enabled);

        if (_showResult) {
          setState(() {
            _showResult = false;
          });
        }
      },
    );
  }

  Widget _buildResult() {
    final risk = _riskLevel();

    final Color background;
    final Color foreground;
    final IconData icon;
    final String title;
    final String guidance;

    if (risk == 2) {
      background = const Color(0xFFFBE8E4);
      foreground = const Color(0xFF8F352C);
      icon = Icons.dangerous_rounded;
      title = _text('High spoilage concern', 'खराब होने की अधिक चिंता');
      guidance = _text(
        'Keep this batch separate. Do not rely on this screening alone to decide whether it is safe to feed. Arrange expert inspection and laboratory testing, especially when mould, unusual smell or heating is present.',
        'इस बैच को अलग रखें। इसे खिलाने के लिए सुरक्षित मानने हेतु केवल इस स्क्रीनिंग पर निर्भर न रहें। विशेष रूप से फफूँद, असामान्य गंध या गर्मी होने पर विशेषज्ञ निरीक्षण और प्रयोगशाला जाँच कराएँ।',
      );
    } else if (risk == 1) {
      background = const Color(0xFFFFF1CF);
      foreground = const Color(0xFF795315);
      icon = Icons.warning_amber_rounded;
      title = _text(
        'Storage conditions need attention',
        'भंडारण की स्थिति पर ध्यान दें',
      );
      guidance = _text(
        'Recheck the measurements and inspect the batch for heating, air exposure, smell and visible mould. Review compaction, sealing and feed-out management with an expert.',
        'मापों को दोबारा जाँचें और बैच में गर्मी, हवा का संपर्क, गंध तथा दिखाई देने वाली फफूँद की जाँच करें। दबाव, सीलिंग और चारा निकालने की प्रक्रिया की विशेषज्ञ से समीक्षा कराएँ।',
      );
    } else {
      background = const Color(0xFFE3F1E6);
      foreground = const Color(0xFF286B3E);
      icon = Icons.check_circle_rounded;
      title = _text(
        'No immediate warning detected',
        'कोई तत्काल चेतावनी नहीं मिली',
      );
      guidance = _text(
        'The entered values are within the current prototype screening range. Continue regular inspection because this form does not continuously monitor the batch or confirm feed safety.',
        'दर्ज किए गए मान वर्तमान प्रोटोटाइप स्क्रीनिंग सीमा में हैं। नियमित निरीक्षण जारी रखें क्योंकि यह फॉर्म बैच की लगातार निगरानी या चारे की सुरक्षा की पुष्टि नहीं करता।',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  guidance,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Storage Monitor', 'भंडारण निगरानी'),
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8C979)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF8A6418),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _text(
                            'Prototype offline screening—not continuous monitoring or laboratory confirmation.',
                            'यह प्रोटोटाइप ऑफलाइन स्क्रीनिंग है—लगातार निगरानी या प्रयोगशाला पुष्टि नहीं।',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF74591E),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: const Color(0xFFE0E8DD)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _batchController,
                        decoration: InputDecoration(
                          labelText: _text(
                            'Batch ID (optional)',
                            'बैच आईडी (वैकल्पिक)',
                          ),
                          prefixIcon: const Icon(Icons.qr_code_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFeed,
                        decoration: InputDecoration(
                          labelText: _text('Stored feed', 'भंडारित चारा'),
                          prefixIcon: const Icon(Icons.inventory_2_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Maize Silage',
                            child: Text('Maize Silage'),
                          ),
                          DropdownMenuItem(
                            value: 'Grass Silage',
                            child: Text('Grass Silage'),
                          ),
                          DropdownMenuItem(
                            value: 'Other Silage',
                            child: Text('Other Silage'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedFeed = value;
                            _showResult = false;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _measurementField(
                        controller: _storageDaysController,
                        label: _text('Storage duration', 'भंडारण अवधि'),
                        icon: Icons.calendar_today_rounded,
                        suffix: _text('days', 'दिन'),
                      ),
                      const SizedBox(height: 15),
                      _measurementField(
                        controller: _moistureController,
                        label: _text('Moisture', 'नमी'),
                        icon: Icons.water_drop_outlined,
                        suffix: '%',
                      ),
                      const SizedBox(height: 15),
                      _measurementField(
                        controller: _phController,
                        label: _text('Estimated pH', 'अनुमानित pH'),
                        icon: Icons.science_outlined,
                        suffix: 'pH',
                      ),
                      const SizedBox(height: 15),
                      _measurementField(
                        controller: _temperatureController,
                        label: _text('Temperature', 'तापमान'),
                        icon: Icons.thermostat_rounded,
                        suffix: '°C',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: const Color(0xFFE0E8DD)),
                  ),
                  child: Column(
                    children: [
                      _observationSwitch(
                        title: _text('Visible mould', 'दिखाई देने वाली फफूँद'),
                        subtitle: _text(
                          'Any white, green, blue or black growth',
                          'सफेद, हरी, नीली या काली वृद्धि',
                        ),
                        icon: Icons.coronavirus_outlined,
                        value: _visibleMould,
                        onChanged: (value) {
                          setState(() {
                            _visibleMould = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _observationSwitch(
                        title: _text(
                          'Unusual or rotten smell',
                          'असामान्य या सड़ी गंध',
                        ),
                        subtitle: _text(
                          'Strong rotten, musty or ammonia-like smell',
                          'तेज सड़ी, सीलन या अमोनिया जैसी गंध',
                        ),
                        icon: Icons.air_rounded,
                        value: _unusualSmell,
                        onChanged: (value) {
                          setState(() {
                            _unusualSmell = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _observationSwitch(
                        title: _text('Unexpected heating', 'असामान्य गर्मी'),
                        subtitle: _text(
                          'The batch feels warmer than expected',
                          'बैच अपेक्षा से अधिक गर्म लगता है',
                        ),
                        icon: Icons.local_fire_department_outlined,
                        value: _heatingObserved,
                        onChanged: (value) {
                          setState(() {
                            _heatingObserved = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _analyseStorage,
                    style: FilledButton.styleFrom(
                      backgroundColor: ParakhColors.forestGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(
                      _text('Check storage condition', 'भंडारण स्थिति जाँचें'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (_showResult) ...[
                  const SizedBox(height: 20),
                  _buildResult(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
