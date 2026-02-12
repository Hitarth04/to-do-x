import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:to_do_x/core/notification_service.dart';
import 'screens/home/home_screen.dart';
import 'core/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    bool isDark = box.read('isDark') ?? false;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do X',

      // LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.cardBgLight,
        primaryColor: AppColors.primary, // Shared Purple
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textMainLight,
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.cardBgLight,
        ),
      ),

      // DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark, // Lighter Black
        cardColor: AppColors.cardBgDark, // Dark Grey
        primaryColor: AppColors.primary, // Shared Purple (Kept same)
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textMainDark, // Pure White
        ),
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary, // Shared Purple
          secondary: AppColors.accent,
          surface: AppColors.cardBgDark,
        ),
        // Ensure standard text styles default to white
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(),
    );
  }
}
