import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final ref = FirebaseDatabase.instance.ref('mentor');
  final snapshot = await ref.get();
  
  print('Mentor data exists: ${snapshot.exists}');
  print('Mentor data type: ${snapshot.value.runtimeType}');
  print('Mentor data: ${snapshot.value}');
  
  exit(0);
}
