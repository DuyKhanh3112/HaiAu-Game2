import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentPlayerResult extends StatefulWidget {
  CurrentPlayerResult({Key? key}) : super(key: key);

  @override
  State<CurrentPlayerResult> createState() => _CurrentPlayerResult();
}

class _CurrentPlayerResult extends State<CurrentPlayerResult> {
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');
  CollectionReference scoresCollection = FirebaseFirestore.instance.collection('scores');

  bool isLoading = false;

  Map<String, dynamic> userScores = {};
  List<Stage> listStage = [];

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
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      }
      else {
        setState(() {
          isLoading = true;
        });

        await GetAllStage(userInfo[0].toString());
        await StreamScore(userId[0].toString());

        setState(() {
          isLoading = false;
        });
      }
    } else{
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  GetAllStage(String idProgram) async {
    var snapshot = await stagesCollection.where("id_program", isEqualTo: idProgram).get();
    if (snapshot.docs.isNotEmpty) {
      List<Stage> newListStage = []; 

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id;
        Stage newStage = Stage.fromJson(data);
        newListStage.add(newStage);
      }
      newListStage.sort((a, b) => a.order_index.compareTo(b.order_index));

      if(mounted){
        setState(() {
          listStage = newListStage;
        });
      }
    }
  }

  StreamScore(String idUser) async {
    scoresCollection.where("id_user", isEqualTo: idUser).snapshots().listen((snapshot) { 
      if(snapshot.docs.isNotEmpty) {
        Map<String, dynamic> newUserScore = {};
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id;
          Score newScore = Score.fromJson(data);
          newUserScore[newScore.id_stage] = newScore.score; 
        }

        if (mounted) {
          setState(() {
            userScores = newUserScore;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Container(
      height: MediaQuery.of(context).size.height * 1,
      width: MediaQuery.of(context).size.width * 1,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              "https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659197878/ojax6iozxypjo3bo5ttu.jpg"),
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
                            'My result',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700),
                          )),
                          const SizedBox(height:10),
                          Container(
                            height:350,
                            child: SingleChildScrollView(
                              child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal:0),
                              child: 
                              listStage.isEmpty
                              ?
                              Center(
                                child: SizedBox(
                                  child: Column(children: [
                                    const SizedBox(height: 30),
                                    Image.network(
                                      'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1644332818/aa4_zfk64k.png',
                                      height: 100,
                                    ),
                                    const SizedBox(height: 24),
                                    const Center(
                                      child: Text(
                                          'Sorry, your results are not found',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize:20,
                                              color: Colors.white)),
                                    )
                                  ]),
                                )
                              )
                              :
                              Column(children: [
                                ...listStage.map((Stage stage) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal:10,vertical:7),
                                      margin: const EdgeInsets.symmetric(vertical:5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF043150)
                                        .withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          width: 3,
                                          color: const Color(0xFF6fd3ea),
                                      )),
                                      child: Row(children: [
                                        Image.network(
                                            'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659098707/wznudxkak8yxhmw0frm2.png',
                                            height: 35),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(stage.name,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )),
                                              const SizedBox(height: 5),
                                              Text(
                                                userScores[stage.id.toString()] != null 
                                                  ? "Score: " + userScores[stage.id.toString()].toString()
                                                  : "Score: 0", 
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )
                                              )
                                            ],
                                          ),
                                        )
                                      ]),
                                    ))
                              ]),
                            ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () {
                              Navigator.of(context)
                                  .pop();
                            },
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF043150)
                                        .withOpacity(0.8),
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
