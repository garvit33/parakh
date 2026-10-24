import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/parakh_colors.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _isHindi = false;

  List<OnboardingItem> get _pages => [
    OnboardingItem(
      title: AppStrings.text('welcomeTitle', _isHindi),
      description: AppStrings.text('welcomeBody', _isHindi),
      icon: Icons.agriculture_rounded,
    ),
    OnboardingItem(
      title: AppStrings.text('connectTitle', _isHindi),
      description: AppStrings.text('connectBody', _isHindi),
      icon: Icons.bluetooth_connected_rounded,
    ),
    OnboardingItem(
      title: AppStrings.text('scanTitle', _isHindi),
      description: AppStrings.text('scanBody', _isHindi),
      icon: Icons.document_scanner_rounded,
    ),
    OnboardingItem(
      title: AppStrings.text('resultTitle', _isHindi),
      description: AppStrings.text('resultBody', _isHindi),
      icon: Icons.task_alt_rounded,
    ),
  ];

  Future<void> _finishOnboarding() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool('tutorialCompleted', true);
    await preferences.setString('language', _isHindi ? 'hi' : 'en');

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => HomeScreen(isHindi: _isHindi)),
    );
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(AppStrings.text('skip', _isHindi)),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: false, label: Text('EN')),
                      ButtonSegment<bool>(value: true, label: Text('हिं')),
                    ],
                    selected: {_isHindi},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() {
                        _isHindi = selection.first;
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE7F0E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 100,
                            color: ParakhColors.forestGreen,
                          ),
                        ),
                        const SizedBox(height: 46),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: index == _currentPage ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? ParakhColors.forestGreen
                          : const Color(0xFFD5DDD7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _goNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: ParakhColors.forestGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppStrings.text(
                      _currentPage == pages.length - 1 ? 'start' : 'next',
                      _isHindi,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
