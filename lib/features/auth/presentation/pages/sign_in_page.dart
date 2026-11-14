import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/progress_tracker_logo.dart';
import '../../../tasks/presentation/pages/tasks_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/google_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const canvasColor = Color(0xFF0B0F17);
    const mintColor = Color(0xFF86EFAC);
    const emeraldColor = Color(0xFF22C55E);
    const textColor = Color(0xFFF8FAFC);
    const mutedColor = Color(0xFF94A3B8);
    const faintColor = Color(0xFF64748B);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TasksPage()),
          );
        } else if (state is AuthFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: canvasColor,
          body: Stack(
            children: [
              // Ambient background radial glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambient,
                  builder: (context, _) {
                    final b =
                        0.5 - 0.5 * math.cos(2 * math.pi * _ambient.value);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.45),
                          radius: 0.85 + 0.08 * b,
                          colors: [
                            mintColor.withAlpha((26 + 14 * b).round()),
                            emeraldColor.withAlpha(8),
                            canvasColor.withAlpha(0),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      ProgressTrackerLogo(
                        size: 128,
                        mode: isLoading
                            ? ProgressLogoMode.loop
                            : ProgressLogoMode.intro,
                        speed: isLoading ? 1.15 : 1.0,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Progress Tracker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track your habits with simple daily green grids',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                      const Spacer(flex: 2),
                      GoogleButton(
                        busy: isLoading,
                        onTap: () {
                          context
                              .read<AuthBloc>()
                              .add(const SignInWithGoogleRequested());
                        },
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 13, color: faintColor),
                          SizedBox(width: 5),
                          Text(
                            'Secured by Supabase Auth',
                            style: TextStyle(fontSize: 12, color: faintColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Works 100% offline • Zero tracking ads',
                        style: TextStyle(fontSize: 12, color: faintColor),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
