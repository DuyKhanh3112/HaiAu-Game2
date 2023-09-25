class User {
  User(this.name, this.username, this.password, this.avatar, this.role,
      this.id_program, this.currentStage, this.startAt, this.isOnline);
  String? id;
  String name;
  String username;
  String password;
  String avatar;
  String role;
  String id_program;
  int currentStage;
  String startAt;
  String isOnline;

  User.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        name = json["name"],
        username = json["username"],
        password = json["password"],
        avatar = json["avatar"],
        role = json["role"],
        id_program = json["id_program"],
        currentStage = json["currentStage"],
        startAt = json["startAt"],
        isOnline = json["isOnline"];

  Map<String, dynamic> toJson() => {
        "name": name,
        "username": username,
        "password": password,
        "avatar": avatar,
        "role": role,
        "id_program": id_program,
        "currentStage": currentStage,
        "startAt": startAt,
        "isOnline":isOnline,
      };
}
