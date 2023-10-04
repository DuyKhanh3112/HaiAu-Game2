class Program {
  Program(this.name, this.duration, this.password);
  String? id;
  String name;
  String duration;
  String password;
  bool isAllowManyDevice = true;

  Program.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        name = json["name"],
        duration = json["duration"],
        password = json["password"],
        isAllowManyDevice = json["isAllowManyDevice"];

  Map<String, dynamic> toJson() => {
        "name": name,
        "duration": duration,
        "password": password,
        "isAllowManyDevice": isAllowManyDevice
      };
}
