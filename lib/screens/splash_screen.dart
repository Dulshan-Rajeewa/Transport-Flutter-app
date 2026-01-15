import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    try {
      // Wait for providers to be available
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Force reload settings from Firestore to get latest data
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        await settingsProvider.loadSettings();
        
        // Wait a bit for settings to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh all data from Firestore
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.refreshAllData();
        
        // Wait remaining time to show splash
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error loading data on startup: $e');
    }
    
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/Lorry.png',
              width: 150,
              height: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'KS Transport',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
