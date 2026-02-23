import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3; // Phone, Code, Name (Example)
  String _selectedCountryCode = '+1';

  // Controllers for inputs
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(6, (i) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (i) => FocusNode());

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
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

  @override
  Widget build(BuildContext context) {
    // Calculate progress as a value between 0.0 and 1.0
    double progress = (_currentPage + 1) / (_totalPages*2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevPage,
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
                           child: Theme(
                             data: Theme.of(context).copyWith(
                               highlightColor: Colors.transparent,
                               splashColor: Colors.transparent,
                               hoverColor: Colors.transparent,
                               focusColor: Colors.transparent,
                             ),
                             child: DropdownButtonFormField<String>(
                               initialValue: _selectedCountryCode,
                               borderRadius: BorderRadius.circular(16),
                               isDense: true,
                               itemHeight: kMinInteractiveDimension,
                               menuMaxHeight: 180,
                               dropdownColor: Colors.white,
                               decoration: const InputDecoration(
                                 border: UnderlineInputBorder(),
                               ),
                               style: GoogleFonts.urbanist(
                                 fontSize: 24,
                                 color: Colors.black,
                               ),
                               selectedItemBuilder: (context) {
                                 return ['+1', '+55', '+44']
                                     .map(
                                       (code) => Container(
                                         color: Colors.transparent,
                                         child: Text(code),
                                       ),
                                     )
                                     .toList();
                               },
                               items: ['+1', '+55', '+44']
                                   .map(
                                     (code) => DropdownMenuItem<String>(
                                       value: code,
                                       child: Container(
                                         color: Colors.transparent,
                                         child: Text(code),
                                       ),
                                     ),
                                   )
                                   .toList(),
                               onChanged: (value) {
                                 if (value == null) return;
                                 setState(() {
                                   _selectedCountryCode = value;
                                 });
                               },
                             ),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: TextField(
                             controller: _phoneController,
                             keyboardType: TextInputType.phone,
                             inputFormatters: const [UsPhoneTextInputFormatter()],
                             autofocus: true,
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
                     title: "Enter the code",
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

                   // Step 3: Name (Placeholder)
                   _buildStep(
                     icon: LucideIcons.idCard,
                     title: "What's your name?",
                     subtitle: "This needs to be your real name.",
                     child: Center(
                        child: Text("Name input goes here", style: GoogleFonts.urbanist(fontSize: 18, color: Colors.black)),
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
                      child: const Icon(Icons.arrow_forward, size: 30),
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
          const SizedBox(height: 40),
          child,
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
