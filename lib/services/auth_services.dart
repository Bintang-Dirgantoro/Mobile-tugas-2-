import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
Future <UserCredential> login (
  String email, String password,
) async {
  return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
}

Future<void> logout() async {
  await _firebaseAuth.signOut();
}

User? get currentUser {
  return _firebaseAuth.currentUser; 
}


}