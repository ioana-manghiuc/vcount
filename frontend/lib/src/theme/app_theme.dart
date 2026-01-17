// import 'package:flutter/material.dart';

// class AppTheme {
//   static ThemeData buildLightTheme() {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       scaffoldBackgroundColor: const Color.fromARGB(255, 245,236,236),
//       colorScheme: ColorScheme.light(
//         primary: const Color.fromARGB(255,124,41,41)!,           // Dark red
//         onPrimary: Colors.white,
//         secondary: const Color.fromARGB(255, 109, 12, 12)!,         // Red
//         onSecondary: Colors.white,
//         surface: Colors.white,
//         onSurface: Colors.black,
//         error: Colors.red[700]!,
//       ),
//       appBarTheme: AppBarTheme(
//         backgroundColor: const Color.fromARGB(255, 232,224,224),
//         foregroundColor: const Color.fromARGB(255,41,7,6),
//         elevation: 2,
//       ),
//       cardTheme: CardTheme(
//         color: Colors.grey[50],
//         elevation: 1,
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color.fromARGB(255,124,41,41),
//           foregroundColor: Colors.white,
//         ),
//       ),
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: const Color.fromARGB(255,124,41,41),
//         ),
//       ),
//       toggleButtonsTheme: ToggleButtonsThemeData(
//         fillColor: const Color.fromARGB(255,124,41,41),        // Background when selected
//         selectedColor: const Color.fromARGB(255, 245,236,236),        // Text color when selected
//         color: Colors.grey[600],            // Text color when not selected
//         borderColor: const Color.fromARGB(255,124,41,41),       // Border color
//         selectedBorderColor: const Color.fromARGB(255,41,7,6),
//       ),
//       iconTheme: const IconThemeData(color: Color.fromARGB(255,41,7,6)),
//     );
//   }

//   static ThemeData buildDarkTheme() {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       scaffoldBackgroundColor: Colors.black,
//       colorScheme: ColorScheme.dark(
//         primary: Colors.red[400]!,            // Lighter red for dark mode
//         onPrimary: Colors.black,
//         secondary: Colors.red[300]!,          // Light red
//         onSecondary: Colors.black,
//         surface: Colors.grey[900]!,
//         onSurface: Colors.white,
//         background: Colors.black,
//         onBackground: Colors.white,
//         error: Colors.red[400]!,
//       ),
//       appBarTheme: AppBarTheme(
//         backgroundColor: Colors.grey[900],
//         foregroundColor: Colors.white,
//         elevation: 2,
//       ),
//       cardTheme: CardTheme(
//         color: Colors.grey[850],
//         elevation: 1,
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red[400],
//           foregroundColor: Colors.black,
//         ),
//       ),
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: Colors.red[400],
//         ),
//       ),
//       iconTheme: const IconThemeData(color: Colors.white70),
//     );
//   }
// }
