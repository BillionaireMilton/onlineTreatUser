import 'dart:async';
import 'dart:io';
import '../screens/mainpage.dart';
import '../widgets/TaxiButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';

class TestPage extends StatefulWidget {
  static const String id = 'testpage';
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<String> attachments = [];
  bool isHTML = false;

  final _recipientController = TextEditingController(
    text: 'example@example.com',
  );

  final _subjectController = TextEditingController(text: 'The subject');

  final _bodyController = TextEditingController(
    text: 'Mail body.',
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> send() async {
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Created with '),
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(Icons.airport_shuttle),
                ),
              ),
              TextSpan(text: 'By Michael'),
            ],
          ),
        ),
        leading: IconButton(
          alignment: Alignment.bottomLeft,
          icon: Icon(Icons.keyboard_arrow_left),
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
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _recipientController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Recipient',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Subject',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                      labelText: 'Body', border: OutlineInputBorder()),
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
