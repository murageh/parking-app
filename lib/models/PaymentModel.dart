import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentModel {
  List<Payment> payments = [];

  Payment getById(int id) => payments[id];

  Payment getByPosition(int position) {
    return getById(position);
  }
}

@immutable
class Payment {
  final int id;
  final int amount;
  final int userId; // In minutes
  final int parkingSpotId; // Per every additional 1 minute
  final String createdAt; // Per every additional 1 minute

  const Payment({
    required this.id,
    required this.amount,
    required this.parkingSpotId,
    required this.userId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final DateTime bookedAt = DateTime.parse(json['createdAt'] ?? "0");
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String dateTime = formatter.format(bookedAt);

    return Payment(
      id: json['id'],
      amount: json['amountPaid'],
      parkingSpotId: json['ParkingSpotId'],
      userId: json['UserId'],
      createdAt: dateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'amountPaid': this.amount,
        'UserId': this.userId,
        'ParkingSpotId': this.parkingSpotId,
        'createdAt': this.createdAt,
      };

  @override
  int get hashCode => this.id;

  @override
  bool operator ==(Object other) => other is Payment && other.id == this.id;

  @override
  String toString() {
    return "Payment Id(${this.id}) of Kes.(${this.amount}) completed on (${this.createdAt})";
  }
}
