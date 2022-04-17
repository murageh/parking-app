import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:parking_app/models/ParkingSpotModel.dart';
import 'package:parking_app/models/PaymentModel.dart';
import 'package:parking_app/utils.dart';

import 'models/UserModel.dart';

String baseUrl = dotenv.get('BASE_URL', fallback: '');

Future<User> login(
    {email, password, updateLoading, isRegistration = false, details}) async {
  try {
    final suffix = isRegistration ? "" : "login";
    final Map<String, String> map = isRegistration
        ? {...details}
        : {"email": email.trim(), "password": password};

    final response =
        await http.post(Uri.parse('$baseUrl/users/$suffix'), body: {...map});

    if (response.statusCode == 200 || response.statusCode == 201) {
      var obj = jsonDecode(response.body);
      if ((obj["error"] != null && obj["error"]) ||
          (obj["success"] != null && !obj["success"])) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      var user = obj["user"] ?? {};
      if (user != null && user != {}) {
        // print("user => " + user.toString());
        // print("trying " + User.fromJson(user).toString());
        return User.fromJson(user);
      } else
        throw Exception("No user found in the server.");
    } else {
      throw Exception(
          "Login failed with status code ${response.statusCode.toString()}. ${jsonDecode(response.body)['message'] ?? ""}");
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: "login api error: " + exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    updateLoading(false);
    return Future.error(exception);
  }
}

Future<List<ParkingSpot>> fetchParkingSpots(
    {bool? booked, updateLoading}) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/parking'));
    print(response.request);

    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if (obj["success"] != null && !obj["success"]) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      var spots = obj["spots"] ?? [];
      List<ParkingSpot> list = [];
      if (booked == true) {
        spots = spots.where((spot) => (spot["booked"] == true)).toList();
      } else if (booked == false) {
        spots = spots.where((spot) => (spot["booked"] == false)).toList();
      }
      spots.forEach((spot) => list.add(ParkingSpot.fromJson(spot)));
      return list;
    } else {
      return Future.error(Exception(
          'Failed to load spots - Received an error ' +
              response.statusCode.toString()));
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    return Future.error(exception);
  }
}

Future<List<Payment>> fetchPayments({userId, updateLoading}) async {
  try {
    final response =
        await http.get(Uri.parse('$baseUrl/payments/fromUser/$userId'));
    print(response.request);

    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if (obj["success"] != null && !obj["success"]) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      var payments = obj["payments"] ?? [];
      List<Payment> list = [];
      payments.forEach((payment) => list.add(Payment.fromJson(payment)));
      return list;
    } else {
      return Future.error(Exception(
          'Failed to load payments - Received an error ' +
              response.statusCode.toString()));
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    return Future.error(exception);
  }
}

Future<User> fetchUser(
    {required int id, updateLoading, context, updateUser}) async {
  final response = await http.get(Uri.parse('$baseUrl/users/$id'));

  try {
    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if ((obj["error"] != null && obj["error"]) ||
          (obj["success"] != null && !obj["success"])) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      var user = obj["user"] ?? {};
      if (user != null && user != {}) {
        var u = User.fromJson(user);
        saveUser(u, context);
        if (updateUser != null) updateUser(u);
        // print("response " + user);
        // print("response " + user.toString());
        // if (updateUser != null) updateUser(u);
        return u;
      } else
        throw Exception('No user found with that id.');
    } else {
      throw Exception('Failed to load user data - Received an error ' +
          response.statusCode.toString());
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    updateLoading(false);
    return Future.error(exception);
  }
}

Future<bool> bookParkingSpot(
    {userId, spotId, carReg, bool? paying, updateLoading}) async {
  try {
    final Map<String, String> map = {
      "parkingSpotId": spotId.toString(),
      "carRegNo": carReg
    };
    print(map.toString());
    final response = await http
        .post(Uri.parse('$baseUrl/users/$userId/bookParking'), body: {...map});

    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if (obj["success"] != null && !obj["success"]) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      return true;
    } else {
      throw Exception('Failed to load rooms - Received an error ' +
          response.statusCode.toString());
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: "Booking " + exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    updateLoading(false);
    Future.error(exception);
    return false;
  }
}

Future<bool> pay({userId, amount, updateLoading}) async {
  try {
    final Map<String, String> map = {"amount": amount.toString()};

    final response = await http
        .post(Uri.parse('$baseUrl/users/$userId/pay'), body: {...map});

    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if (obj["success"] != null && !obj["success"]) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      return true;
    } else {
      throw Exception('Failed to make payment - Received an error ' +
          response.statusCode.toString());
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: "payment " + exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    updateLoading(false);
    Future.error(exception);
    return false;
  }
}

Future<int> getParkingBill({userId, updateLoading}) async {
  try {
    final response =
        await http.get(Uri.parse('$baseUrl/users/$userId/getBill'));

    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if (obj["success"] != null && !obj["success"]) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      print('Cost: ${obj['totalCost']}');
      return obj['totalCost'] ?? -1;
    } else {
      throw Exception('Failed to fetch bill - Received an error ' +
          response.statusCode.toString());
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: "Fetch bill " + exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    updateLoading(false);
    Future.error(exception);
    return 0;
  }
}

Future<bool> requestCheckout({userId, updateLoading}) async {
  try {
    final Map<String, String> map = {"user_id": userId.toString()};
    final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/requestCheckout'),
        body: {...map});

    if (response.statusCode == 200) {
      var obj = jsonDecode(response.body);
      if ((obj["error"] != null && obj["error"]) ||
          (obj["success"] != null && !obj["success"])) {
        throw Exception(
            obj["message"] ?? "The server could not process this request.");
      }
      return true;
    } else {
      throw Exception('Failed to request clearance - Received an error ' +
          response.statusCode.toString());
    }
  } catch (exception) {
    Fluttertoast.showToast(
        msg: "Checkout " + exception.toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red);
    updateLoading(false);
    Future.error(exception);
    return false;
  }
}
