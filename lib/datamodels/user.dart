import 'package:firebase_database/firebase_database.dart';

class UserProfile {
  String fullName;
  String email;
  String gender;
  String phone;
  String id;
  String imageUrl;

  UserProfile({
    this.email,
    this.gender,
    this.fullName,
    this.phone,
    this.id,
    this.imageUrl
  });

  UserProfile.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    phone = snapshot.value['phone'];
    email = snapshot.value['email'];
    gender = snapshot.value['gender'];
    imageUrl = snapshot.value['imageUrl'];
    fullName = snapshot.value['fullName'];
  }
}
