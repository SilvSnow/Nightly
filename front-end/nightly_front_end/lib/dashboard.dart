import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nightly_front_end/moon_swipe_tab.dart';

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

  int _selectedTabIndex = 0;

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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const MoonSwipeTab();
      case 1:
        return _PlaceholderTab(
          title: 'Messages',
          subtitle: 'Your conversations will appear here.',
          icon: LucideIcons.messageCircle,
        );
      case 2:
        return _PlaceholderTab(
          title: 'Likes',
          subtitle: 'Groups you liked will appear here.',
          icon: LucideIcons.heart,
        );
      case 3:
        return _PlaceholderTab(
          title: 'Profile',
          subtitle: 'Your account details will appear here.',
          icon: LucideIcons.user,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavIcon({required int index, required IconData icon}) {
    final isSelected = _selectedTabIndex == index;

    return IconButton(
      onPressed: () {
        if (_selectedTabIndex == index) return;
        setState(() {
          _selectedTabIndex = index;
        });
      },
      icon: Icon(
        icon,
        size: 34,
        color: isSelected ? const Color(0xFF89247B) : const Color(0xFFCFA4C8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: Opacity(
              opacity: _fade.value,
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
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, _contentY.value),
                      child: _buildTabContent(),
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
                        children: [
                          _buildNavIcon(index: 0, icon: LucideIcons.moon),
                          _buildNavIcon(
                            index: 1,
                            icon: LucideIcons.messageCircle,
                          ),
                          _buildNavIcon(index: 2, icon: LucideIcons.heart),
                          _buildNavIcon(index: 3, icon: LucideIcons.user),
                        ],
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

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF89247B)),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 18,
                color: const Color(0xFF888888),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
