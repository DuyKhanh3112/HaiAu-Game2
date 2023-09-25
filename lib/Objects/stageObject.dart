class Stage {
  Stage(this.order_index, this.name, this.destination, this.password, this.id_program,this.description);
  String? id;
  int order_index;
  String name;
  String destination;
  String password;
  String id_program;
  String description;

  Stage.fromJson(Map<String, dynamic> json)
    : id = json["id"],
      order_index = json["order_index"],
      name = json["name"],
      destination = json["destination"],
      password = json["password"],
      id_program = json["id_program"],
      description = json["description"];

  Map<String, dynamic> toJson() => {
    "order_index": order_index,
    "name": name,
    "destination": destination,
    "password": password,
    "id_program": id_program,
    "description":description,
  };
}