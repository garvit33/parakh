import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/parakh_colors.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );

    _controller.forward();

    Future<void>.delayed(const Duration(milliseconds: 2800), _openNextScreen);
  }

  Future<void> _openNextScreen() async {
    final preferences = await SharedPreferences.getInstance();

    final tutorialCompleted = preferences.getBool('tutorialCompleted') ?? false;

    final savedLanguage = preferences.getString('language') ?? 'en';

    if (!mounted) return;

    final Widget destination;

    if (tutorialCompleted) {
      destination = HomeScreen(isHindi: savedLanguage == 'hi');
    } else {
      destination = const OnboardingScreen();
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _contentOpacity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: const _AnimatedParakhLogo(),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Parakh',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Better Feed, Healthier Herds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ParakhColors.forestGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const SizedBox(
                    width: 145,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      color: ParakhColors.saffron,
                      backgroundColor: Color(0xFFDDE5DF),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Preparing your feed-quality assistant…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ParakhColors.secondaryText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedParakhLogo extends StatefulWidget {
  const _AnimatedParakhLogo();

  @override
  State<_AnimatedParakhLogo> createState() => _AnimatedParakhLogoState();
}

class _AnimatedParakhLogoState extends State<_AnimatedParakhLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: ParakhColors.forestGreen,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35124735),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.eco_rounded, color: Colors.white, size: 67),
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Positioned(
                left: 25,
                right: 25,
                top: 27 + (_scanController.value * 60),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: ParakhColors.saffron,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: ParakhColors.saffron, blurRadius: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TemporaryHomeScreen extends StatelessWidget {
  const TemporaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Parakh setup successful',
          style: TextStyle(
            color: ParakhColors.forestGreen,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
