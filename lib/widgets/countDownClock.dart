import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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

    DateTime timeUserStart;
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
              Text(
                hours < 10 ? "0${hours.toString()}" : hours.toString(),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              const Text(
                ":",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                minutes < 10 ? "0${minutes.toString()}" : minutes.toString(),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              const Text(
                ":",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                seconds < 10 ? "0${seconds.toString()}" : seconds.toString(),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
            ],
          )
        ],
      )
    ]);
  }
}
