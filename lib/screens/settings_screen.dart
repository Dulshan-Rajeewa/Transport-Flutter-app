import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pricePerKmController = TextEditingController();
  final _driverPaymentController = TextEditingController();
  final _fuelCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _pricePerKmController.text = settings.pricePerKm.toString();
    _driverPaymentController.text = settings.driverPaymentPerKm.toString();
    _fuelCostController.text = settings.fuelCostPerKm.toString();
  }

  @override
  void dispose() {
    _pricePerKmController.dispose();
    _driverPaymentController.dispose();
    _fuelCostController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    try {
      await settingsProvider.updatePartialSettings(
        pricePerKm: double.tryParse(_pricePerKmController.text),
        driverPaymentPerKm: double.tryParse(_driverPaymentController.text),
        fuelCostPerKm: double.tryParse(_fuelCostController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: Text(themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
                      secondary: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Pricing Configuration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pricePerKmController,
                    decoration: const InputDecoration(
                      labelText: 'Price Per KM (Rs)',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'Enter price per kilometer',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _driverPaymentController,
                    decoration: const InputDecoration(
                      labelText: 'Driver Payment Per KM (Rs)',
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Enter driver payment per kilometer',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fuelCostController,
                    decoration: const InputDecoration(
                      labelText: 'Fuel Cost Per KM (Rs)',
                      prefixIcon: Icon(Icons.local_gas_station),
                      hintText: 'Enter fuel cost per kilometer',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Default Routes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Routes are used in the trip creation form',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...settingsProvider.settings.defaultRoutes.where((route) => route != 'Custom Route').map(
                    (route) {
                      final isDefaultRoute = [
                        'Panadura', 'High level', 'Veyangoda', 'Kaluthara',
                        'Divulapitiya', 'Kottawa', 'Katharagama', 'Colombo',
                        'Kerawalapitiya', 'Ja ela', 'Kelaniya', 'Badulla', 'Galle'
                      ].contains(route);
                      
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.route),
                          title: Text(route),
                          trailing: isDefaultRoute
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: Colors.blue,
                                      onPressed: () => _editRoute(context, route, settingsProvider),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red,
                                      onPressed: () => _deleteRoute(context, route, settingsProvider),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Automatic Expense Calculation',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The app automatically calculates monthly driver payment and fuel costs based on total kilometers driven and the rates configured above. These automatic expenses are shown separately in the expenses list and included in the profit calculations.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _editRoute(BuildContext context, String oldRoute, SettingsProvider settingsProvider) {
    final controller = TextEditingController(text: oldRoute);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Route'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter route name',
            labelText: 'Route',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != oldRoute) {
                await settingsProvider.updateRoute(oldRoute, controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Route updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteRoute(BuildContext context, String route, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete \"$route\"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settingsProvider.deleteRoute(route);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
