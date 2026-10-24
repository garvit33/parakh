import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/test_history_storage.dart';
import '../../core/theme/parakh_colors.dart';
import '../calibration/calibration_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.isHindi,
    required this.isDeviceConnected,
    super.key,
  });

  final bool isHindi;
  final bool isDeviceConnected;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isHindi;
  bool _isClearingHistory = false;
  bool _isDemoMode = false;

  String _text(String english, String hindi) {
    return _isHindi ? hindi : english;
  }

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _loadDemoMode();
  }

  Future<void> _loadDemoMode() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool('demoMode') ?? false;

    if (!mounted) return;

    setState(() {
      _isDemoMode = enabled;
    });
  }

  Future<void> _changeDemoMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('demoMode', enabled);

    if (!mounted) return;

    setState(() {
      _isDemoMode = enabled;
    });
  }

  Future<void> _changeLanguage(bool isHindi) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('language', isHindi ? 'hi' : 'en');

    if (!mounted) return;

    setState(() {
      _isHindi = isHindi;
    });
  }

  void _closeSettings() {
    Navigator.of(context).pop(_isHindi);
  }

  Future<void> _showClearHistoryDialog() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_text('Clear test history?', 'जाँच इतिहास हटाएँ?')),
          content: Text(
            _text(
              'All saved test results will be permanently removed from this phone.',
              'इस फोन में सहेजे गए सभी जाँच परिणाम स्थायी रूप से हटा दिए जाएँगे।',
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
                backgroundColor: const Color(0xFFB84B42),
              ),
              child: Text(_text('Clear history', 'इतिहास हटाएँ')),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !mounted) return;

    setState(() {
      _isClearingHistory = true;
    });

    await TestHistoryStorage().clearHistory();

    if (!mounted) return;

    setState(() {
      _isClearingHistory = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Test history cleared successfully.',
            'जाँच इतिहास सफलतापूर्वक हटा दिया गया।',
          ),
        ),
        backgroundColor: ParakhColors.forestGreen,
      ),
    );
  }

  Future<void> _showReplayTutorialDialog() async {
    final shouldReplay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _text(
              'Replay interactive tutorial?',
              'इंटरैक्टिव ट्यूटोरियल दोबारा देखें?',
            ),
          ),
          content: Text(
            _text(
              'The Home and NIR highlighted tutorials will be shown again.',
              'होम और NIR के हाइलाइट किए गए ट्यूटोरियल फिर से दिखाए जाएँगे।',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_text('Cancel', 'रद्द करें')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_text('Start tutorial', 'ट्यूटोरियल शुरू करें')),
            ),
          ],
        );
      },
    );

    if (shouldReplay != true) return;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool('homeTutorialCompleted', false);
    await preferences.setBool('nirTutorialCompleted', false);

    if (!mounted) return;

    Navigator.of(context).pop(_isHindi);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeSettings();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F8F2),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: _closeSettings,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            _text('Settings', 'सेटिंग्स'),
            style: const TextStyle(
              color: Color(0xFF20352A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(_text('Language', 'भाषा')),
                  const SizedBox(height: 10),
                  _buildLanguageCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    _text('Portable device', 'पोर्टेबल डिवाइस'),
                  ),
                  const SizedBox(height: 10),
                  _buildDeviceCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    _text('App preferences', 'ऐप प्राथमिकताएँ'),
                  ),
                  const SizedBox(height: 10),
                  _buildPreferencesCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    _text('Data and storage', 'डेटा और स्टोरेज'),
                  ),
                  const SizedBox(height: 10),
                  _buildStorageCard(),
                  const SizedBox(height: 24),
                  _buildAboutCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF185B3E), Color(0xFF2F7B55)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F185B3E),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PARAKH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(
                    'Better Feed, Healthier Herds',
                    'बेहतर आहार, स्वस्थ पशुधन',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFDDEDE4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF20352A),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildLanguageCard() {
    return _settingsCard(
      child: Column(
        children: [
          _languageOption(
            title: 'English',
            subtitle: 'Use Parakh in English',
            iconText: 'EN',
            selected: !_isHindi,
            onTap: () => _changeLanguage(false),
          ),
          const Divider(height: 1),
          _languageOption(
            title: 'हिन्दी',
            subtitle: 'परख ऐप का उपयोग हिन्दी में करें',
            iconText: 'हि',
            selected: _isHindi,
            onTap: () => _changeLanguage(true),
          ),
        ],
      ),
    );
  }

  Widget _languageOption({
    required String title,
    required String subtitle,
    required String iconText,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDDEEE4)
                    : const Color(0xFFF0F3EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                iconText,
                style: TextStyle(
                  color: selected
                      ? ParakhColors.forestGreen
                      : const Color(0xFF68736C),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF26372D),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7A847D),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? ParakhColors.forestGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? ParakhColors.forestGreen
                      : const Color(0xFFADB6B0),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard() {
    final connected = widget.isDeviceConnected;

    return _settingsCard(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: connected
                    ? const Color(0xFFDDEEE4)
                    : const Color(0xFFF1F2F0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.bluetooth_rounded,
                color: connected
                    ? ParakhColors.forestGreen
                    : const Color(0xFF778079),
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PARAKH-01',
                    style: TextStyle(
                      color: Color(0xFF26372D),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connected
                        ? _text('Connected', 'कनेक्टेड')
                        : _text('Not connected', 'कनेक्ट नहीं है'),
                    style: TextStyle(
                      color: connected
                          ? const Color(0xFF32834C)
                          : const Color(0xFF93645A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: connected
                    ? const Color(0xFF43A65B)
                    : const Color(0xFFB7BDB8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF8063A6),
            iconBackground: const Color(0xFFF0EAF7),
            title: _text('Replay tutorial', 'ट्यूटोरियल दोबारा देखें'),
            subtitle: _text(
              'View the first-time guide again',
              'पहली बार उपयोग करने की जानकारी देखें',
            ),
            onTap: _showReplayTutorialDialog,
          ),
          _settingsTile(
            icon: Icons.biotech_rounded,
            iconColor: const Color(0xFF3D70A8),
            iconBackground: const Color(0xFFEAF1FA),
            title: _text('Calibration workspace', 'कैलिब्रेशन कार्यक्षेत्र'),
            subtitle: _text(
              'Prototype/admin use • Compare scans with lab results',
              'प्रोटोटाइप/एडमिन उपयोग • स्कैन की लैब परिणामों से तुलना करें',
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CalibrationScreen(isHindi: _isHindi),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 76),
          const Divider(height: 1, indent: 76),
          _settingsTile(
            icon: Icons.science_rounded,
            iconColor: const Color(0xFFD17B3F),
            iconBackground: const Color(0xFFFBEDE3),
            title: _text('Demo mode', 'डेमो मोड'),
            subtitle: _text(
              'Use simulated device readings for demonstrations',
              'प्रदर्शन के लिए सिम्युलेटेड डिवाइस रीडिंग का उपयोग करें',
            ),
            trailing: Switch.adaptive(
              value: _isDemoMode,
              activeTrackColor: ParakhColors.forestGreen,
              onChanged: _changeDemoMode,
            ),
            onTap: () => _changeDemoMode(!_isDemoMode),
          ),
          const Divider(height: 1, indent: 76),
          _settingsTile(
            icon: Icons.cloud_off_rounded,
            iconColor: const Color(0xFF2F7650),
            iconBackground: const Color(0xFFE3F0E8),
            title: _text('Offline mode', 'ऑफलाइन मोड'),
            subtitle: _text(
              'Core testing features work without internet',
              'मुख्य जाँच सुविधाएँ बिना इंटरनेट काम करती हैं',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return _settingsCard(
      child: _settingsTile(
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFB84B42),
        iconBackground: const Color(0xFFF9E9E6),
        title: _text('Clear test history', 'जाँच इतिहास हटाएँ'),
        subtitle: _text(
          'Remove all saved offline results',
          'सभी सहेजे गए ऑफलाइन परिणाम हटाएँ',
        ),
        trailing: _isClearingHistory
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : null,
        onTap: _isClearingHistory ? null : _showClearHistoryDialog,
      ),
    );
  }

  Widget _buildAboutCard() {
    return _settingsCard(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          children: [
            const Icon(
              Icons.eco_rounded,
              color: ParakhColors.forestGreen,
              size: 36,
            ),
            const SizedBox(height: 10),
            const Text(
              'Parakh',
              style: TextStyle(
                color: Color(0xFF20352A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _text('Version 1.0.0', 'संस्करण 1.0.0'),
              style: const TextStyle(color: Color(0xFF7A847D)),
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                'Smart feed and silage quality testing for farmers.',
                'किसानों के लिए स्मार्ट आहार और साइलेज गुणवत्ता जाँच।',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF647068), height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'SIH26111',
              style: TextStyle(
                color: ParakhColors.forestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE5DA)),
        ),
        child: child,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF26372D),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF7A847D), fontSize: 13),
        ),
      ),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7A847D),
                )),
    );
  }
}
