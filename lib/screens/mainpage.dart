import 'package:animated_text_kit/animated_text_kit.dart';
import '../Dataprovider/appdata.dart';
import '../brand_colors.dart';
import '../datamodels/directiondetails.dart';
import '../datamodels/nearbydoctor.dart';
import '../datamodels/user.dart';
import '../globalvariables.dart';
import '../helpers/firehelper.dart';
import '../treatmentVariables.dart';
import '../screens/loginpage.dart';
import '../screens/profile.dart';
import '../screens/reportAbuse.dart';
import '../screens/tst.dart';
import '../screens/wait.dart';
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
import 'package:url_launcher/url_launcher.dart';

import 'historypage.dart';
import 'openLink.dart';

class MainPage extends StatefulWidget {
  static const String id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
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

  Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchInWebViewOrVC(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: true,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchInWebViewWithJavaScript(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: true,
        enableJavaScript: true,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchInWebViewWithDomStorage(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: true,
        enableDomStorage: true,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchUniversalLinkIos(String url) async {
    if (await canLaunch(url)) {
      final bool nativeAppLaunchSucceeded = await launch(
        url,
        forceSafariVC: false,
        universalLinksOnly: true,
      );
      if (!nativeAppLaunchSucceeded) {
        await launch(
          url,
          forceSafariVC: true,
        );
      }
    }
  }

  Widget _launchStatus(BuildContext context, AsyncSnapshot<void> snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const Text('');
    }
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit Pet Ambulance'),
            actions: <Widget>[
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text("NO"),
              ),
              SizedBox(height: 16),
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Text("YES"),
              ),
            ],
          ),
        ) ??
        false;
  }

  //onWillPop: _onBackPressed,

  final FirebaseAuth auth = FirebaseAuth.instance;
  BitmapDescriptor nearbyIcon;

  var geoLocator = Geolocator();
  Position currentPosition;
  DirectionDetails treatmentDirectionDetails;

  Future<void> _launched;

  String appState = 'NORMAL';

  String imageUrl;

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

    startGeofireListener();
  }

  void showDetailSheet() async {
    await getDirection();

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

    createTreatmentRequest();
  }

  showTreatmentSheet() {
    setState(() {
      requestingSheetHeight = 0;
      treatmentSheetHeight = (Platform.isAndroid) ? 275 : 300;
      mapBottomPadding = (Platform.isAndroid) ? 280 : 270;
    });
  }

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(1, 1));
      BitmapDescriptor.fromAssetImage(
        imageConfiguration,
        (Platform.isIOS)
            // ? 'images/car_ios.png'
            ? 'images/new_amb2.png'
            // : 'images/doc_and.jpg')
            : 'images/new_amb2.png',
      ).then((icon) {
        nearbyIcon = icon;
      });
    }
  }

  void getCurrentUserInfo() async {
    currentFirebaseUser = FirebaseAuth.instance.currentUser;
    String userid = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userid');

    await userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = UserProfile.fromSnapshot(snapshot);
        print('my name is ${currentUserInfo.fullName}');
      }
    });
    setState(() {
      imageUrl = currentUserInfo.imageUrl;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUserInfo();
    //imageUrl = currentUserInfo.imageUrl;
    //HelperMethods.getCurrentUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    const String tecRole = 'https://www.petambulance.ng/role/technnologist';
    const String docRole = 'https://www.petambulance.ng/role/doctor';
    const String about = 'https://www.petambulance.ng/about';
    const String store = 'http://petambulance.ng/store/view';
    createMarker();

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
          key: scaffoldKey,
          drawer: Container(
            width: 250,
            color: Colors.white,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.all(0),
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    height: 160,
                    child: DrawerHeader(
                      decoration: BoxDecoration(color: Colors.white),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 45.0,
                            backgroundImage:
                                //"${currentUserInfo.imageUrl}" != "null"
                                imageUrl != null
                                    ? NetworkImage(imageUrl)
                                    : AssetImage('images/user_icon.png'),
                            backgroundColor: Colors.white,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  currentUserInfo?.fullName ?? "Pet Owner",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 20, fontFamily: 'Brand-Bold'),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  currentUserInfo?.email ?? "Pet owner's email",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  BrandDivider(),
                  SizedBox(
                    height: 10,
                  ),
                  // ListTile(
                  //   leading: Icon(OMIcons.cardGiftcard),
                  //   title: Text(
                  //     'Free Treatments',
                  //     style: kDrawerItemStyle,
                  //   ),
                  // ),
                  // ListTile(
                  //   leading: Icon(OMIcons.creditCard),
                  //   title: Text(
                  //     'Payments',
                  //     style: kDrawerItemStyle,
                  //   ),
                  // ),
                  // ListTile(
                  //   leading: Icon(OMIcons.history),
                  //   title: Text(
                  //     'Treatment History',
                  //     style: kDrawerItemStyle,
                  //   ),
                  // ),
                  // ListTile(
                  //   leading: Icon(OMIcons.contactSupport),
                  //   title: Text(
                  //     'Support',
                  //     style: kDrawerItemStyle,
                  //   ),
                  // ),
                  ListTile(
                    leading: Icon(OMIcons.person),
                    title: Text(
                      'Profile',
                      style: kDrawerItemStyle,
                    ),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, ProfilePage.id, (route) => false);
                      // changeScreenReplacement(context, LoginScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(OMIcons.history),
                    title: Text(
                      'History',
                      style: kDrawerItemStyle,
                    ),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, HistoryPage.id, (route) => false);
                      // changeScreenReplacement(context, LoginScreen());
                    },
                  ),

                  ListTile(
                    leading: Icon(FontAwesome.stethoscope),
                    title: Text(
                      'Role of Veterinary Doctor',
                      style: kDrawerItemStyle,
                    ),
                    onTap: () {
                      setState(() {
                        _launched = _launchInBrowser(docRole);
                      });
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.medical_services_outlined),
                    title: Text(
                      'Role of Animal Health Technologist',
                      style: kDrawerItemStyle,
                    ),
                    onTap: () {
                      setState(() {
                        _launched = _launchInBrowser(tecRole);
                      });
                    },
                  ),

                  ListTile(
                    leading: Icon(OMIcons.store),
                    title: Text(
                      'Stores',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _launched = _launchInWebViewWithJavaScript(store);
                      });
                    },
                  ),

                  ListTile(
                    // dense: true,
                    // visualDensity:
                    //     VisualDensity(horizontal: 0, vertical: -4),
                    leading: Icon(Icons.warning_amber_rounded),
                    title: Text(
                      "Report Abuse",
                      style: kDrawerItemStyle,
                    ),
                    onTap: () {
                      // auth.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, ReportPage.id, (route) => false);
                      // changeScreenReplacement(context, LoginScreen());
                    },
                  ),
                  // ListTile(
                  //   // dense: true,
                  //   // visualDensity:
                  //   //     VisualDensity(horizontal: 0, vertical: -4),
                  //   leading: Icon(Icons.auto_awesome),
                  //   title: Text(
                  //     "loading",
                  //     style: kDrawerItemStyle,
                  //   ),
                  //   onTap: () {
                  //     auth.signOut();
                  //     Navigator.pushNamedAndRemoveUntil(
                  //         context, MyHomePage.id, (route) => false);
                  //     // changeScreenReplacement(context, LoginScreen());
                  //   },
                  // ),
                  ListTile(
                    leading: Icon(OMIcons.info),
                    title: Text(
                      'About Petambulance',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _launched = _launchInBrowser(about);
                      });
                    },
                  ),
                  ListTile(
                    // dense: true,
                    // visualDensity:
                    //     VisualDensity(horizontal: 0, vertical: -4),
                    leading: Icon(Icons.exit_to_app),
                    title: Text(
                      "Log out",
                      style: kDrawerItemStyle,
                    ),
                    onTap: () {
                      auth.signOut();
                      auth.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, LoginPage.id, (route) => false);
                      // changeScreenReplacement(context, LoginScreen());
                    },
                  ),
                ],
              ),
            ),
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                padding: EdgeInsets.only(bottom: mapBottomPadding),
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                initialCameraPosition: GooglePlex,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: true,
                polylines: _polylines,
                markers: _Markers,
                circles: _Circles,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  mapController = controller;

                  setState(() {
                    mapBottomPadding = (Platform.isAndroid) ? 280 : 270;
                  });

                  setupPositionLocator();
                },
              ),

              ///MenuButton
              Positioned(
                top: 44,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    if (drawerCanOpen) {
                      scaffoldKey.currentState.openDrawer();
                    } else {
                      resetApp();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5.0,
                              spreadRadius: 0.5,
                              offset: Offset(
                                0.7,
                                0.7,
                              ))
                        ]),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(
                        (drawerCanOpen) ? Icons.menu : Icons.arrow_back,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              /// SearchSheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSize(
                  vsync: this,
                  duration: new Duration(milliseconds: 150),
                  curve: Curves.easeIn,
                  child: Container(
                    height: searchSheetHeight,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15.0,
                              spreadRadius: 0.5,
                              offset: Offset(
                                0.7,
                                0.7,
                              ))
                        ]),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Nice to see you!',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            'Get the best pet doctors',
                            style: TextStyle(
                                fontSize: 18, fontFamily: 'Brand-Bold'),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // GestureDetector(
                          //   onTap: () async {
                          //     var response = await Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //             builder: (context) => SearchPage()));

                          //     if (response == 'getDirection') {
                          //       showDetailSheet();
                          //     }
                          //   },
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //         color: Colors.white,
                          //         borderRadius: BorderRadius.circular(4),
                          //         boxShadow: [
                          //           BoxShadow(
                          //               color: Colors.black12,
                          //               blurRadius: 5.0,
                          //               spreadRadius: 0.5,
                          //               offset: Offset(
                          //                 0.7,
                          //                 0.7,
                          //               ))
                          //         ]),
                          //     child: Padding(
                          //       padding: EdgeInsets.all(12.0),
                          //       child: Row(
                          //         children: <Widget>[
                          //           Icon(
                          //             Icons.search,
                          //             color: Colors.blueAccent,
                          //           ),
                          //           SizedBox(
                          //             width: 10,
                          //           ),
                          //           Text('Search Destination'),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: TaxiButton(
                              title: 'REQUEST  PET  AMBULANCE',
                              color: Colors.pink[900],
                              onPressed: () {
                                setState(() {
                                  appState = 'REQUESTING';
                                });

                                showRequestingSheet();

                                availableDoctors = FireHelper.nearbyDoctorList;
                                // print("${availableDoctors.length}");

                                findDoctor();
                              },
                            ),
                          ),
                          SizedBox(
                            height: 22,
                          ),
                          Row(
                            children: <Widget>[
                              Icon(
                                OMIcons.home,
                                color: BrandColors.colorDimText,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      Provider.of<AppData>(context)
                                                  .pickupAddress !=
                                              null
                                          ? Provider.of<AppData>(context)
                                              .pickupAddress
                                              .placeName
                                          : "Getting Your Location...",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      'Your Current Location',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: BrandColors.colorDimText,
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          //SizedBox(height: 10),
                          //BrandDivider(),
                          //SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// TreatmentDetails Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSize(
                  vsync: this,
                  duration: new Duration(milliseconds: 150),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15.0, // soften the shadow
                          spreadRadius: 0.5, //extend the shadow
                          offset: Offset(
                            0.7, // Move to right 10  horizontally
                            0.7, // Move to bottom 10 Vertically
                          ),
                        )
                      ],
                    ),
                    height: treatmentDetailsSheetHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            color: BrandColors.colorAccent1,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: <Widget>[
                                  Image.asset(
                                    'images/ndoc.png',
                                    height: 70,
                                    width: 70,
                                  ),
                                  SizedBox(
                                    width: 16,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Doctor',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Brand-Bold'),
                                      ),
                                      Text(
                                        (treatmentDirectionDetails != null)
                                            ? treatmentDirectionDetails
                                                .distanceText
                                            : '',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: BrandColors.colorTextLight),
                                      )
                                    ],
                                  ),
                                  Expanded(child: Container()),
                                  Text(
                                    (treatmentDirectionDetails != null)
                                        ? '\₹${HelperMethods.estimateFares(treatmentDirectionDetails)}'
                                        : '',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Brand-Bold'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 22,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  FontAwesomeIcons.moneyBillAlt,
                                  size: 18,
                                  color: BrandColors.colorTextLight,
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Text('Cash'),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: BrandColors.colorTextLight,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 22,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: TaxiButton(
                              title: 'REQUEST PETAMBULANCE',
                              color: BrandColors.colorGreen,
                              onPressed: () {
                                setState(() {
                                  appState = 'REQUESTING';
                                });
                                showRequestingSheet();

                                availableDoctors = FireHelper.nearbyDoctorList;

                                findDoctor();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Request Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSize(
                  vsync: this,
                  duration: new Duration(milliseconds: 150),
                  curve: Curves.easeIn,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15.0, // soften the shadow
                          spreadRadius: 0.5, //extend the shadow
                          offset: Offset(
                            0.7, // Move to right 10  horizontally
                            0.7, // Move to bottom 10 Vertically
                          ),
                        )
                      ],
                    ),
                    height: requestingSheetHeight,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                          ),
                          // Container(
                          //   child: TypewriterAnimatedTextKit(
                          //     text: ['Requesting Petambulance...'],
                          //     textStyle: TextStyle(
                          //       color: Colors.black,
                          //       fontSize: 20.0,
                          //       fontWeight: FontWeight.w400,
                          //     ),
                          //   ),
                          // ),
                          Container(
                            child: Text(
                              "Requesting Petambulance...",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          // SizedBox(

                          //   width: double.infinity,
                          //   child:
                          //   // TextLiquidFill(
                          //   //   text: 'Requesting a Treatment...',
                          //   //   waveColor: Colors.red,
                          //   //   boxBackgroundColor: Colors.white,
                          //   //   textStyle: TextStyle(
                          //   //       color: BrandColors.colorText,
                          //   //       fontSize: 22.0,
                          //   //       fontFamily: 'Brand-Bold'),
                          //   //   boxHeight: 40.0,
                          //   // ),
                          // ),
                          SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () {
                              cancelRequest();
                              resetApp();
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    width: 1.0,
                                    color: BrandColors.colorLightGrayFair),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 25,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: double.infinity,
                            child: Text(
                              'Cancel Request',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Treatment Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSize(
                  vsync: this,
                  duration: new Duration(milliseconds: 150),
                  curve: Curves.easeIn,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15.0, // soften the shadow
                          spreadRadius: 0.5, //extend the shadow
                          offset: Offset(
                            0.7, // Move to right 10  horizontally
                            0.7, // Move to bottom 10 Vertically
                          ),
                        )
                      ],
                    ),
                    height: treatmentSheetHeight,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                treatmentStatusDisplay,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Brand-Bold'),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          BrandDivider(),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            doctorCarDetails,
                            style: TextStyle(color: BrandColors.colorTextLight),
                          ),
                          Text(
                            doctorFullName,
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          BrandDivider(),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular((25))),
                                      border: Border.all(
                                          width: 1.0,
                                          color: BrandColors.colorTextLight),
                                    ),
                                    child: Icon(Icons.call),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text('Call'),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular((25))),
                                      border: Border.all(
                                          width: 1.0,
                                          color: BrandColors.colorTextLight),
                                    ),
                                    child: Icon(Icons.list),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text('Details'),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular((25))),
                                      border: Border.all(
                                          width: 1.0,
                                          color: BrandColors.colorTextLight),
                                    ),
                                    child: Icon(OMIcons.clear),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text('Cancel'),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Future<void> getDirection() async {
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    var pickLatLng = LatLng(pickup.latitude, pickup.longitude);
    var destinationLatLng = LatLng(destination.latitude, destination.longitude);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              status: 'Please wait...',
            ));

    var thisDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);

    setState(() {
      treatmentDirectionDetails = thisDetails;
    });

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(thisDetails.encodedPoints);

    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      results.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    _polylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyid'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      _polylines.add(polyline);
    });

    // make polyline to fit into the map

    LatLngBounds bounds;

    if (pickLatLng.latitude > destinationLatLng.latitude &&
        pickLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
    } else if (pickLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude));
    } else if (pickLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
        northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      bounds =
          LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
    }

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      position: pickLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location'),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId('destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: destination.placeName, snippet: 'Destination'),
    );

    setState(() {
      _Markers.add(pickupMarker);
      _Markers.add(destinationMarker);
    });

    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickLatLng,
      fillColor: BrandColors.colorGreen,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId('destination'),
      strokeColor: BrandColors.colorAccentPurple,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: BrandColors.colorAccentPurple,
    );

    setState(() {
      _Circles.add(pickupCircle);
      _Circles.add(destinationCircle);
    });
  }

  void startGeofireListener() {
    Geofire.initialize('doctorsAvailable');
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 20)
        .listen((map) {
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyDoctor nearbyDoctor = NearbyDoctor();
            nearbyDoctor.key = map['key'];
            nearbyDoctor.latitude = map['latitude'];
            nearbyDoctor.longitude = map['longitude'];
            FireHelper.nearbyDoctorList.add(nearbyDoctor);

            if (nearbyDoctorsKeysLoaded) {
              updateDoctorsOnMap();
            }
            break;

          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDoctorsOnMap();
            break;

          case Geofire.onKeyMoved:
            // Update your key's location

            NearbyDoctor nearbyDoctor = NearbyDoctor();
            nearbyDoctor.key = map['key'];
            nearbyDoctor.latitude = map['latitude'];
            nearbyDoctor.longitude = map['longitude'];

            FireHelper.updateNearbyLocation(nearbyDoctor);
            updateDoctorsOnMap();
            break;

          case Geofire.onGeoQueryReady:
            nearbyDoctorsKeysLoaded = true;
            updateDoctorsOnMap();
            break;
        }
      }
    });
  }

  void updateDoctorsOnMap() {
    setState(() {
      _Markers.clear();
    });

    Set<Marker> tempMarkers = Set<Marker>();

    for (NearbyDoctor doctor in FireHelper.nearbyDoctorList) {
      LatLng doctorPosition = LatLng(doctor.latitude, doctor.longitude);
      Marker thisMarker = Marker(
        markerId: MarkerId('doctor${doctor.key}'),
        position: doctorPosition,
        icon: nearbyIcon,
        rotation: HelperMethods.generateRandomNumber(360),
      );

      tempMarkers.add(thisMarker);
    }

    setState(() {
      _Markers = tempMarkers;
    });
  }

  void createTreatmentRequest() {
    treatmentRef =
        FirebaseDatabase.instance.reference().child('treatmentRequest').push();

    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    Map pickupMap = {
      'latitude': pickup.latitude.toString(),
      'longitude': pickup.longitude.toString(),
    };

    // Map destinationMap = {
    //   'latitude': destination.latitude.toString(),
    //   'longitude': destination.longitude.toString(),
    // };

    Map treatmentMap = {
      'created_at': DateTime.now().toString(),
      'owner_name': currentUserInfo.fullName,
      'owner_phone': currentUserInfo.phone,
      'pickup_address': pickup.placeName,
      //'destination_address': destination.placeName,
      'location': pickupMap,
      //'destination': destinationMap,
      'payment_method': 'card',
      'doctor_id': 'waiting',
    };

    treatmentRef.set(treatmentMap);

    treatmentSubscription = treatmentRef.onValue.listen((event) async {
      //check for null snapshot
      if (event.snapshot.value == null) {
        return;
      }

      //get doctor details
      if (event.snapshot.value['doctor_details'] != null) {
        setState(() {
          doctorCarDetails = event.snapshot.value['doctor_details'].toString();
        });
      }

      // get doctor name
      if (event.snapshot.value['doctor_name'] != null) {
        setState(() {
          doctorFullName = event.snapshot.value['doctor_name'].toString();
        });
      }

      // get doctor phone number
      if (event.snapshot.value['doctor_phone'] != null) {
        setState(() {
          doctorPhoneNumber = event.snapshot.value['doctor_phone'].toString();
        });
      }

      //get and use doctor location updates
      if (event.snapshot.value['doctor_location'] != null) {
        double doctorLat = double.parse(
            event.snapshot.value['doctor_location']['latitude'].toString());
        double doctorLng = double.parse(
            event.snapshot.value['doctor_location']['longitude'].toString());
        LatLng doctorLocation = LatLng(doctorLat, doctorLng);

        if (status == 'accepted') {
          updateToPickup(doctorLocation);
        } else if (status == 'ontreatment') {
          updateToDestination(doctorLocation);
        } else if (status == 'arrived') {
          setState(() {
            treatmentStatusDisplay = 'Doctor has arrived';
          });
        }
      }

      if (event.snapshot.value['status'] != null) {
        status = event.snapshot.value['status'].toString();
      }

      if (status == 'accepted') {
        showTreatmentSheet();
        Geofire.stopListener();
        removeGeofireMarkers();
      }

      if (status == 'ended') {
        if (event.snapshot.value['fares'] != null) {
          int fares = int.parse(event.snapshot.value['fares'].toString());

          var response = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectPayment(
              paymentMethod: 'cash',
              fares: fares,
            ),

            //    builder: (BuildContext context) => CollectPayment(paymentMethod: 'cash', fares: fares,),
          );

          if (response == 'close') {
            treatmentRef.onDisconnect();
            treatmentRef = null;
            treatmentSubscription.cancel();
            treatmentSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void removeGeofireMarkers() {
    setState(() {
      _Markers.removeWhere((m) => m.markerId.value.contains('doctor'));
    });
  }

  void updateToPickup(LatLng doctorLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;

      var positionLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      var thisDetails = await HelperMethods.getDirectionDetails(
          doctorLocation, positionLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        treatmentStatusDisplay =
            'Doctor is Arriving - ${thisDetails.durationText}';
      });

      isRequestingLocationDetails = false;
    }
  }

  void updateToDestination(LatLng doctorLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;

      var destination =
          Provider.of<AppData>(context, listen: false).destinationAddress;

      var destinationLatLng =
          LatLng(destination.latitude, destination.longitude);

      var thisDetails = await HelperMethods.getDirectionDetails(
          doctorLocation, destinationLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        treatmentStatusDisplay =
            'Driving to Destination - ${thisDetails.durationText}';
      });

      isRequestingLocationDetails = false;
    }
  }

  void cancelRequest() {
    treatmentRef.remove();

    setState(() {
      appState = 'NORMAL';
    });
  }

  resetApp() {
    setState(() {
      polylineCoordinates.clear();
      _polylines.clear();
      _Markers.clear();
      _Circles.clear();
      treatmentDetailsSheetHeight = 0;
      requestingSheetHeight = 0;
      treatmentSheetHeight = 0;
      searchSheetHeight = (Platform.isAndroid) ? 230 : 300;
      mapBottomPadding = (Platform.isAndroid) ? 280 : 270;
      drawerCanOpen = true;

      status = '';
      doctorFullName = '';
      doctorPhoneNumber = '';
      doctorCarDetails = '';
      treatmentStatusDisplay = 'Doctor is Arriving';
    });

    setupPositionLocator();
  }

  void noDoctorFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDoctorDialog());
  }

  void findDoctor() {
    print("________FINDING DOCTOR___________");
    if (availableDoctors.length == 0) {
      // if (availableDoctors == null) {
      cancelRequest();
      resetApp();
      noDoctorFound();
      return;
    }

    var doctor = availableDoctors[0];

    print("initialize notify doctor function");

    notifyDoctor(doctor);

    availableDoctors.removeAt(0);

    print("Doctor key generated");
    print(doctor.key);
  }

  void notifyDoctor(NearbyDoctor doctor) {
    print("____________________notify doctor___________________");
    DatabaseReference doctorTreatmentRef = FirebaseDatabase.instance
        .reference()
        .child('doctors/${doctor.key}/newtreatment');
    doctorTreatmentRef.set(treatmentRef.key);

    // Get and notify doctor using token
    print("Get and notify doctor using token");
    DatabaseReference tokenRef = FirebaseDatabase.instance
        .reference()
        .child('doctors/${doctor.key}/token');

    tokenRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        String token = snapshot.value.toString();

        // send notification to selected doctor
        print("send notification to selected doctor");
        print(token);
        print("${treatmentRef.key}");
        HelperMethods.sendNotification(token, context, treatmentRef.key);
        print("send notificationHelper method called______________");
      } else {
        return;
      }

      const oneSecTick = Duration(seconds: 1);
      print("onesecToc and timer here___________");
      var timer = Timer.periodic(oneSecTick, (timer) {
        print("stop timer when treatment request is cancelled");
        // stop timer when treatment request is cancelled;
        if (appState != 'REQUESTING') {
          doctorTreatmentRef.set('cancelled');
          doctorTreatmentRef.onDisconnect();
          timer.cancel();
          doctorRequestTimeout = 30;
        }

        print("doctor request time out here_____________");
        doctorRequestTimeout--;

        // a value event listener for doctor accepting treatment request
        doctorTreatmentRef.onValue.listen((event) {
          // confirms that doctor has clicked accepted for the new treatment request
          if (event.snapshot.value.toString() == 'accepted') {
            doctorTreatmentRef.onDisconnect();
            timer.cancel();
            doctorRequestTimeout = 30;
          }
        });

        if (doctorRequestTimeout == 0) {
          //informs doctor that treatment has timed out
          doctorTreatmentRef.set('timeout');
          doctorTreatmentRef.onDisconnect();
          doctorRequestTimeout = 30;
          timer.cancel();

          //select the next closest doctor
          findDoctor();
        }
      });
    });
  }
}
