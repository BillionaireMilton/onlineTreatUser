import 'Dataprovider/appdata.dart';
import 'globalvariables.dart';
import 'screens/loginpage.dart';
import 'screens/profile.dart';
import 'screens/registrationpage.dart';
import 'screens/reportAbuse.dart';
import 'screens/tst.dart';
import 'screens/wait.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/mainpage.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'dart:async';
import 'screens/profWait.dart';
import 'screens/editProfile.dart';
import 'screens/openLink.dart';
import 'screens/historypage.dart';
import 'screens/reset.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp(
    name: 'db2',
    options: Platform.isIOS || Platform.isMacOS
        ? FirebaseOptions(
            appId: '1:297855924061:ios:c6de2b69b03a5be8',
            apiKey: 'AIzaSyD_shO5mfO9lhy2TVWhfo1VUmARKlG4suk',
            projectId: 'flutter-firebase-plugins',
            messagingSenderId: '297855924061',
            databaseURL: 'https://flutterfire-cd2f7.firebaseio.com',
          )
        : FirebaseOptions(
            appId: '1:709215467433:android:ee7c9687418c5db9a776b8',
            apiKey: 'AIzaSyDjkvF86Dthiwx8UxsttoW6qZAdb1wlYZQ',
            messagingSenderId: '709215467433',
            projectId: 'pet-amb',
            databaseURL: 'https://pet-amb-default-rtdb.firebaseio.com/',
          ),
  );

  currentFirebaseUser = await FirebaseAuth.instance.currentUser;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Brand-Regular',
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute:
            (currentFirebaseUser == null) ? LoginPage.id : MainPage.id,
        routes: {
          RegistrationPage.id: (context) => RegistrationPage(),
          LoginPage.id: (context) => LoginPage(),
          MainPage.id: (context) => MainPage(),
          ProfilePage.id: (context) => ProfilePage(),
          EditProfilePage.id: (context) => EditProfilePage(),
          ReportPage.id: (context) => ReportPage(),
          TestPage.id: (context) => TestPage(),
          MyHomePage.id: (context) => MyHomePage(),
          OpenLink.id: (context) => OpenLink(),
          ProfWait.id: (context) => ProfWait(),
          HistoryPage.id: (context) => HistoryPage(),
          ResetPasswordPage.id: (context) => ResetPasswordPage(),
        },
      ),
    );
  }
}
