import 'dart:async';
import '../datamodels/user.dart';
import '../globalvariables.dart';
import '../helpers/helpermethods.dart';
//import '../helpers/pushnotificationservice.dart';
import '../screens/mainpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  static const String id = 'homesplash';
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<MyHomePage> {
  // void getCurrentDoctorInfo() async {
  //   currentFirebaseUser = FirebaseAuth.instance.currentUser;
  //   DatabaseReference doctorRef = FirebaseDatabase.instance
  //       .reference()
  //       .child('doctors/${currentFirebaseUser.uid}');
  //   doctorRef.once().then((DataSnapshot snapshot) {
  //     if (snapshot.value != null) {
  //       currentDoctorInfo = Doctor.fromSnapshot(snapshot);
  //       print('my name is ${currentDoctorInfo.fullName}');
  //       print('this is data list ${currentDoctorInfo}');
  //     }
  //   });
  //   PushNotificationService pushNotificationService = PushNotificationService();

  //   pushNotificationService.initialize(context);
  //   pushNotificationService.getToken();

  //   HelperMethods.getHistoryInfo(context);
  // }

  @override
  void initState() {
    super.initState();
    //getCurrentDoctorInfo();
    Timer(
        Duration(seconds: 2),
        () => Navigator.pushNamedAndRemoveUntil(
            context, MainPage.id, (route) => false));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(false);
        return false;
      },
      child: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 100),
              Container(
                child: Image.asset(
                  "images/lg.png",
                  height: 210,
                  width: 210,
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 20.0)),
              new Container(
                child: new Stack(
                  children: <Widget>[
                    new Container(
                      alignment: AlignmentDirectional.center,
                      decoration: new BoxDecoration(
                        color: Colors.white70,
                      ),
                      child: new Container(
                        decoration: new BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: new BorderRadius.circular(10.0)),
                        width: 300.0,
                        height: 200.0,
                        alignment: AlignmentDirectional.center,
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Center(
                              child: new SizedBox(
                                height: 50.0,
                                //width: 50.0,
                                child: new Text(
                                  'Your report was sent successfully',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            new Container(
                              margin: const EdgeInsets.only(top: 10.0),
                              child: new Center(
                                child: new Text(
                                  "will be attended to very soon",
                                  style: new TextStyle(color: Colors.pink[900]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 20.0)),
              // CircularProgressIndicator(
              //   backgroundColor: Colors.white,
              //   strokeWidth: 1,
              // )
            ],
          ),
        ),
      ),
    );
  }
}
