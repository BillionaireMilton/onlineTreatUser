import '../Dataprovider/appdata.dart';
import '../brand_colors.dart';
import '../globalvariables.dart';
import '../screens/mainpage.dart';
import '../widgets/BrandDivier.dart';
import '../widgets/HistoryTile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  static const String id = 'history';
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, MainPage.id, (route) => false);
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text('Treatment History'),
            backgroundColor: Colors.green,
            leading: IconButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, MainPage.id, (route) => false);
              },
              icon: Icon(Icons.keyboard_arrow_left),
            ),
          ),
          body: Provider.of<AppData>(context).treatmentHistory.isNotEmpty
              ? ListView.separated(
                  padding: EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    return HistoryTile(
                      history:
                          Provider.of<AppData>(context).treatmentHistory[index],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      BrandDivider(),
                  itemCount:
                      Provider.of<AppData>(context).treatmentHistory.length,
                  physics: ClampingScrollPhysics(),
                  shrinkWrap: true,
                )
              : Container(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            // '${Provider.of<AppData>(context).treatmentHistory}',
                            // "${currentDoctorInfo.fullName}",
                            "",
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.green),
                          ),
                          Text(
                            // '${Provider.of<AppData>(context).treatmentHistory}',
                            "You have not requested for any successful treatment",
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.green),
                          ),
                          Text(
                            // '${Provider.of<AppData>(context).treatmentHistory}',
                            "",
                            style:
                                TextStyle(fontSize: 25.0, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
    );
  }
}
