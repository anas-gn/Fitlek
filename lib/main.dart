import 'package:flutter/material.dart';
import 'screens/ENG/welcome.dart';
import 'screens/ENG/ClientSessions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 // await UserSession.instance.load(); 
  runApp(const Fitlek());
}

class Fitlek extends StatelessWidget {
  const Fitlek({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home:// UserSession.instance.isLoaded 
         // ? const MainLayout() 
         const WelcomeScreen(),  
    );
  }
}