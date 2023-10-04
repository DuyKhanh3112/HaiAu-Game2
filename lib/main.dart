import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:haiau_game2/Screens/AdminAccountViewPage.dart';
import 'package:haiau_game2/Screens/AdminPage.dart';
import 'package:haiau_game2/Screens/AdminResultPage.dart';
import 'package:haiau_game2/Screens/AdminSettingPage.dart';
import 'package:haiau_game2/Screens/AllTeamResult.dart';
import 'package:haiau_game2/Screens/CreateProgramPage.dart';
import 'package:haiau_game2/Screens/CreateStagePage.dart';
import 'package:haiau_game2/Screens/CurrentPlayerResult.dart';
import 'package:haiau_game2/Screens/EndingPage.dart';
import 'package:haiau_game2/Screens/EvaluationPage.dart';
import 'package:haiau_game2/Screens/LoginScreen.dart';
import 'package:haiau_game2/Screens/StageDescriptionPage.dart';
import 'package:haiau_game2/Screens/StageGamePage.dart';
import 'package:haiau_game2/Screens/UpdateInfoPage.dart';
import 'package:haiau_game2/Screens/WaitingRoom.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        // apiKey: "AIzaSyDYvbniPqkpQA8lPoA0sWRYLEmDp6oAiTs",
        // authDomain: "hai-au-game2-964d9.firebaseapp.com",
        // projectId: "hai-au-game2-964d9",
        // storageBucket: "hai-au-game2-964d9.appspot.com",
        // messagingSenderId: "837769445219",
        // appId: "1:837769445219:web:2551a0b6f34c556fb89d56"
        apiKey: "AIzaSyC_eKn3T2S1ZDv2GTFGrB8dmaOOywDXmFU",
        authDomain: "haiau-game2-6a5ee.firebaseapp.com",
        databaseURL: "https://haiau-game2-6a5ee-default-rtdb.firebaseio.com",
        projectId: "haiau-game2-6a5ee",
        storageBucket: "haiau-game2-6a5ee.appspot.com",
        messagingSenderId: "601120271252",
        appId: "1:601120271252:web:2242c0a5261a72aaa13d81"),
  );
  runApp(const MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        "/read-description": (context) => StageDescription(),
        "/view-account": (context) => AdminAccountViewPage(),
        "/all-team-result": (context) => AllTeamResult(),
        "/player-result": (context) => CurrentPlayerResult(),
        "/ending": (context) => EndingPage(),
        "/update-info": (context) => UpdateInfoPage(),
        "/waiting-room": (context) => const WaitingRoom(),
        "/login": (context) => const LoginScreen(),
        "/admin-home": (context) => const AdminPage(),
        "/add-program": (context) => const CreateProgramPage(),
        "/add-stage": (context) => const CreateStagePage(),
        "/evaluation": (context) => EvaluationPage(),
        "/admin-result": (context) => const AdminResultPage(),
        "/game-stage": (context) => const StageGamePage(),
        "/admin-setting": (context) => const AdminSettingPage(),
      },
    );
  }
}
