// lib/screens/auth/sign_in_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController
      ..clear()
      ..dispose();
    _passwordController
      ..clear()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9FAFF),
              Color(0xFFF7EEF4),
              Color(0xFFF5D9E2),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Header: pinned to the VERY top =====
                    SizedBox(
                      height: 48, // compact so the brand sits high, like Figma
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              splashRadius: 24,
                            ),
                          ),
                          // Centered Nightly (logo + word), Urbanist 36 SemiBold
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/nightly_logo.png',
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Nightly',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    height: 1.0,
                                    letterSpacing: 0.0,
                                    color: const Color(0xFF1F1F29),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ===== "Sign In" centered, Roboto 22 =====
                    Text(
                      'Sign In',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F29),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Email / Phone =====
                    _ShadowField(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration('Email or Phone Number'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== Password =====
                    _ShadowField(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: _fieldDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Forgot password',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7A7A86),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== Gradient Sign In button =====
                    _GradientButton(
                      onTap: () {},
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ===== Social sign up text =====
                    const Center(
                      child: Text(
                        'New Here? Sign up with',
                        style: TextStyle(
                          color: Color(0xFF6B6B78),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ===== Frosted social buttons with PNG logos =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _GlassSquare(
                          child: _Logo(path: 'assets/logos/facebook.png'),
                        ),
                        SizedBox(width: 18),
                        _GlassSquare(
                          child: _Logo(path: 'assets/logos/google.png'),
                        ),
                        SizedBox(width: 18),
                        _GlassSquare(
                          child: _Logo(path: 'assets/logos/apple.png'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ===== Continue with Email link =====
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // navigate to email sign-up
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: 'or ',
                            style: TextStyle(
                              color: Color(0xFF6B6B78),
                            ),
                            children: [
                              TextSpan(
                                text: 'Continue with Email',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2F2F37),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB7B7C3),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    );
  }
}

/// Soft drop shadow wrapper for rounded fields
class _ShadowField extends StatelessWidget {
  const _ShadowField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x1F000000),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

/// Gradient pill button
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF6D2CF4),
                Color(0xFFD94A7A),
              ],
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Frosted "liquid glass" square (slightly rounded) used for social logos.
class _GlassSquare extends StatelessWidget {
  const _GlassSquare({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.28),
                  Colors.white.withOpacity(0.12),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 6),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Simple logo image widget with consistent sizing.
class _Logo extends StatelessWidget {
  const _Logo({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: 40,  // match your Figma 40×40 logos
      height: 40,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stack) => const Icon(
        Icons.image_not_supported_outlined,
        size: 28,
        color: Color(0xFF8A8A98),
      ),
    );
  }
}
