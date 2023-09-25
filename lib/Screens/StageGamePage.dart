import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:haiau_game2/Screens/AllTeamResult.dart';
import 'package:haiau_game2/Screens/CurrentPlayerResult.dart';
import 'package:haiau_game2/Screens/StageDescriptionPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

class StageGamePage extends StatefulWidget {
  StageGamePage({Key? key}) : super(key: key);

  @override
  State<StageGamePage> createState() => _StageGamePageState();
}

class _StageGamePageState extends State<StageGamePage> {
  final cloudinary = CloudinaryPublic('dhrpdnd8m', 'v9hyxc50', cache: false);

  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference stagesCollection =
      FirebaseFirestore.instance.collection('stages');
  CollectionReference scoresCollection =
      FirebaseFirestore.instance.collection('scores');
  CollectionReference programsCollection =
      FirebaseFirestore.instance.collection('programs');

  final TextEditingController _passwordController = TextEditingController();

  List currentStage = [];
  bool isVerifying = false;
  String startedTime = '';
  String programDuration = '';
  Map<String, dynamic> userBasicInfo = {};

  Uint8List? imageBytes;
  var imagePath;

  @override
  void initState() {
    super.initState();
    initialFunction();
    WebView.platform = WebWebViewPlatform();
  }

  initialFunction() async {
    await checkForAuth();
    await getStageBasedOnPlayerCurrentStage();
  }

  @override
  void dispose() {
    super.dispose();
    _passwordController.clear();
  }

  checkForAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    final List<String>? userId = prefs.getStringList('player_id');
    final bool? alreadyEnter = prefs.getBool('alreadyEnterProgram');

    if (userInfo != null && userId != null) {
      // kiểm tra tổng số stage của program
      final snapshotStage = await stagesCollection
          .where('id_program', isEqualTo: userInfo[0])
          .get();
      final allRelatedStage = snapshotStage.docs.map((doc) => doc.id).toList();

      // Kiểm tra vị trí stage hiện tại của player
      final snapshot = await usersCollection.doc(userId[0]).get();
      final relatedUser =
          User.fromJson(snapshot.data() as Map<String, dynamic>);

      if (userInfo[1] != 'player') {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      } else if (userInfo[1] == 'player' &&
          (alreadyEnter == null || alreadyEnter == false)) {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
        // Nếu currentStage của player lớn hơn tổng hơn số stage của program thì chuyển về ending
      } else if (relatedUser.currentStage > allRelatedStage.length - 1) {
        Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/ending');
        });
      }

      // Kiểm tra liệu đã quá thời hạn của chương trình khi player đã bắt đầu game

      final snapshotProgram = await programsCollection.doc(userInfo[0]).get();
      final relatedProgram =
          Program.fromJson(snapshotProgram.data() as Map<String, dynamic>);

      DateTime dateTime = DateTime.now();
      final currrentTime = dateTime.toUtc().add(const Duration(hours: 7));

      var timeUserStart;
      if (relatedUser.startAt.isEmpty) {
        timeUserStart = currrentTime;
      } else {
        timeUserStart = DateTime.parse(relatedUser.startAt);
      }

      Duration diff = currrentTime.difference(timeUserStart);
      final diffInSeconds = diff.inSeconds;
      final duration = int.parse(relatedProgram.duration) * 60;

      if (duration - diffInSeconds <= 0) {
        if (mounted) {
          Future.delayed(const Duration(seconds: 0), () {
            Navigator.of(context).pushReplacementNamed('/ending');
          });
        }
      }
    } else {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  getStageBasedOnPlayerCurrentStage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userId = prefs.getStringList('player_id');
    final List<String>? userInfo = prefs.getStringList('player_auth');

    if (userId == null || userInfo == null) {
      return Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/waiting-room');
      });
    }

    // Kiểm tra xem current stage của player còn hợp lệ không
    // Nếu không hợp lệ thì chuyển về ending
    // Nếu hợp lệ thì setState các thông tin của stage hiện tại và program

    final snapshotUser = await usersCollection.doc(userId[0]).get();

    final relatedUser = User.fromJson(snapshotUser.data() as Map<String, dynamic>);

    final snapshotStage = await stagesCollection
        .where('id_program', isEqualTo: userInfo[0])
        .where('order_index', isEqualTo: relatedUser.currentStage)
        .get();
    final allRelatedStage = snapshotStage.docs
        .map((doc) => Stage.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    final snapshotProgram = await programsCollection.doc(userInfo[0]).get();
    final relatedProgram = Program.fromJson(snapshotProgram.data() as Map<String, dynamic>);

    if (allRelatedStage.isEmpty) {
      if (mounted) {
        return Future.delayed(const Duration(seconds: 0), () {
          Navigator.of(context).pushReplacementNamed('/ending');
        });
      }
    }

    if (mounted) {
      setState(() {
        currentStage = allRelatedStage;
        startedTime = relatedUser.startAt;
        programDuration = relatedProgram.duration;
        userBasicInfo = {
          "name":relatedUser.name,
          "avatar":relatedUser.avatar
        };
      });
    }
  }

  handleCheckForNextStage() async {
    if (isVerifying) return;
    String imageURL = '';
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userId = prefs.getStringList('player_id');
    final List<String>? userInfo = prefs.getStringList('player_auth');

    final stagePassword = currentStage[0].password;

    if (_passwordController.text == '' || imagePath == null) {
      return showDialog(
          context: context,
          builder: (context) => AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                contentPadding: const EdgeInsets.all(0),
                content: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF6fd3ea),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF043150),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          height: 100,
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: const Center(
                              child: Text(
                                  'Password and check-in image are needed',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700))),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF043150),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                  top: 10.0, bottom: 10.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF187498),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Close",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
    }

    if (_passwordController.text.toLowerCase() != stagePassword.toLowerCase()) {
      return showDialog(
          context: context,
          builder: (context) => AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                contentPadding: const EdgeInsets.all(0),
                content: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF6fd3ea),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF043150),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          height: 100,
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: const Center(
                              child: Text('Incorrect password',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700))),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF043150),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                  top: 10.0, bottom: 10.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF187498),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Close",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
    }

    setState(() {
      isVerifying = true;
    });

    final snapshotStage = await stagesCollection
        .where('id_program', isEqualTo: userInfo![0])
        .where('name', isEqualTo: currentStage[0].name)
        .get();
    final allRelatedStage = snapshotStage.docs.map((doc) => doc.id).toList();

    final snapshot = await scoresCollection
        .where('id_program', isEqualTo: userInfo[0])
        .where('id_stage', isEqualTo: allRelatedStage[0])
        .where('id_user', isEqualTo: userId![0])
        .get();
    // final allRelatedScores = snapshot.docs.map((doc) => Score.fromJson(doc.data() as Map<String, dynamic>)).toList();
    final relatedScoreId = snapshot.docs.map((doc) => doc.id).toList();

    final snapshotUser = await usersCollection.doc(userId[0]).get();
    final relatedUser =
        User.fromJson(snapshotUser.data() as Map<String, dynamic>);

    final snapshotProgramStages = await stagesCollection
        .where('id_program', isEqualTo: userInfo[0])
        .get();
    final relatedStages =
        snapshotProgramStages.docs.map((doc) => doc.id).toList();

    if (relatedUser.currentStage > relatedStages.length - 1) {
      return Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/ending');
      });
    }

    // if(allRelatedScores.isEmpty){
    //   setState(() {
    //     isVerifying = false;
    //   });
    //   return showDialog(
    //     context: context,
    //     builder: (context) =>  AlertDialog(
    //       shape: const RoundedRectangleBorder(
    //       borderRadius: BorderRadius.all(Radius.circular(10.0))),
    //       contentPadding: const EdgeInsets.all(0),
    //       content: Container(
    //         decoration: BoxDecoration(
    //           borderRadius: BorderRadius.circular(10),
    //           color:const Color(0xFF6fd3ea),
    //         ),
    //         padding:const EdgeInsets.all(3),
    //         child: Container(
    //           decoration: BoxDecoration(
    //             borderRadius: BorderRadius.circular(10),
    //             color:const Color(0xFF043150),
    //           ),
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             crossAxisAlignment: CrossAxisAlignment.stretch,
    //             mainAxisSize: MainAxisSize.min,
    //             children: <Widget>[
    //               Container(
    //                 height:100,
    //                 padding: const EdgeInsets.only(left: 20.0, right: 20.0),
    //                 child:const Center(child:Text('Vui lòng chờ khi điểm được nhập',style:TextStyle(color: Colors.white,fontSize:20,fontWeight: FontWeight.w700))),
    //               ),
    //               Container(
    //                 decoration: BoxDecoration(
    //                   color:const Color(0xFF043150),
    //                   borderRadius: BorderRadius.circular(10),
    //                 ),
    //                 padding: const EdgeInsets.symmetric(horizontal:18,vertical:10),
    //                 child: InkWell(
    //                   onTap:(){
    //                     Navigator.of(context).pop();
    //                   },
    //                   child: Container(
    //                     padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
    //                     decoration: BoxDecoration(
    //                       color: const Color(0xFF187498),
    //                       borderRadius: BorderRadius.circular(10),
    //                     ),
    //                     child: const Text(
    //                       "Đã rõ",
    //                       style: TextStyle(color: Colors.white,fontSize:17,fontWeight: FontWeight.w700),
    //                       textAlign: TextAlign.center,
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     )
    //   );
    // }

    CloudinaryResponse response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(imagePath,
          resourceType: CloudinaryResourceType.Image),
    );

    imageURL = response.secureUrl;
    _passwordController.clear();

    // Nếu score chưa đc nhập thì tạo score rồi cập nhật checkin
    // Còn có thì cập nhật checkin
    if (relatedScoreId.isEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      Score newScore = Score(
        0,
        '',
        userId[0].toString(),
        userInfo[0].toString(),
        allRelatedStage[0].toString(),
      );

      String newScoreId = scoresCollection.doc().id;
      DocumentReference refScore = scoresCollection.doc(newScoreId);
      batch.set(refScore, newScore.toJson());

      await batch.commit();
    } else {
      await scoresCollection
          .doc(relatedScoreId[0].toString())
          .update({'check_in': imageURL});
    }

    final currentUser = await usersCollection.doc(userId[0]).get();
    final currentUserInfo =
        User.fromJson(currentUser.data() as Map<String, dynamic>);

    if (currentUserInfo.currentStage == currentStage[0].order_index) {
      await usersCollection
          .doc(userId[0].toString())
          .update({'currentStage': currentStage[0].order_index + 1});
    }

    setState(() {
      isVerifying = false;
      imagePath = null;
      imageBytes = null;
      currentStage = [];
    });

    // Sau khi đã cập nhật xong thì gọi lại hàm để lấy stage tiếp theo
    await getStageBasedOnPlayerCurrentStage();
  }

  Future handleCaptureImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage == null) return;
    final bytes = await pickedImage.readAsBytes();
    setState(() {
      imageBytes = bytes;
      imagePath = pickedImage.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
            decoration: BoxDecoration(
              color: const Color(0xFF043150).withOpacity(0.6),
            ),
            child: SingleChildScrollView(
                child: currentStage.isEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 1,
                        child: const Center(
                            child: SpinKitWave(
                          color: Colors.white,
                          size: 50.0,
                        )),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 15),
                          ClockCountDown(
                              timeStart: startedTime,
                              currentProgramDuration: programDuration),
                          const SizedBox(height: 15),
                          if(userBasicInfo['name'] != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal:30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius:34,
                                    backgroundColor:Colors.white,
                                    child: CircleAvatar(
                                      radius:32,
                                      child: CircleAvatar(
                                        radius:30,
                                        backgroundImage: NetworkImage(userBasicInfo['avatar']),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${userBasicInfo['name']}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize:21,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Current stage: ${currentStage[0].order_index}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              (currentStage[0].name).toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Colors.yellow,
                                letterSpacing: 1,
                                shadows: <Shadow>[
                                  Shadow(
                                    offset: Offset(4.0, 4.0),
                                    blurRadius: 10.0,
                                    color: Color(0xFF085076),
                                  ),
                                  Shadow(
                                    offset: Offset(-4.0, -4.0),
                                    blurRadius: 10.0,
                                    color: Color(0xFF085076),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              height: 250,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                  width: 3,
                                  color: Colors.white,
                                )),
                                padding: const EdgeInsets.all(5),
                                child: imageBytes != null
                                    ? Stack(children: [
                                        Image.memory(imageBytes!,
                                            height: 250,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                1,
                                            fit: BoxFit.cover),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                1,
                                            height: 250,
                                            child: Column(
                                              children: [
                                                const Spacer(),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          primary: const Color(
                                                              0xFF187498),
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      50,
                                                                  vertical:
                                                                      13)),
                                                      onPressed: () {
                                                        setState(() {
                                                          imageBytes = null;
                                                          imagePath = null;
                                                        });
                                                      },
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ))
                                      ])
                                    : WebView(
                                        initialUrl: currentStage[0].destination,
                                        key: UniqueKey(),
                                        javascriptMode:
                                            JavascriptMode.unrestricted,
                                        // onWebViewCreated: (WebViewController webViewController) {
                                        //   webViewController.loadUrl(currentStage[0].destination);
                                        // },
                                      ),
                              )),
                          // Camera Icon
                          const SizedBox(height: 10),

                          // Read description
                          ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => StageDescription()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Color.fromARGB(255, 219, 22, 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 17, horizontal: 20),
                              ),
                              child: const Text(
                                "Read description of this stage",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600),
                              )),
                          const SizedBox(height: 10),
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
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700))
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: handleCaptureImage,
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
                                                'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659413758/mipubniiyvumy2tmngaf.png',
                                                height: 32)),
                                      ),
                                    ),
                                    Container(height: 5),
                                    const Text('Camera',
                                        style: TextStyle(
                                            fontSize: 15,
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
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700))
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),
                          // Text input
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: TextField(
                              controller: _passwordController,
                              style: const TextStyle(
                                  color: Color(0xFF00b0ec),
                                  fontSize: 20,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Color(0xFF6fd3ea)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(
                                      width: 3,
                                      color: Color(0xFF6fd3ea)), //<-- SEE HERE
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(
                                      width: 3,
                                      color: Color(0xFF6fd3ea)), //<-- SEE HERE
                                ),
                                hintText: 'Password to next stage',
                                hintStyle: TextStyle(
                                    color: const Color(0xFF00b0ec)
                                        .withOpacity(0.8),
                                    fontSize: 16,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w700),
                                fillColor: const Color(0xFF071a29),
                                filled: true,
                                contentPadding: const EdgeInsets.all(8),
                              ),
                              keyboardType: TextInputType.text,
                              obscureText: false,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    width: 3,
                                    color: const Color(
                                        0xFF02c3ca) //                   <--- border width here
                                    ),
                              ),
                              child: Container(
                                child: InkWell(
                                  onTap: handleCheckForNextStage,
                                  child: Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: ShapeDecoration(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF037520),
                                          Color(0xFF09ad32),
                                          Color(0xFF08e15c),
                                          Color(0xFF0add5a),
                                          Color(0xFF08e15c),
                                          Color(0xFF09ad32),
                                          Color(0xFF037520),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      isVerifying ? 'VERIFYING...' : 'VERIFY',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: Offset(1.0, 1.0),
                                            blurRadius: 1.0,
                                            color:
                                                Color.fromARGB(125, 0, 0, 255),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ))),
      )),
    );
  }
}

class ClockCountDown extends StatefulWidget {
  ClockCountDown(
      {Key? key, required this.timeStart, required this.currentProgramDuration})
      : super(key: key);

  String timeStart;
  String currentProgramDuration;

  @override
  State<ClockCountDown> createState() =>
      _ClockCountDownState(timeStart, currentProgramDuration);
}

class _ClockCountDownState extends State<ClockCountDown> {
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  CollectionReference programsCollection =
      FirebaseFirestore.instance.collection('programs');

  int hours = 0;
  int minutes = 0;
  int seconds = 0;

  late String timeStart;
  String currentProgramDuration;

  int timeLeft = 0;

  _ClockCountDownState(this.timeStart, this.currentProgramDuration);

  @override
  void initState() {
    super.initState();
    getTotalTime();
  }

  getTotalTime() async {
    DateTime dateTime = DateTime.now();
    final currrentTime = dateTime.toUtc().add(const Duration(hours: 7));

    var timeUserStart;
    if (timeStart.isEmpty) {
      timeUserStart = currrentTime;
    } else {
      timeUserStart = DateTime.parse(timeStart);
    }

    Duration diff = currrentTime.difference(timeUserStart);
    final diffInSeconds = diff.inSeconds;
    final duration = int.parse(currentProgramDuration) * 60;

    if (duration - diffInSeconds > 0) {
      if (mounted) {
        setState(() {
          timeLeft = duration - diffInSeconds;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          timeLeft = 0;
        });
      }
      return Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/ending');
      });
    }

    getHours();
    getMinutes();
    getSeconds();

    if (timeLeft > 0) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        getTotalTime();
      });
    }
  }

  getHours() {
    int hourLeft = timeLeft ~/ 3600;
    if (mounted) {
      setState(() {
        hours = hourLeft;
      });
    }
  }

  getMinutes() {
    int minuteLeft = (timeLeft % 3600) ~/ 60;
    if (mounted) {
      setState(() {
        minutes = minuteLeft;
      });
    }
  }

  getSeconds() {
    int secondLeft = timeLeft % 60;
    if (mounted) {
      setState(() {
        seconds = secondLeft;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text('Time left until the event ends',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
              'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659411656/padteq8jvwnvc5xgxl2m.png',
              height: 35),
          const SizedBox(width: 10),
          Row(
            children: [
              Text(hours < 10 ? "0${hours.toString()}" : hours.toString(),
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              const Text(":",
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              Text(minutes < 10 ? "0${minutes.toString()}" : minutes.toString(),
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              const Text(":",
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              Text(seconds < 10 ? "0${seconds.toString()}" : seconds.toString(),
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
            ],
          )
        ],
      )
    ]);
  }
}
