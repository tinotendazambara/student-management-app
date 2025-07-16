import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'enrolled_students.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zztjhancnbzkpnzllaaq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6dGpoYW5jbmJ6a3BuemxsYWFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NTQ5ODAsImV4cCI6MjA2ODIzMDk4MH0.SugH1pX_n-rj44AdPFVA2BlRwng4JzF2tHxEtNrw5_s',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EnrolledStudents(),
    );
  }
}
