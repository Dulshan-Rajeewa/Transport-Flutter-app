import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../models/trip.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? tripToEdit;
  
  const AddTripScreen({super.key, this.tripToEdit});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _kilometersController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showRoutePicker = false;
  double _calculatedEarnings = 0.0;
  double _calculatedDriverPayment = 0.0;
  double _calculatedFuelCost = 0.0;

  @override
  void initState() {
    super.initState();
    
    // If editing, populate fields with existing data
    if (widget.tripToEdit != null) {
      _routeController.text = widget.tripToEdit!.route;
      _kilometersController.text = widget.tripToEdit!.kilometers.toString();
      _selectedDate = widget.tripToEdit!.date;
      _calculatedEarnings = widget.tripToEdit!.earnings ?? 0.0;
      _calculatedDriverPayment = widget.tripToEdit!.driverPayment ?? 0.0;
      _calculatedFuelCost = widget.tripToEdit!.fuelCost ?? 0.0;
    }
    
    _kilometersController.addListener(_calculateValues);
  }

  void _calculateValues() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final kilometers = int.tryParse(_kilometersController.text) ?? 0;
    setState(() {
      _calculatedEarnings = kilometers * settingsProvider.settings.pricePerKm;
      _calculatedDriverPayment = kilometers * settingsProvider.settings.driverPaymentPerKm;
      _calculatedFuelCost = kilometers * settingsProvider.settings.fuelCostPerKm;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  @override
  void dispose() {
    _kilometersController.removeListener(_calculateValues);
    _routeController.dispose();
    _kilometersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleAddTrip() async {
    if (_formKey.currentState!.validate()) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      final trip = Trip(
        id: widget.tripToEdit?.id,
        route: _routeController.text.trim(),
        kilometers: int.parse(_kilometersController.text),
        earnings: _calculatedEarnings,
        date: _selectedDate,
        createdAt: widget.tripToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        driverPayment: _calculatedDriverPayment,
        fuelCost: _calculatedFuelCost,
      );

      final bool success;
      if (widget.tripToEdit != null) {
        success = await dataProvider.updateTrip(widget.tripToEdit!.id!, trip);
      } else {
        success = await dataProvider.addTrip(trip);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.tripToEdit != null 
                ? 'Trip updated successfully!' 
                : 'Trip added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dataProvider.error ?? (widget.tripToEdit != null 
                ? 'Failed to update trip' 
                : 'Failed to add trip')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoutePickerModal() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final routes = settingsProvider.settings.defaultRoutes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Route',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                  final route = routes[index];
                  final isSelected = _routeController.text == route;
                  final isCustom = route == 'Custom Route';
                  
                  if (isCustom) {
                    return ListTile(
                      leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                      title: const Text(
                        'Custom Route',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Enter your own route'),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              title: const Text('Enter Custom Route'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., Panadura - Colombo',
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
                                    if (controller.text.isNotEmpty) {
                                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                                      
                                      // Save custom route to Firebase
                                      await settingsProvider.addCustomRoute(controller.text.trim());
                                      
                                      setState(() {
                                        _routeController.text = controller.text;
                                        _showRoutePicker = false;
                                      });
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }
                  
                  return ListTile(
                    leading: Icon(
                      Icons.route,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: Text(
                      route,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _routeController.text = route;
                        _showRoutePicker = false;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    if (_showRoutePicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRoutePickerModal();
        setState(() {
          _showRoutePicker = false;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripToEdit != null ? 'Edit Trip' : 'Add Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Route Picker
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showRoutePicker = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _routeController.text.isEmpty
                              ? 'Select Route'
                              : _routeController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: _routeController.text.isEmpty
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kilometersController,
                decoration: const InputDecoration(
                  labelText: 'Kilometers',
                  prefixIcon: Icon(Icons.speed),
                  hintText: 'Enter distance in km',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter kilometers';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Calculated Earnings Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculated Earnings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${_calculatedEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) => Text(
                              '${_kilometersController.text.isEmpty ? '0' : _kilometersController.text} km × Rs ${settings.settings.pricePerKm}/km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Automatic Expenses Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Automatic Expenses',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Color(0xFF9C27B0)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Driver Payment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs ${_calculatedDriverPayment.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9C27B0),
                                ),
                              ),
                              Consumer<SettingsProvider>(
                                builder: (context, settings, _) => Text(
                                  '${_kilometersController.text.isEmpty ? '0' : _kilometersController.text} km × Rs ${settings.settings.driverPaymentPerKm}/km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_gas_station, size: 16, color: Color(0xFFFF6B35)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Fuel Cost',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs ${_calculatedFuelCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                              Consumer<SettingsProvider>(
                                builder: (context, settings, _) => Text(
                                  '${_kilometersController.text.isEmpty ? '0' : _kilometersController.text} km × Rs ${settings.settings.fuelCostPerKm}/km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These expenses will be added automatically and can be edited later',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Date Picker with Today/Yesterday buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isToday(_selectedDate)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            foregroundColor: _isToday(_selectedDate)
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate =
                                  DateTime.now().subtract(const Duration(days: 1));
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isYesterday(_selectedDate)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            foregroundColor: _isYesterday(_selectedDate)
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text('Yesterday'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _selectDate(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: dataProvider.isLoading ? null : _handleAddTrip,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: dataProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.tripToEdit != null ? 'Update Trip' : 'Add Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
