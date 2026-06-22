/// Data models for the Virent mobile app.

class Scooter {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int battery;
  final String status;
  final int ratePerMin;
  final int? distance;

  Scooter({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.battery,
    required this.status,
    required this.ratePerMin,
    this.distance,
  });

  factory Scooter.fromJson(Map<String, dynamic> json) => Scooter(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        lat: (json['lat'] ?? 0).toDouble(),
        lng: (json['lng'] ?? 0).toDouble(),
        battery: json['battery'] ?? 0,
        status: json['status'] ?? 'unknown',
        ratePerMin: json['rate_per_min'] ?? 1200,
        distance: json['distance'],
      );
}

class Trip {
  final String id;
  final String scooterId;
  final String? startTime;
  final String? endTime;
  final int? startBattery;
  final int? cost;
  final String status;
  final int? durationMin;

  Trip({
    required this.id,
    required this.scooterId,
    this.startTime,
    this.endTime,
    this.startBattery,
    this.cost,
    required this.status,
    this.durationMin,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] ?? '',
        scooterId: json['scooter_id'] ?? '',
        startTime: json['start_time'],
        endTime: json['end_time'],
        startBattery: json['start_battery'],
        cost: json['cost'],
        status: json['status'] ?? 'unknown',
        durationMin: json['duration_min'],
      );
}

class User {
  final String id;
  final String? phone;
  final String? name;
  final String? email;
  final int balance;
  final int tripsCount;
  final String? createdAt;

  User({
    required this.id,
    this.phone,
    this.name,
    this.email,
    this.balance = 0,
    this.tripsCount = 0,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        phone: json['phone'],
        name: json['name'],
        email: json['email'],
        balance: json['balance'] ?? 0,
        tripsCount: json['trips_count'] ?? 0,
        createdAt: json['created_at'],
      );
}

class Transaction {
  final String id;
  final String type;
  final int amount;
  final String description;
  final String createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        amount: json['amount'] ?? 0,
        description: json['description'] ?? '',
        createdAt: json['created_at'] ?? '',
      );
}
