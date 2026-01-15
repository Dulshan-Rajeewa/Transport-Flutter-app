import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY']!,
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        appId: dotenv.env['FIREBASE_APP_ID']!,
      ),
    );
  }

  // Trips collection reference
  static CollectionReference get tripsCollection =>
      firestore.collection('trips');

  // Expenses collection reference
  static CollectionReference get expensesCollection =>
      firestore.collection('expenses');

  // Routes collection reference
  static CollectionReference get routesCollection =>
      firestore.collection('routes');

  // Settings document reference
  static DocumentReference get settingsDocument =>
      firestore.collection('app_settings').doc('main_settings');
}
