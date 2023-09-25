import 'package:flutter/material.dart';

class ViewImagePage extends StatelessWidget {
  ViewImagePage({Key? key, required this.imageUrl}) : super(key: key);

  String ? imageUrl;

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(
        child:SingleChildScrollView(
          child:SizedBox(
            height: MediaQuery.of(context).size.height*1,
            child: Stack(
              children:[
                SizedBox(
                  height: MediaQuery.of(context).size.height*1,
                  child: Center(child: Image.network(imageUrl.toString(),fit: BoxFit.contain,))
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Quay lại',
                              style: TextStyle(fontSize: 18, color: Colors.white,fontWeight: FontWeight.w700))),
                    )
                  ]),
                ),
              ]
            ),
          )
        )
      ) ,
    );
  }
}