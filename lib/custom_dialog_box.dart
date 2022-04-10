import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'constants.dart';
import 'models/UserModel.dart';

class CustomDialogBox extends StatefulWidget {
  final String title, descriptions, text;
  final Image? img;
  final okAction;
  final User? user;
  final bool? paying;
  final bool? booking;
  final int? amount;
  final bool? requestingClearance;
  final bool? paymentReceipt;

  const CustomDialogBox(
      {Key? key,
      required this.title,
      required this.descriptions,
      required this.text,
      this.img,
      this.okAction,
      this.user,
      this.booking,
      this.paying,
      this.amount,
      this.requestingClearance,
      this.paymentReceipt})
      : super(key: key);

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

class _CustomDialogBoxState extends State<CustomDialogBox> {
  final GlobalKey<State<StatefulWidget>> _printKey = GlobalKey();
  bool _loading = false;
  String amountToPay = '';
  String carReg = '';
  bool isPaying = false;

  void updateLoading(isLoading) {
    setState(() {
      _loading = isLoading;
    });
  }

  void updateISPaying(paying) {
    isPaying = paying;
  }

  handleBooking(User? user) async {
    if (user == null) {
      Fluttertoast.showToast(
          msg: "Could not complete action. User object is null.",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red);
    } else {
      bookParkingSpot(
              userId: user.id,
              spotId: widget.amount,
              carReg: carReg,
              updateLoading: updateLoading)
          .then((value) async {
        finish();
      }).catchError((error) => print(error.toString()));
    }
  }

  handlePayment() async {
    if (isPaying) return;
    User? user = widget.user;
    if (amountToPay == '' || int.parse(amountToPay).isNaN) {
      Fluttertoast.showToast(
          msg: "Please enter a valid amount.",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red);
    } else if (int.parse(amountToPay) != (widget.amount ?? 0)) {
      Fluttertoast.showToast(
          msg: "Please enter the correct amount. Khs. (${widget.amount ?? 0})",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red);
    } else {
      if (user == null) {
        Fluttertoast.showToast(
            msg: "Could not complete action. User object is null.",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red);
      } else {
        updateISPaying(true);
        pay(
                userId: user.id,
                amount: widget.amount,
                updateLoading: updateLoading)
            .then((value) => {finish(key: "paid", value: value)})
            .catchError((error) => print(error.toString()))
        .whenComplete(() => updateISPaying(false));
      }
    }
  }

  void finish({key, value}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (key != null && value != null) {
      if (value is bool) {
        preferences.setBool(key, value);
        print("after payment:" + preferences.getBool(key).toString());
      } else if (value is String) {
        preferences.setString(key, value);
        print("after payment:" + preferences.getString(key).toString());
      }
    }
    widget.okAction();
    Navigator.of(context).pop();
  }

  void _printScreen() {
    Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final doc = pw.Document();

      final image = await WidgetWraper.fromKey(
        key: _printKey,
        pixelRatio: 2.0,
      );

      doc.addPage(pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Expanded(
                child: pw.Image(image),
              ),
            );
          }));

      return doc.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.padding),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: widget.paymentReceipt != null && widget.paymentReceipt == true
            ? acknowledgementBox(context)
            : contentBox(context),
      ),
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: Constants.padding,
              top: Constants.avatarRadius + Constants.padding,
              right: Constants.padding,
              bottom: Constants.padding),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.title,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                widget.descriptions,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              (widget.paying != null && widget.paying == true)
                  ? Column(
                      children: [
                        SizedBox(height: 22.0),
                        Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.symmetric(horizontal: 40),
                          child: TextField(
                            onChanged: (text) => amountToPay = text,
                            decoration: InputDecoration(
                              labelText: "Amount to pay",
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    )
                  : (widget.booking != null && widget.booking == true)
                      ? Column(
                          children: [
                            SizedBox(height: 22.0),
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(horizontal: 40),
                              child: TextField(
                                onChanged: (text) => carReg = text,
                                decoration: InputDecoration(
                                  labelText: "CAR REG NUMBER",
                                ),
                                keyboardType: TextInputType.text,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [],
                        ),
              SizedBox(
                height: 22,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: _loading
                    ? (CircularProgressIndicator(
                        semanticsLabel: 'Processing',
                      ))
                    : FlatButton(
                        onPressed: () {
                          widget.paying != null && widget.paying == true
                              ? handlePayment()
                              : handleBooking(widget.user);
                        },
                        child: Text(
                          widget.text,
                          style: TextStyle(fontSize: 18),
                        )),
              ),
            ],
          ),
        ),
        Positioned(
          left: Constants.padding,
          right: Constants.padding,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: Constants.avatarRadius,
            child: ClipRRect(
                borderRadius:
                    BorderRadius.all(Radius.circular(Constants.avatarRadius)),
                child: Image.asset("assets/images/parking.png")),
          ),
        ),
      ],
    );
  }

  acknowledgementBox(context) {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss aa');
    final String dateTime = formatter.format(now);

    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: Constants.padding,
              top: Constants.padding,
              right: Constants.padding,
              bottom: Constants.padding),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SingleChildScrollView(
                key: _printKey,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: Constants.padding),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: Constants.avatarRadius,
                          child: ClipRRect(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(Constants.avatarRadius)),
                              child:
                                  Image.asset("assets/images/green_check.png")),
                        ),
                      ),
                      Text(
                        widget.title,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        "Kes. ${widget.amount ?? 0} ",
                        style: TextStyle(
                            fontSize: 32,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        widget.descriptions,
                        style: TextStyle(fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Parking Spot: ${widget.user?.parkingSpot?.name} ID(${widget.user?.parkingSpot?.id})\n"
                        "Date of generation: $dateTime",
                        style: TextStyle(fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 22,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                // alignment: Alignment.bottomCenter,
                widthFactor: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                          onPressed: () {
                            _printScreen();
                          },
                          child: Text(
                            "Download receipt",
                            style: TextStyle(fontSize: 18),
                          )),
                    ),
                    Expanded(
                      child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            widget.text,
                            style: TextStyle(fontSize: 18),
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
