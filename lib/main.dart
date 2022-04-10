import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parking_app/Screens/home.dart';
import 'package:parking_app/Screens/register/register.dart';

import 'Screens/login/login.dart';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

ThemeData theme = ThemeData(
  primarySwatch: createMaterialColor(Color(0xff750152)),
  backgroundColor: Color(0xFFFAFAFA),
  // Define the default font family.
  fontFamily: 'Helvetica',

  // Define the default TextTheme. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  textTheme: TextTheme(
    headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
    headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.normal),
    bodyText1: TextStyle(
      fontSize: 16.0,
    ),
    bodyText2: TextStyle(
      fontSize: 14.0,
    ),
  ),
  scaffoldBackgroundColor: Colors.white,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) {
        // final isValidHost = host == "parking-app-js.herokuapp.com";
        // Allowing multiple hosts
        final isValidHost =
            host == "parking-app-js.herokuapp.com" || host == "localhost";
        return isValidHost;
      });
  }
}

Future main() async {
  HttpOverrides.global = new MyHttpOverrides();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book your hostel',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signUp': (context) => RegisterScreen(),
        // '/home': (context) => HomeScreen(),
      },
    );
  }
}
