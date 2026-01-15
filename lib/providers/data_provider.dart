import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/settings.dart';
import '../services/firebase_service.dart';

class MonthlyStats {
  final double totalEarnings;
  final double totalExpenses;
  final int totalKilometers;
  final int totalTrips;
  final double netProfit;
  final double averagePerTrip;
  final double automaticDriverPayment;
  final double automaticFuelCost;
  final double totalExpensesWithAutomatic;
  final double netProfitWithAutomatic;

  MonthlyStats({
    required this.totalEarnings,
    required this.totalExpenses,
    required this.totalKilometers,
    required this.totalTrips,
    required this.netProfit,
    required this.averagePerTrip,
    required this.automaticDriverPayment,
    required this.automaticFuelCost,
    required this.totalExpensesWithAutomatic,
    required this.netProfitWithAutomatic,
  });
}

class DataProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  MonthlyStats? _monthlyStats;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  AppSettings? _settings;

  List<Trip> get trips => _trips;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MonthlyStats? get monthlyStats => _monthlyStats;
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;

  // Month navigation
  void goToPreviousMonth() {
    if (_currentMonth == 1) {
      _currentMonth = 12;
      _currentYear--;
    } else {
      _currentMonth--;
    }
    notifyListeners();
    _loadInitialData();
  }

  void goToNextMonth() {
    final now = DateTime.now();
    final isCurrentMonth =
        _currentMonth == now.month && _currentYear == now.year;

    if (!isCurrentMonth) {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
      notifyListeners();
      _loadInitialData();
    }
  }

  void goToCurrentMonth() {
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;
    notifyListeners();
    _loadInitialData();
  }

  void setSettings(AppSettings settings) {
    final needsRefresh = _settings != null &&
        (_settings!.driverPaymentPerKm != settings.driverPaymentPerKm ||
            _settings!.fuelCostPerKm != settings.fuelCostPerKm);

    _settings = settings;

    if (needsRefresh) {
      debugPrint('⚙️ Settings changed, refreshing data');
      _loadInitialData();
    }
  }

  Future<void> refreshAllData() async {
    debugPrint('🔄 Refreshing all data from Firestore...');
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _isLoading = true;
      notifyListeners();

      await Future.wait([
        _loadTrips(),
        _loadExpenses(),
      ]);

      await _loadMonthlyStats();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrips() async {
    await _loadTrips();
  }

  Future<void> fetchExpenses() async {
    await _loadExpenses();
  }

  Future<void> _loadTrips() async {
    try {
      debugPrint('🔍 Loading trips from Firebase...');

      final querySnapshot = await FirebaseService.tripsCollection.get();
      final allTrips = querySnapshot.docs
          .map((doc) => Trip.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      debugPrint('📊 All trips from Firebase: ${allTrips.length}');

      // Filter trips by current month/year
      _trips = allTrips.where((trip) {
        return trip.date.month == _currentMonth &&
            trip.date.year == _currentYear;
      }).toList();

      // Sort by date descending (newest first)
      _trips.sort((a, b) => b.date.compareTo(a.date));

      debugPrint(
          '✅ Filtered trips for $_currentMonth/$_currentYear: ${_trips.length}');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading trips: $e');
      rethrow;
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final querySnapshot = await FirebaseService.expensesCollection.get();
      final allExpenses = querySnapshot.docs
          .map((doc) => Expense.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter expenses by current month/year
      _expenses = allExpenses.where((expense) {
        return expense.date.month == _currentMonth &&
            expense.date.year == _currentYear;
      }).toList();

      // Sort by date descending (newest first)
      _expenses.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading expenses: $e');
      rethrow;
    }
  }

  Future<void> _loadMonthlyStats() async {
    if (_settings == null) {
      debugPrint('⚠️ Settings not loaded yet, skipping stats calculation');
      return;
    }

    try {
      final totalEarnings =
          _trips.fold<double>(0, (total, trip) => total + (trip.earnings ?? 0));
      final totalKilometers =
          _trips.fold<int>(0, (total, trip) => total + (trip.kilometers ?? 0));
      final totalTrips = _trips.length;

      // All expenses from database
      final totalExpenses =
          _expenses.fold<double>(0, (total, exp) => total + exp.amount);

      final netProfit = totalEarnings - totalExpenses;
      final averagePerTrip = totalTrips > 0 ? totalEarnings / totalTrips : 0.0;

      _monthlyStats = MonthlyStats(
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        totalKilometers: totalKilometers,
        totalTrips: totalTrips,
        netProfit: netProfit,
        averagePerTrip: averagePerTrip,
        automaticDriverPayment: 0,
        automaticFuelCost: 0,
        totalExpensesWithAutomatic: totalExpenses,
        netProfitWithAutomatic: netProfit,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
    }
  }

  Future<bool> addTrip(Trip trip) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await FirebaseService.tripsCollection.add(trip.toFirestore());

      // Add automatic expense entries for this trip
      if (trip.driverPayment != null && trip.driverPayment! > 0) {
        final driverExpense = Expense(
          type: 'Driver Payment',
          amount: trip.driverPayment!,
          description: '${trip.route} - ${trip.kilometers} km × Rs ${(trip.driverPayment! / trip.kilometers).toStringAsFixed(2)}/km',
          date: trip.date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isAutomatic: false, // Set to false so user can edit/delete
        );
        await FirebaseService.expensesCollection.add(driverExpense.toFirestore());
      }

      if (trip.fuelCost != null && trip.fuelCost! > 0) {
        final fuelExpense = Expense(
          type: 'Fuel Cost',
          amount: trip.fuelCost!,
          description: '${trip.route} - ${trip.kilometers} km × Rs ${(trip.fuelCost! / trip.kilometers).toStringAsFixed(2)}/km',
          date: trip.date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isAutomatic: false, // Set to false so user can edit/delete
        );
        await FirebaseService.expensesCollection.add(fuelExpense.toFirestore());
      }

      await _loadTrips();
      await _loadExpenses();
      await _loadMonthlyStats();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding trip: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTrip(String tripId, Trip updatedTrip) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      // Get the old trip data first
      final oldTripDoc = await FirebaseService.tripsCollection.doc(tripId).get();
      final oldTripData = oldTripDoc.data() as Map<String, dynamic>?;
      
      // Update the trip
      await FirebaseService.tripsCollection
          .doc(tripId)
          .update(updatedTrip.toFirestore());

      // Update associated expenses (driver payment and fuel cost)
      if (oldTripData != null) {
        final oldRoute = oldTripData['route'];
        final oldDate = (oldTripData['date'] as Timestamp).toDate();
        
        // Find and update driver payment expense
        final driverPaymentQuery = await FirebaseService.expensesCollection
            .where('type', isEqualTo: 'Driver Payment')
            .where('date', isEqualTo: Timestamp.fromDate(oldDate))
            .get();
        
        for (var doc in driverPaymentQuery.docs) {
          final expense = doc.data() as Map<String, dynamic>;
          final description = expense['description'] as String?;
          if (description != null && description.contains(oldRoute)) {
            // Update driver payment expense
            if (updatedTrip.driverPayment != null && updatedTrip.driverPayment! > 0) {
              await doc.reference.update({
                'amount': updatedTrip.driverPayment,
                'description': '${updatedTrip.route} - ${updatedTrip.kilometers} km × Rs ${(updatedTrip.driverPayment! / updatedTrip.kilometers).toStringAsFixed(2)}/km',
                'date': Timestamp.fromDate(updatedTrip.date),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
        
        // Find and update fuel cost expense
        final fuelCostQuery = await FirebaseService.expensesCollection
            .where('type', isEqualTo: 'Fuel Cost')
            .where('date', isEqualTo: Timestamp.fromDate(oldDate))
            .get();
        
        for (var doc in fuelCostQuery.docs) {
          final expense = doc.data() as Map<String, dynamic>;
          final description = expense['description'] as String?;
          if (description != null && description.contains(oldRoute)) {
            // Update fuel cost expense
            if (updatedTrip.fuelCost != null && updatedTrip.fuelCost! > 0) {
              await doc.reference.update({
                'amount': updatedTrip.fuelCost,
                'description': '${updatedTrip.route} - ${updatedTrip.kilometers} km × Rs ${(updatedTrip.fuelCost! / updatedTrip.kilometers).toStringAsFixed(2)}/km',
                'date': Timestamp.fromDate(updatedTrip.date),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      await _loadTrips();
      await _loadExpenses();
      await _loadMonthlyStats();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating trip: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await FirebaseService.tripsCollection.doc(tripId).delete();

      await _loadTrips();
      await _loadExpenses(); // Reload expenses to update automatic calculations
      await _loadMonthlyStats();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting trip: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await FirebaseService.expensesCollection.add(expense.toFirestore());

      await _loadExpenses();
      await _loadMonthlyStats();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding expense: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateExpense(String expenseId, Expense updatedExpense) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await FirebaseService.expensesCollection
          .doc(expenseId)
          .update(updatedExpense.toFirestore());

      await _loadExpenses();
      await _loadMonthlyStats();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating expense: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await FirebaseService.expensesCollection.doc(expenseId).delete();

      await _loadExpenses();
      await _loadMonthlyStats();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting expense: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _loadInitialData();
  }

  // Computed properties matching React Native
  double get totalEarnings => _monthlyStats?.totalEarnings ?? 0;
  double get totalExpenses => _monthlyStats?.totalExpenses ?? 0;
  int get totalKilometers => _monthlyStats?.totalKilometers ?? 0;
  double get profit => _monthlyStats?.netProfit ?? 0;
}
