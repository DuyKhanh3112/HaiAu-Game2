import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:haiau_game2/widgets/allTotalScore.dart';
import 'package:haiau_game2/widgets/filteredScore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAccountViewPage extends StatefulWidget {
  AdminAccountViewPage({Key? key}) : super(key: key);

  @override
  State<AdminAccountViewPage> createState() => _AdminAccountViewPageState();
}

class _AdminAccountViewPageState extends State<AdminAccountViewPage> {
  CollectionReference scoresCollection =
      FirebaseFirestore.instance.collection('scores');
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference programsCollection =
      FirebaseFirestore.instance.collection('programs');
  CollectionReference stagesCollection =
      FirebaseFirestore.instance.collection('stages');

  bool isLoading = false;
  bool isFetchingData = false;

  List allScores = [];
  List scoresId = [];
  List allUsers = [];
  List programNameList = [];
  List programIdList = [];

  List playerList = [];
  List playerNameList = [];
  List playerIdList = [];

  String? programId;
  String? programName;

  @override
  void initState() {
    super.initState();
    checkForAuth();
    fetchProgram();
  }

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? user_info = prefs.getStringList('player_auth');

    if (user_info != null) {
      if (user_info[1] == 'player') {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      } else if (user_info[1] == 'porter'){
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  fetchUserForProgram() async {
    setState(() {
      isFetchingData = true;
    });
    final index = programNameList.indexOf(programName);
    final currentProgramId = programIdList[index];
    final snapshot = await usersCollection
        .where('id_program', isEqualTo: currentProgramId)
        .get();
    final allPlayerIds = snapshot.docs.map((doc) => doc.id).toList();
    final allPlayerList = snapshot.docs
        .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    final allPlayerNameList = snapshot.docs.map((doc) => doc['name']).toList();
    
    final porterList = [...allPlayerList].where((e) => e.role == 'porter');
    final playerRoleList = [...allPlayerList].where((e) => e.role == 'player'); 
    
    setState(() {
      playerNameList = allPlayerNameList;
      playerList = [...porterList,...playerRoleList];
      playerIdList = allPlayerIds;
      isLoading = false;
      programId = currentProgramId;
      isFetchingData = false;
    });
  }

  fetchProgram() async {
    final snapshot = await programsCollection.get();
    final allProgramIds = snapshot.docs.map((doc) => doc.id).toList();
    final allProgramName = snapshot.docs.map((doc) => doc['name']).toList();

    setState(() {
      programNameList = allProgramName;
      programIdList = allProgramIds;
      isLoading = false;
    });
  }

  Future<String> checkForStageName(user)async{
    final snapshot = await stagesCollection.where('id_program', isEqualTo:programId).where('order_index',isEqualTo:user.currentStage).get();
    final stage = snapshot.docs
        .map((doc) => Stage.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    if(stage.isNotEmpty){
      return stage[0].name.toString();
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/admin-home');
            },
            icon: const Icon(Icons.keyboard_return, size: 30),
          )
        ]),
      ),
      // Title
      Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Text('Xem và tìm kiếm',
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.green,
                    fontWeight: FontWeight.w900)),
            Text('tài khoản người dùng',
                style: TextStyle(
                    fontSize: 23,
                    color: Color(0xFF1A4D2E),
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      const SizedBox(height: 0),
      
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: 1,
              color: Colors.grey,
            ),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            isDense: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(10),
            focusColor: Colors.white,
            hint: const Text('Chọn chương trình'),
            value: programName,
            isExpanded: true,
            items: <String>[...programNameList].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                programName = newValue!;
                allScores = [];
                scoresId = [];
                allUsers = [];
              });
              fetchUserForProgram();
            },
          ),
        ),
      ),
      

  !isFetchingData && !isLoading && programName != null && playerList.isEmpty
      ? SizedBox(
          child: Column(children: [
            const SizedBox(height: 30),
            Image.network(
              'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1644332818/aa4_zfk64k.png',
              height: 100,
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Chưa có điểm số nào được nhập',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.red)),
            )
          ]),
        )
      :
      !isFetchingData && !isLoading && programName != null && playerList.isNotEmpty
      ?
      Padding(
        padding: const EdgeInsets.symmetric(vertical:10,horizontal:20),
        child: Column(
          children: [
            ...playerList.map((e) => Container(
              decoration: BoxDecoration(
                color:Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.23),
                    spreadRadius:1,
                    blurRadius:1,
                    offset: const Offset(1,1), // changes position of shadow
                  ),
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.23),
                    spreadRadius:1,
                    blurRadius:1,
                    offset: const Offset(-1,-1), // changes position of shadow
                  ),
                ],
              ),
              margin:const EdgeInsets.symmetric(vertical:5),
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
              child: Row(
                children: [
                  Image.network(
                    e.role =='player'
                    ?
                    'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659596577/wlczan5h7mhx4t0dbjfp.png'
                    :
                    'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659596570/djz4bz5p8ppjnzghhrcy.png'
                    ,height:35),
                  const SizedBox(width:10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.username,overflow: TextOverflow.ellipsis,style:const TextStyle(color: Colors.black,fontSize:17,fontWeight: FontWeight.w700,overflow:TextOverflow.ellipsis,)),
                        const SizedBox(height:5),
                        Text("Mật khẩu: ${e.password}",style:const TextStyle(color: Colors.green,fontSize:15,fontWeight: FontWeight.w700,overflow:TextOverflow.ellipsis,)),
                        if (e.role == 'porter')
                        const SizedBox(height: 5),
                        if(e.role == 'porter')
                        FutureBuilder<String>(
                          future:checkForStageName(e),
                          builder: ((BuildContext context,AsyncSnapshot<String> snapshot) {
                            if(snapshot.hasError){
                              return const Text("Chặng: Lỗi xảy ra...",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                )
                              );
                            }else if(snapshot.hasData){
                                return Text("Chặng: ${snapshot.data}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  )
                                );
                              }else{
                                return const Text("Chặng: Đang tải...",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  )
                                );
                              }
                            }
                          ),
                        )
                      ],
                    ),
                  )
                ]
              ),
            ))
          ]
        ),
      )
      : programName != null && isFetchingData
          ? SizedBox(
              child: Column(children: const [
                SizedBox(height: 30),
                Center(
                  child: Text('Đang tải dữ liệu...',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.black)),
                )
              ]),
            )
      : const SizedBox()
    ]))));
  }
}
