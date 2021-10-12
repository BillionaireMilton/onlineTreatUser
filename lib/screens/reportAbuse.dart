import 'dart:async';
import 'dart:io';
import '../screens/mainpage.dart';
import '../screens/wait.dart';
import '../widgets/TaxiButton.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';

class ReportPage extends StatefulWidget {
  static const String id = 'reportpage';
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<String> attachments = [];
  bool isHTML = false;

  final _recipientController = TextEditingController(
    text: 'dpetworldpetambulance@gmail.com',
  );

  var _subjectController = TextEditingController();

  var _bodyController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void showSnackBar(String title) {
    final snackbar = SnackBar(
      content: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15),
      ),
    );
    _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  Future<void> send() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      showSnackBar('No internet connectivity');
      return;
    }
    if (_subjectController.text.length < 3) {
      showSnackBar('Please provide a valid subject');
      return;
    }

    if (_bodyController.text.length < 3) {
      showSnackBar('Please tell us about the abuse');
      return;
    }

    final Email email = Email(
      body: _bodyController.text,
      subject: _subjectController.text,
      recipients: [_recipientController.text],
      attachmentPaths: attachments,
      isHTML: isHTML,
    );

    String platformResponse;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = 'success';
      Navigator.pushNamedAndRemoveUntil(
          context, MyHomePage.id, (route) => false);
    } catch (error) {
      platformResponse = error.toString();
    }

    if (!mounted) return;

    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(platformResponse),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, MainPage.id, (route) => false);
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'Report Abuse '),
                WidgetSpan(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Icon(Icons.warning_amber_rounded),
                  ),
                ),
                // TextSpan(text: 'By Michael'),
              ],
            ),
          ),
          leading: IconButton(
            alignment: Alignment.bottomLeft,
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.keyboard_arrow_left),
            ),
            color: Colors.white,
            onPressed: () {
              // Navigator.pop(context, 'mainpage');
              Navigator.pushNamedAndRemoveUntil(
                  context, MainPage.id, (route) => false);
            },
          ),
          actions: <Widget>[
            IconButton(
              onPressed: send,
              icon: Icon(Icons.send),
            )
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Padding(
              //   padding: EdgeInsets.all(8.0),
              //   child: TextField(
              //     controller: _recipientController,
              //     decoration: InputDecoration(
              //       border: OutlineInputBorder(),
              //       labelText: 'Recipient',
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 12, right: 12, top: 8, bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: TextFormField(
                      controller: _subjectController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.green),
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.green),
                          labelText: "Subject",
                          hintText: "a dog abuse report",
                          icon: Icon(
                            Icons.forward,
                            color: Colors.green,
                          )),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 8, bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: TextFormField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(color: Colors.green),
                            border: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.green),
                            labelText: "Message",
                            hintText: "enter the abuse report here",
                            icon: Icon(
                              Icons.email,
                              color: Colors.green,
                            )),
                      ),
                    ),
                  ),
                ),
              ),
              // CheckboxListTile(
              //   contentPadding:
              //       EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
              //   title: Text('HTML'),
              //   onChanged: (bool value) {
              //     setState(() {
              //       isHTML = value;
              //     });
              //   },
              //   value: isHTML,
              // ),

              //com.example.cabby
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Wrap(
                  children: <Widget>[
                    for (var i = 0; i < attachments.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                              flex: 0,
                              child: Container(
                                margin: EdgeInsets.all(10),
                                width: 40,
                                height: 40,
                                child: Image.file(File(attachments[i]),
                                    fit: BoxFit.cover),
                              )),
                          IconButton(
                            icon: Icon(Icons.remove_circle),
                            onPressed: () => {_removeAttachment(i)},
                          )
                        ],
                      ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openImagePicker,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Attach file',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.attach_file),
                                onPressed: _openImagePicker,
                              ),
                            ],
                          ),
                        ),
                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: IconButton(
                        //     onPressed: send,
                        //     icon: Icon(Icons.send),
                        //   ),
                        // ),
                        //
                        SizedBox(width: 25),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TaxiButton(
                              title: 'Send Message',
                              color: Colors.pink[900],
                              onPressed: send,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _openImagePicker() async {
    final pick = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pick != null) {
      setState(() {
        attachments.add(pick.path);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      attachments.removeAt(index);
    });
  }
}
