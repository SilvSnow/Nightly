import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _contentY;
  late final Animation<double> _topY;
  late final Animation<double> _bottomY;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _contentY = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _topY = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _bottomY = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _fabScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double hotbarHeight = 82;
    const double hotbarBottomInset = 19;
    const double fabInset = 20;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: Opacity(
              opacity: _fade.value,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 19),
                    child: Column(
                      children: [
                      Transform.translate(
                        offset: Offset(0, _topY.value),
                        child: SizedBox(
                          height: 68,
                          child: Row(
                            children: [
                              const SizedBox(width: 22),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Dashboard',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 56,
                                child: Center(
                                  child: const Icon(
                                    LucideIcons.inbox,
                                    size: 30,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, _contentY.value),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(34, 48, 34, 0),
                            child: Text(
                              'Create a new group to start\nmaking friends!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 25,
                                color: Colors.grey.shade500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                        Transform.translate(
                          offset: Offset(0, _bottomY.value),
                          child: Container(
                          height: 82,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Icon(
                                LucideIcons.messageCircle,
                                color: Color(0xFF89247B),
                                size: 34,
                              ),
                              Icon(
                                LucideIcons.moon,
                                color: Color(0xFF89247B),
                                size: 34,
                              ),
                              Icon(
                                LucideIcons.heart,
                                color: Color(0xFF89247B),
                                size: 34,
                              ),
                              Icon(
                                LucideIcons.user,
                                color: Color(0xFF89247B),
                                size: 34,
                              ),
                            ],
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: fabInset,
                    bottom: hotbarHeight + hotbarBottomInset + fabInset,
                    child: Transform.scale(
                      scale: _fabScale.value,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF89247B),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
