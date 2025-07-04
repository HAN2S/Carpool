import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/weekly_schedule_screen.dart';
import 'screens/driver_information_screen.dart';
import 'main_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


Future<void> main() async {
  await setup();
  runApp(MyApp());
}

Future<void> setup() async {
  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(dotenv.env["MAPBOX_ACCESS_TOKEN"]!,);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pendla',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme.copyWith(
                headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
                bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
                bodySmall: TextStyle(fontSize: 14, color: Colors.grey[600]),
                labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/signin': (context) => SignInScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/weekly_schedule': (context) => WeeklyScheduleScreen(),
        '/driver_information': (context) => DriverInformationScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}