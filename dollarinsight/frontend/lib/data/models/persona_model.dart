class PersonaModel {
  final int id;
  final String code;

  PersonaModel({
    required this.id,
    required this.code,
  });

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: json['id'] as int,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
    };
  }
}
