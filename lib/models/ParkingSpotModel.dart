import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParkingSpotModel {
  List<ParkingSpot> spots = [];

  /// Get room by [id].
  ///
  /// In this sample, the catalog is infinite, looping over [spots].
  ParkingSpot getById(int id) => spots[id];

  /// Get item by its position in the catalog.
  ParkingSpot getByPosition(int position) {
    return getById(position);
  }
}

@immutable
class ParkingSpot {
  final int id;
  final String name;
  final int cost;
  final int duration; // In minutes
  final int lateFee; // Per every additional 1 minute
  final bool booked;
  final String? bookedAt;
  final String? currentVehicle;
  final int? userId;

  const ParkingSpot({
    required this.id,
    required this.name,
    required this.cost,
    required this.duration,
    required this.lateFee,
    required this.booked,
    required this.bookedAt,
    required this.currentVehicle,
    required this.userId,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      cost: int.parse(json['cost'].toString()),
      duration: int.parse(json['duration'].toString()),
      lateFee: int.parse(json['lateFee'].toString()),
      booked: json['booked'] == true,
      bookedAt: json['bookedAt'] ?? null,
      currentVehicle: json['currentVehicle'] ?? null,
      userId: json['UserId'] ?? null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'name': this.name,
        'cost': this.cost,
        'duration': this.duration,
        'lateFee': this.lateFee,
        'booked': this.booked == true,
        'bookedAt': this.bookedAt,
        'currentVehicle': this.currentVehicle,
        'UserId': this.userId,
      };

  @override
  int get hashCode => this.id;

  @override
  bool operator ==(Object other) => other is ParkingSpot && other.id == this.id;

  @override
  String toString() {
    final DateTime bookedAt = DateTime.parse(this.bookedAt ?? "0");
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String dateTime = formatter.format(bookedAt);
    return "${this.name}:id(${this.name}) current vehicle (${this.currentVehicle}) booked at ${this.bookedAt != null ? dateTime : null}";
  }
}
