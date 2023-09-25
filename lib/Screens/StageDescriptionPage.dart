import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StageDescription extends StatefulWidget {
  StageDescription({Key? key}) : super(key: key);

  @override
  State<StageDescription> createState() => _StageDescriptionPageStage();
}

class _StageDescriptionPageStage extends State<StageDescription> {
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference stagesCollection =
      FirebaseFirestore.instance.collection('stages');
  CollectionReference scoresCollection =
      FirebaseFirestore.instance.collection('scores');
  CollectionReference programsCollection =
      FirebaseFirestore.instance.collection('programs');

  bool isLoading = false;

  List userResults = [];
  List allStageRelated = [];
  List description = [];

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



      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

     final snapshot = await usersCollection.doc(userId[0]).get();
      final relatedUser = User.fromJson(snapshot.data() as Map<String, dynamic>);

      final snapshotStage = await stagesCollection
          .where('id_program', isEqualTo: userInfo[0])
          .get();
      final allRelatedStages = snapshotStage.docs
          .map((doc) => Stage.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      final currentViewedStage = allRelatedStages.where((e)=>e.order_index == relatedUser.currentStage );


      setState(() {
        userResults = [...currentViewedStage];
        isLoading = false;
      });

      if(userResults.isEmpty){
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      }

      final allParagraphs = userResults[0].description.split('/n/');
      setState(() {
        description = allParagraphs ;
      });

    } else {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(
        child:Center(
          child:Container(
            height: MediaQuery.of(context).size.height*1,
            width: MediaQuery.of(context).size.width*1,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    "https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659197878/ojax6iozxypjo3bo5ttu.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child:Container(
              height: MediaQuery.of(context).size.height * 1,
              width: MediaQuery.of(context).size.width * 1,
              decoration: BoxDecoration(
                color: const Color(0xFF043150).withOpacity(0.6),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: 
                  isLoading
                  ?
                   SizedBox(
                    height:
                        MediaQuery.of(context).size.height * 1,
                    child: const Center(
                        child: SpinKitWave(
                      color: Colors.white,
                      size: 50.0,
                    )),
                  )
                  :
                  description.isNotEmpty
                  ?
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Description'.toUpperCase(),style:const TextStyle(fontSize:30,color:Colors.white,fontWeight:FontWeight.w700)),
                        const SizedBox(height: 20),
                        Container(
                          color:Colors.white,
                          padding:const EdgeInsets.symmetric(horizontal:20,vertical:15),
                          height:300,
                          child:SingleChildScrollView(
                            child: Column(
                              children: [
                                ...description.map((item){
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom:10
                                    ),
                                    child: Text(item,textAlign: TextAlign.justify,style:const TextStyle(letterSpacing: 1, fontSize:18,color:Colors.black,fontWeight:FontWeight.w500,)),
                                  );
                                }).toList()
                              ],
                            ),
                          )
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal:30),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal:10, vertical: 10),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF043150)
                                        .withOpacity(0.8),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      width: 3,
                                      color: const Color(0xFF6fd3ea),
                                    )),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Text('Return',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w700))
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
                  )
                  :
                  // Not found 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:[
                      Image.network(
                        'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1644332818/aa4_zfk64k.png',
                        height: 100,
                      ),
                      const SizedBox(height: 24),
                      const Text('Sorry, description is not founded !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Colors.white
                        )
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
              ),
            )
          )
        )
      )
    );
  }       
}
