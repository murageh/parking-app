import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:parking_app/models/UserModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/PaymentModel.dart';

void saveUser(User user, context, {redirect}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var userString = json.encode(user.toJson());
  prefs.setString("user", userString);
  if (redirect != null) Navigator.popAndPushNamed(context, '/');
}

Future<User> fetchCurrentUser({setUser, updateUser}) async {
  final prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> defaultUser = {
    'id': 0,
    'name': '',
    'email': '',
    'parkingSpot': null,
    'payments': List<Payment>.from([]),
  };
  var userString = prefs.getString("user");
  // print("--- userStr => " + userString.toString());
  User user = User.fromJson(defaultUser);

  if (userString != null) {
    Map<String, dynamic> map = json.decode(userString);
    // print("--- map => " + map.toString());
    user = User.fromJson(map);
    // print("--- user => " + user.toString());
  }

  if (updateUser != null) updateUser(user);
  print(user);
  return user;
}
