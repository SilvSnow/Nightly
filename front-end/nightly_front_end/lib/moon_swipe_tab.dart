import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoonSwipeTab extends StatefulWidget {
  const MoonSwipeTab({super.key});

  @override
  State<MoonSwipeTab> createState() => _MoonSwipeTabState();
}

class _MoonSwipeTabState extends State<MoonSwipeTab>
    with SingleTickerProviderStateMixin {
  int _currentProfileIndex = 0;
  Offset _cardOffset = Offset.zero;
  bool _isCardAnimating = false;
  late final AnimationController _cardThrowController;
  Animation<Offset>? _cardOffsetAnimation;

  final List<_GroupProfile> _profiles = const [
    _GroupProfile(
      id: 'night_owls',
      name: 'Night Owls Crew',
      ageRange: '21-22',
      location: 'London',
      memberCount: '2',
      about:
          'We\'re a duo who live for the weekend. Always looking for the best spots to dance, drink, and make memories. Looking for some girls to join us for our next big night out.',
      stars: '4.33',
      partyFrequency: 4,
      budget: r'$$ - $$$',
      energyLevel: 5,
      imageUrl:
          'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?auto=format&fit=crop&w=1200&q=80',
      reviews: [
        _VenueReview(
          title: '212',
          rating: '4.8',
          subtitle: 'Downtown Montreal',
          description:
              'Amazing vibe, great cocktails, and the DJ was on fire! Definitely our new favourite spot for Saturday nights.',
        ),
        _VenueReview(
          title: 'Yoko Luna',
          rating: '4.5',
          subtitle: 'Downtown Montreal',
          description:
              'Incredible energy and the best house music in town. Drinks are a bit pricey but worth it for the experience.',
        ),
      ],
    ),
    _GroupProfile(
      id: 'city_glow',
      name: 'City Glow Girls',
      ageRange: '22-24',
      location: 'Toronto',
      memberCount: '3',
      about:
          'Brunch by day and rooftop bars by night. We love finding cute spots, trying signature drinks, and meeting chill people with fun energy.',
      stars: '4.57',
      partyFrequency: 3,
      budget: r'$$ - $$$',
      energyLevel: 4,
      imageUrl:
          'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1200&q=80',
      reviews: [
        _VenueReview(
          title: 'BarChef',
          rating: '4.7',
          subtitle: 'King West',
          description:
              'Creative cocktails and such a cool atmosphere. Perfect for starting the night before heading to a dance floor.',
        ),
        _VenueReview(
          title: 'Isabelle\'s',
          rating: '4.4',
          subtitle: 'King Street',
          description:
              'Super stylish venue with a lively crowd. Great place for birthdays and special nights out with friends.',
        ),
      ],
    ),
    _GroupProfile(
      id: 'sunset_society',
      name: 'Sunset Society',
      ageRange: '20-23',
      location: 'Vancouver',
      memberCount: '4',
      about:
          'We love ocean views, rooftop sunsets, and dancing till late. Looking for social, easygoing people who are down for spontaneous plans.',
      stars: '4.61',
      partyFrequency: 5,
      budget: r'$$$',
      energyLevel: 5,
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
      reviews: [
        _VenueReview(
          title: 'The Keefer Bar',
          rating: '4.9',
          subtitle: 'Chinatown',
          description:
              'Hands down one of the best cocktail bars in the city. Unique menu and super friendly staff every time.',
        ),
        _VenueReview(
          title: 'Levels',
          rating: '4.3',
          subtitle: 'Gastown',
          description:
              'Fun crowd and solid music all night. We always end up meeting new people here and having a blast.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardThrowController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          final animation = _cardOffsetAnimation;
          if (animation == null) return;
          setState(() {
            _cardOffset = animation.value;
          });
        });
  }

  @override
  void dispose() {
    _cardThrowController.dispose();
    super.dispose();
  }

  Future<void> _animateCardTo({
    required Offset target,
    required Duration duration,
    required Curve curve,
  }) async {
    _cardThrowController.stop();
    _cardThrowController.duration = duration;
    _cardOffsetAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _cardThrowController, curve: curve));

    setState(() {
      _isCardAnimating = true;
    });

    await _cardThrowController.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _isCardAnimating = false;
    });
  }

  Future<void> _animateCardBack() async {
    await _animateCardTo(
      target: Offset.zero,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _animateCardOffscreen({required bool liked}) async {
    if (_isCardAnimating) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = liked ? screenWidth * 1.25 : -screenWidth * 1.25;
    final targetY = _cardOffset.dy + (liked ? -16 : 16);

    await _animateCardTo(
      target: Offset(targetX, targetY),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );

    if (!mounted) return;

    _moveToNextProfile(liked: liked);

    setState(() {
      _cardOffset = Offset.zero;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isCardAnimating) return;

    final updatedDx = (_cardOffset.dx + details.delta.dx).clamp(-280.0, 280.0);
    setState(() {
      _cardOffset = Offset(updatedDx, 0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isCardAnimating) return;

    final velocity = details.primaryVelocity ?? 0;
    const throwDistanceThreshold = 110.0;
    const throwVelocityThreshold = 900.0;

    final swipeRight =
        _cardOffset.dx > throwDistanceThreshold ||
        velocity > throwVelocityThreshold;
    final swipeLeft =
        _cardOffset.dx < -throwDistanceThreshold ||
        velocity < -throwVelocityThreshold;

    if (swipeRight) {
      _animateCardOffscreen(liked: true);
      return;
    }

    if (swipeLeft) {
      _animateCardOffscreen(liked: false);
      return;
    }

    _animateCardBack();
  }

  void _moveToNextProfile({required bool liked}) {
    if (_profiles.isEmpty) return;

    setState(() {
      _currentProfileIndex = (_currentProfileIndex + 1) % _profiles.length;
    });
  }

  Widget _buildTag({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8F8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8A2C8C)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A2C8C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStars(int filled) {
    return Row(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.star,
            size: 18,
            color: index < filled
                ? const Color(0xFFB36AD0)
                : const Color(0xFFE7D7F0),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBolts(int filled) {
    return Row(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.bolt,
            size: 16,
            color: index < filled
                ? const Color(0xFFB36AD0)
                : const Color(0xFFE7D7F0),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(_VenueReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.title,
                  style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF454545),
                  ),
                ),
              ),
              const Icon(Icons.star, size: 14, color: Color(0xFFB36AD0)),
              const SizedBox(width: 4),
              Text(
                review.rating,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF454545),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                review.subtitle,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            review.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(_GroupProfile profile) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 360,
                    width: double.infinity,
                    child: Image.network(
                      profile.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.name,
                                style: GoogleFonts.urbanist(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111111),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF59A9FF),
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTag(
                              icon: Icons.cake_outlined,
                              label: profile.ageRange,
                            ),
                            _buildTag(
                              icon: Icons.location_on_outlined,
                              label: profile.location,
                            ),
                            _buildTag(
                              icon: Icons.person_outline,
                              label: profile.memberCount,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(thickness: 1, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'About Us',
                              style: GoogleFonts.urbanist(
                                fontSize: 35,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.female,
                              size: 24,
                              color: Color(0xFF1E1E1E),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile.about,
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            color: const Color(0xFF8A8A8A),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Stars',
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF252525),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_outlined,
                              size: 17,
                              color: Color(0xFF8A2C8C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.stars,
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF252525),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Party Frequency',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF252525),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMetricStars(profile.partyFrequency),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Budget',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF252525),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.budget,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB36AD0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Energy Level',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF252525),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMetricBolts(profile.energyLevel),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(thickness: 1, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Venue Reviews',
                          style: GoogleFonts.urbanist(
                            fontSize: 35,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...profile.reviews.map(_buildReviewCard),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1E8F8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF8A2C8C),
                              size: 25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          top: 425,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _animateCardOffscreen(liked: false),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8A2C8C),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _animateCardOffscreen(liked: true),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8A2C8C),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profiles.isEmpty ? null : _profiles[_currentProfileIndex];

    if (profile == null) {
      return Center(
        child: Text(
          'No profiles available right now.',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            fontSize: 24,
            color: Colors.grey.shade500,
          ),
        ),
      );
    }

    final nextProfile =
        _profiles[(_currentProfileIndex + 1) % _profiles.length];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final normalizedDx = (_cardOffset.dx / width).clamp(-1.0, 1.0);
        final rotation = normalizedDx * 0.12;
        final absDx = normalizedDx.abs();

        // Glass clears proportionally as card reveals the card underneath
        final glassOpacity = (1.0 - absDx * 1.8).clamp(0.0, 1.0);
        final blurAmount = 14.0 * glassOpacity;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Stack(
            children: [
              // Next card sitting underneath
              Positioned.fill(child: _buildProfileCard(nextProfile)),

              // Frosted glass — fades away as the top card slides off
              if (blurAmount > 0.2)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: blurAmount,
                          sigmaY: blurAmount,
                        ),
                        child: Container(
                          color: Colors.white.withOpacity(0.18 * glassOpacity),
                        ),
                      ),
                    ),
                  ),
                ),

              // Top card being swiped
              Transform.translate(
                offset: _cardOffset,
                child: Transform.rotate(
                  angle: rotation,
                  child: _buildProfileCard(profile),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupProfile {
  final String id;
  final String name;
  final String ageRange;
  final String location;
  final String memberCount;
  final String about;
  final String stars;
  final int partyFrequency;
  final String budget;
  final int energyLevel;
  final String imageUrl;
  final List<_VenueReview> reviews;

  const _GroupProfile({
    required this.id,
    required this.name,
    required this.ageRange,
    required this.location,
    required this.memberCount,
    required this.about,
    required this.stars,
    required this.partyFrequency,
    required this.budget,
    required this.energyLevel,
    required this.imageUrl,
    required this.reviews,
  });
}

class _VenueReview {
  final String title;
  final String rating;
  final String subtitle;
  final String description;

  const _VenueReview({
    required this.title,
    required this.rating,
    required this.subtitle,
    required this.description,
  });
}
