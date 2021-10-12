import 'package:animated_text_kit/animated_text_kit.dart';
import '../Dataprovider/appdata.dart';
import '../brand_colors.dart';
import '../datamodels/directiondetails.dart';
import '../datamodels/nearbydoctor.dart';
import '../globalvariables.dart';
import '../helpers/firehelper.dart';
import '../treatmentVariables.dart';
import '../screens/loginpage.dart';
import '../styles/styles.dart';
import '../widgets/BrandDivier.dart';
import '../widgets/CollectPaymentDialog.dart';
import '../widgets/NoDoctorDialog.dart';
import '../widgets/ProgressDialog.dart';
import '../widgets/TaxiButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'dart:async';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'dart:io';
import '../helpers/helpermethods.dart';
import 'package:provider/provider.dart';
import '../screens/searchpage.dart';
import '../datamodels/prediction.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'editProfile.dart';
import 'mainpage.dart';

class ProfilePage extends StatefulWidget {
  static const String id = 'profilepage';

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  double searchSheetHeight = (Platform.isIOS) ? 300 : 230;
  double treatmentDetailsSheetHeight = 0; // (Platform.isAndroid) ? 235 : 260
  double requestingSheetHeight = 0; // (Platform.isAndroid) ? 195 : 220
  double treatmentSheetHeight = 0; // (Platform.isAndroid) ? 275 : 300

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  double mapBottomPadding = 0;

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _Markers = {};
  Set<Circle> _Circles = {};

  final FirebaseAuth auth = FirebaseAuth.instance;
  BitmapDescriptor nearbyIcon;

  var geoLocator = Geolocator();
  Position currentPosition;
  DirectionDetails treatmentDirectionDetails;

  String appState = 'NORMAL';

  bool drawerCanOpen = true;

  DatabaseReference treatmentRef;

  StreamSubscription<Event> treatmentSubscription;

  List<NearbyDoctor> availableDoctors;

  bool nearbyDoctorsKeysLoaded = false;

  bool isRequestingLocationDetails = false;

  void setupPositionLocator() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;

    LatLng pos = LatLng(position.latitude, position.longitude);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));

    // confirm location
    await HelperMethods.findCordinateAddress(position, context);

    //startGeofireListener();
  }

  void showDetailSheet() async {
    //await getDirection();

    setState(() {
      searchSheetHeight = 0;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      treatmentDetailsSheetHeight = (Platform.isAndroid) ? 235 : 260;
      drawerCanOpen = false;
    });
  }

  void showRequestingSheet() {
    setState(() {
      treatmentDetailsSheetHeight = 0;
      requestingSheetHeight = (Platform.isAndroid) ? 195 : 220;
      mapBottomPadding = (Platform.isAndroid) ? 200 : 190;
      drawerCanOpen = true;
    });

    //createTreatmentRequest();
  }

  showTreatmentSheet() {
    setState(() {
      requestingSheetHeight = 0;
      treatmentSheetHeight = (Platform.isAndroid) ? 275 : 300;
      mapBottomPadding = (Platform.isAndroid) ? 280 : 270;
    });
  }

  // void createMarker() {
  //   if (nearbyIcon == null) {
  //     ImageConfiguration imageConfiguration =
  //         createLocalImageConfiguration(context, size: Size(2, 2));
  //     BitmapDescriptor.fromAssetImage(
  //             imageConfiguration,
  //             (Platform.isIOS)
  //                 ? 'images/car_ios.png'
  //                 : 'images/car_android.png')
  //         .then((icon) {
  //       nearbyIcon = icon;
  //     });
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    HelperMethods.getCurrentUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    // createMarker();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, MainPage.id, (route) => false);
        return true;
      },
      child: Scaffold(
        key: scaffoldKey,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, EditProfilePage.id, (route) => false);
            // setState(() {
            //   counter = counter + 1;
            // });
          },
          child: Container(
            width: 60,
            height: 60,
            child: Icon(Icons.edit),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.pink[900]],
                )),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.pink[900]],
                      ),
                    ),
                    child: Column(children: [
                      SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            alignment: Alignment.bottomLeft,
                            icon: Icon(Icons.arrow_back),
                            color: Colors.white,
                            onPressed: () {
                              // Navigator.pop(context, 'mainpage');
                              Navigator.pushNamedAndRemoveUntil(
                                  context, MainPage.id, (route) => false);
                            },
                          ),
                          // SizedBox(
                          //   height: 50,
                          // )
                        ],
                      ),
                      SizedBox(height: 20),
                      CircleAvatar(
                        radius: 45.0,
                        backgroundImage: "${currentUserInfo.imageUrl}" != "null"
                            ? NetworkImage(currentUserInfo.imageUrl)
                            : AssetImage('images/user_icon.png'),
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(currentUserInfo?.fullName ?? "",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30.0,
                          )),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        currentUserInfo?.email ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                        ),
                      )
                    ]),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Card(
                        margin: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
                        child: Container(
                          width: 310.0,
                          height: 290.0,
                          child: Padding(
                            padding:
                                EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Information",
                                  style: TextStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Divider(
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.home,
                                            color: Colors.green,
                                            size: 35,
                                          ),
                                          SizedBox(
                                            width: 20.0,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0.0, 4.0, 0.0, 0.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Your Current Location",
                                                  style: TextStyle(
                                                    fontSize: 15.0,
                                                  ),
                                                ),
                                                Text(
                                                  Provider.of<AppData>(context)
                                                              .pickupAddress !=
                                                          null
                                                      ? Provider.of<AppData>(
                                                              context)
                                                          .pickupAddress
                                                          .placeName
                                                      : "Your Current Location",
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: 40.0,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            color: Colors.green,
                                            size: 35,
                                          ),
                                          SizedBox(
                                            width: 20.0,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0.0, 4.0, 0.0, 0.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Phone",
                                                  style: TextStyle(
                                                    fontSize: 15.0,
                                                  ),
                                                ),
                                                Text(
                                                  currentUserInfo?.phone ??
                                                      "+90055005",
                                                  style: TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.green,
                                                  ),
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
