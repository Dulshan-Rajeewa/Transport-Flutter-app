class Trip {
  final String? id;
  final String route;
  final int kilometers;
  final double earnings;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? driverPayment;
  final double? fuelCost;

  Trip({
    this.id,
    required this.route,
    required this.kilometers,
    required this.earnings,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.driverPayment,
    this.fuelCost,
  });

  factory Trip.fromFirestore(Map<String, dynamic> data, String id) {
    final now = DateTime.now();
    return Trip(
      id: id,
      route: data['route'] ?? '',
      kilometers: data['kilometers'] ?? 0,
      earnings: (data['earnings'] ?? 0).toDouble(),
      date: data['date'] != null ? (data['date'] as dynamic).toDate() : now,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate() : now,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as dynamic).toDate() : now,
      driverPayment: data['driverPayment'] != null ? (data['driverPayment'] as num).toDouble() : null,
      fuelCost: data['fuelCost'] != null ? (data['fuelCost'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'route': route,
      'kilometers': kilometers,
      'earnings': earnings,
      'date': date,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'driverPayment': driverPayment,
      'fuelCost': fuelCost,
    };
  }
}
