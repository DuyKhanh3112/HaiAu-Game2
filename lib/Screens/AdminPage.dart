import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haiau_game2/widgets/showNotifyAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool isAdmin = true;
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference scoresCollection =
      FirebaseFirestore.instance.collection('scores');
  CollectionReference programCollection =
      FirebaseFirestore.instance.collection('programs');
  CollectionReference stageCollection =
      FirebaseFirestore.instance.collection('stages');

  @override
  void initState() {
    super.initState();
    checkForRole();
    checkForAuth();
  }

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');

    if (userInfo != null) {
      if (userInfo[1] == 'player') {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  checkForRole() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');

    if (userInfo != null) {
      if (userInfo[1] == 'porter') {
        setState(() {
          isAdmin = false;
        });
      } else if (userInfo[1] == 'admin') {
        setState(() {
          isAdmin = true;
        });
      }
    }
  }

  handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userId = prefs.getStringList('player_id');

    if (userId != null) {
      usersCollection.doc(userId[0].toString()).update({"isOnline": "false"});
    }

    await prefs.remove('player_auth');
    await prefs.remove('player_id');

    Future.delayed(const Duration(seconds: 0), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  final TextEditingController _confirmController = TextEditingController();

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
    final snapshotProgram = await programCollection.get();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Container(
            height: MediaQuery.of(context).size.height * 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0BAB64),
                  Color(0xFF63D471),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  alignment: Alignment.centerLeft,
                  width: MediaQuery.of(context).size.width * 1,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('Trang cài đặt',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const Spacer(),
                      InkWell(
                          onTap: handleLogout,
                          child: const Icon(
                            Icons.logout_outlined,
                            color: Colors.white,
                            size: 30,
                          ))
                    ],
                  ),
                ),

                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                    decoration: const BoxDecoration(),
                    child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                            color: const Color(0xFF65C18C),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Image.network(
                              'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1658933234/ihgabxpkuopa6drlbflx.png',
                              height: 90,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 30),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dễ dàng chỉnh sửa,',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600)),
                                  Text('cập nhật dữ liệu',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600))
                                ],
                              ),
                            )
                          ],
                        ))),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                        top: 20, bottom: 0, left: 20, right: 20),
                    margin: const EdgeInsets.only(top: 30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(70),
                      ),
                    ),
                    child: Column(children: [
                      isAdmin
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/add-program');
                                },
                                child: Row(
                                  children: [
                                    Image.network(
                                        'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649987746/signpost_er59go.png',
                                        height: 40),
                                    const SizedBox(width: 10),
                                    const Text('Tạo chương trình',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                      isAdmin
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/add-stage');
                                },
                                child: Row(
                                  children: [
                                    Image.network(
                                        'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649807285/test_awqpim.png',
                                        height: 40),
                                    const SizedBox(width: 10),
                                    const Text('Cài đặt màn chơi',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                      isAdmin
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/admin-result');
                                },
                                child: Row(
                                  children: [
                                    Image.network(
                                        'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1650166951/ma3ihzogdupe6gbkr277.png',
                                        height: 40),
                                    const SizedBox(width: 10),
                                    const Text('Tra cứu thông tin',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                      isAdmin
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/view-account');
                                },
                                child: Row(
                                  children: [
                                    Image.network(
                                        'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649657800/folder_1_a35vck.png',
                                        height: 40),
                                    const SizedBox(width: 10),
                                    const Text('Xem tài khoản người dùng',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/evaluation');
                          },
                          child: Row(
                            children: [
                              Image.network(
                                  'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1650367345/nxurus64oyv5kcbc30vb.png',
                                  height: 40),
                              const SizedBox(width: 10),
                              const Text('Chấm điểm người chơi',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      isAdmin
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/admin-setting');
                                },
                                // showDialog<String>(
                                //   context: context,
                                //   builder: (BuildContext context) =>
                                //       AlertDialog(
                                //     title: const Text(
                                //       'Xác nhận làm mới dữ liệu',
                                //       style: TextStyle(
                                //         fontWeight: FontWeight.bold,
                                //         // color: Colors.red,
                                //         fontSize: 20,
                                //       ),
                                //     ),
                                //     content: SingleChildScrollView(
                                //       child: ListBody(
                                //         children: <Widget>[
                                //           const Text(
                                //             'Dữ liệu chương trình, chặng chơi, người chơi sẽ bị xóa sau khi làm mới.',
                                //             style: TextStyle(
                                //               fontStyle: FontStyle.italic,
                                //               color: Colors.red,
                                //             ),
                                //           ),
                                //           TextField(
                                //             controller: _confirmController,
                                //             decoration: const InputDecoration(
                                //               label: Text(
                                //                   'Nhập "reset" để làm mới lại dữ liệu.'),
                                //             ),
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //     actions: <Widget>[
                                //       TextButton(
                                //         onPressed: () =>
                                //             Navigator.pop(context, 'Cancel'),
                                //         child: const Text('Cancel'),
                                //       ),
                                //       TextButton(
                                //         onPressed: () {
                                //           final confirm =
                                //               _confirmController.text;
                                //           if (confirm == "reset") {
                                //             resetGame();
                                //             Navigator.pop(context, 'Cancel');
                                //           } else {
                                //             showDialog(
                                //               context: context,
                                //               builder: (context) =>
                                //                   const ShowNotifyAlert(
                                //                       type: 'Không thành công',
                                //                       errorText:
                                //                           'Làm mới dữ liệu không thành công!'),
                                //             );
                                //           }
                                //         },
                                //         child: const Text('OK'),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                child: Row(
                                  children: [
                                    Image.network(
                                        'https://res.cloudinary.com/dgmoowcth/image/upload/v1695890331/hai_au_game/icon_setting_khuyvb.png',
                                        height: 40),
                                    // Icon(Icons.settings, size: 40),
                                    const SizedBox(width: 10),
                                    const Text('Cài đặt',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
