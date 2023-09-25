import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'dart:math';
import 'package:haiau_game2/widgets/showNotifyAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateProgramPage extends StatefulWidget {
  CreateProgramPage({Key? key}) : super(key: key);

  @override
  State<CreateProgramPage> createState() => _CreateProgramPageState();
}

class _CreateProgramPageState extends State<CreateProgramPage> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _mapNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  CollectionReference programsCollection = FirebaseFirestore.instance.collection('programs');
  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkForAuth();
  }

  @override
  void dispose() {
    super.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    _mapNameController.dispose();
    _passwordController.dispose();
  }

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? user_info = prefs.getStringList('player_auth');

    if (user_info != null) {
      if (user_info[1] == 'player') {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      } else if (user_info[1] == 'porter') {
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

  handleCreateProgram() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    if (_durationController.text.isEmpty ||
        _mapNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _quantityController.text.isEmpty) {
      return showDialog(
          context: context,
          builder: (context) => const ShowNotifyAlert(
              type: 'Lỗi', errorText: 'Vui lòng nhập đầy đủ thông tin'));
    } else if (int.parse(_durationController.text) == 0 ||
        int.parse(_quantityController.text) == 0) {
      return showDialog(
          context: context,
          builder: (context) => const ShowNotifyAlert(
              type: 'Lỗi', errorText: 'Giá trị nhập phải lớn hơn 0'));
    }

    setState(() {
      isLoading = true;
    });


    // create program
    Program newProgram = Program(_mapNameController.text, _durationController.text, _passwordController.text);
    String newProgramId = programsCollection.doc().id;
    DocumentReference refProgram = programsCollection.doc(newProgramId);
    batch.set(refProgram, newProgram.toJson());

    // create default state bonus
    Stage newStage = Stage(0, "Bonus", "", "", newProgramId, "");
    String newStageId = stagesCollection.doc().id;
    DocumentReference refStage = stagesCollection.doc(newStageId);
    batch.set(refStage, newStage.toJson());

    // create user
    for (var i = 0; i < int.parse(_quantityController.text); i++) {
      String newUserId = usersCollection.doc().id;
      DocumentReference refUser = usersCollection.doc(newUserId);
      User newUser = User(
          "team${i + 1}",
          "team${i + 1}${generateRandomString(5)}",
          random(100000, 999999).toString(),
          "https://res.cloudinary.com/dhrpdnd8m/image/upload/v1657729253/j6lrhf3wtvbnznp220fy.webp",
          "player",
          newProgramId,
          1,
          '',
          "false",
        );
      batch.set(refUser, newUser.toJson());
    }

    await batch.commit();

    _mapNameController.clear();
    _durationController.clear();
    _passwordController.clear();
    _quantityController.clear();

    setState(() {
      isLoading = false;
    });

    showDialog(
        context: context,
        builder: (context) => const ShowNotifyAlert(
            type: 'Thành công',
            errorText: 'Đã tạo chương trình và người chơi thành công'));
  }

  int random(min, max) {
    return min + Random().nextInt(max - min);
  }

  String generateRandomString(int len) {
    var r = Random();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                //Header
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .pushReplacementNamed('/admin-home');
                      },
                      child: const Icon(Icons.keyboard_return, size: 30),
                    )
                  ]),
                ),
                // Title
                Container(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Text('Tạo chương trình',
                          style: TextStyle(
                              fontSize: 30,
                              color: Colors.green,
                              fontWeight: FontWeight.w900)),
                      Text('và số lượng người chơi',
                          style: TextStyle(
                              fontSize: 23,
                              color: Color(0xFF1A4D2E),
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hệ thống tự động tạo số lượng người chơi',
                          style: TextStyle(
                              overflow: TextOverflow.ellipsis, fontSize: 14),
                        ),
                        const Text('dựa vào giá trị đã nhập',
                            style: TextStyle(fontSize: 14)),
                        Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                // Số lượng ng chơi
                                TextField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Colors.green,
                                            width: 1,
                                          )),
                                      labelText: "Số lượng người chơi",
                                    )),
                                const SizedBox(height: 24),
                                // Tên chương trình
                                TextField(
                                    controller: _mapNameController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Colors.green,
                                            width: 1,
                                          )),
                                      labelText: "Tên chương trình",
                                    )),
                                const SizedBox(height: 24),
                                // Thời lượng chương trình
                                TextField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: Colors.green,
                                              width: 1,
                                            )),
                                        labelText: "Thời lượng chương trình",
                                        hintText: 'Đơn vị là phút')),
                                const SizedBox(height: 24),
                                // Mật khẩu chương trình
                                TextField(
                                    controller: _passwordController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Colors.green,
                                            width: 1,
                                          )),
                                      labelText: "Mật khẩu chương trình",
                                    )),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 1,
                                  child: ElevatedButton(
                                      onPressed: handleCreateProgram,
                                      style: ElevatedButton.styleFrom(
                                          primary: isLoading
                                              ? const Color.fromARGB(
                                                  255, 44, 103, 46)
                                              : Colors.green,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 15),
                                          textStyle: const TextStyle(
                                            fontSize: 17,
                                          )),
                                      child: isLoading
                                          ? const Text('Đang tạo ...',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600))
                                          : const Text('Tạo chương trình',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                )
                              ],
                            ))
                      ],
                    ))
              ],
            ),
          ),
        ));
  }
}
