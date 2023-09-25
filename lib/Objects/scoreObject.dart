class Score {
  Score(this.score, this.check_in, this.id_user, this.id_program, this.id_stage);
  String? id;
  int score;
  String check_in;
  String id_user;
  String id_program;
  String id_stage;

  Score.fromJson(Map<String, dynamic> json)
    : id = json["id"],
      score = json["score"],
      check_in = json["check_in"],
      id_user = json["id_user"],
      id_program = json["id_program"],
      id_stage = json["id_stage"];

  Map<String, dynamic> toJson() => {
    "score": score,
    "check_in": check_in,
    "id_user": id_user,
    "id_program": id_program,
    "id_stage": id_stage,
  };
}