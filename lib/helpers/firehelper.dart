import '../datamodels/nearbydoctor.dart';

class FireHelper {
  static List<NearbyDoctor> nearbyDoctorList = [];

  static void removeFromList(String key) {
    int index = nearbyDoctorList.indexWhere((element) => element.key == key);
    nearbyDoctorList.remove(index);
  }

  static void updateNearbyLocation(NearbyDoctor doctor) {
    int index =
        nearbyDoctorList.indexWhere((element) => element.key == doctor.key);

    nearbyDoctorList[index].longitude = doctor.longitude;
    nearbyDoctorList[index].latitude = doctor.latitude;
  }
}
