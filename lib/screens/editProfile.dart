import 'dart:io';

import '../datamodels/user.dart';
import '../screens/mainpage.dart';
import '../widgets/ProgressDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:intl/intl.dart';

import '../globalvariables.dart';
import 'profile.dart';
import 'profWait.dart';

class EditProfilePage extends StatefulWidget {
  @override
  MapScreenState createState() => MapScreenState();
  static const String id = 'editprofilepage';
}

class MapScreenState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  bool _status = false;

  String userImageUrl;
  String dummyUrl;
  String gender = currentUserInfo.gender;

  List _genderList = [
    'Male',
    'Female',
  ];

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  final FocusNode myFocusNode = FocusNode();

  var fullNameController = TextEditingController();

  var phoneController = TextEditingController();

  var emailController = TextEditingController();

  //var genderController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
  }

  void showSnackBar(String title) {
    final snackbar = SnackBar(
      content: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15),
      ),
    );
    scaffoldKey.currentState.showSnackBar(snackbar);
  }

  void updateProfile(context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        status: 'Uploading profile picture',
      ),
    );
    await _uploadImage();
    await _uploadImage();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        status: 'Updating your profile',
      ),
    );

    String id = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$id');

    Map<String, dynamic> userMap = {
      'imageUrl': userImageUrl,
      'fullName': fullNameController.text,
      'phone': phoneController.text,
      'gender': gender,
    };

    await userRef.update(userMap);

    Navigator.pushNamedAndRemoveUntil(context, ProfWait.id, (route) => false);
  }

  // files required in the form
  File _imageFile;
  File _dummyFile;
  String imageName;
  ImagePicker imagePicker = ImagePicker();

  // Choose profile image function
  Future<void> _choosedImage() async {
    PickedFile pickedFile = await imagePicker.getImage(
      source: ImageSource.gallery,
    );

    setState(() {
      _imageFile = File(pickedFile.path);
      imageName =
          "petambulance profile picture.${_imageFile.path.split('.').last}";
    });
  }

  // Upload profile pic
  Future<void> _uploadImage() async {
    // Create a unique filename for image
    String imageFileName = DateTime.now().microsecondsSinceEpoch.toString();
    final Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('${currentUserInfo.email}')
        .child(imageFileName);
    final UploadTask uploadTask = storageReference.putFile(_imageFile);
    await uploadTask.then((TaskSnapshot taskSnapshot) {
      taskSnapshot.ref.getDownloadURL().then((imageUrl) async {
        // Save to real time database
        //updateProfile(imageUrl);
        await setState(() {
          userImageUrl = imageUrl;
        });
      });
    }).catchError((error) {
      showSnackBar(
        error.toString(),
      );
    });
  }

  // Upload profile pic
  Future<void> _dummyFunc() async {
    // Create a unique filename for image
    String dummyFileName = '';
    final Reference storageReference =
        FirebaseStorage.instance.ref().child('').child(dummyFileName);
    final UploadTask uploadTask = storageReference.putFile(_dummyFile);
    await uploadTask.then((TaskSnapshot taskSnapshot) {
      taskSnapshot.ref.getDownloadURL().then((imageUrl) async {
        // Save to real time database
        //updateProfile(imageUrl);
        await setState(() {
          dummyUrl = imageUrl;
        });
      });
    }).catchError((error) {
      showSnackBar(
        error.toString(),
      );
    });
  }

  getUserInfo() async {
    currentFirebaseUser = FirebaseAuth.instance.currentUser;
    String userid = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userid');

    userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = UserProfile.fromSnapshot(snapshot);
        fullNameController.text = currentUserInfo.fullName;
        phoneController.text = currentUserInfo.phone;
        //genderController.text = currentUserInfo.gender;
        // setState(() {
        //   gender = currentUserInfo.gender;
        // });
        //print('my gender is ${currentUserInfo.gender}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, ProfilePage.id, (route) => false);
        return true;
      },
          child: new Scaffold(
          body: new Container(
        color: Colors.white,
        child: new ListView(
          children: <Widget>[
            Column(
              children: <Widget>[
                new Container(
                  height: 250.0,
                  color: Colors.white,
                  child: new Column(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(left: 20.0, top: 20.0),
                          child: new Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new IconButton(
                                icon: Icon(Icons.arrow_back_ios),
                                color: Colors.black,
                                alignment: Alignment.topCenter,
                                onPressed: () {
                                  // Navigator.pop(context, 'mainpage');
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, ProfilePage.id, (route) => false);
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 95.0, top: 8.0),
                                child: new Text('Profile',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                        fontFamily: 'sans-serif-light',
                                        color: Colors.black)),
                              )
                            ],
                          )),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: new Stack(fit: StackFit.loose, children: <Widget>[
                          new Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new Container(
                                  width: 140.0,
                                  height: 140.0,
                                  decoration: new BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: new DecorationImage(
                                      image: _imageFile == null
                                          ? "${currentUserInfo.imageUrl}" !=
                                                  "null"
                                              ? NetworkImage(
                                                  currentUserInfo.imageUrl)
                                              : new ExactAssetImage(
                                                  'images/user_icon.png')
                                          : FileImage(_imageFile),
                                      fit: BoxFit.cover,
                                    ),
                                  )),
                            ],
                          ),
                          Padding(
                              padding: EdgeInsets.only(top: 90.0, right: 100.0),
                              child: GestureDetector(
                                onTap: () {
                                  _choosedImage();
                                },
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new CircleAvatar(
                                      backgroundColor: Colors.green,
                                      radius: 25.0,
                                      child: new Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                      ),
                                    )
                                  ],
                                ),
                              )),
                        ]),
                      )
                    ],
                  ),
                ),
                new Container(
                  color: Color(0xffFFFFFF),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 25.0),
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 25.0),
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    new Text(
                                      'Parsonal Information',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                new Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _status ? _getEditIcon() : new Container(),
                                  ],
                                )
                              ],
                            )),
                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 25.0),
                            child: new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    new Text(
                                      'Full Name',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 2.0),
                            child: new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Flexible(
                                  child: new TextField(
                                    controller: fullNameController,
                                    decoration: const InputDecoration(
                                      hintText: "Enter Your Name",
                                    ),
                                    enabled: !_status,
                                    autofocus: !_status,
                                  ),
                                ),
                              ],
                            )),
                        // Padding(
                        //     padding: EdgeInsets.only(
                        //         left: 25.0, right: 25.0, top: 25.0),
                        //     child: new Row(
                        //       mainAxisSize: MainAxisSize.max,
                        //       children: <Widget>[
                        //         new Column(
                        //           mainAxisAlignment: MainAxisAlignment.start,
                        //           mainAxisSize: MainAxisSize.min,
                        //           children: <Widget>[
                        //             new Text(
                        //               'Email',
                        //               style: TextStyle(
                        //                   fontSize: 16.0,
                        //                   fontWeight: FontWeight.bold),
                        //             ),
                        //           ],
                        //         ),
                        //       ],
                        //     )),
                        // Padding(
                        //     padding: EdgeInsets.only(
                        //         left: 25.0, right: 25.0, top: 2.0),
                        //     child: new Row(
                        //       mainAxisSize: MainAxisSize.max,
                        //       children: <Widget>[
                        //         new Flexible(
                        //           child: new TextField(
                        //             decoration: const InputDecoration(
                        //                 hintText: "Enter Email"),
                        //             enabled: !_status,
                        //           ),
                        //         ),
                        //       ],
                        //     )),
                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 25.0),
                            child: new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    new Text(
                                      'Mobile',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 2.0),
                            child: new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Flexible(
                                  child: new TextField(
                                    controller: phoneController,
                                    decoration: const InputDecoration(
                                        hintText: "Enter Mobile Number"),
                                    enabled: !_status,
                                  ),
                                ),
                              ],
                            )),

                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 25.0),
                            child: new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    new Text(
                                      'Gender',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                        Padding(
                            padding: EdgeInsets.only(
                                left: 25.0, right: 25.0, top: 2.0),
                            child: new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Flexible(
                                  child: new DropdownButton(
                                    hint: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.green),
                                        children: [
                                          // WidgetSpan(
                                          //   child: Padding(
                                          //     padding: const EdgeInsets.only(
                                          //         right: 15),
                                          //     child: Icon(
                                          //       MaterialIcons.people,
                                          //       color: Colors.green,
                                          //     ),
                                          //   ),
                                          // ),
                                          TextSpan(text: gender),
                                        ],
                                      ),
                                    ),
                                    dropdownColor: Colors.white,
                                    elevation: 5,
                                    // icon: Icon(
                                    //   Icons.arrow_drop_down,
                                    //   color: Colors.green,
                                    // ),
                                    iconSize: 36.0,
                                    isExpanded: true,
                                    underline: Padding(
                                      padding: EdgeInsets.all(5),
                                    ),
                                    value: gender,
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 16.0),
                                    onChanged: (value) {
                                      setState(() {
                                        gender = value;
                                      });
                                    },
                                    items: _genderList.map((value) {
                                      return DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            )),

                        // Padding(
                        //     padding: EdgeInsets.only(
                        //         left: 25.0, right: 25.0, top: 25.0),
                        //     child: new Row(
                        //       mainAxisSize: MainAxisSize.max,
                        //       mainAxisAlignment: MainAxisAlignment.start,
                        //       children: <Widget>[
                        //         Expanded(
                        //           child: Container(
                        //             child: new Text(
                        //               'Pin Code',
                        //               style: TextStyle(
                        //                   fontSize: 16.0,
                        //                   fontWeight: FontWeight.bold),
                        //             ),
                        //           ),
                        //           flex: 2,
                        //         ),
                        //         Expanded(
                        //           child: Container(
                        //             child: new Text(
                        //               'State',
                        //               style: TextStyle(
                        //                   fontSize: 16.0,
                        //                   fontWeight: FontWeight.bold),
                        //             ),
                        //           ),
                        //           flex: 2,
                        //         ),
                        //       ],
                        //     )),
                        // Padding(
                        //     padding: EdgeInsets.only(
                        //         left: 25.0, right: 25.0, top: 2.0),
                        //     child: new Row(
                        //       mainAxisSize: MainAxisSize.max,
                        //       mainAxisAlignment: MainAxisAlignment.start,
                        //       children: <Widget>[
                        //         Flexible(
                        //           child: Padding(
                        //             padding: EdgeInsets.only(right: 10.0),
                        //             child: new TextField(
                        //               decoration: const InputDecoration(
                        //                   hintText: "Enter Pin Code"),
                        //               enabled: !_status,
                        //             ),
                        //           ),
                        //           flex: 2,
                        //         ),
                        //         Flexible(
                        //           child: new TextField(
                        //             decoration: const InputDecoration(
                        //                 hintText: "Enter State"),
                        //             enabled: !_status,
                        //           ),
                        //           flex: 2,
                        //         ),
                        //       ],
                        //     )),
                        !_status ? _getActionButtons() : new Container(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      )),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myFocusNode.dispose();
    super.dispose();
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 45.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                  child: new RaisedButton(
                child: new Text("Cancel"),
                textColor: Colors.white,
                color: Colors.pink[900],
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, ProfilePage.id, (route) => false);
                  // setState(() {
                  //   _status = true;
                  //   FocusScope.of(context).requestFocus(new FocusNode());
                  // });
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )),
            ),
            flex: 2,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                child: new RaisedButton(
                  child: new Text("Update"),
                  textColor: Colors.white,
                  color: Colors.green,
                  onPressed: () {
                    updateProfile(context);
                    // setState(() {
                    //   _status = true;
                    //   FocusScope.of(context).requestFocus(new FocusNode());
                    // });
                  },
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(20.0)),
                ),
              ),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }

  Widget _getEditIcon() {
    return new GestureDetector(
      child: new CircleAvatar(
        backgroundColor: Colors.green,
        radius: 14.0,
        child: new Icon(
          Icons.edit,
          color: Colors.white,
          size: 16.0,
        ),
      ),
      onTap: () {
        setState(() {
          _status = false;
        });
      },
    );
  }
}
