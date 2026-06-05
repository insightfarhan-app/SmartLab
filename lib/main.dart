import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smartlab/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (kIsWeb) {
          final isDesktopWeb = defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux;

          if (isDesktopWeb) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Please switch to mobile web to run the app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            );
          }
        }
        return child!;
      },
      home: const SplashScreen(),
    ),
  );
}
