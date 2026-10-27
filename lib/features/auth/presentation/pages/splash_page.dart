import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/progress_tracker_logo.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'sign_in_page.dart';
import '../../../tasks/presentation/pages/tasks_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.animate = true,
    this.speed = 0.75,
  });

  /// When true, waits for the animated logo sequence to complete before routing.
  /// Can be set to false in fast widget tests.
  final bool animate;

  /// Playback speed multiplier (e.g. 0.75 to make the progress animation a bit slower and smoother).
  final double speed;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _animationCompleted = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_animationCompleted) {
        _handleState(context.read<AuthBloc>().state);
      }
    });
  }

  void _onLogoCompleted() {
    if (!mounted) return;
    setState(() {
      _animationCompleted = true;
    });
    _handleState(context.read<AuthBloc>().state);
  }

  void _handleState(AuthState state) {
    if (!mounted || !_animationCompleted) return;
    if (state is Authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TasksPage()),
      );
    } else if (state is Unauthenticated || state is AuthFailureState) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark
        ? ProgressTrackerPalette.dark
        : ProgressTrackerPalette.light;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleState(state),
      child: Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressTrackerLogo(
                size: 140,
                palette: palette,
                speed: widget.speed,
                autoPlay: widget.animate,
                mode: widget.animate
                    ? ProgressLogoMode.intro
                    : ProgressLogoMode.still,
                onCompleted: _onLogoCompleted,
              ),
              const SizedBox(height: 24),
              Text(
                'Progress Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Build your wall of green.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

