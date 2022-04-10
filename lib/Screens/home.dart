import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parking_app/api.dart';
import 'package:parking_app/models/ParkingSpotModel.dart';
import 'package:parking_app/models/PaymentModel.dart';
import 'package:parking_app/models/UserModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_dialog_box.dart';
import '../utils.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<User?> futureUser;
  late Future<List<ParkingSpot>> futureParkingSpots;

  // late Future<List<Payment>> futurePayments;
  late User user;
  bool _loading = false;
  bool _paymentLoading = false;
  bool _bookingLoading = false;
  late SharedPreferences preferences;

  @override
  void initState() {
    super.initState();
    asyncMethod();
  }

  void asyncMethod() async {
    futureUser = fetchCurrentUser(setUser: true, updateUser: setUser);
    futureParkingSpots = fetchParkingSpots();
    // futurePayments = fetchPayments();

    preferences = await SharedPreferences.getInstance();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void setUser(value) => user = value;

  void asyncFetchUpdatesUserData(userId) async {
    var user = fetchUser(
        id: userId,
        updateLoading: updateLoading,
        context: context,
        updateUser: setUser);
    futureParkingSpots = fetchParkingSpots();
    // futurePayments = fetchPayments();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        futureUser = user;
      });
    });
  }

  fullRefresh(userId) async {
    // asyncMethod();
    setState(() {
      _loading = true;
    });
    asyncFetchUpdatesUserData(userId);
  }

  void updateLoading(bool isLoading) {
    setState(() {
      _loading = isLoading;
    });
  }

  void updatePaymentLoading(bool isLoading) {
    setState(() {
      _paymentLoading = isLoading;
    });
  }

  void bookSpot(ParkingSpot spot) {
    setState(() {
      _bookingLoading = true;
    });
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return CustomDialogBox(
                title: "Confirm booking",
                descriptions: "Spot name: ${spot.name}.\n\n"
                    "Cost:  Kes. ${spot.cost} for ${spot.duration ~/ 60}/hr.\n\n"
                    "Every extra 5 minutes are charged at ${spot.lateFee} shilling(s).",
                text: "Yes",
                booking: true,
                amount: spot.id, // use the amount field to pass parking spot id
                user: new User(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    parkingSpot: user.parkingSpot,
                    payments: user.payments),
                okAction: () => fullRefresh(user.id),
              );
            },
          );
        }).then((value) => {
          setState(() {
            _bookingLoading = false;
          })
        });
  }

  void handlePay() async {
    setState(() {
      _paymentLoading = true;
    });
    var bill =
        await getParkingBill(userId: user.id, updateLoading: updateLoading);
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return CustomDialogBox(
                title: "Confirm payment",
                descriptions: "This is a simulation of payment. \n\n\n"
                    "Do you want to pay Kes. $bill to cater for the parking spot?",
                text: "Yes",
                paying: true,
                amount: bill,
                user: new User(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    parkingSpot: user.parkingSpot,
                    payments: user.payments),
                okAction: () => {fullRefresh(user.id)},
              );
            },
          );
        }).then((value) => {
          setState(() {
            _paymentLoading = false;
          })
        });
  }

  void showReceipt(Payment payment) {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomDialogBox(
            title: "Payment Receipt",
            descriptions: "This is to acknowledge that ${user.name} of "
                "car registration number ${user.parkingSpot?.currentVehicle}, paid "
                "Kes. ${payment.amount}/= on ${payment.createdAt}.",
            text: "OKAY",
            paymentReceipt: true,
            amount: payment.amount,
            user: new User(
                id: user.id,
                name: user.name,
                email: user.email,
                parkingSpot: user.parkingSpot,
                payments: user.payments),
            okAction: asyncMethod,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: FutureBuilder<User?>(
        future: futureUser,
        builder: (BuildContext buildContext, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.none &&
              !snapshot.hasData) {
            return Center(child: Text("Error. ${snapshot.error.toString()}"));
          } else if ((snapshot.data != null) && (snapshot.data.id != 0)) {
            return Scaffold(
              appBar: AppBar(
                  // backgroundColor: Color(0xfffafafa),
                  leading: Icon(
                    Icons.home,
                    size: 20,
                  ),
                  titleSpacing: 0,
                  title: Text(
                    "Parking app",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  actions: <Widget>[
                    IconButton(
                        onPressed: () => fullRefresh(snapshot.data.id),
                        icon: Icon(Icons.refresh)),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                      child: PopupMenuButton<String>(
                        // color: Theme.of(context).primaryColor,
                        child: Icon(
                          Icons.more_vert,
                        ),
                        onSelected: handleMenuClick,
                        itemBuilder: (BuildContext context) {
                          return {'Logout'}.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ],
                  bottom: const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.event_available), text: "All spots"),
                      Tab(icon: Icon(Icons.account_box), text: "My details"),
                    ],
                  )),
              // body: Text("Body"),
              body: FutureBuilder<List<ParkingSpot>?>(
                  future: futureParkingSpots,
                  builder: (BuildContext buildContext, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.none &&
                        !snapshot.hasData) {
                      return Center(
                          child: Text("Error. ${snapshot.error.toString()}"));
                    } else if ((snapshot.data != null) &&
                        (snapshot.data.length > -1)) {
                      var parkingSpots = snapshot.data
                          .where((spot) => (spot.booked != true))
                          .toList();
                      return TabBarView(
                        children: [
                          parkingSpots.length > 0
                              ? (GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisSpacing: 1,
                                    mainAxisSpacing: 2,
                                    crossAxisCount: 2,
                                  ),
                                  itemCount: parkingSpots.length,
                                  itemBuilder: (BuildContext ctx, index) {
                                    return GestureDetector(
                                      onTap: () => {
                                        if (user.parkingSpot == null)
                                          {bookSpot(parkingSpots[index])}
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Card(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12),
                                              child: Column(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    radius: 30,
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    30)),
                                                        child: Image.asset(
                                                          "assets/images/parking.png",
                                                          height: 60,
                                                          width: 60,
                                                        )),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child: Text(
                                                      parkingSpots[index].name,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child: Text(
                                                      'Kes. ${parkingSpots[index].cost.toString()}/hr',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child: Text(
                                                      'Kes. ${(parkingSpots[index].lateFee * 5).toString()}/each 5 extra minutes.',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          color: Colors.orange),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            decoration: BoxDecoration(
                                                color: Color(0xfffffff),
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                          ),
                                        ),
                                      ),
                                    );
                                  }))
                              : Center(
                                  child: Text(
                                      "It seems like there are no unbooked parking spots at the moment.")),
                          Column(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                widthFactor: 1,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 16, 16, 0),
                                  child: Icon(
                                    Icons.account_circle,
                                    size: 64,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    widthFactor: 1,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 8, 2),
                                      child: Text(
                                        "${user.name == "" ? "Your name" : user.name} ",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    widthFactor: 1,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 2, 8, 2),
                                      child: Text(
                                        "${user.email}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              (user.parkingSpot?.name != null &&
                                      user.parkingSpot?.name != "")
                                  ? _paymentLoading
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        )
                                      : Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16, 24, 16, 4),
                                                child: Text(
                                                  "My booked spots",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle: FontStyle.normal,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ListTile(
                                              title: Text(
                                                user.parkingSpot?.name ??
                                                    "Could not load name",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              subtitle: RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text:
                                                            '${user.parkingSpot?.currentVehicle}',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color:
                                                                Colors.black54),
                                                      ),
                                                    ]),
                                              ),
                                              trailing: ElevatedButton(
                                                onPressed: () => {
                                                  !_paymentLoading
                                                      ? handlePay()
                                                      : {}
                                                },
                                                child: Text("Pay now",
                                                    textAlign:
                                                        TextAlign.center),
                                                style: ElevatedButton.styleFrom(
                                                    textStyle: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.normal)),
                                              ),
                                            )
                                          ],
                                        )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 16.0),
                                      child: Text(
                                        "You have not booked any parking spot right now.",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                              (user.payments.length > 0)
                                  ? _paymentLoading
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        )
                                      : Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16, 24, 16, 4),
                                                child: Text(
                                                  "Previous payments",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle: FontStyle.normal,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                ...user.payments
                                                    .map((payment) => (ListTile(
                                                          title: Text(
                                                            payment.createdAt,
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                          subtitle: RichText(
                                                            text: TextSpan(
                                                                children: <
                                                                    TextSpan>[
                                                                  TextSpan(
                                                                    text: payment
                                                                        .amount
                                                                        .toStringAsFixed(
                                                                            2),
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .normal,
                                                                        color: Colors
                                                                            .black54),
                                                                  ),
                                                                ]),
                                                          ),
                                                          trailing:
                                                              ElevatedButton(
                                                            onPressed: () => {
                                                              !_paymentLoading
                                                                  ? showReceipt(
                                                                      payment)
                                                                  : {}
                                                            },
                                                            child: Text(
                                                                "View receipt",
                                                                textAlign:
                                                                    TextAlign
                                                                        .center),
                                                            style: ElevatedButton.styleFrom(
                                                                textStyle: TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal)),
                                                          ),
                                                        )))
                                              ],
                                            ),
                                          ],
                                        )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 16.0),
                                      child: Text(
                                        "You have not made any payments in the past.",
                                        style: TextStyle(fontSize: 18),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ],
                          )
                        ],
                      );
                    } else if ((snapshot.data != null) &&
                        snapshot.data.id == 0) {
                      Center(
                          child: Text(
                              "Could not load parking spots. ${snapshot.error.toString()}"));
                    } else if (snapshot.connectionState ==
                        ConnectionState.active) {
                      return Center(
                          child: CircularProgressIndicator(
                        semanticsLabel: 'Loading parking spots',
                      ));
                    }
                    return Center(child: Text("Waiting to load"));
                  }),
            );
          } else if ((snapshot.data != null) && snapshot.data.id == 0) {
            SchedulerBinding.instance?.addPostFrameCallback((_) {
              Fluttertoast.showToast(
                  msg: "You are not not logged in.",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
              Navigator.popAndPushNamed(context, '/login');
            });
          } else if (snapshot.connectionState == ConnectionState.active) {
            return Center(
                child: CircularProgressIndicator(
              semanticsLabel: 'Loading',
            ));
          }
          return Scaffold(
              body: Center(
            child: ListView(
                children: [Text("Waiting to load home ${snapshot.error}")]),
          ));
        },
      ),
    );
  }

  void clearData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.clear();
    Fluttertoast.showToast(
        msg: 'Logged out successfully.',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.green);
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      Navigator.popAndPushNamed(context, '/login');
    });
  }

  handleMenuClick(String value) {
    switch (value) {
      case 'Logout':
        clearData();
        break;
      case 'Exit app':
        Fluttertoast.showToast(
            msg: 'This will close the app',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green);
        break;
    }
  }
}
