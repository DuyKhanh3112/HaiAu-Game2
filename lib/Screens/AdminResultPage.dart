import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:haiau_game2/Screens/ViewImagePage.dart';
import 'package:haiau_game2/widgets/allTotalScore.dart';
import 'package:haiau_game2/widgets/filteredScore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haiau_game2/widgets/showNotifyAlert.dart';
import 'package:confirm_dialog/confirm_dialog.dart';

class AdminResultPage extends StatefulWidget {
  const AdminResultPage({Key? key}) : super(key: key);

  @override
  State<AdminResultPage> createState() => _AdminResultPageState();
}

class _AdminResultPageState extends State<AdminResultPage> {
  CollectionReference scoresCollection =
      FirebaseFirestore.instance.collection('scores');
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference programCollection =
      FirebaseFirestore.instance.collection('programs');
  CollectionReference stageCollection =
      FirebaseFirestore.instance.collection('stages');

  bool isViewingTotalScore = true;

  List<Program> listPrograms = [];
  List<User> listUsers = [];
  List<Score> listScores = [];
  List<Stage> listStages = [];

  String? selectedIdProgram;
  String? selectedIdUser;

  @override
  void initState() {
    Initial();
    super.initState();
  }

  Initial() async {
    await checkForAuth();
    await fetchProgram();
  }

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');

    if (userInfo != null) {
      if (userInfo[1] == 'player') {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/game-screen');
        });
      } else if (userInfo[1] == 'porter') {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/evaluation');
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  fetchProgram() async {
    List<Program> newListProgram = [];

    var snapshotProgram = await programCollection.get();
    for (var doc in snapshotProgram.docs) {
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

  fetchStage() async {
    List<Stage> newListStage = [];

    var snapshotStage = await stageCollection
        .where("id_program", isEqualTo: selectedIdProgram)
        .get();
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

  ChangeProgram(idProgram) async {
    setState(() {
      selectedIdProgram = idProgram;
      selectedIdUser = null;
      isSuccess = false;
    });

    await fetchStage();
    await StreamUser();
    await StreamScore();
  }

  ChangeUser(idUser) {
    setState(() {
      selectedIdUser = idUser;
    });
  }

  StreamUser() async {
    // Get all player of program
    if (selectedIdProgram != null) {
      usersCollection
          .where("id_program", isEqualTo: selectedIdProgram)
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
    if (selectedIdProgram != null) {
      scoresCollection
          .where("id_program", isEqualTo: selectedIdProgram)
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
          if (mounted) {
            setState(() {
              listScores = newListScore;
            });
          }
        }
      });
    }
  }

  bool isSuccess = false;
  TotalScoreWidget() {
    List<Map<String, dynamic>> listUserTotalScore = [];
    for (var user in listUsers) {
      // Calculate total score of the user
      int totalScore = 0;
      List<Score> listUserScore =
          listScores.where((Score score) => score.id_user == user.id).toList();
      if (listUserScore.isNotEmpty) {
        for (var score in listUserScore) {
          totalScore = totalScore + score.score;
        }
        listUserTotalScore.add({"name": user.name, "totalScore": totalScore});
      } else {
        totalScore = 0;
        listUserTotalScore.add({"name": user.name, "totalScore": 0});
      }
    }
    listUserTotalScore
        .sort((a, b) => b["totalScore"].compareTo(a["totalScore"]));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        children: isSuccess
            ? []
            : [
                const SizedBox(height: 5),
                ...listUserTotalScore.asMap().entries.map(
                  (entry) {
                    int index = entry.key;
                    var data = entry.value;
                    return Container(
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? const Color(0xFFF2F2F2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      child: Row(
                        children: [
                          index + 1 == 1
                              ? Image.network(
                                  'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/rtdyrotylzjzr3c00h0t.png',
                                  height: 30)
                              : index + 1 == 2
                                  ? Image.network(
                                      'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/mgbxzflmkttbtakcl8eo.png',
                                      height: 30)
                                  : index + 1 == 3
                                      ? Image.network(
                                          'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/x0gyryatf0chcyzcxxgb.png',
                                          height: 30)
                                      : SizedBox(
                                          width: 30,
                                          child: Center(
                                              child: Text(
                                                  (index + 1).toString(),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.black
                                                          .withOpacity(0.8),
                                                      fontSize: 25)))),
                          const SizedBox(width: 10),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data["name"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 18)),
                                Row(
                                  children: [
                                    const Text('Tổng số điểm:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                            fontSize: 16)),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(data["totalScore"].toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                            fontSize: 16)),
                                  ],
                                ),
                              ])
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                  ),
                  onPressed: () async {
                    if (await confirm(context,
                        title: const Text(
                            "Bạn có muốn khởi động lại chương trình"),
                        content: const Text(
                            "Thông tin người chơi và điểm số sẽ được làm mới sau khi khởi động lại chương trình"))) {
                      resetProgram();
                      return print('pressedOK');
                    }
                    return print('pressedCancel');
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restart_alt, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Khởi động lại chương trình',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black))
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                  ),
                  onPressed: () async {
                    if (await confirm(context,
                        title: const Text("Bạn có muốn xóa chương trình"),
                        content: const Text(
                            "Thông tin chương trình, chặng chơi, người chơi và điểm số sẽ bị xóa sau khi xóa chương trình"))) {
                      deleteProgram();
                      return print('pressedOK');
                    }
                    return print('pressedCancel');
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Xóa Chương Trình',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black))
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  resetProgram() async {
    //score
    final snapshotScore = await scoresCollection
        .where('id_program', isEqualTo: selectedIdProgram)
        .get();
    final scoreList = snapshotScore.docs.map((doc) => doc.id).toList();

    //user
    final snapshotUser = await usersCollection
        .where('id_program', isEqualTo: selectedIdProgram)
        .get();
    final usersList = snapshotUser.docs.map((doc) => doc.id).toList();

    //xoa core
    for (String sc in scoreList) {
      FirebaseFirestore.instance.collection('scores').doc(sc).delete();
    }
    //reset user
    for (String u in usersList) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(u)
          .update({'currentStage': 0, 'startAt': ''});
    }

    setState(() {
      showDialog(
          context: context,
          builder: (context) => const ShowNotifyAlert(
              type: 'Thành công',
              errorText: 'Khởi động lại chương trình thành công!'));

      // selectedIdProgram = null;
      // selectedIdUser = null;
      // listPrograms = List.empty();

      // listUsers = List.empty();
      // listScores = List.empty();
      // listUsers = List.empty();

      // fetchProgram();
      // StreamUser();
      // StreamScore();
      // // isViewingTotalScore = false;
      // isSuccess = true;
    });
  }

  deleteProgram() async {
    CollectionReference programsCollection =
        FirebaseFirestore.instance.collection('programs');
    CollectionReference stagesCollection =
        FirebaseFirestore.instance.collection('stages');
    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    CollectionReference scoreCollection =
        FirebaseFirestore.instance.collection('scores');

// xoa stage
    final snapshotStage = await stagesCollection
        .where('id_program', isEqualTo: selectedIdProgram)
        .get();
    final stageList = snapshotStage.docs.map((doc) => doc.id).toList();

    // xoa score
    final snapshotScore = await scoresCollection
        .where('id_program', isEqualTo: selectedIdProgram)
        .get();
    final scoreList = snapshotScore.docs.map((doc) => doc.id).toList();

    //xoa user
    final snapshotUser = await usersCollection
        .where('id_program', isEqualTo: selectedIdProgram)
        .get();
    final usersList = snapshotUser.docs.map((doc) => doc.id).toList();

//xoa stage
    for (String s in stageList) {
      FirebaseFirestore.instance.collection('stages').doc(s).delete();
    }
    //xoa core
    for (String sc in scoreList) {
      FirebaseFirestore.instance.collection('scores').doc(sc).delete();
    }
    //xoa user
    for (String u in usersList) {
      FirebaseFirestore.instance.collection('users').doc(u).delete();
    }
    //xoa program
    FirebaseFirestore.instance
        .collection('programs')
        .doc(selectedIdProgram)
        .delete();

    setState(() {
      showDialog(
          context: context,
          builder: (context) => const ShowNotifyAlert(
              type: 'Thành công',
              errorText: 'Đã xóa chương trình thành công!'));

      selectedIdProgram = null;
      selectedIdUser = null;
      listPrograms = List.empty();

      listUsers = List.empty();
      listScores = List.empty();
      listUsers = List.empty();

      fetchProgram();
      StreamUser();
      StreamScore();
      // isViewingTotalScore = false;
      isSuccess = true;
    });
  }

  FillteredScoreWidget() {
    List<Map<String, dynamic>> ListUserDetailScore = [];
    for (Stage stage in listStages) {
      //List<Score> listUserScore = listScores.where((Score score) => score.id_user == selectedIdUser && score.id_stage == stage.id).toList();
      var indexCurrentScore = listScores.indexWhere((Score score) =>
          score.id_user == selectedIdUser && score.id_stage == stage.id);
      if (indexCurrentScore != -1) {
        ListUserDetailScore.add({
          "stage": stage.name,
          "score": listScores[indexCurrentScore].score,
          "check-in": listScores[indexCurrentScore].check_in
        });
      } else {
        ListUserDetailScore.add(
            {"stage": stage.name, "score": 0, "check-in": ""});
      }
    }
    ListUserDetailScore.sort((a, b) => a["stage"].compareTo(b["stage"]));

    return Container(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(children: [
              const Text('Nhấn vào chặng có ảnh check-in để xem chi tiết',
                  style: TextStyle(fontSize: 16, color: Colors.black)),
              const SizedBox(height: 20),
              ...ListUserDetailScore.map((data) => InkWell(
                    onTap: () {
                      if (data['check-in'] != "") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ViewImagePage(
                                    imageUrl: data['check-in'],
                                  )),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.23),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(
                                1, 1), // changes position of shadow
                          ),
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.23),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(
                                -1, -1), // changes position of shadow
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(children: [
                        Image.network(
                          data["check-in"] == "" || data["check-in"] == null
                              ? 'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659098707/wznudxkak8yxhmw0frm2.png'
                              : data["check-in"],
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['stage'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  overflow: TextOverflow.ellipsis,
                                )),
                            const SizedBox(height: 5),
                            Text("Số điểm: ${data['score']}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  overflow: TextOverflow.ellipsis,
                                ))
                          ],
                        )
                      ]),
                    ),
                  ))
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Xem và tìm kiếm',
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.green,
                            fontWeight: FontWeight.w900)),
                    Text('thông tin, điểm số',
                        style: TextStyle(
                            fontSize: 23,
                            color: Color(0xFF1A4D2E),
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              // Tab Buttons
              Container(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Để xem tổng điểm, chọn "Tổng điểm."',
                      style: TextStyle(
                          overflow: TextOverflow.ellipsis, fontSize: 14),
                    ),
                    Text('Chọn "Bộ Lọc" nếu kèm theo điều kiện',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    value: selectedIdProgram,
                    isExpanded: true,
                    items: [
                      ...listPrograms.map((Program program) {
                        return DropdownMenuItem(
                            value: program.id, child: Text(program.name));
                      })
                    ],
                    onChanged: (newIdProgram) => ChangeProgram(newIdProgram),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isViewingTotalScore
                            ? const Color.fromARGB(255, 44, 103, 46)
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                      ),
                      onPressed: () {
                        setState(() {
                          isViewingTotalScore = true;
                          selectedIdUser = null;
                        });
                      },
                      child: Row(
                        children: [
                          Image.network(
                              'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1644040211/research_ixkp6b.png',
                              height: 25),
                          const SizedBox(width: 10),
                          const Text('Tổng điểm',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600))
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isViewingTotalScore
                            ? const Color.fromARGB(255, 44, 103, 46)
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                      ),
                      onPressed: () {
                        setState(() {
                          isViewingTotalScore = false;
                        });
                      },
                      child: Row(
                        children: [
                          Image.network(
                              'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1647156696/browsing_yizhbs.png',
                              height: 25),
                          const SizedBox(width: 10),
                          const Text('Bộ lọc',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              isViewingTotalScore && listUsers.isNotEmpty
                  ? TotalScoreWidget()
                  : !isViewingTotalScore && listUsers.isNotEmpty
                      ? Container(
                          child: Column(
                            children: [
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButton(
                                        isDense: true,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        borderRadius: BorderRadius.circular(10),
                                        focusColor: Colors.white,
                                        hint: const Text('Chọn người chơi'),
                                        value: selectedIdUser,
                                        items: [
                                          ...listUsers.map((User user) {
                                            return DropdownMenuItem(
                                                value: user.id,
                                                child: Text(user.name));
                                          })
                                        ],
                                        onChanged: (newId) =>
                                            ChangeUser(newId)),
                                  )),
                              if (selectedIdUser != null) FillteredScoreWidget()
                            ],
                          ),
                        )
                      : const SizedBox()
            ],
          ),
        ),
      ),
    );
  }
}
