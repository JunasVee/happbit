// lib/widgets/app_loading_screen.dart
import 'package:flutter/material.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key, this.bgAsset = 'assets/images/splash_bg.png'});

  /// Path to the background image asset (decorative shapes only, no text).
  final String bgAsset;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 1.0, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    // start animation
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors that match your theme — tweak if needed
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image (cover). Provide an image with transparent center so text sits on white.
          Positioned.fill(
            child: Image.asset(
              widget.bgAsset,
              fit: BoxFit.cover,
            ),
          ),

          // Centered animated text
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome to...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'HappBit!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Small bottom center loader (optional)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
