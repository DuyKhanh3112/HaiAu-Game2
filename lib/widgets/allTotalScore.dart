import 'package:flutter/material.dart';
import 'package:collection/collection.dart';


class TotalScore extends StatefulWidget {
  TotalScore({Key? key,required this.totalScores, required this.allUserName, required this.allUserId, required this.allPlayerList}) : super(key: key);

  List totalScores;
  List allUserName;
  List allUserId;
  List allPlayerList;

  @override
  State<TotalScore> createState() => _TotalScoreState(totalScores,allUserName,allUserId,allPlayerList);
}

class _TotalScoreState extends State<TotalScore> {

  late List totalScores;
  late List allUserName;
  late List allUserId;
  late List allPlayerList;

  List allTeamTotalScore = [];
  
  _TotalScoreState(this.totalScores, this.allUserName, this.allUserId, this.allPlayerList);

  @override
  void initState() {
    super.initState();
    categorizeAndSumScoresForEachTeam();
  }

  searchForName(userId){
    String currentUserName = '';
    for (int i = 0; i < allUserId.length;i++){
      if(userId == allUserId[i]){
        currentUserName = allPlayerList[i].name;
      }
    }
    return currentUserName;
  }

  searchForAvatar(userId){
    String currentAvatar = '';
    for (int i = 0; i < allUserId.length;i++){
      if(userId == allUserId[i]){
        currentAvatar = allPlayerList[i].avatar;
      }
    }
    return currentAvatar;
  }

  sortScoreList(arr){
    List indexedArr = [];
    List filteredArr = [];
    List newArr = arr;
    newArr.sort((a,b)=>b['score'].compareTo(a['score']));

    for(int i=0;i<newArr.length;i++){
      final existingData = filteredArr.where((e)=>e['id_user'] == newArr[i]['id_user']);
      if(existingData.isEmpty){
        filteredArr.add(newArr[i]);
      }
    }

    filteredArr.asMap().forEach((key,value)=>{
      indexedArr.add({
        "index":key,
        "data":value,
      })
    });
    return indexedArr;
  }

  checkForExistingTeamResult(userId){
    bool isExisting = false;
    for (int i = 0; i < allTeamTotalScore.length;i++){
      if(allTeamTotalScore[i]['id_user'] == userId){
        isExisting = true;
      }
    }

    return isExisting;
  }

  categorizeAndSumScoresForEachTeam(){
    for(var i = 0; i < totalScores.length; i++){
      var userInfo = {
        "id_user":totalScores[i].id_user,
        "avatar":searchForAvatar(totalScores[i].id_user),
        "name": searchForName(totalScores[i].id_user),
        "score":0,
      };

      for(var j = 0; j < totalScores.length; j++){
        if(totalScores[i].id_user.toString() == totalScores[j].id_user.toString()){
          userInfo['score'] = userInfo['score'] + totalScores[j].score;
        }
      }


      setState(() {
        allTeamTotalScore = [...allTeamTotalScore,userInfo];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:const EdgeInsets.symmetric(vertical:10,horizontal:20),
      child:Column(
        children:[
          const SizedBox(height:5),
            ...sortScoreList(allTeamTotalScore).map((e) => Container(
              decoration: BoxDecoration(
                color:(e['index']+1)%2 == 0 ? const Color(0xFFF2F2F2) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal:5,vertical:10),
              child:Row(
                children: [
                  e['index']+1 == 1
                  ?
                  Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/rtdyrotylzjzr3c00h0t.png',height:30)
                  :
                  e['index']+1 == 2
                  ?
                  Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/mgbxzflmkttbtakcl8eo.png',height:30)
                  :
                  e['index']+1 == 3
                  ?
                  Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659256477/x0gyryatf0chcyzcxxgb.png',height:30)
                  :
                  SizedBox(width:30,child: Center(child: Text((e['index']+1).toString(),style:TextStyle(fontWeight: FontWeight.w800,color:Colors.black.withOpacity(0.8),fontSize:25)))),
                  const SizedBox(width:10),
                  CircleAvatar(
                    radius:20,
                    backgroundImage: NetworkImage(e['data']['avatar']),
                  ),
                  const SizedBox(width:10,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['data']['name'].length>16 ? e['data']['name'].substring(0,16)+'...': e['data']['name'],style:const TextStyle(fontWeight: FontWeight.bold,color:Colors.black,fontSize:18)),
                      Row(
                        children: [
                          const Text('Tổng số điểm:',style:TextStyle(fontWeight: FontWeight.w500,color:Colors.green,fontSize:16)),
                          const SizedBox(width: 5,),
                          Text(e['data']['score'].toString(),style:const TextStyle(fontWeight: FontWeight.w500,color:Colors.green,fontSize:16)),
                        ],
                      ),
                    ]
                  )
                ],
              )
            ))
        ]
      )
    );
  }
}