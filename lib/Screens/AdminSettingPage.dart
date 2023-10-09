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

class AdminSettingPage extends StatefulWidget {
  const AdminSettingPage({Key? key}) : super(key: key);

  @override
  State<AdminSettingPage> createState() => _AdminSettingPageState();
}

class _AdminSettingPageState extends State<AdminSettingPage> {
  @override
  void initState() {
    fetchData();
    super.initState();
  }

  String? programeName;
  String destinationUrl = "";
  String description = "";
  List programStage = [];
  List programList = [];
  List programNameList = [];
  List programIdList = [];
  List isAllowList = [];
  String programId = '';

  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference scoresCollection =
      FirebaseFirestore.instance.collection('scores');
  CollectionReference programsCollection =
      FirebaseFirestore.instance.collection('programs');
  CollectionReference stageCollection =
      FirebaseFirestore.instance.collection('stages');

  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();
  bool isSettingProgram = false;
  bool isAllow = true;

  resetGame() async {
    // xoa score
    final snapshotScore = await scoresCollection.get();
    final scoreList = snapshotScore.docs.map((doc) => doc.id).toList();
    for (String sc in scoreList) {
      FirebaseFirestore.instance.collection('scores').doc(sc).delete();
    }
    // xoa user
    final snapshotUser = await usersCollection.get();
    // final usersList = snapshotUser.docs.map((doc) => doc.id).toList();
    for (var doc in snapshotUser.docs) {
      if (doc['role'] != 'admin') {
        FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
      }
    }

    // xoa stage
    final snapshotStage = await stageCollection.get();
    final stageList = snapshotStage.docs.map((doc) => doc.id).toList();
    for (String s in stageList) {
      FirebaseFirestore.instance.collection('stages').doc(s).delete();
    }

    // xoa program
    final snapshotProgram = await programsCollection.get();
    final programList = snapshotProgram.docs.map((doc) => doc.id).toList();
    for (String p in programList) {
      FirebaseFirestore.instance.collection('programs').doc(p).delete();
    }

    setState(() {
      showDialog(
          context: context,
          builder: (context) => const ShowNotifyAlert(
              type: 'Thành công',
              errorText: 'Làm mới lại dữ liệu thành công!'));
    });
  }

  fetchData() async {
    final snapshot = await programsCollection.get();
    final allData = snapshot.docs
        .map((doc) => Program.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    final allProgramIds = snapshot.docs.map((doc) => doc.id).toList();
    final allProgramName = snapshot.docs.map((doc) => doc['name']).toList();
    final allIsAllow =
        snapshot.docs.map((doc) => doc['isAllowManyDevice']).toList();

    setState(() {
      programNameList = allProgramName;
      programList = allData;
      programIdList = allProgramIds;
      isAllowList = allIsAllow;
      // isAllow = currentIsAllow[0];
    });
  }

  fetchProgram() async {
    final index = programNameList.indexOf(programeName);
    final currentProgramId = programIdList[index];
    final currentIsAllow = isAllowList[index];
    print("ID: $currentProgramId; $currentIsAllow");

    setState(() {
      programId = currentProgramId;
      isAllow = currentIsAllow;
    });
  }

  saveSettingProgram() async {
    // print("ISALLOW: $isAllow");
    final index = programNameList.indexOf(programeName);
    final currentProgramId = programIdList[index];

    final docPrograms = FirebaseFirestore.instance
        .collection('programs')
        .doc(currentProgramId)
        .update({"isAllowManyDevice": isAllow});

    final snapshot = await programsCollection
        .where('id_program', isEqualTo: currentProgramId)
        .where('role', isEqualTo: "player")
        .get();

    final programPlayer = snapshot.docs
        .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    for (User u in programPlayer) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(u.id)
          .update({"id_device": ""});
    }

    showDialog(
        context: context,
        builder: (context) => const ShowNotifyAlert(
            type: 'Thành công', errorText: 'Cài đặt chương trình thành công!'));

    setState(() {
      isSettingProgram = false;
      programId = "";
    });
    fetchData();
  }

  updateLogo() async {
    CollectionReference pictureCollection =
        FirebaseFirestore.instance.collection('picture');
    final snapshot = await pictureCollection.get();
    final pictureID = snapshot.docs.map((doc) => doc.id).toList();

    FirebaseFirestore.instance
        .collection("picture")
        .doc(pictureID[0])
        .update({"logo": _logoController.text});

    showDialog(
        context: context,
        builder: (context) => const ShowNotifyAlert(
            type: 'Thành công',
            errorText: 'Cập nhật logo trò chơi thành công!'));
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
                    Text('Cài đặt và cấu hình',
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.green,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: () {
                    // Navigator.of(context).pushReplacementNamed('/add-program');
                    setState(() {
                      isSettingProgram = true;
                    });
                  },
                  child: Row(
                    children: [
                      Image.network(
                          'https://res.cloudinary.com/dgmoowcth/image/upload/v1695890445/hai_au_game/icon_setting_program_ob4shv.png',
                          height: 40),
                      const SizedBox(width: 10),
                      const Text('Cài đặt chương trình',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              !isSettingProgram
                  ? const SizedBox(height: 20)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          DropdownButton<String>(
                            isDense: true,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(10),
                            focusColor: Colors.white,
                            hint: const Text('Chọn chương trình'),
                            value: programeName,
                            isExpanded: true,
                            items: <String>[...programNameList]
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                programeName = newValue!;
                              });

                              fetchProgram();
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          programId == ''
                              ? const SizedBox()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Cho phép nhiều thiết bị sử dụng 1 tài khoản',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Checkbox(
                                      value: isAllow,
                                      onChanged: (value) {
                                        //print("RESULT: $value");
                                        setState(() {
                                          isAllow = !isAllow;
                                          print("RESULT: $isAllow");
                                        });
                                      },
                                    ),
                                  ],
                                ),
                          programId == ''
                              ? const SizedBox()
                              : const SizedBox(
                                  height: 20,
                                ),
                          programId == ''
                              ? const SizedBox()
                              : ElevatedButton(
                                  onPressed: () {
                                    saveSettingProgram();
                                  },
                                  child: const Text("Lưu cài đặt")),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text(
                          'Cập nhật đường dẫn logo trò chơi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // color: Colors.red,
                            fontSize: 20,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              TextField(
                                controller: _logoController,
                                decoration: const InputDecoration(
                                  label: Text('Nhập đường dẫn logo mới.'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            child: const Text('Đóng'),
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            child: const Text('Cập nhật'),
                            onPressed: () {
                              if (_logoController.text.isEmpty ||
                                  _logoController.text == "") {
                              } else {
                                updateLogo();
                              }
                              Navigator.pop(context, 'Cancel');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Image.network(
                          'https://res.cloudinary.com/dgmoowcth/image/upload/v1695890553/hai_au_game/icon_setting_logo_ayd9oa.png',
                          height: 40),
                      const SizedBox(width: 10),
                      const Text('Cập nhật logo trò chơi',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: () {
                    // Navigator.of(context).pushReplacementNamed('/evaluation');
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text(
                          'Xác nhận làm mới dữ liệu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // color: Colors.red,
                            fontSize: 20,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              const Text(
                                'Dữ liệu chương trình, chặng chơi, người chơi sẽ bị xóa sau khi làm mới.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.red,
                                ),
                              ),
                              TextField(
                                controller: _confirmController,
                                decoration: const InputDecoration(
                                  label: Text(
                                      'Nhập "reset" để làm mới lại dữ liệu.'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            child: const Text('Đóng'),
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final confirm = _confirmController.text;
                              if (confirm == "reset") {
                                resetGame();
                                Navigator.pop(context, 'Cancel');
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => const ShowNotifyAlert(
                                      type: 'Không thành công',
                                      errorText:
                                          'Làm mới dữ liệu không thành công!'),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            child: const Text('Khởi động lại'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Image.network(
                          'https://res.cloudinary.com/dgmoowcth/image/upload/v1695890713/hai_au_game/icon_restart_ovtibg.png',
                          height: 40),
                      const SizedBox(width: 10),
                      const Text('Khởi động lại trò chơi',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
