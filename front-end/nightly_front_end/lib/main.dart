import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightly_front_end/create_account_page.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        textTheme: GoogleFonts.urbanistTextTheme(
          Theme.of(context).textTheme,
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
        ),

        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // int _counter = 0;

  // void _incrementCounter() {
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _counter++;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Extend the body behind the AppBar so the gradient hits the top of the phone
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent, // Makes the bar clear
        elevation: 0, // Removes the shadow
      ),
      
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/gradient.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 90.0), // Adjust spacing from the top
                child: Image.asset(
                  'assets/images/logo.webp',
                  width: 240, // Set the width of your logo
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                // const Text(
                //   'Test text',
                //   style: TextStyle(color: Colors.white, fontSize: 24),
                // ),
                // Text(
                //   '$_counter',
                //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                //         color: Colors.white,
                //       ),
                // ),
              ],
            ),
          ),

          // TERMS & PRIVACY TEXT
          Positioned(
            bottom: 215.0, // Positioned above the buttons
            left: 40.0,
            right: 40.0,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5, // Line height for readability
                ),
                children: [
                  const TextSpan(text: 'By tapping “Sign in” / “Create Account”, you agree to our '),
                  TextSpan(
                    text: 'Terms',
                    style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url = 'https://www.cs.mcgill.ca/~jvybihal/index.php';
                        if (!await launchUrl(Uri.parse(url))) {
                          throw Exception('Could not launch $url');
                        }
                      },
                  ),
                  const TextSpan(text: '. Learn how your data is processed in our '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url = 'https://www.cs.mcgill.ca/~jvybihal/index.php';
                        if (!await launchUrl(Uri.parse(url))) {
                          throw Exception('Could not launch $url');
                        }
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Cookies Policy',
                    style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url = 'https://www.cs.mcgill.ca/~jvybihal/index.php';
                        if (!await launchUrl(Uri.parse(url))) {
                          throw Exception('Could not launch $url');
                        }
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),

          // CREATE ACCOUNT BUTTON
          Positioned(
            bottom: 135.0, // Distance from the bottom of the screen
            left: 40.0,   // Distance from the left side
            right: 40.0,  // Distance from the right side
            child: SizedBox(
              height: 60, // Height of the button
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE06073),
                  foregroundColor: Colors.white, // Text color
                  shape: const StadiumBorder(), // This creates the "Oval/Pill" shape automatically
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          

          // SIGN IN BUTTON
          Positioned(
            bottom: 50.0, // Distance from the bottom of the screen
            left: 40.0,   // Distance from the left side
            right: 40.0,  // Distance from the right side
            child: SizedBox(
              height: 60, // Height of the button
              child: ElevatedButton(
                onPressed: () {
                  print("Button Pressed!");
                },
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(
                    color: const Color(0xFFE06073), // The stroke color
                    width: 2.0,        // The stroke width
                  ),
                  backgroundColor: const Color(0xFFE06073).withOpacity(0),

                  foregroundColor: Colors.white, // Text color
                  shape: const StadiumBorder(), // This creates the "Oval/Pill" shape automatically
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),

        ]
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
