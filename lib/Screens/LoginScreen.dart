import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/userObject.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String username = '';
  String password = '';

  bool isLoading = false;
  bool isFailed = false;
  bool isSuccessful = false;

  @override
  void initState() {
    super.initState();
    getLogoURL();
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
  }

  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  loginUser() async {
    if (isLoading) return;
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isLoading = true;
    });

    final snapshot = await usersCollection
        .where('username', isEqualTo: _usernameController.text.toString())
        .where('password', isEqualTo: _passwordController.text.toString())
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        isSuccessful = true;
        isFailed = false;
        isLoading = false;
      });

      Map<String, dynamic> data =
          snapshot.docs[0].data() as Map<String, dynamic>;
      data["id"] = snapshot.docs[0].id;
      User user = User.fromJson(data);

      await prefs.setStringList('player_auth', <String>[
        user.id_program.toString(),
        user.role.toString(),
        user.name.toString(),
        user.avatar.toString(),
      ]);

      await prefs.setStringList('player_id', <String>[user.id.toString()]);

      if (user.role != 'player') {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      }
    } else {
      setState(() {
        isFailed = true;
        isSuccessful = false;
        isLoading = false;
      });
    }
  }

  String logoUrl = "";
  getLogoURL() async {
    CollectionReference pictureCollection =
        FirebaseFirestore.instance.collection('picture');
    final snapshotPicture = await pictureCollection.get();
    for (var doc in snapshotPicture.docs) {
      setState(() {
        logoUrl = doc['logo'];
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
                height: MediaQuery.of(context).size.height * 1,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // image: DecorationImage(
                  //   image: NetworkImage(
                  //       "https://res.cloudinary.com/dhrpdnd8m/image/upload/v1661140728/vqn8ddw7ucvgxki6dwjp.jpg"),
                  //   fit: BoxFit.cover,
                  // ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // const SizedBox(height: 20),
                      SizedBox(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.network(
                                logoUrl,
                                // 'https://res.cloudinary.com/dgmoowcth/image/upload/v1695288215/hai_au_game/title-03_rgrpyl.png',
                                height: 300,
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                        ),
                      ),
                      !isSuccessful && isFailed && !isLoading
                          ? Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(left: 20),
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                              0xFF444941), //                   <--- border color
                                          width: 3.0,
                                        ),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFB22727),
                                            Color(0xFFB20600),
                                            Color(0xFFD61C4E),
                                            Color(0xFFB20600),
                                            Color(0xFFB22727),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                          child: Text(
                                        'Access denied !',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800),
                                      ))),
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Color(0xFF444941),
                                    child: CircleAvatar(
                                      backgroundColor: Color(0xFFB22727),
                                      radius: 27,
                                      child: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659279107/a6rn1plpksqwgqf8eq0e.png'),
                                        radius: 27,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : isSuccessful && !isFailed && !isLoading
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Container(
                                          width: double.infinity,
                                          padding:
                                              const EdgeInsets.only(left: 20),
                                          height: 45,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(
                                                  0xFF0AA1DD), //                   <--- border color
                                              width: 3.0,
                                            ),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF1F4690),
                                                Color(0xFF1363DF),
                                                Color(0xFF0078AA),
                                                Color(0xFF1363DF),
                                                Color(0xFF1F4690),
                                              ],
                                            ),
                                          ),
                                          child: const Center(
                                              child: Text(
                                            'Success !',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800),
                                          ))),
                                      const CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Color(0xFF0AA1DD),
                                        child: CircleAvatar(
                                          radius: 27,
                                          backgroundColor: Color(0xFF1F4690),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659281709/fdmiz9etqzdctftpstpr.jpg',
                                                scale: 2),
                                            radius: 27,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : const SizedBox(height: 0),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //text field email
                              TextField(
                                onChanged: (value) => {
                                  setState(() {
                                    username = value;
                                  })
                                },
                                controller: _usernameController,
                                style: const TextStyle(
                                    color: Color(0xFF444941),
                                    fontSize: 20,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person_sharp,
                                      color: Color(0xFF444941)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                        width: 3,
                                        color:
                                            Color(0xFF444941)), //<-- SEE HERE
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                        width: 3,
                                        color:
                                            Color(0xFF444941)), //<-- SEE HERE
                                  ),
                                  hintText: 'USERNAME',
                                  hintStyle: TextStyle(
                                      color: const Color(0xFF444941)
                                          .withOpacity(0.7),
                                      fontSize: 20,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700),
                                  fillColor: const Color(0xFFFFFFFF),
                                  filled: true,
                                  contentPadding: const EdgeInsets.all(8),
                                ),
                                keyboardType: TextInputType.text,
                                obscureText: false,
                              ),
                              const SizedBox(height: 24),
                              //text field password
                              TextField(
                                onChanged: (value) => {
                                  setState(() {
                                    password = value;
                                  })
                                },
                                controller: _passwordController,
                                style: const TextStyle(
                                    color: Color(0xFF444941),
                                    fontSize: 20,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: Color(0xFF444941)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                        width: 3,
                                        color:
                                            Color(0xFF444941)), //<-- SEE HERE
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                        width: 3,
                                        color:
                                            Color(0xFF444941)), //<-- SEE HERE
                                  ),
                                  hintText: 'PASSWORD',
                                  hintStyle: TextStyle(
                                      color: const Color(0xFF444941)
                                          .withOpacity(0.7),
                                      fontSize: 20,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700),
                                  fillColor: const Color(0xFFFFFFFF),
                                  filled: true,
                                  contentPadding: const EdgeInsets.all(8),
                                ),
                                keyboardType: TextInputType.text,
                                obscureText: true,
                              ),
                              const SizedBox(height: 24),
                              //text field password
                              username.isNotEmpty &&
                                      password.isNotEmpty &&
                                      !isSuccessful
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            width: 3,
                                            color: const Color(
                                                0xFF444941) //                   <--- border width here
                                            ),
                                      ),
                                      child: Container(
                                        child: InkWell(
                                          onTap: loginUser,
                                          child: Container(
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            decoration: ShapeDecoration(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                              isLoading
                                                  ? 'VERIFYING...'
                                                  : 'LOGIN',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                shadows: <Shadow>[
                                                  Shadow(
                                                    offset: Offset(1.0, 1.0),
                                                    blurRadius: 1.0,
                                                    color: Color.fromARGB(
                                                        125, 0, 0, 255),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : (username.isEmpty || password.isEmpty) &&
                                          !isSuccessful
                                      ? Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                width: 3,
                                                color: const Color(
                                                    0xFF444941) //                   <--- border width here
                                                ),
                                          ),
                                          child: Container(
                                            child: InkWell(
                                              onTap: () {},
                                              child: Container(
                                                width: double.infinity,
                                                alignment: Alignment.center,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                decoration: ShapeDecoration(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  gradient:
                                                      const LinearGradient(
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
                                                child: const Text(
                                                  'LOGIN',
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 110, 106, 106),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    shadows: <Shadow>[
                                                      Shadow(
                                                        offset:
                                                            Offset(1.0, 1.0),
                                                        blurRadius: 1.0,
                                                        color: Color.fromARGB(
                                                            125, 0, 0, 255),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(height: 0),
                              const SizedBox(height: 40),
                              //Transitioning to sign up screen
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ))));
  }
}
