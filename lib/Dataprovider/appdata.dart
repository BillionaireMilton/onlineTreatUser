import '../datamodels/history.dart';
import '../datamodels/address.dart';
import 'package:flutter/cupertino.dart';

class AppData extends ChangeNotifier {
  Address pickupAddress;
  int treatmentCount = 0;
  List<String> treatmentHistoryKeys = [];
  List<History> treatmentHistory = [];

  Address destinationAddress;
  void updatePickupAddress(Address pickup) {
    pickupAddress = pickup;
    notifyListeners();
  }

  void updateDestinationAddress(Address destination) {
    destinationAddress = destination;
    notifyListeners();
  }

  void updateTreatmentCount(int newTreatmentCount) {
    treatmentCount = newTreatmentCount;
    notifyListeners();
  }

  void updateTreatmentKeys(List<String> newKeys) {
    treatmentHistoryKeys = newKeys;
    notifyListeners();
  }

  void updateTreatmentHistory(History historyItem) {
    treatmentHistory.add(historyItem);
    notifyListeners();
  }
}
