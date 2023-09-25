import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllTeamResult extends StatefulWidget {
  AllTeamResult({Key? key}) : super(key: key);

  @override
  State<AllTeamResult> createState() => _AllTeamResult();
}

class _AllTeamResult extends State<AllTeamResult> {
  CollectionReference scoresCollection = FirebaseFirestore.instance.collection('scores');
  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  CollectionReference programCollection = FirebaseFirestore.instance.collection('programs');
  CollectionReference stageCollection = FirebaseFirestore.instance.collection('stages');

  bool isLoading = false;

  List<User> listUsers = [];
  List<Score> listScores = [];
  List<Stage> listStages = [];

  String? currentIdUser;
  
  @override
  void initState() {
    super.initState();
    checkForAuth();
  }

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    final List<String>? userId = prefs.getStringList('player_id');

    if (userInfo != null && userId != null) {
      if (userInfo[1] != 'player') {
        return Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/admin');
        });
      }

      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      await fetchStage();
      await StreamUser();
      await StreamScore();

      if (mounted) {
        setState(() {
          isLoading = false;
          currentIdUser = userId[0];
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  fetchStage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    
    List<Stage> newListStage = [];
    var snapshotStage = await stageCollection.where("id_program", isEqualTo: userInfo![0]).get();
    for (var doc in snapshotStage.docs) {
      Map<String, dynamic> stageJson = doc.data() as Map<String, dynamic>;
      stageJson["id"] = doc.id;
      Stage newStage = Stage.fromJson(stageJson);
      newListStage.add(newStage);
    }
    newListStage.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      listStages = newListStage;
    });
  }


  StreamUser() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    // Get all player of program
    if ( userInfo!= null) {
      usersCollection
          .where("id_program", isEqualTo: userInfo[0])
          .where("role", isEqualTo: "player")
          .snapshots()
          .listen((snapshotUser) {
        if (snapshotUser.docs.isNotEmpty) {
          List<User> newListUser = [];
          for (var doc in snapshotUser.docs) {
            Map<String, dynamic> userJson = doc.data() as Map<String, dynamic>;
            userJson["id"] = doc.id;
            User newUser = User.fromJson(userJson);
            newListUser.add(newUser);
          }
          newListUser.sort((a, b) => a.name.compareTo(b.name));

          setState(() {
            listUsers = newListUser;
          });
        }
      });
    }
  }

  StreamScore() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    
    if (userInfo != null) {
      scoresCollection
          .where("id_program", isEqualTo: userInfo[0])
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          List<Score> newListScore = [];
          for (var doc in snapshot.docs) {
            Map<String, dynamic> jsonScore = doc.data() as Map<String, dynamic>;
            jsonScore["id"] = doc.id;
            Score newScore = Score.fromJson(jsonScore);
            newListScore.add(newScore);
          }

          if(mounted){
            setState(() {
              listScores = newListScore;
            });
          }
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {

    List<Map<String, dynamic>> listUserTotalScore = [];
    for (var user in listUsers) {
      // Calculate total score of the user
      int totalScore = 0;
      List<Score> listUserScore = listScores.where((Score score) => score.id_user == user.id).toList();
      if (listUserScore.isNotEmpty) {
        for (var score in listUserScore) {
          totalScore = totalScore + int.parse(score.score.toString());
        }
        listUserTotalScore.add({"id": user.id, "name": user.name, "totalScore": totalScore});
      }
      else {
        totalScore = 0;
        listUserTotalScore.add({"id": user.id, "name": user.name, "totalScore": 0});
      }
    }
    listUserTotalScore.sort((a, b) => b["totalScore"].compareTo(a["totalScore"]));

    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Container(
      height: MediaQuery.of(context).size.height * 1,
      width: MediaQuery.of(context).size.width * 1,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage("https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659197878/ojax6iozxypjo3bo5ttu.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
          height: MediaQuery.of(context).size.height * 1,
          width: MediaQuery.of(context).size.width * 1,
          decoration: BoxDecoration(
            color: const Color(0xFF043150).withOpacity(0.4),
          ),
          child: SingleChildScrollView(
            child: isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 1,
                    child: const Center(
                        child: SpinKitWave(
                      color: Colors.white,
                      size: 50.0,
                    )),
                  )
                : Container(
                    height: MediaQuery.of(context).size.height * 1,
                    width: MediaQuery.of(context).size.width * 1,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Center(
                            child: Text(
                          'Leaderboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w700),
                        )),
                        const SizedBox(height: 10),
                        Container(
                          height: 350,
                          child: SingleChildScrollView(
                            child: Container(
                              padding:const EdgeInsets.symmetric(vertical:10,horizontal:20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 5),
                                  ...listUserTotalScore.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var data = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF043150).withOpacity(0.8),
                                        border: Border.all(
                                          color: currentIdUser == data["id"] ? Colors.yellow :const Color(0xFF6fd3ea),
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal:5,vertical:10),
                                      child: Row(
                                        children: [
                                          index + 1 == 1
                                          ?
                                          Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/rtdyrotylzjzr3c00h0t.png',height:30)
                                          :
                                        index + 1 == 2
                                          ?
                                          Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/mgbxzflmkttbtakcl8eo.png',height:30)
                                          :
                                          index + 1 == 3
                                          ?
                                          Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/x0gyryatf0chcyzcxxgb.png',height:30)
                                          :
                                          SizedBox(width:30,child: Center(child: Text((index + 1).toString(),style:TextStyle(fontWeight: FontWeight.w800,color:Colors.white.withOpacity(0.8),fontSize:25)))),
                                          const SizedBox(width:10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(data["name"] ,style:const TextStyle(fontWeight: FontWeight.bold,color:Colors.white,fontSize:18)),
                                              Row(
                                                children: [
                                                  const Text('Tổng số điểm:',style:TextStyle(fontWeight: FontWeight.w500,color:Colors.white,fontSize:16)),
                                                  const SizedBox(width: 5,),
                                                  Text(data["totalScore"].toString(), style:const TextStyle(fontWeight: FontWeight.w500,color:Colors.white,fontSize:16)),
                                                ],
                                              ),
                                            ]
                                          )
                                        ],
                                      ),
                                    );
                                  })
                                ],
                              ),
                            )
                          ),
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF043150).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    width: 3,
                                    color: const Color(0xFF6fd3ea),
                                  )),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('Return',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700))
                                ],
                              )),
                        ),
                      ],
                    ),
                  ),
          )),
    ))));
  }
}
