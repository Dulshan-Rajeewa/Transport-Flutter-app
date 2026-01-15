class AppSettings {
  final double pricePerKm;
  final double driverPaymentPerKm;
  final double fuelCostPerKm;
  final List<String> defaultRoutes;
  final String currency;

  AppSettings({
    required this.pricePerKm,
    required this.driverPaymentPerKm,
    required this.fuelCostPerKm,
    required this.defaultRoutes,
    required this.currency,
  });

  static AppSettings get defaultSettings => AppSettings(
        pricePerKm: 50.0, // Default rate in LKR
        driverPaymentPerKm: 25.0, // Default driver payment per km in LKR
        fuelCostPerKm: 8.0, // Default fuel cost per km in LKR
        defaultRoutes: [
          'Panadura',
          'High level',
          'Veyangoda',
          'Kaluthara',
          'Divulapitiya',
          'Kottawa',
          'Katharagama',
          'Colombo',
          'Kerawalapitiya',
          'Ja ela',
          'Kelaniya',
          'Badulla',
          'Galle',
          'Custom Route',
        ],
        currency: 'Rs',
      );

  Map<String, dynamic> toJson() {
    return {
      'pricePerKm': pricePerKm,
      'driverPaymentPerKm': driverPaymentPerKm,
      'fuelCostPerKm': fuelCostPerKm,
      'defaultRoutes': defaultRoutes,
      'currency': currency,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      pricePerKm: (json['pricePerKm'] ?? 50.0).toDouble(),
      driverPaymentPerKm: (json['driverPaymentPerKm'] ?? 25.0).toDouble(),
      fuelCostPerKm: (json['fuelCostPerKm'] ?? 8.0).toDouble(),
      defaultRoutes: List<String>.from(json['defaultRoutes'] ?? []),
      currency: json['currency'] ?? 'Rs',
    );
  }

  AppSettings copyWith({
    double? pricePerKm,
    double? driverPaymentPerKm,
    double? fuelCostPerKm,
    List<String>? defaultRoutes,
    String? currency,
  }) {
    return AppSettings(
      pricePerKm: pricePerKm ?? this.pricePerKm,
      driverPaymentPerKm: driverPaymentPerKm ?? this.driverPaymentPerKm,
      fuelCostPerKm: fuelCostPerKm ?? this.fuelCostPerKm,
      defaultRoutes: defaultRoutes ?? this.defaultRoutes,
      currency: currency ?? this.currency,
    );
  }
}
