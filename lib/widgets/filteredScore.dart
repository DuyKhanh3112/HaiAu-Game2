import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haiau_game2/Objects/scoreObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';

class SortedScore extends StatefulWidget {
  SortedScore({Key? key,required this.totalScores, required this.allUserName, required this.allUserId, required this.allPlayerList,required this.currentProgramId}) : super(key: key);

  List totalScores;
  List allUserName;
  List allUserId;
  List allPlayerList;
  
  String currentProgramId;

  @override
  State<SortedScore> createState() => _SortedScoreState(totalScores,allUserName,allUserId,allPlayerList,currentProgramId);
}

class _SortedScoreState extends State<SortedScore> {
  _SortedScoreState(this.totalScores, this.allUserName, this.allUserId, this.allPlayerList, this.currentProgramId);

  late List totalScores;
  late List allUserName;
  late List allUserId;
  late List allPlayerList;
  late String currentProgramId;
  
  String ? playerName;
  String ? playerId;

  List userResults = [];
  List allStageRelated = [];

  CollectionReference scoresCollection = FirebaseFirestore.instance.collection('scores');
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');



  fetchScoresForCurrentUser()async{
    final index = allUserName.indexOf(playerName);
    final currentPlayerId = allUserId[index];

    final snapshot = await scoresCollection.where('id_user',isEqualTo: currentPlayerId).get();
    final allData = snapshot.docs.map((doc) => Score.fromJson(doc.data() as Map<String, dynamic>)).toList();

    final snapshotStage = await stagesCollection.where('id_program',isEqualTo: currentProgramId).orderBy('order_index').get();
    final allRelatedStages = snapshotStage.docs.map((doc) => Stage.fromJson(doc.data() as Map<String, dynamic>)).toList();
    final allStageIds = snapshotStage.docs.map((doc) => doc.id).toList();
    final allStageName = snapshotStage.docs.map((doc) => doc['name']).toList();

    setState(() {
      userResults = allData;
    });

    List tempArr = [];

    for(int i=0; i<userResults.length; i++){
      Map newResult = {
        "stage":"",
        "score":userResults[i].score,
      };

      for(int j=0; j<allRelatedStages.length; j++){
          final index = allStageName.indexOf(allRelatedStages[j].name);
          final id =  allStageIds[index];
        if(userResults[i].id_stage == id){
          newResult['stage'] = allRelatedStages[j].name;
        }
      }
      tempArr.add(newResult);
    }

    setState(() {
      userResults = tempArr;
    }); 
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      child:Column(
        children: [
          const SizedBox(height:20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:20,vertical:0),
            child: Container(
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border:Border.all(
                  width:1,
                  color:Colors.grey,
                ),
                color: Colors.white,  
              ),
              child: DropdownButton<String>(
                isDense:true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(10),
                focusColor: Colors.white,
                hint: const Text('Chọn người chơi để xem'),
                value:playerName,
                isExpanded: true,
                items: <String>[...allUserName].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String ? newValue) {
                  setState(() {
                    playerName = newValue!;
                  });
                  fetchScoresForCurrentUser();
                },
              ),
            ),
          ),
          const SizedBox(height:10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical:10,horizontal:20),
            child: Column(
              children: [
                ...userResults.map((e) => Container(
                  decoration: BoxDecoration(
                    color:Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.23),
                        spreadRadius:1,
                        blurRadius:1,
                        offset: const Offset(1,1), // changes position of shadow
                      ),
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.23),
                        spreadRadius:1,
                        blurRadius:1,
                        offset: const Offset(-1,-1), // changes position of shadow
                      ),
                    ],
                  ),
                  margin:const EdgeInsets.symmetric(vertical:5),
                  padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
                  child: Row(
                    children: [
                      Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659098707/wznudxkak8yxhmw0frm2.png',height:35),
                      const SizedBox(width:10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['stage'].length>15 ? e['stage'].substring(0,15)+'...':e['stage'],style:const TextStyle(color: Colors.black,fontSize:17,fontWeight: FontWeight.w700,overflow:TextOverflow.ellipsis,)),
                          const SizedBox(height:5),
                          Text("Số điểm: ${e['score']}",style:const TextStyle(color: Colors.green,fontSize:15,fontWeight: FontWeight.w700,overflow:TextOverflow.ellipsis,))
                        ],
                      )
                    ]
                  ),
                ))
              ]
            ),
          ),
        ],
      )
    );
  }
}