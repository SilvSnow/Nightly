import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nightly_front_end/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasReachedReviewPage = false;
  bool _suppressKeyboardDuringFastForward = false;
  final int _totalPages = 11; // Phone, Code, Birthday, Location, Gender, Profile, Drinking, Weed, Cig, Language, Review
  String _selectedCountryCode = '+1';
  String? _selectedBirthDay;
  String? _selectedBirthMonth;
  String? _selectedBirthYear;
  String? _selectedGender;
  String? _selectedPhotoSource;
  String? _selectedDrinkingLevel;
  String? _selectedWeedLevel;
  String? _selectedCigLevel;

  // Controllers for inputs
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _languageFocusNode = FocusNode();
  final List<TextEditingController> _codeControllers = List.generate(6, (i) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (i) => FocusNode());
  final List<String> _selectedLanguages = ['English'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleKeyboardForPage(_currentPage);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _locationController.dispose();
    _languageController.dispose();
    _phoneFocusNode.dispose();
    _locationFocusNode.dispose();
    _languageFocusNode.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _codeFocusNodes) {
      node.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _handleKeyboardForPage(int page) {
    FocusScope.of(context).unfocus();

    switch (page) {
      case 0:
        _phoneFocusNode.requestFocus();
        break;
      case 1:
        _codeFocusNodes[0].requestFocus();
        break;
      case 3:
        _locationFocusNode.requestFocus();
        break;
      case 9:
        _languageFocusNode.requestFocus();
        break;
      default:
        SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  void _nextPage() {
    final reviewPage = _totalPages - 1;

    if (_currentPage == reviewPage) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
      return;
    }

    if (_hasReachedReviewPage && _currentPage < reviewPage) {
      final pagesRemaining = reviewPage - _currentPage;
      _suppressKeyboardDuringFastForward = true;
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _pageController.animateToPage(
        reviewPage,
        duration: Duration(milliseconds: 120 * pagesRemaining),
        curve: Curves.easeOutCubic,
      ).whenComplete(() {
        if (!mounted) return;
        _suppressKeyboardDuringFastForward = false;
        _handleKeyboardForPage(reviewPage);
      });
      return;
    }

    if (_currentPage < reviewPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onCodeInputChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move focus to next field if digit is entered
      if (index < 5) {
        _codeFocusNodes[index + 1].requestFocus();
      }
    }
  }

  void _addLanguageFromInput([String? value]) {
    final input = (value ?? _languageController.text).trim();
    if (input.isEmpty) return;

    final exists = _selectedLanguages.any(
      (language) => language.toLowerCase() == input.toLowerCase(),
    );
    if (!exists) {
      setState(() {
        _selectedLanguages.add(input);
      });
    }
    _languageController.clear();
  }

  void _removeLanguage(String language) {
    setState(() {
      _selectedLanguages.remove(language);
    });
  }

  String _displayOrDefault(String? value, {String fallback = 'Not set'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  String _birthdaySummary() {
    final day = _selectedBirthDay ?? '--';
    final month = _selectedBirthMonth ?? '--';
    final year = _selectedBirthYear ?? '----';
    if (day == '--' && month == '--' && year == '----') return 'Not set';
    return '$day/$month/$year';
  }

  bool _shouldFadeLanguageRow(double availableWidth) {
    const chipHorizontalPadding = 14.0;
    const chipRightSpacing = 10.0;
    const iconWidth = 18.0;
    const iconGap = 8.0;
    const rowHorizontalBuffer = 2.0;

    final textStyle = GoogleFonts.urbanist(
      fontSize: 18,
      color: Colors.white,
    );

    double totalWidth = rowHorizontalBuffer;
    for (final language in _selectedLanguages) {
      final painter = TextPainter(
        text: TextSpan(text: language, style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      totalWidth +=
          painter.width +
          (chipHorizontalPadding * 2) +
          iconGap +
          iconWidth +
          chipRightSpacing;
    }

    return totalWidth > availableWidth;
  }

  void _goToReviewSelection(int targetPage) {
    final reviewPage = _totalPages - 1;

    if (_currentPage == reviewPage && targetPage < reviewPage) {
      _pageController.jumpToPage(targetPage);
      return;
    }

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildReviewRow({
    required String pageName,
    required String selection,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pageName,
                    style: GoogleFonts.urbanist(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selection,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCupertinoStringPicker({
    required List<String> options,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    if (options.isEmpty) return;

    var initialIndex = currentValue == null ? 0 : options.indexOf(currentValue);
    if (initialIndex < 0) {
      initialIndex = 0;
    }

    var tempSelected = options[initialIndex];
    final controller = FixedExtentScrollController(initialItem: initialIndex);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                height: 300,
                width: double.infinity,
                color: CupertinoColors.systemBackground.resolveFrom(popupContext),
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            onSelected(tempSelected);
                            Navigator.of(popupContext).pop();
                          },
                          child: Text(
                            'Done',
                            style: GoogleFonts.urbanist(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: controller,
                        itemExtent: 36,
                        onSelectedItemChanged: (index) {
                          tempSelected = options[index];
                        },
                        children: options
                            .map(
                              (option) => Center(
                                child: Text(
                                  option,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 24,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCupertinoPickerField({
    required String? value,
    required String placeholder,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _showCupertinoStringPicker(
          options: options,
          currentValue: value,
          onSelected: onSelected,
        );
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade400,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  color: value == null ? Colors.grey.shade400 : Colors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label) {
    final isSelected = _selectedGender == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Center(
                child: isSelected
                    ? TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 32),
                        builder: (context, size, child) {
                          return Container(
                            width: size,
                            height: size,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 24),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Center(
                child: isSelected
                    ? TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 30),
                        builder: (context, size, child) {
                          return Container(
                            width: size,
                            height: size,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 18),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSourceButton(String label) {
    final isSelected = _selectedPhotoSource == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhotoSource = label;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          color: isSelected ? Colors.grey.shade100 : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress as a value between 0.0 and 1.0
    double progress = (_currentPage + 1) / _totalPages;
    final dayOptions = List.generate(
      31,
      (index) => '${index + 1}'.padLeft(2, '0'),
    );
    final monthOptions = List.generate(
      12,
      (index) => '${index + 1}'.padLeft(2, '0'),
    );
    final currentYear = DateTime.now().year;
    final yearOptions = List.generate(
      currentYear - 1900 + 1,
      (index) => '${currentYear - index}',
    );
    const frequencyOptions = ['Never', 'Rarely', '50/50', 'Often', 'Always'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevPage,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 6,
            width: 200, // Adjust width as needed
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF89247B), // Your brand color
                minHeight: 6,
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to force button use
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                    if (page == _totalPages - 1) {
                      _hasReachedReviewPage = true;
                    }
                  });
                  if (_suppressKeyboardDuringFastForward) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _handleKeyboardForPage(page);
                  });
                },
                children: [
                   // Step 1: Phone Number
                   _buildStep(
                     icon: LucideIcons.phone,
                     title: "What's your phone number?",
                     subtitle: "A verification code will be sent to your number. Message and data rates may apply.",
                     child: Row(
                       children: [
                         SizedBox(
                           width: 95,
                           child: _buildCupertinoPickerField(
                             value: _selectedCountryCode,
                             placeholder: '+1',
                             options: const ['+1', '+55', '+44'],
                             onSelected: (value) {
                               setState(() {
                                 _selectedCountryCode = value;
                               });
                             },
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: TextField(
                             controller: _phoneController,
                             focusNode: _phoneFocusNode,
                             keyboardType: TextInputType.phone,
                             inputFormatters: const [UsPhoneTextInputFormatter()],
                             decoration: InputDecoration(
                               hintText: "(555) 123 4567",
                               border: const UnderlineInputBorder(),
                               hintStyle: GoogleFonts.urbanist(
                                 fontSize: 24,
                                 color: Colors.grey.shade400,
                               ),
                             ),
                             style: GoogleFonts.urbanist(
                               fontSize: 24,
                               color: Colors.black,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),

                   // Step 2: Verification Code
                   _buildStep(
                     icon: LucideIcons.phone,
                     title: "Enter the verification code",
                     subtitle: "Didn't get a code?",
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: List.generate(
                         6,
                         (index) => SizedBox(
                           width: 45,
                           child: TextField(
                             controller: _codeControllers[index],
                             focusNode: _codeFocusNodes[index],
                             keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                             textAlign: TextAlign.center,
                             maxLength: 1,
                             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                             onChanged: (value) => _onCodeInputChanged(value, index),
                             decoration: InputDecoration(
                               counterText: '',
                               border: const UnderlineInputBorder(),
                               contentPadding: const EdgeInsets.only(bottom: 8),
                             ),
                             style: GoogleFonts.urbanist(
                               fontSize: 28,
                               fontWeight: FontWeight.bold,
                               color: Colors.black,
                             ),
                           ),
                         ),
                       ),
                     ),
                   ),

                   // Step 3: Birthday
                   _buildStep(
                     icon: LucideIcons.cake,
                     title: "When's your birthday?",
                     subtitle: null,
                     child: Row(
                       children: [
                         Expanded(
                           child: _buildCupertinoPickerField(
                             value: _selectedBirthDay,
                             placeholder: 'DD',
                             options: dayOptions,
                             onSelected: (value) {
                               setState(() {
                                 _selectedBirthDay = value;
                               });
                             },
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                          child: _buildCupertinoPickerField(
                             value: _selectedBirthMonth,
                             placeholder: 'MM',
                             options: monthOptions,
                             onSelected: (value) {
                               setState(() {
                                 _selectedBirthMonth = value;
                               });
                             },
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: _buildCupertinoPickerField(
                             value: _selectedBirthYear,
                             placeholder: 'YYYY',
                             options: yearOptions,
                             onSelected: (value) {
                               setState(() {
                                 _selectedBirthYear = value;
                               });
                             },
                           ),
                         ),
                       ],
                     ),
                   ),

                   // Step 4: Location
                   _buildStep(
                     icon: LucideIcons.map,
                     title: "What's your location?",
                     subtitle: null,
                     child: SingleChildScrollView(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           TextField(
                             controller: _locationController,
                             focusNode: _locationFocusNode,
                             keyboardType: TextInputType.streetAddress,
                             decoration: InputDecoration(
                               hintText: 'Search',
                               border: const UnderlineInputBorder(),
                               hintStyle: GoogleFonts.urbanist(
                                 fontSize: 24,
                                 color: Colors.grey.shade400,
                               ),
                             ),
                             style: GoogleFonts.urbanist(
                               fontSize: 24,
                               color: Colors.black,
                             ),
                           ),
                           const SizedBox(height: 24),
                           Row(
                             children: [
                               Icon(
                                 LucideIcons.locateFixed,
                                 size: 22,
                                 color: const Color(0xFF1D9BF0),
                               ),
                               const SizedBox(width: 10),
                               Text(
                                 'find me',
                                 style: GoogleFonts.urbanist(
                                   fontSize: 22,
                                   color: const Color(0xFF1D9BF0),
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),

                   // Step 5: Gender
                   _buildStep(
                     icon: LucideIcons.venusAndMars,
                     title: "What's your gender?",
                     subtitle: null,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildGenderOption('Man'),
                         _buildGenderOption('Woman'),
                         _buildGenderOption('Non-Binary'),
                         Padding(
                           padding: const EdgeInsets.only(left: 66),
                           child: Text(
                             'More >',
                             style: GoogleFonts.urbanist(
                               fontSize: 18,
                               color: const Color(0xFF1D9BF0),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),

                   // Step 6: Profile Picture
                   _buildStep(
                     icon: LucideIcons.image,
                     title: 'Upload a Profile Picture',
                     subtitle: null,
                     child: Column(
                       children: [
                         _buildProfileSourceButton('Photo Library'),
                         const SizedBox(height: 12),
                         _buildProfileSourceButton('Camera Roll'),
                       ],
                     ),
                   ),

                   // Step 7: Drinking Level
                   _buildStep(
                     icon: LucideIcons.martini,
                     title: 'How often do you drink on a night out?',
                     subtitle: null,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         ...frequencyOptions.map(
                           (option) => _buildPreferenceOption(
                             label: option,
                             isSelected: _selectedDrinkingLevel == option,
                             onTap: () {
                               setState(() {
                                 _selectedDrinkingLevel = option;
                               });
                             },
                           ),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           'Why am I answering this?',
                           style: GoogleFonts.urbanist(
                             fontSize: 14,
                             color: const Color(0xFF1D9BF0),
                           ),
                         ),
                       ],
                     ),
                   ),

                   // Step 8: Weed Level
                   _buildStep(
                     icon: LucideIcons.leaf,
                     title: 'How often do you smoke weed on a night out?',
                     subtitle: null,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         ...frequencyOptions.map(
                           (option) => _buildPreferenceOption(
                             label: option,
                             isSelected: _selectedWeedLevel == option,
                             onTap: () {
                               setState(() {
                                 _selectedWeedLevel = option;
                               });
                             },
                           ),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           'Why am I answering this?',
                           style: GoogleFonts.urbanist(
                             fontSize: 14,
                             color: const Color(0xFF1D9BF0),
                           ),
                         ),
                       ],
                     ),
                   ),

                   // Step 9: Cigarette Level
                   _buildStep(
                     icon: LucideIcons.cigarette,
                     title: 'How often do you smoke cigarettes on a night out?',
                     subtitle: null,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         ...frequencyOptions.map(
                           (option) => _buildPreferenceOption(
                             label: option,
                             isSelected: _selectedCigLevel == option,
                             onTap: () {
                               setState(() {
                                 _selectedCigLevel = option;
                               });
                             },
                           ),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           'Why am I answering this?',
                           style: GoogleFonts.urbanist(
                             fontSize: 14,
                             color: const Color(0xFF1D9BF0),
                           ),
                         ),
                       ],
                     ),
                   ),

                   // Step 10: Language
                   _buildStep(
                     icon: LucideIcons.languages,
                     title: 'What languages do you speak fluently?',
                     subtitle: null,
                     child: SingleChildScrollView(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           TextField(
                             controller: _languageController,
                             focusNode: _languageFocusNode,
                             keyboardType: TextInputType.text,
                             textInputAction: TextInputAction.done,
                             onSubmitted: _addLanguageFromInput,
                             decoration: InputDecoration(
                               hintText: 'Search',
                               border: const UnderlineInputBorder(),
                               hintStyle: GoogleFonts.urbanist(
                                 fontSize: 24,
                                 color: Colors.grey.shade400,
                               ),
                             ),
                             style: GoogleFonts.urbanist(
                               fontSize: 24,
                               color: Colors.black,
                             ),
                           ),
                           const SizedBox(height: 18),
                            SizedBox(
                              height: 42,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final shouldFade =
                                      _shouldFadeLanguageRow(constraints.maxWidth);

                                  final chipsRow = SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _selectedLanguages
                                          .map(
                                            (language) => Padding(
                                              padding:
                                                  const EdgeInsets.only(right: 10),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF89247B),
                                                  borderRadius:
                                                      BorderRadius.circular(22),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      language,
                                                      style:
                                                          GoogleFonts.urbanist(
                                                        fontSize: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _removeLanguage(language),
                                                      child: const Icon(
                                                        CupertinoIcons
                                                            .xmark_circle_fill,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );

                                  if (!shouldFade) return chipsRow;

                                  return ShaderMask(
                                    blendMode: BlendMode.dstIn,
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: [0.0, 0.93, 1.0],
                                        colors: [
                                          Colors.black,
                                          Colors.black,
                                          Colors.transparent,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: chipsRow,
                                  );
                                },
                              ),
                            ),
                         ],
                       ),
                     ),
                   ),

                   _buildStep(
                     icon: LucideIcons.clipboardCheck,
                     title: 'Look good?',
                     subtitle: null,
                     child: Transform.translate(
                       offset: const Offset(0, -12),
                       child: SizedBox(
                         height: 430,
                         child: ShaderMask(
                           blendMode: BlendMode.dstIn,
                           shaderCallback: (bounds) {
                             return const LinearGradient(
                               begin: Alignment.topCenter,
                               end: Alignment.bottomCenter,
                               stops: [0.0, 0.84, 1.0],
                               colors: [
                                 Colors.black,
                                 Colors.black,
                                 Colors.transparent,
                               ],
                             ).createShader(bounds);
                           },
                           child: SingleChildScrollView(
                             padding: const EdgeInsets.only(bottom: 24),
                             child: Column(
                               children: [
                                 _buildReviewRow(
                                   pageName: 'Phone',
                                   selection: '$_selectedCountryCode ${_displayOrDefault(_phoneController.text)}',
                                   onTap: () => _goToReviewSelection(0),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Birthday',
                                   selection: _birthdaySummary(),
                                   onTap: () => _goToReviewSelection(2),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Location',
                                   selection: _displayOrDefault(_locationController.text),
                                   onTap: () => _goToReviewSelection(3),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Gender',
                                   selection: _displayOrDefault(_selectedGender),
                                   onTap: () => _goToReviewSelection(4),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Drinking Level',
                                   selection: _displayOrDefault(_selectedDrinkingLevel),
                                   onTap: () => _goToReviewSelection(6),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Weed Level',
                                   selection: _displayOrDefault(_selectedWeedLevel),
                                   onTap: () => _goToReviewSelection(7),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Cigarette Level',
                                   selection: _displayOrDefault(_selectedCigLevel),
                                   onTap: () => _goToReviewSelection(8),
                                 ),
                                 Divider(color: Colors.grey.shade300, height: 1),
                                 _buildReviewRow(
                                   pageName: 'Languages',
                                   selection: _selectedLanguages.isEmpty
                                       ? 'Not set'
                                       : _selectedLanguages.join(', '),
                                   onTap: () => _goToReviewSelection(9),
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
            
            // Floating Next Button area
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: const Color(0xFF89247B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        _currentPage == _totalPages - 1
                          ? Icons.check
                            : Icons.arrow_forward,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Icon(
            icon,
            size: 34,
            color: Colors.black,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Flexible(
            fit: FlexFit.loose,
            child: child,
          ),
        ],
      ),
    );
  }
}

class UsPhoneTextInputFormatter extends TextInputFormatter {
  const UsPhoneTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 10 ? digits.substring(0, 10) : digits;

    String formatted = limitedDigits;
    if (limitedDigits.isNotEmpty) {
      if (limitedDigits.length <= 3) {
        formatted = '($limitedDigits';
      } else if (limitedDigits.length <= 6) {
        formatted =
            '(${limitedDigits.substring(0, 3)}) ${limitedDigits.substring(3)}';
      } else {
        formatted =
            '(${limitedDigits.substring(0, 3)}) ${limitedDigits.substring(3, 6)} ${limitedDigits.substring(6)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
