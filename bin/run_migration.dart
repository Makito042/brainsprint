import 'package:brainsprint/main_migration.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  print('🚀 Starting Firestore migration...');
  await migrateFirestore();
  
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Migration completed successfully!'),
      ),
    ),
  ));
}
