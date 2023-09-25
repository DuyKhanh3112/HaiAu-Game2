import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaitingRoom extends StatefulWidget {
  WaitingRoom({Key? key}) : super(key: key);

  @override
  State<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<WaitingRoom> {

  final TextEditingController _programPasswordController = TextEditingController();
  String password = '';
  bool isVerifying = false;
  bool isFailed = false;

  CollectionReference programsCollection = FirebaseFirestore.instance.collection('programs');
  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');

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
        Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
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

      var timeUserStart;
      if(relatedUser.startAt.isEmpty){
        timeUserStart = currrentTime;
      }else{
        timeUserStart = DateTime.parse(relatedUser.startAt);
      }

      Duration diff = currrentTime.difference(timeUserStart);
      final diffInSeconds = diff.inSeconds;
      final duration = int.parse(relatedProgram.duration)*60;
      if(userInfo[1] == 'player' && alreadyEnter != null && duration - diffInSeconds > 0 && relatedUser.currentStage <= allRelatedStage.length - 1){
        return Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/game-stage');
        });
      }
    }else{
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  handleLogout()async{
    if(isVerifying) return;
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userId = prefs.getStringList('player_id');

    if (userId != null) {
      usersCollection.doc(userId[0].toString()).update({"isOnline": "false"});
    }

    await prefs.remove('player_auth');
    await prefs.remove('alreadyEnterProgram');
    await prefs.remove('player_id');
    Future.delayed(const Duration(seconds:0), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  handleEnterGame()async{
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    final List<String>? userId = prefs.getStringList('player_id');

    if(_programPasswordController.text == '') return;
    if(userInfo == null){
      return Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      }); 
    }
    
    if(isVerifying) return;

    setState(() {
      isVerifying = true;
    });

    DateTime dateTime = DateTime.now();
    final timeStart = dateTime.toUtc().add(const Duration(hours:7));
    

    final snapshot = await programsCollection.doc(userInfo[0]).get();
    final allRelatedProgram = Program.fromJson(snapshot.data() as Map<String, dynamic>);
    
    if(_programPasswordController.text.toString() == allRelatedProgram.password){
      await prefs.setBool('alreadyEnterProgram', true);
      final snapshotStage = await stagesCollection.where('id_program',isEqualTo: userInfo[0]).get();
      final allRelatedStage = snapshotStage.docs.map((doc) => doc.id).toList();  
      
      final snapshot = await usersCollection.doc(userId![0]).get();
      final relatedUser = User.fromJson(snapshot.data() as Map<String, dynamic>);

      DateTime dateTime = DateTime.now();
      final currrentTime = dateTime.toUtc().add(const Duration(hours:7));

      if(relatedUser.startAt.isNotEmpty){
        final timeUserStart = DateTime.parse(relatedUser.startAt);
        Duration diff = currrentTime.difference(timeUserStart);
        final diffInSeconds = diff.inSeconds;
        final duration = int.parse(allRelatedProgram.duration)*60;
        
        if (duration - diffInSeconds <= 0) {
          if (mounted) {
            return Future.delayed(const Duration(seconds: 0), () {
              Navigator.of(context).pushReplacementNamed('/ending');
            });
          }
        }
      }

      if(relatedUser.currentStage > allRelatedStage.length-1){
        return Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed('/ending');
        });
      }

      setState(() {
        isVerifying = false;
        isFailed = false;
        password = '';
      });

      
      if(relatedUser.startAt.isEmpty){
        usersCollection.doc(userId[0].toString()).update({'startAt':timeStart.toIso8601String()});
      }

      _programPasswordController.clear();
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed('/game-stage');
      });
    }else{
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pop();
      });
      Future.delayed(const Duration(milliseconds:500), () {
        handleShowTextBox();
      });
      setState(() {
        isVerifying = false;
        isFailed = true;
      });
    }
  }

  handleShowTextBox(){
    return showDialog(
      barrierColor: const Color(0xFF043150).withOpacity(0.5),
      context: context,
      builder: (context) =>  StatefulBuilder(
        builder: (context,setState){
          return AlertDialog(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color:const Color(0xFF6fd3ea),
            ),
            padding:const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color:const Color(0xFF043150),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height:80,
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child:const Center(child:Text("Password of event",style:TextStyle(color: Colors.white,fontSize:20,fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(height:0),
                  isFailed
                  ?
                  const Padding(
                    padding:EdgeInsets.symmetric(horizontal:20),
                    child:Text("Incorrect password",style:TextStyle(color: Colors.red,fontSize:16,fontWeight: FontWeight.w700)),
                  )
                  :
                  const SizedBox(),
                  const SizedBox(height:10),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal:20),
                    child: TextField(
                      onChanged: (value) =>{
                        setState(() {
                          password = value;
                        })
                      },
                      controller: _programPasswordController ,
                      style: const TextStyle(color: Color(0xFF00b0ec),fontSize:20,letterSpacing:2,fontWeight: FontWeight.w800),
                      decoration:  InputDecoration(
                        prefixIcon:  const Icon(Icons.lock_outline,color:Color(0xFF6fd3ea)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(width: 3, color: Color(0xFF6fd3ea)), //<-- SEE HERE
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(width: 3, color: Color(0xFF6fd3ea)), //<-- SEE HERE
                        ),
                        hintText: 'MẬT KHẨU',
                        fillColor: const Color(0xFF071a29),
                        filled:true,
                        contentPadding: const EdgeInsets.all(8),
                      ),
                      keyboardType: TextInputType.text,
                      obscureText:false, 
                    ),
                  ),
                  const SizedBox(height:10),
                    // Button enter
                  Container(
                    decoration: BoxDecoration(
                      color:const Color(0xFF043150),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal:18,vertical:10),
                    child: InkWell(
                      onTap:handleEnterGame,
                      child: Container(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        decoration: BoxDecoration(
                          color: password.isNotEmpty ? const Color(0xFF187498) : const Color(0xFF73777B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:Text(
                          "START",
                          style: TextStyle(color: password.isNotEmpty ? Colors.white : const Color(0xFFCFD2CF),fontSize:17,fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
    );
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
                color: const Color(0xFF043150).withOpacity(0.5),
              ),
              child: SingleChildScrollView(
                child:Container(
                  height: MediaQuery.of(context).size.height*1,
                  width: MediaQuery.of(context).size.width*1,
                  padding: const EdgeInsets.symmetric(horizontal:30),
                  child: Column(
                    mainAxisAlignment:MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children:  [
                      InkWell(
                        onTap:handleShowTextBox,
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
                            children: [
                              Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649671485/right-arrow_qulvq4.png',width:30),
                              const SizedBox(width:10),
                              const Text('Start to play',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                            ],
                          )
                        ),
                      ),
                      const SizedBox(height:20),
                      InkWell(
                        onTap:(){
                          if(isVerifying) return;
                          Navigator.of(context).pushReplacementNamed('/update-info');
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
                            children: [
                              Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649670849/exam_mzkm0b.png',width:30),
                              const SizedBox(width:10),
                              const Text('Update information',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                            ],
                          )
                        ),
                      ),
                      const SizedBox(height:20),
                      InkWell(
                        onTap:handleLogout,
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
                            children: [
                              Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659322178/l2znkw8hqeggwph8ah71.png',width:30),
                              const SizedBox(width:10),
                              const Text('Log out my account',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                            ],
                          )
                        ),
                      ),
                    ],
                  ),
                )
              ),
            ),
          ),
        )
      )
    );
  }
}