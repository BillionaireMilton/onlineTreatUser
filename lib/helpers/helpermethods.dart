import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import '../Dataprovider/appdata.dart';
import '../datamodels/directiondetails.dart';
import '../datamodels/user.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../globalvariables.dart';
import '../helpers/requesthelper.dart';
import '../datamodels/address.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class HelperMethods {
  static void getCurrentUserInfo() async {
    currentFirebaseUser = FirebaseAuth.instance.currentUser;
    String userid = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userid');

    userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = UserProfile.fromSnapshot(snapshot);
        print('my name is ${currentUserInfo.fullName}');
      }
    });
  }

  final FirebaseAuth auth = FirebaseAuth.instance;

  static Future<String> findCordinateAddress(Position position, context) async {
    String placeAddress = '';
    String st1, st2, st3, st4;

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }

    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyDjkvF86Dthiwx8UxsttoW6qZAdb1wlYZQ';

    var response = await RequestHelper.getRequest(url);
    print(response);

    if (response != 'failed') {
      //placeAddress = response['results'][0]['formatted_address'];
      st1 = response["results"][0]["address_components"][0]["long_name"];
      st2 = response["results"][0]["address_components"][1]["long_name"];
      st3 = response["results"][0]["address_components"][5]["long_name"];
      st4 = response["results"][0]["address_components"][6]["long_name"];
      placeAddress = st1 + ", " + st2 + ", " + st3 + ", " + st4;

      Address pickupAddress = new Address();
      pickupAddress.longitude = position.longitude;
      pickupAddress.latitude = position.latitude;
      pickupAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickupAddress(pickupAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails> getDirectionDetails(
      LatLng startPosition, LatLng endPosition) async {
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${startPosition.latitude},${startPosition.longitude}&destination=${endPosition.latitude},${endPosition.longitude}&mode=driving&key=AIzaSyDjkvF86Dthiwx8UxsttoW6qZAdb1wlYZQ';
    print('URL: ${url}');
    var response = await RequestHelper.getRequest(url);

    if (response == 'failed') {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.durationText =
        response['routes'][0]['legs'][0]['duration']['text'];
    directionDetails.durationValue =
        response['routes'][0]['legs'][0]['duration']['value'];

    directionDetails.distanceText =
        response['routes'][0]['legs'][0]['distance']['text'];

    directionDetails.distanceValue =
        response['routes'][0]['legs'][0]['distance']['value'];

    directionDetails.encodedPoints =
        response['routes'][0]['overview_polyline']['points'];

    return directionDetails;
  }

  static int estimateFares(DirectionDetails details) {
    //per km = 6 rupees
    //per minute = 5 rupees
    // base fare = 20 rupees

    double baseFare = 20;
    double distanceFare = (details.distanceValue / 1000) * 6;
    double timeFare = (details.durationValue / 60) * 5;

    double totalFare = baseFare + distanceFare + timeFare;

    return totalFare.truncate();
  }

  static double generateRandomNumber(int max) {
    var randomGenerator = Random();
    int randInt = randomGenerator.nextInt(max);

    return randInt.toDouble();
  }

  static sendNotification(String token, context, String treatment_id) async {
    print("send notification function supposed loading __________");
    var destination =
        Provider.of<AppData>(context, listen: false).pickupAddress;
    print("${destination}");

    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization': serverKey,
    };

    Map notificationMap = {
      'title': 'NEW TREATMENT REQUEST',
      'body': 'Destination, ${destination.placeName}',
    };

    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'treatment_id': treatment_id,
    };

    Map bodyMap = {
      'notification': notificationMap,
      'data': dataMap,
      'priority': 'high',
      'to': token,
    };

    var response = await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: headerMap,
      body: jsonEncode(bodyMap),
    );

    print(response.body);
  }

  static String formatMyDate(String datestring) {
    DateTime thisDate = DateTime.parse(datestring);

    String formattedDate =
        '${DateFormat.MMMd().format(thisDate)},${DateFormat.y().format(thisDate)} -${DateFormat.jm().format(thisDate)}';

    return formattedDate;
  }
}
