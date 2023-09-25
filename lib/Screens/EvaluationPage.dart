import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:haiau_game2/widgets/showNotifyAlert.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluationPage extends StatefulWidget {
  EvaluationPage({Key? key}) : super(key: key);

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final TextEditingController _scoreController =  TextEditingController();

  CollectionReference programCollection = FirebaseFirestore.instance.collection("programs");
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');
  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  CollectionReference scoresCollection = FirebaseFirestore.instance.collection('scores');

  List<Program> listPrograms = [];
  List<User> listUsers = [];
  List<Stage> listStages = [];
  List<Score> listScores = [];

  String? selectedIdProgram;
  String? selectedIdUser;
  String? selectedIdStage;

  bool isLoading = false;
  String? currentUserRole;

  @override
  void initState() {
    Initial();
    super.initState();
  }

  @override
  void dispose() {
    _scoreController.clear();
    super.dispose();
  }

  Initial() async {
    await checkForAuth();
    if (selectedIdProgram != null) {
      await GetStage();
      await StreamUser();
      await StreamScore();
    }
    else {
      await fetchProgram();
    }
  }

  fetchProgram() async {
    List<Program> newListProgram = [];

    var snapshot = await programCollection.get();
    for (var doc in snapshot.docs) {
      Map<String, dynamic> programJson = doc.data() as Map<String, dynamic>;
      programJson["id"] = doc.id;
      Program newProgram = Program.fromJson(programJson);
      newListProgram.add(newProgram);
    }

    newListProgram.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      listPrograms = newListProgram;
    });
  }

  GetStage() async {
    // Get all stage of program
    if (selectedIdProgram != null) {
      List<Stage> newListStage= [];
      List<User> newListUser = [];

      var snapshotStage = await stagesCollection.where("id_program", isEqualTo: selectedIdProgram).get();
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
  }

  StreamUser() async {
    // Get all player of program
    if (selectedIdProgram != null) {
      usersCollection.where("id_program", isEqualTo: selectedIdProgram).where("role", isEqualTo: "player").snapshots().listen((snapshotUser) {
        if (snapshotUser.docs.isNotEmpty) {
          List<User> newListUser = [];
          for (var doc in snapshotUser.docs) {
            Map<String, dynamic> userJson = doc.data() as Map<String, dynamic>;
            userJson["id"] = doc.id;
            User newUser = User.fromJson(userJson);
            newListUser.add(newUser);
          }
          newListUser.sort((a, b) => a.name.compareTo(b.name));

          if(mounted){
            setState(() {
              listUsers = newListUser;
            });
          }
        }
      });
    }
  }

  StreamScore() async {
    if (selectedIdProgram != null) {
      scoresCollection.where("id_program", isEqualTo: selectedIdProgram).snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          List<Score> newListScore = [];
          for (var doc in snapshot.docs) {
            Map<String, dynamic> jsonScore = doc.data() as Map<String, dynamic>;
            jsonScore["id"] = doc.id;
            Score newScore = Score.fromJson(jsonScore);
            newListScore.add(newScore);
            if (newScore.id_stage == selectedIdStage && newScore.id_user == selectedIdUser) {
              _scoreController.text = newScore.score.toString();
            }
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

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? user_info = prefs.getStringList('player_auth');

    if(user_info != null){
      if(user_info[1] == 'player'){
        Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/game-screen');
        });
      }
      else {
        final prefs = await SharedPreferences.getInstance();
        final List<String>? user_info = prefs.getStringList('player_auth');
        final List<String>? user_id = prefs.getStringList('player_id');
      

        if (user_info![1] == "porter") {
          var idProgram = user_info[0];
          String userId = user_id![0];

          // Lấy current stage hiện tại của porter
          final snapshot = await usersCollection.doc(userId).get();
          final stageOfPorter = User.fromJson(snapshot.data() as Map<String, dynamic>);

          // Lấy id của stage từ stageOfPorter
          final snapshotOfPorter = await stagesCollection.where('order_index',isEqualTo:stageOfPorter.currentStage).get();
          final stageId = snapshotOfPorter.docs[0].id;

          setState(() {
            selectedIdProgram = idProgram;
            currentUserRole = user_info[1];
            selectedIdStage = stageId.toString();
          });
        }
        else {
          setState(() {
            currentUserRole = user_info[1];
          });
        }
      }
    }else{
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  ChangeProgram(idProgram) async {
    setState(() {
      selectedIdProgram = idProgram;
      selectedIdStage = null;
      selectedIdUser = null;
      _scoreController.clear();
    });

    await GetStage();
    await StreamUser();
    await StreamScore();
  }

  ChangeStage(idStage) async {
    if (selectedIdUser != null) {
      List<Score> tempListScore = listScores.where((Score score) => score.id_stage == idStage && score.id_user == selectedIdUser).toList();
      if (tempListScore.isEmpty) {
        _scoreController.text = "";
      }
      else {
        _scoreController.text = tempListScore.last.score.toString();
      }
    }

    setState(() {
      selectedIdStage = idStage;
    });
  }

  ChangeUser(idUser) async {
    if (selectedIdStage != null) {
      List<Score> tempListScore = listScores.where((Score score) => score.id_user == idUser && score.id_stage == selectedIdStage).toList();
      if (tempListScore.isEmpty) {
        _scoreController.text = "";
      }
      else {
        _scoreController.text = tempListScore.last.score.toString();
      }
    }

    setState(() {
      selectedIdUser = idUser;
    });
  }

  handleSetScore() async {
    if (selectedIdUser != null && selectedIdStage != null && _scoreController.text.isNotEmpty) {
      List<Score> tempListScore = listScores.where((Score score) => score.id_user == selectedIdUser && score.id_stage == selectedIdStage).toList();
      // if score is exist then update score
      if (tempListScore.isNotEmpty) {
        Score score = tempListScore.last;
        await scoresCollection.doc(score.id).update({"score": int.parse(_scoreController.text)});
      }
      // if score is not exist then insert new score
      else {
        Score score = Score(int.parse(_scoreController.text),'','','','');
        score.id_program = selectedIdProgram.toString();
        score.id_stage = selectedIdStage.toString();
        score.id_user = selectedIdUser.toString();

        String newScoreId = FirebaseFirestore.instance.collection("scores").doc().id;
        await scoresCollection.doc(newScoreId).set(score.toJson());
      }
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text("Điểm số đã được cập nhật")
          )
        );
      }
    }
    else {      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text("Vui lòng chọn chặng, người chơi và nhập điểm số")
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child:Column(
            children: [
              Container(
                height:80,
                decoration:const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0BAB64),
                      Color(0xFF63D471),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text('Chấm điểm người chơi',style:TextStyle(color: Colors.white,fontSize:23,fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height:24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal:0),
                decoration:BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child:Column(
                  children: [
                    const Text('Chọn chương trình, màn chơi và',style:TextStyle(fontSize:18,color:Color.fromARGB(255, 105, 99, 99),fontWeight:FontWeight.w600)),
                    const Text('tên người chơi rồi nhập điểm vào',style:TextStyle(fontSize:18,color:Color.fromARGB(255, 105, 99, 99),fontWeight:FontWeight.w600)),
                    Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649825627/quote_fk6ieg.png',height:40)
                  ],
                )
              ),
              const SizedBox(height:24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal:20.0),
                child: Column(
                  children:[
                  if (currentUserRole == "admin")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal:10,vertical:10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:Border.all(
                          width:1,
                          color:Colors.grey,
                        ),
                        color: Colors.white,  
                      ),
                      child: DropdownButton<String>(
                        isDense:true,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(10),
                        focusColor: Colors.white,
                        hint: const Text('Chọn chương trình'),
                        value: selectedIdProgram,
                        isExpanded: true,
                        items: [
                          ...listPrograms.map((Program program) {
                            return DropdownMenuItem(
                              value: program.id,
                              child: Text(program.name)
                            );
                          })
                        ],
                        onChanged: (newIdProgram) => ChangeProgram(newIdProgram),
                      ),
                    ),
                    if (currentUserRole == "admin")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal:10,vertical:10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:Border.all(
                          width:1,
                          color:Colors.grey,
                        ),
                        color: Colors.white,  
                      ),
                      child: DropdownButton<String>(
                        isDense:true,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(10),
                        focusColor: Colors.white,
                        hint: const Text('Chọn chặng của chương trình'),
                        value: selectedIdStage,
                        isExpanded: true,
                        items: [
                          ...listStages.map((Stage stage) {
                            return DropdownMenuItem(
                              value: stage.id,
                              child: Text(stage.name)
                            );
                          })
                        ],
                        onChanged: (newIdStage) => ChangeStage(newIdStage),
                      ),
                    ),
                    const SizedBox(height:24),
                    Container(
                      padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:Border.all(
                          width:1,
                          color:Colors.grey,
                        ),
                        color: Colors.white,  
                      ),
                      child: DropdownButton<String>(
                        isDense:true,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(10),
                        focusColor: Colors.white,
                        hint: const Text('Chọn người chơi'),
                        value: selectedIdUser,
                        isExpanded: true,
                        items: [
                          ...listUsers.map((User user) {
                            return DropdownMenuItem(
                              value: user.id,
                              child: Text(user.name)
                            );
                          })
                        ],
                        onChanged: (newIdUser) => ChangeUser(newIdUser)
                      ),
                    ),
                    const SizedBox(height:24),
                    TextField(
                      controller: _scoreController,
                      inputFormatters:<TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense:true,
                        fillColor: Colors.white,
                        border : OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                          borderSide:const BorderSide(
                            color: Colors.green,
                            width: 1,
                          )
                        ),
                        labelText: "Điểm số",
                      )
                    ),
                  ]
                ),
              ),
              const SizedBox(height:24),
              Container(
                width: MediaQuery.of(context).size.width*1,
                padding:const EdgeInsets.symmetric(horizontal:20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    primary: isLoading ? const Color.fromARGB(255, 44, 103, 46) : Colors.green,
                  ),
                  onPressed: () => handleSetScore(),
                  child: isLoading 
                    ? const Text('Đang cập nhật...', style: TextStyle(color:Colors.white,fontWeight: FontWeight.w600,fontSize:16,))
                    : const Text('Cập nhật điểm số', style: TextStyle(color:Colors.white,fontWeight: FontWeight.w600,fontSize:16,)),
                ),
              ),
              
              const SizedBox(height:24),
              Container(
                width: MediaQuery.of(context).size.width*1,
                padding:const EdgeInsets.symmetric(horizontal:20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    primary: Colors.black,
                  ),
                  onPressed: (){
                    Navigator.of(context).pushReplacementNamed('/admin-home');
                  },
                  child: const Text('Trở về màn hình chính',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600)),
                ),
              ),
            ],
          )
        ),
      )
    );
  }
}

