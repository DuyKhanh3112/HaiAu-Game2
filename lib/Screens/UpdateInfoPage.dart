import 'dart:io' as io;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloudinary_public/cloudinary_public.dart';


class UpdateInfoPage extends StatefulWidget {
  UpdateInfoPage({Key? key}) : super(key: key);

  @override
  State<UpdateInfoPage> createState() => _UpdateInfoPageState();
}

class _UpdateInfoPageState extends State<UpdateInfoPage> {
final cloudinary = CloudinaryPublic('dhrpdnd8m', 'v9hyxc50', cache: false);

  String avatar = '';
  String name = '';
  
  bool isLoading = true;
  bool isUpdating = false;

  var imageBytes;
  var imagePath;

  final TextEditingController _nameController = TextEditingController();

  CollectionReference programsCollection = FirebaseFirestore.instance.collection('programs');
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');
  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');


  @override
  void initState() {
    super.initState();
    checkForAuth();
  }

  checkForAuth() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    final List<String>? userId = prefs.getStringList('player_id');
    final bool? alreadyEnter = prefs.getBool('alreadyEnterProgram');

    if(userInfo != null){
      if(userInfo[1] != 'player'){
        setState(() {
          isLoading = false;
        });
        Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      }else{
        final snapshotStage = await stagesCollection.where('id_program',isEqualTo: userInfo[0]).get();
        final allRelatedStage = snapshotStage.docs.map((doc) => doc.id).toList();  
        
        final snapshot = await usersCollection.doc(userId![0]).get();
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

        if(userInfo[1] == 'player' && alreadyEnter != null && duration - diffInSeconds >0 && relatedUser.currentStage <= allRelatedStage.length-1){
          
          setState(() {
            isLoading = false;
          });
          return Future.delayed(const Duration(seconds:0), () {
            Navigator.of(context).pushReplacementNamed('/game-stage');
          });
        }

        setState(() {
          avatar = userInfo[3].toString();
          name = userInfo[2].toString();
          _nameController.text = userInfo[2].toString();
          isLoading = false;
        });
      }
    }else{
      setState(() {
        isLoading = false;
      });
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  Future selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if(pickedImage == null) return;
    final bytes = await pickedImage.readAsBytes();
    setState(() {
      imageBytes = bytes;
      imagePath = pickedImage.path;
    });
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(List.generate(len, (index) => r.nextInt(33) + 89));
  }

  handleUpdateData()async{
    final prefs = await SharedPreferences.getInstance();
    final List<String>? userInfo = prefs.getStringList('player_auth');
    final List<String>? userId = prefs.getStringList('player_id');
    String imageURL = avatar;
    
    if(isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    if(imageBytes != null){
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imagePath, resourceType: CloudinaryResourceType.Image),
      );
    
      imageURL = response.secureUrl;
      
      userInfo![2] = name;
      userInfo[3] = imageURL;
      usersCollection.doc(userId![0].toString()).update({'name':name,'avatar':imageURL});
    }else{
      userInfo![2] = name;
      usersCollection.doc(userId![0].toString()).update({'name':name});
    }
    await prefs.setStringList('player_auth', <String>[...userInfo]);

    setState(() {
      isUpdating = false;
      imageBytes = null;
      imagePath = null;
      avatar = imageURL;
      name = _nameController.text;
    });

    showDialog(
      context: context,
      builder: (context) =>  AlertDialog(
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
                height:100,
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child:const Center(child:Text('Updated successfully',style:TextStyle(color: Colors.white,fontSize:20,fontWeight: FontWeight.w700))),
              ),
              Container(
                decoration: BoxDecoration(
                  color:const Color(0xFF043150),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal:18,vertical:10),
                child: InkWell(
                  onTap:(){
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF187498),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(color: Colors.white,fontSize:17,fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                image: 
                NetworkImage("https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659197878/ojax6iozxypjo3bo5ttu.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF043150).withOpacity(0.5),
              ),
              child: SingleChildScrollView(
                child:Container(
                  padding: const EdgeInsets.symmetric(horizontal:30),
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
                  Column(
                    mainAxisAlignment:MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height:60),
                      const Text(
                        'INFORMATION',
                        style: TextStyle( 
                          fontSize:30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFccebff),
                          letterSpacing:2,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(4.0, 4.0),
                              blurRadius:10.0,
                              color: Color(0xFF085076),
                            ),
                            Shadow(
                              offset: Offset(-4.0, -4.0),
                              blurRadius:10.0,
                              color: Color(0xFF085076),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height:30),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF6fd3ea),
                        radius:60,
                        child: 
                        imageBytes != null
                        ?
                        CircleAvatar(
                          backgroundImage: MemoryImage(imageBytes!),
                          radius:58,
                        )
                        :
                        CircleAvatar(
                          backgroundImage: NetworkImage(avatar),
                          radius:58,
                        ),
                      ),
                      const SizedBox(height:15),
                      InkWell(
                        onTap:selectImage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal:40),
                          child: Container(
                            padding:const EdgeInsets.symmetric(horizontal:10, vertical:10), 
                            decoration: BoxDecoration(
                              color: const Color(0xFF043150).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border:Border.all(
                                width:3,
                                color: const Color(0xFF6fd3ea),
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFFB22727),
                                  Color(0xFFB20600),
                                  Color(0xFFD61C4E),
                                  Color(0xFFB20600),
                                  Color(0xFFB22727),
                                ],
                              ),
                            ),
                            child:const Center(
                              child:Text('Change avatar',style:TextStyle(color: Colors.white,fontSize:20,fontWeight: FontWeight.w700))
                            )
                          ),
                        ),
                      ),
                      const SizedBox(height:10),
                      TextField(
                        onChanged: (value) =>{
                          setState(() {
                            name = value;
                          })
                        },
                        controller: _nameController ,
                        style: const TextStyle(color: Color(0xFF00b0ec),fontSize:20,letterSpacing:2,fontWeight: FontWeight.w800),
                        decoration:  InputDecoration(
                          prefixIcon:  const Icon(Icons.person_sharp,color:Color(0xFF6fd3ea)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(width: 3, color: Color(0xFF6fd3ea)), //<-- SEE HERE
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(width: 3, color: Color(0xFF6fd3ea)), //<-- SEE HERE
                          ),
                          hintText: 'USERNAME',
                          fillColor: const Color(0xFF071a29),
                          filled:true,
                          contentPadding: const EdgeInsets.all(8),
                        ),
                        keyboardType: TextInputType.text,
                        obscureText: false,  
                      ),
                      const SizedBox(height:40),
                      _nameController.text.isNotEmpty
                      ?
                      InkWell(
                        onTap: handleUpdateData,
                        child: Container(
                          padding:const EdgeInsets.symmetric(horizontal:15, vertical:10), 
                          decoration: BoxDecoration(
                            color: const Color(0xFF043150).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border:Border.all(
                              width: 3,
                              color: const Color(0xFF6fd3ea),
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
                          child:Center(
                            child:
                            isUpdating
                            ?
                            const Text('Updating...',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                            :
                            const Text('Update my information',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                          )
                        ),
                      )
                      :
                      InkWell(
                        onTap:(){},
                        child: Container(
                          padding:const EdgeInsets.symmetric(horizontal:15, vertical:10), 
                          decoration: BoxDecoration(
                            color: const Color(0xFF043150).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border:Border.all(
                              width: 3,
                              color: const Color(0xFF6fd3ea),
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF73777B),
                                Color(0xFF7F8487),
                                Color(0xFF9D9D9D),
                                Color(0xFF7F8487),
                                Color(0xFF73777B),
                              ],
                            ),
                          ),
                          child:const Center(
                            child:
                            Text('Update my information',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                          )
                        ),
                      ),
                      
                      const SizedBox(height:7),
                      !isUpdating
                      ?
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
                          child:const Center(
                            child:Text('Back',style:TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700))
                          )
                        ),
                      )
                      :
                      const SizedBox(),
                      const SizedBox(height:10),
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