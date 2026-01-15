import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/data_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_trip_screen.dart';
import 'screens/add_expense_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, DataProvider>(
          create: (_) => DataProvider(),
          update: (_, settings, dataProvider) {
            dataProvider!.setSettings(settings.settings);
            return dataProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'KS Transport',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(initialTab: 0),
            ),
            GoRoute(
              path: '/trips',
              builder: (context, state) => const HomeScreen(initialTab: 1),
            ),
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const HomeScreen(initialTab: 2),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const HomeScreen(initialTab: 3),
            ),
            GoRoute(
              path: '/add-trip',
              builder: (context, state) => const AddTripScreen(),
            ),
            GoRoute(
              path: '/add-expense',
              builder: (context, state) => const AddExpenseScreen(),
            ),
          ],
        ),
        debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
