import 'package:flutter/material.dart';

class ShowNotifyAlert extends StatelessWidget {
  final String errorText;
  final String type;
  const ShowNotifyAlert({Key? key,required this.errorText,required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(type,style:TextStyle(color:Colors.black,fontWeight: FontWeight.bold),),
      content: Text(errorText),
      actions: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal:15, vertical:15),
            textStyle: const TextStyle(
            fontWeight: FontWeight.bold)
          ),
          child: const Text('Đồng ý'),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }
}