import 'package:flutter/material.dart';

import 'ParkingSpotModel.dart';
import 'PaymentModel.dart';

@immutable
class User {
  final int id;
  final String name;
  final String email;
  final ParkingSpot? parkingSpot;
  final List<Payment> payments;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.parkingSpot,
    required this.payments,
  });

  factory User.fromJson(Map<String, dynamic> body) {
    List<Payment> list = [];
    if (body['payments'] != null) {
      body['payments'].forEach((element) {
        // print("--- element " + element.toString());
        Payment payment = Payment.fromJson({...element});
        // print("--- payment  " + payment.toString());
        list.add(payment);
      });
    }
    // print("--- list " + list.toString());

    return User(
      id: body['id'],
      name: body['name'],
      email: body['email'],
      payments: list,
      parkingSpot: body['parkingSpot'] != null
          ? ParkingSpot.fromJson(body['parkingSpot'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    List list = [];
    this.payments.forEach((payment) {
      list.add(payment.toJson());
    });
    // print("user payments to json - " + list.toString());
    return {
      'id': this.id,
      'name': this.name,
      'email': this.email,
      'payments': [...list],
      'parkingSpot':
          this.parkingSpot != null ? this.parkingSpot?.toJson() : null,
    };
  }

  @override
  int get hashCode => this.id;

  @override
  bool operator ==(Object other) => other is User && other.id == this.id;

  @override
  String toString() {
    return "${this.name}, id(${this.id}) car(${this.parkingSpot != null ? this.parkingSpot?.currentVehicle : null}) email(${this.email}), "
        "booked(${this.parkingSpot != null ? this.parkingSpot?.name : "none"}) made ${this.payments.length} payments";
  }
}
