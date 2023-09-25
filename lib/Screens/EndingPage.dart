import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:haiau_game2/Screens/AllTeamResult.dart';
import 'package:haiau_game2/Screens/CurrentPlayerResult.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndingPage extends StatefulWidget {
  EndingPage({Key? key}) : super(key: key);

  @override
  State<EndingPage> createState() => _EndingPageState();
}

class _EndingPageState extends State<EndingPage> {

  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');
  CollectionReference scoresCollection = FirebaseFirestore.instance.collection('scores');
  CollectionReference programsCollection = FirebaseFirestore.instance.collection('programs');

  bool isFinished = false;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    checkForAuth();
  }

  checkForAuth()async{
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    final List<String>? userId = prefs.getStringList('player_id');
    final bool? alreadyEnter = prefs.getBool('alreadyEnterProgram');

    if(userInfo != null && userId != null){

      if(userInfo[1] != 'player'){
        return Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      }else if(userInfo[1] == 'player' && (alreadyEnter == null || alreadyEnter == false)){
        return Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      }

      if(mounted){
        setState(() {
          isLoading = true;
        });
      }

      final snapshotStage = await stagesCollection.where('id_program',isEqualTo: userInfo[0]).get();
      final allRelatedStage = snapshotStage.docs.map((doc) => doc.id).toList();  
      
      final snapshot = await usersCollection.doc(userId[0]).get();
      final relatedUser = User.fromJson(snapshot.data() as Map<String, dynamic>);
      
      final snapshotProgram = await programsCollection.doc(userInfo[0]).get();
      final relatedProgram = Program.fromJson(snapshotProgram.data() as Map<String, dynamic>);

      DateTime dateTime = DateTime.now();
      final currrentTime = dateTime.toUtc().add(const Duration(hours:7));

      final timeUserStart = relatedUser.startAt.isNotEmpty ? DateTime.parse(relatedUser.startAt) : currrentTime;

      Duration diff = currrentTime.difference(timeUserStart);
      final diffInSeconds = diff.inSeconds;
      final duration = int.parse(relatedProgram.duration)*60;
      if(userInfo[1] == 'player' && alreadyEnter != null && duration - diffInSeconds >0 && relatedUser.currentStage <= allRelatedStage.length-1){
        return Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/game-stage');
        });
      }

      if(mounted){
        if(userInfo[1] == 'player' && alreadyEnter != null &&  relatedUser.currentStage > allRelatedStage.length -1){
          setState(() {
            isLoading = false;
            isFinished = true;
          });
        }else{
          setState(() {
            isLoading = false;
            isFinished = false;
          });
        }
      }
    }else{
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(
        child:Center(
          child: Container(
            height: MediaQuery.of(context).size.height*1,
            width: MediaQuery.of(context).size.width*1,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659197878/ojax6iozxypjo3bo5ttu.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height*1,
              width: MediaQuery.of(context).size.width*1,
              decoration: BoxDecoration(
                color: const Color(0xFF043150).withOpacity(0.6),
              ),
              child: SingleChildScrollView(
                child: 
                isLoading
                ?
                SizedBox(
                  height: MediaQuery.of(context).size.height*1,
                  child: const Center(
                    child:SpinKitWave(
                      color: Colors.white,
                      size: 50.0,
                    ) 
                  ),
                )
                :
                Container(
                  height: MediaQuery.of(context).size.height*1,
                  width: MediaQuery.of(context).size.width*1,
                  padding:const EdgeInsets.symmetric(horizontal:30),
                  child: Center(
                    child: Column(
                      mainAxisAlignment:MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                          Center(child: Text(isFinished ? 'You have finished all stages. Congratulations to all of you !' : 'This event is over. Please turn back to home page !',textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize:23,fontWeight: FontWeight.w700),)),
                          const SizedBox(height:30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 35),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AllTeamResult()),
                                        );
                                      },
                                      child: Container(
                                        height: 65,
                                        width: 65,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF043150)
                                              .withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                              width: 2,
                                              color: const Color(
                                                  0xFF02c3ca) //                   <--- border width here
                                              ),
                                        ),
                                        child: Center(
                                            child: Image.network(
                                                'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659512636/flnyyj0ysm9nibrniomb.png',
                                                height: 32)),
                                      ),
                                    ),
                                    Container(height: 5),
                                    const Text('Leaderboard',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700))
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CurrentPlayerResult()),
                                        );
                                      },
                                      child: Container(
                                        height: 65,
                                        width: 65,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF043150)
                                              .withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                              width: 2,
                                              color: const Color(
                                                  0xFF02c3ca) //                   <--- border width here
                                              ),
                                        ),
                                        child: Center(
                                            child: Image.network(
                                                'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659512636/rpcrsikdvbcqqicjpxo2.png',
                                                height: 32)),
                                      ),
                                    ),
                                    Container(height: 5),
                                    const Text('My result',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700))
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height:20),
                          InkWell(
                          onTap:(){
                            Navigator.of(context).pushReplacementNamed('/waiting-room');
                          },
                          child: Container(
                            padding:const EdgeInsets.symmetric(horizontal:15, vertical:10), 
                            decoration: BoxDecoration(
                              color: const Color(0xFF043150).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border:Border.all(
                                width: 3,
                                color: const Color(0xFF6fd3ea),
                              )
                            ),
                            child:Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const[
                                Text('Return',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                              ],
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ),
          )
        )
      )
    );
  }
}